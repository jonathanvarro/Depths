extends SceneTree
## #166 isolated surface/state review. No Main, gameplay saves or preferences.
const DM = preload("res://scripts/dungeon_map.gd")
const BUILDER = preload("res://scripts/level_builder.gd")
const SURFACE = "res://art/textures/drowned-water-v1/"
const PROP = "res://art/props/drowned-water-v1/sluice.tscn"
const OUT = "res://art/concepts/drowned-water-v1/"
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var world: Node3D
var wheel: Node3D
var waters: Array = []
var lamp: OmniLight3D
var caption: Label
var camera: Camera3D

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for i in 5: await process_frame

func run() -> void:
	for type in ["shallow","deep"]:
		var texture: Texture2D = load(SURFACE+type+".png")
		check(texture.get_size()==Vector2(128,128),type+" native128")
		check(texture.get_image().get_format()!=Image.FORMAT_RGBA8 or texture.get_image().get_pixel(0,0).a==1,type+" opaque water")
		var surface = load(SURFACE+type+".tscn").instantiate()
		root.add_child(surface)
		surface.configure(Vector2i(3,5),2.0,false)
		check(surface.mesh.size==Vector2(2,2),type+" exact cell footprint")
		check(surface.position==Vector3(6,0.12 if type=="deep" else 0.018,10),type+" world-grid origin")
		if type=="deep":
			check(surface.mesh.material is ShaderMaterial,"Deep uses one opaque shader")
			check(surface.mesh.material.get_shader_parameter("motion_enabled")==false,"Still mode")
			surface.set_motion(true)
			check(surface.mesh.material.get_shader_parameter("motion_enabled")==true,"Motion can resume")
		else:
			check(surface.mesh.material.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST,"Shallow nearest sampling")
		surface.free()
	var test: Node3D = load(PROP).instantiate()
	root.add_child(test)
	var sprite: Sprite3D = test.get_node("Sprite")
	var pos := sprite.position
	var pixel := sprite.pixel_size
	var closed: Texture2D = sprite.texture
	check(closed.get_size()==Vector2(192,192),"Sluice native192")
	check(sprite.billboard==BaseMaterial3D.BILLBOARD_DISABLED,"Sluice is wall mounted, not camera-facing")
	test.state="empty"
	check(sprite.texture!=closed and sprite.texture.resource_path.ends_with("sluice-open.png"),"Resolved state opens the gate")
	check(sprite.position==pos and sprite.pixel_size==pixel,"State retains exact registration")
	check(sprite.texture.get_image().get_pixel(120,110).a>0.99,"Open passage is opaque, not a hole through the wall")
	test.state="closed"
	check(sprite.texture==closed,"Ready state restores the closed gate")
	test.free()
	if DisplayServer.get_name()=="headless" or "--shots" not in OS.get_cmdline_user_args():
		finish("headless-validation.json")
		return
	build_world()
	await settle()
	for size in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=size
		camera.position.z=5.6
		for state in ["dry","shallow","deep","sluice-closed","sluice-open","dim-still"]:
			set_state(state)
			await snap(state+"-"+str(size.x))
		camera.position.z=3.5
		for state in ["sluice-closed","sluice-open"]:
			set_state(state)
			await snap(state+"-near-"+str(size.x))
	# Hold the camera, lights and caption still: only the deep shader can move.
	camera.position.z=5.6
	set_state("deep");caption.text="Motion comparison · unchanged camera and light"
	for surface in waters:
		if surface.deep:surface.set_motion(true)
	await settle();await RenderingServer.frame_post_draw
	var a := root.get_texture().get_image().get_data()
	await create_timer(1.1).timeout
	await RenderingServer.frame_post_draw
	check(a!=root.get_texture().get_image().get_data(),"Actual renderer shows gentle water motion")
	DirAccess.make_dir_recursive_absolute("res://build/drowned-water-review/motion")
	for frame in 12:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/drowned-water-review/motion/%02d.png"%frame)
		await create_timer(0.25).timeout
	for surface in waters:
		if surface.deep:surface.set_motion(false)
	await settle();await RenderingServer.frame_post_draw
	var frozen := root.get_texture().get_image().get_data()
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	check(frozen==root.get_texture().get_image().get_data(),"Actual still-mode pixels remain fixed")
	world.queue_free()
	for child in root.get_children():
		if child is CanvasLayer:child.queue_free()
	waters.clear();wheel=null;lamp=null;caption=null;camera=null
	await process_frame;await process_frame
	finish("render-validation.json")

func build_world() -> void:
	world=Node3D.new();root.add_child(world)
	var environment := Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("080c0b")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("515d5a")
	environment.ambient_light_energy=0.45
	var env := WorldEnvironment.new();env.environment=environment;world.add_child(env)
	var map=DM.new(PackedStringArray(["#####","#...#","#...#","#.S.#","#####"]),5)
	var level=BUILDER.new();world.add_child(level)
	level.build(map,load("res://themes/cave.tres"),2.0,2.4)
	for y in range(1,4):
		for x in range(1,4):
			for deep in [false,true]:
				if deep and x!=2:continue
				var surface=load(SURFACE+("deep" if deep else "shallow")+".tscn").instantiate()
				world.add_child(surface);surface.configure(Vector2i(x,y),2.0,false)
				surface.set_meta("x",x);waters.append(surface)
	wheel=load(PROP).instantiate();world.add_child(wheel)
	wheel.position=Vector3(4,0,1.025)
	camera=Camera3D.new();world.add_child(camera)
	camera.position=Vector3(4,1.15,5.6);camera.fov=70;camera.current=true
	lamp=OmniLight3D.new();world.add_child(lamp)
	lamp.position=Vector3(3.7,1.45,4.2)
	lamp.light_color=Color("f6c78d");lamp.light_energy=2.0;lamp.omni_range=10
	var ui := CanvasLayer.new();root.add_child(ui)
	caption=Label.new();ui.add_child(caption)
	caption.position=Vector2(54,20);caption.add_theme_font_size_override("font_size",20)
	caption.add_theme_color_override("font_color",Color("eadfc3"))
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",2);caption.add_theme_constant_override("shadow_offset_y",2)

func set_state(state: String) -> void:
	wheel.visible=state.begins_with("sluice-")
	wheel.state="empty" if state=="sluice-open" else "closed"
	lamp.light_energy=0.65 if state=="dim-still" else 2.0
	for surface in waters:
		surface.visible=state!="dry" and state!="sluice-open" and (surface.deep if state in ["deep","sluice-closed","dim-still"] and surface.get_meta("x")==2 else not surface.deep)
		surface.set_motion(false)
	caption.text=state+" · actual Godot renderer · native water and sluice art review"

func snap(name: String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Capture "+name)
	captures.append(name+".png")

func finish(name: String) -> void:
	FileAccess.open(OUT+name,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"scope":"Isolated asset library; live floor placement remains Claude's hookup","physical_iphone":false},"  ")+"\n")
	print("DROWNED_WATER checks=",checks," failures=",failures.size()," captures=",captures.size())
	quit(0 if failures.is_empty() else 1)
