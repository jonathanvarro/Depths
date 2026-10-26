extends SceneTree
## Isolated material/placement/animation review; no Main, saves or audio.
const DM:=preload("res://scripts/dungeon_map.gd")
const BUILDER:=preload("res://scripts/level_builder.gd")
const DRESS:=preload("res://scripts/fungal_dressing.gd")
const THEME:=preload("res://themes/fungal-caverns.tres")
const GENERATOR:=preload("res://scripts/floor_generator.gd")
const SETTINGS:=preload("res://scripts/settings.gd")
const OUT:="res://art/concepts/fungal-caverns-v1/"
var checks:=0
var failures:Array[String]=[]
var captures:Array[String]=[]

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	Engine.set_meta("depths_settings",SETTINGS.DEFAULTS.duplicate())
	Engine.set_meta("depths_settings_loaded",true)
	call_deferred("run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 6:await process_frame

func signature(level:Node3D) -> Array:
	return level.get_node("Dressing").get_children().map(func(p):return [p.get_meta("dressing_id"),p.position,p.rotation])

func snap(name:String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Capture "+name)
	captures.append(name+".png")

func run() -> void:
	for material:StandardMaterial3D in [THEME.wall_material,THEME.floor_material,THEME.ceiling_material]:
		check(material.albedo_texture.get_size()==Vector2(128,128) and material.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST,"Native128 nearest surface")
		check(not material.emission_enabled and material.roughness==1.0,"Neutral rough surface without baked glow")
	check(THEME.wall_material==THEME.wall_variant_material,"Both wall variants belong to the same family")
	var pit:=THEME.descent_scene.instantiate()
	check(pit.get_node("Ground").material_override==THEME.floor_material,"Pit ground matches the environment floor")
	pit.free()
	var categories:={}
	var total:=0
	for seed_value in 48:
		var map=DM.new(GENERATOR.generate(seed_value*7919+31,true,2),2)
		var avoid:={map.start_cell+Vector2i.DOWN:true}
		var before:=var_to_str([map._rows,map.contents,map.doors,map.triggered,map.solid])
		var level:=Node3D.new();root.add_child(level)
		var count:=DRESS.dress(level,map,2,seed_value,2.0,2.4,avoid)
		var pieces:=level.get_node("Dressing").get_children()
		var forbidden:=[]
		var geometry_ok:=true
		var cells:={}
		for p:Node3D in pieces:
			var cell:Vector2i=p.get_meta("cell")
			if map.content_at(cell)!=DM.Content.NONE or map.door_at(cell)!=DM.Door.NONE or map.events.has(cell) or map.encounter_zones.has(cell) or cell==map.start_cell or avoid.has(cell):forbidden.append(cell)
			geometry_ok=geometry_ok and not cells.has(cell)
			cells[cell]=true
			if p.get_meta("mount")=="ceiling":geometry_ok=geometry_ok and p.position.y>=2.35
			if p.get_meta("mount")=="edge":geometry_ok=geometry_ok and Vector2(p.position.x-cell.x*2,p.position.z-cell.y*2).length()>=0.75
			categories[p.get_meta("dressing_id")]=true
		check(forbidden.is_empty(),"Seed %d excludes usable cells, encounter rooms, arrivals and reserved landmarks"%seed_value)
		check(geometry_ok and count<map.floor_cell_count()/2,"Seed %d sparse edge/ceiling placement, at most one piece per cell"%seed_value)
		check(var_to_str([map._rows,map.contents,map.doors,map.triggered,map.solid])==before,"Seed %d cosmetics do not mutate the map"%seed_value)
		var second:=Node3D.new();root.add_child(second)
		DRESS.dress(second,map,2,seed_value,2.0,2.4,avoid)
		check(signature(level)==signature(second),"Seed %d stable second visit"%seed_value)
		total+=count;level.free();second.free()
	check(categories.has("moss-curtain-lit") and categories.has("floor-fungus-lit") and categories.has("wall-roots"),"Generated environments use registered growth, roots and separate glow")
	var world:=Node3D.new();root.add_child(world)
	var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color.BLACK
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("1a2424");env.ambient_light_energy=0.4
	env.fog_enabled=true;env.fog_light_color=Color.BLACK;env.fog_density=0.08
	var we:=WorldEnvironment.new();we.environment=env;world.add_child(we)
	var map=DM.new(PackedStringArray(["#############","#...........#","#..###......#","#....#......#","#....#......#","#....#......#","###.#####.###","#...........#","#.....S.....#","#############"]),2)
	var level:=BUILDER.new();world.add_child(level);level.build(map,THEME,2,2.4)
	var wall:Mesh=level.get_children().filter(func(n):return n is MeshInstance3D and n.mesh is ArrayMesh)[0].mesh
	var wall_arrays:=wall.surface_get_arrays(0)
	var texcoords:PackedVector2Array=wall_arrays[Mesh.ARRAY_TEX_UV]
	check(Array(texcoords).all(func(v):return v.x>=0 and v.x<=1 and v.y>=0 and v.y<=1),"Wall tile UVs fit each full face")
	check(wall_arrays[Mesh.ARRAY_VERTEX].size()==24,"Full-face mapping retains ordinary box geometry")
	DRESS.dress(level,map,2,23,2,2.4)
	var party:=preload("res://scripts/party.gd").new();world.add_child(party);party.setup(2)
	party.locked=true;party.camera.current=true
	var viewpoints:={"hall":[Vector2i(9,5),0],"roots":[Vector2i(2,5),0],"crossing":[Vector2i(6,7),1],"wall":[Vector2i(11,3),1]}
	for shape in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=shape
		for id:String in viewpoints:
			var cell:Vector2i=viewpoints[id][0]
			party.position=Vector3(cell.x*2,0,cell.y*2);party.rotation.y=-viewpoints[id][1]*PI/2.0
			party.set_light(0.8)
			await snap("%s-%d-lantern"%[id,shape.x])
	party.position=Vector3(18,0,10);party.rotation.y=0
	var ambient_color:=env.ambient_light_color
	env.ambient_light_color=Color.WHITE;env.ambient_light_energy=0.65
	party.set_light(0);await snap("hall-neutral-review")
	env.ambient_light_color=ambient_color;env.ambient_light_energy=0.4
	party.set_light(0.12);await snap("hall-phone-dim")
	party.set_light(0);await snap("hall-phone-out")
	var dresser=level.get_node("Dressing")
	check(not dresser._animations.is_empty(),"Review contains real animated growth or drops")
	Engine.get_meta("depths_settings")["flashes"]=false;await settle()
	check(dresser._animations.all(func(s):return not s.is_playing()),"Settings disables all dressing motion")
	check(dresser._animations.filter(func(s):return s.sprite_frames==DRESS.DRIP).all(func(s):return not s.visible),"Still mode removes falling drops")
	var frames:Array=dresser._animations.map(func(s):return s.frame)
	await create_timer(0.4).timeout
	check(frames==dresser._animations.map(func(s):return s.frame),"Still frames remain unchanged over time")
	await snap("hall-phone-still")
	Engine.get_meta("depths_settings")["flashes"]=true;await settle()
	check(dresser._animations.all(func(s):return s.is_playing()),"Re-enabling effects resumes the same drawings")
	check(dresser.find_children("*","CollisionObject3D",true,false).is_empty() and dresser.find_children("*","Light3D",true,false).is_empty(),"Dressing adds neither colliders nor light sources")
	world.free();await settle()
	var file:=FileAccess.open(OUT+"validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"seeds":48,"pieces_reviewed":total,"categories":categories.keys(),"captures":captures,"physical_iPhone":false,"uses_saves":false},"\t")+"\n");file.close()
	print("FUNGAL_CAVERNS: checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
