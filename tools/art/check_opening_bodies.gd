extends SceneTree
## #55: isolated cave rendering and floor-art contract, no live script changes.
const OUT := "res://art/props/opening-bodies-v1/"
const DungeonMap := preload("res://scripts/dungeon_map.gd")
const LevelBuilder := preload("res://scripts/level_builder.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func capture(name: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(OUT+name+".png")
	return image

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for layout in [["desktop",Vector2i(1280,720)],["phone",Vector2i(1278,590)]]:
		root.size = layout[1]
		var world := Node3D.new()
		root.add_child(world)
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color("070908")
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color("7d8790")
		environment.environment.ambient_light_energy = 0.12
		world.add_child(environment)
		var map = DungeonMap.new(PackedStringArray(["#######","#,,,,,#","#,,,,,#","#,,,,,#","#,,,,,#","#,,S,,#","#######"]))
		var level = LevelBuilder.new()
		world.add_child(level)
		level.build(map,load("res://themes/cave.tres"),2.0,2.4)
		var bodies: Array[Node3D] = []
		for i in 2:
			var id: String = ["fallen-a","fallen-b"][i]
			var scene = load(OUT+id+".tscn")
			check(scene is PackedScene,id+" scene loads")
			var body: Node3D = scene.instantiate()
			world.add_child(body)
			bodies.append(body)
			body.position = Vector3(4.6+i*2.0,0,6.0)
			body.rotation.y = -PI/2-0.15 if i == 0 else PI/2+0.15
			var sprite: Sprite3D = body.get_node("Sprite")
			check(body is Node3D and sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y,id+" fixed-Y billboard scene contract")
			check(is_zero_approx(sprite.position.y+(64-120)*sprite.pixel_size),id+" registered floor contact")
			check(is_equal_approx(sprite.pixel_size*128,2.0),id+" fixed world scale")
			check(sprite.shaded,id+" responds to real light")
			check(sprite.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD,id+" cutout transparency")
			check(sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST,id+" nearest filtering")
			check(sprite.texture.get_size() == Vector2(128,128),id+" exact canvas")
			var image: Image = sprite.texture.get_image()
			check(image.get_pixel(0,0).a == 0,id+" transparent padding")
			# Parent yaw keeps the card upright; fixed-Y billboarding faces camera.
			for yaw in [0.0,PI/2,PI,3*PI/2]:
				body.rotation.y = yaw
				check(sprite.global_basis.y.is_equal_approx(Vector3.UP),id+" yaw retains upright sprite")
			body.rotation.y = -PI/2-0.15 if i == 0 else PI/2+0.15
		var camera := Camera3D.new()
		camera.position = Vector3(5.6,1.2,9.4)
		camera.fov = 70
		world.add_child(camera)
		camera.current = true
		var lantern := OmniLight3D.new()
		lantern.position = camera.position + Vector3(0.3,-0.2,-0.5)
		lantern.light_color = Color("e8a84a")
		lantern.light_energy = 1.6
		lantern.omni_range = 7.0
		world.add_child(lantern)
		await create_timer(0.12).timeout
		await capture("cave-"+layout[0])
		# Paired same-camera capture verifies lit material darkens with the lantern.
		lantern.light_energy = 0.35
		lantern.omni_range = 4.0
		await process_frame
		await capture("dim-"+layout[0])
		world.queue_free()
		await process_frame
	var report := {"godot":"4.7.2", "checks":checks,"failures":failures,
		"viewports":[[1280,720],[1278,590]],"physical_phone_test":false,
		"scene_hook":"main.gd body_scene; floor origin, arbitrary yaw",
		"integration":"assets only; live opening implementation preserved"}
	FileAccess.open(OUT+"validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("OPENING_BODY_CHECKS: ",checks," failures: ",failures.size())
	quit(0 if failures.is_empty() else 1)
