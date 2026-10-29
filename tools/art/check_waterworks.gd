extends SceneTree
## Isolated asset fixture; no Main, saves, preferences or audio.
const DM = preload("res://scripts/dungeon_map.gd")
const BUILDER = preload("res://scripts/level_builder.gd")
const TEX := "res://art/textures/waterworks-v1/"
const PROP := "res://art/dressing/waterworks-v1/"
const OUT := "res://art/concepts/waterworks-v1/"
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var world: Node3D
var camera: Camera3D
var lamp: OmniLight3D
var level: Node3D
var waters: Array = []
var props: Array = []

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	for id in ["wet-plain","wet-channelled"]:
		var mat: StandardMaterial3D = load(TEX+id+".tres")
		check(mat.albedo_texture.get_size()==Vector2(128,128),id+" native128")
		check(mat.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST,id+" nearest")
		check(mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,id+" opaque")
		check(not mat.emission_enabled,id+" no emission")
	for id in ["dripping-channel","broken-pipe","silted-lamp"]:
		var item: Node3D = load(PROP+id+".tscn").instantiate()
		root.add_child(item)
		var sprite: Sprite3D = item.get_node("Sprite")
		check(sprite.texture.get_size()==Vector2(128,128),id+" native128")
		check(sprite.billboard==BaseMaterial3D.BILLBOARD_DISABLED,id+" fixed mount")
		check(sprite.shaded and sprite.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST,id+" world light and nearest")
		check(sprite.alpha_cut==SpriteBase3D.ALPHA_CUT_DISCARD,id+" hard alpha")
		check(item.get_child_count()==1,id+" one sprite, no light, collision or particles")
		check(sprite.pixel_size*128<=1.8,id+" cell-safe canvas")
		item.free()
	if DisplayServer.get_name()=="headless" or "--shots" not in OS.get_cmdline_user_args():
		finish("headless-validation.json")
		return
	build_world()
	for size in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=size
		for wall in ["wet-plain","wet-channelled"]:
			build_level(wall)
			for state in ["dry","shallow","deep","dim"]:
				lamp.light_energy=0.7 if state=="dim" else 2.0
				for water in waters:
					water.visible=state!="dry" and (water.deep if state in ["deep","dim"] and water.get_meta("x")==2 else not water.deep)
				camera.position=Vector3(4,1.15,5.6)
				camera.rotation=Vector3.ZERO
				await snap(wall+"-"+state+"-"+str(size.x))
		# Close range to check hard-alpha margins and wall contact.
		camera.position=Vector3(4,1.15,3.5)
		camera.look_at(Vector3(4,0.65,1))
		lamp.light_energy=2.0
		await snap("mounts-near-"+str(size.x))
	world.queue_free()
	waters.clear();props.clear();level=null;camera=null;lamp=null
	await process_frame
	await process_frame
	finish("render-validation.json")

func build_world() -> void:
	world=Node3D.new();root.add_child(world)
	var e := Environment.new()
	e.background_mode=Environment.BG_COLOR;e.background_color=Color("080c0b")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("515d5a");e.ambient_light_energy=0.45
	var env := WorldEnvironment.new();env.environment=e;world.add_child(env)
	for y in range(1,4):
		for x in range(1,4):
			for deep in [false,true]:
				if deep and x!=2:continue
				var water=load("res://art/textures/drowned-water-v1/"+("deep" if deep else "shallow")+".tscn").instantiate()
				world.add_child(water);water.configure(Vector2i(x,y),2.0,false)
				water.set_meta("x",x);waters.append(water)
	var positions := [Vector3(3.4,1.23,1.025),Vector3(4.55,0.8,1.025),Vector3(4.4,0,2)]
	var ids := ["dripping-channel","broken-pipe","silted-lamp"]
	for i in 3:
		var item=load(PROP+ids[i]+".tscn").instantiate()
		world.add_child(item);item.position=positions[i];props.append(item)
		check(item.position.x>3 and item.position.x<5,ids[i]+" remains within front cell width")
	# Existing sluice for a material/scale reference, on another wall cell.
	var sluice=load("res://art/props/drowned-water-v1/sluice.tscn").instantiate()
	world.add_child(sluice);sluice.position=Vector3(6,0,1.025)
	camera=Camera3D.new();world.add_child(camera);camera.fov=70;camera.current=true
	lamp=OmniLight3D.new();world.add_child(lamp)
	lamp.position=Vector3(3.7,1.45,4.2);lamp.light_color=Color("f6c78d");lamp.omni_range=10

func build_level(id: String) -> void:
	if level:
		world.remove_child(level);level.queue_free()
	var theme=load("res://themes/cave.tres").duplicate()
	theme.wall_material=load(TEX+id+".tres");theme.wall_variant_material=theme.wall_material
	theme.wall_face_uv=true
	theme.floor_material=load("res://art/textures/descent-surfaces-v1/drowned-masonry-floor.tres")
	theme.ceiling_material=load("res://art/textures/descent-surfaces-v1/drowned-masonry-ceiling.tres")
	var map=DM.new(PackedStringArray(["#####","#...#","#...#","#.S.#","#####"]),5)
	level=BUILDER.new();world.add_child(level);level.build(map,theme,2.0,2.4)

func snap(id: String) -> void:
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+id+".png")==OK,"Capture "+id)
	captures.append(id+".png")

func finish(name: String) -> void:
	FileAccess.open(OUT+name,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"physical_iphone":false,"scope":"Standalone assets and isolated mounting; live dressing/quest placement untouched"},"  ")+"\n")
	print("WATERWORKS checks=",checks," failures=",failures.size()," captures=",captures.size())
	quit(0 if failures.is_empty() else 1)
