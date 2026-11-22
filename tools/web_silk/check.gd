extends SceneTree
## #274: actual LevelBuilder/Party flow and same-camera before/after rendering.
const MAP := preload("res://scripts/dungeon_map.gd")
const BUILDER := preload("res://scripts/level_builder.gd")
const PARTY := preload("res://scripts/party.gd")
const ART := "res://art/features/web-silk-v2/"
var output := "res://build/web-silk-check"
var checks := 0
var failures: Array[String] = []
var stage: Node3D
var builder: Node3D
var party: Node3D
var map
var cell: Vector2i

func _initialize() -> void:
	if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 5:await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"saved "+name)

func fixture(theme,across := false) -> void:
	if is_instance_valid(stage):stage.free()
	stage=Node3D.new()
	root.add_child(stage)
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color.BLACK
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("1a2424")
	env.ambient_light_energy=.4
	env.fog_enabled=true
	env.fog_light_color=Color.BLACK
	env.fog_density=.08
	var world:=WorldEnvironment.new()
	world.environment=env
	stage.add_child(world)
	map=MAP.new(PackedStringArray(["#######","#..D.S#","#######"]) if across else PackedStringArray(["#####","##.##","##D##","##S##","#####"]))
	cell=Vector2i(3,1) if across else Vector2i(2,2)
	builder=BUILDER.new()
	stage.add_child(builder)
	builder.build(map,theme,2.0,2.4)
	party=PARTY.new()
	stage.add_child(party)
	party.setup(2.0)
	party.place(map,map.start_cell)
	if across:
		party.facing=3
		party.rotation.y=PI/2
	party.camera.current=true
	party.set_light(1.0)
	party.opened_door.connect(builder.refresh_door)
	party.set_process(false) # use the real step method without held desktop input

func run() -> void:
	var intact: Mesh=load(ART+"intact.res")
	var torn: Mesh=load(ART+"torn.res")
	var whole:=intact.surface_get_arrays(0)
	var opened:=torn.surface_get_arrays(0)
	check(whole[Mesh.ARRAY_VERTEX]==opened[Mesh.ARRAY_VERTEX],"all surviving silk shares the intact vertex registration")
	check(whole[Mesh.ARRAY_TEX_UV]==opened[Mesh.ARRAY_TEX_UV],"both states share the exact painting coordinates")
	check(whole[Mesh.ARRAY_INDEX].size()/3==1344,"intact budget is 1344 triangles")
	check(opened[Mesh.ARRAY_INDEX].size()/3==816,"torn budget is 816 triangles")
	check(intact.get_aabb().position.x>=-1.001 and intact.get_aabb().end.x<=1.001,"wall anchors fit a 2m passage")
	check(intact.get_aabb().position.y>=0 and intact.get_aabb().end.y<=2.4,"floor/ceiling envelope retained")
	check(intact.get_aabb().size.z>.06 and intact.get_aabb().size.z<.12,"silk has restrained physical depth")
	check(FileAccess.get_file_as_string(ART+"silk.png.import").contains("mipmaps/generate=true"),"fine fibers have distance mipmaps")
	var central_triangles:=0
	for index in range(0,opened[Mesh.ARRAY_INDEX].size(),3):
		var centre:=Vector3.ZERO
		for j in 3:centre+=opened[Mesh.ARRAY_VERTEX][opened[Mesh.ARRAY_INDEX][index+j]]/3.0
		if absf(centre.x)<.50 and centre.y<1.77:central_triangles+=1
	check(central_triangles==0,"torn state has a genuine clear central aperture")
	for theme_id in ["cave","fungal-caverns"]:
		var theme=load("res://themes/"+theme_id+".tres")
		check(theme.closed_scene.resource_path==ART+"intact.tscn",theme_id+" binds intact silk")
		check(theme.opened_scene.resource_path==ART+"torn.tscn",theme_id+" binds torn silk")
		for across in [false,true]:
			for state in ["previous","refined","torn"]:
				var selected=theme.duplicate()
				if state=="previous":selected.closed_scene=load("res://art/features/transitions-3d-v1/web-intact.tscn")
				fixture(selected,across)
				if state=="torn":
					map.open_door(cell)
					builder.refresh_door(cell)
				await settle()
				var feature: Node3D=builder._door_nodes[cell]
				check(is_equal_approx(absf(feature.rotation.y),PI/2 if across else 0.0),"corridor orientation "+state)
				check(feature.position==Vector3(cell.x*2.0,0,cell.y*2.0),"metric placement "+state)
				if state!="previous":
					check(feature.find_children("*","CollisionObject3D",true,false).is_empty(),"silk has no collision authority")
					var before: Transform3D=feature.get_child(0).transform
					feature.set_motion(false)
					feature.set_motion(true)
					check(feature.get_child(0).transform==before,"silk stays static")
				root.size=Vector2i(1280,720)
				await capture(theme_id+"-"+state+("-across" if across else ""))
		# Close -> tear -> traverse -> restore uses the real Party and builder.
		fixture(theme)
		var start: Vector2i=party.cell
		party._try_step(Vector2i.UP)
		await create_timer(PARTY.TEAR_TIME+.05).timeout
		check(map.door_at(cell)==MAP.Door.OPEN and party.cell==start,"tearing opens the passage and leaves the party in place")
		check(builder._door_nodes[cell].get_meta("asset_id")=="web-torn","real opening selects the registered torn state")
		party._try_step(Vector2i.UP)
		await create_timer(PARTY.MOVE_TIME+.05).timeout
		check(party.cell==cell,"the cleared passage can be traversed")
		map.doors[cell]=MAP.Door.CLOSED
		builder.refresh_door(cell)
		check(builder._door_nodes[cell].get_meta("asset_id")=="web-intact","restored closed state selects intact silk immediately")
		map.doors[cell]=MAP.Door.OPEN
		map.marks["cleared"]=[cell]
		builder.refresh_door(cell)
		check(not builder._door_nodes.has(cell),"a hacked-away blockage still leaves an empty way")
		for size in [Vector2i(844,390),Vector2i(667,375)]:
			root.size=size
			fixture(theme)
			await capture(theme_id+"-phone-"+str(size.x))
			map.open_door(cell);builder.refresh_door(cell)
			await capture(theme_id+"-torn-phone-"+str(size.x))
		# Back and oblique views expose any one-sided or flat-sheet failures.
		fixture(theme)
		party.position=Vector3(cell.x*2.0,0,cell.y*2.0-2.0)
		party.rotation.y=PI
		await capture(theme_id+"-reverse")
		party.position.x+=.65
		party.camera.look_at(Vector3(cell.x*2.0,1.2,cell.y*2.0))
		await capture(theme_id+"-oblique")
		fixture(theme)
		party.position.z+=2.0
		await capture(theme_id+"-distant")
		party.position.z-=2.0
		party.set_light(.1)
		await capture(theme_id+"-dim")
	stage.free()
	FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_iPhone":false},"\t"))
	print("WEB_SILK checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
