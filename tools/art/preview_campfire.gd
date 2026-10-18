extends SceneTree
## Isolated cave preview; does not load Main or modify live room events.
const DungeonMap := preload("res://scripts/dungeon_map.gd")
const LevelBuilder := preload("res://scripts/level_builder.gd")
const FIRE := preload("res://art/features/campfire-v1/scene.tscn")
const OUT := "res://art/concepts/campfire-v1/"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if "--live" in OS.get_cmdline_user_args():
		await _live_opening()
		return
	var world := Node3D.new()
	root.add_child(world)
	var map = DungeonMap.new(PackedStringArray([
		"#######", "###.###", "##,,,##", "##,,,##", "##,,,##", "###S###", "#######"
	]))
	var geometry := LevelBuilder.new()
	world.add_child(geometry)
	geometry.build(map, load("res://themes/cave.tres"), 2.4, 2.4)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.BLACK
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("1a2424")
	environment.ambient_light_energy = 0.4
	environment.fog_enabled = true
	environment.fog_light_color = Color.BLACK
	environment.fog_density = 0.08
	var world_env := WorldEnvironment.new()
	world_env.environment = environment
	world.add_child(world_env)
	var camera := Camera3D.new()
	camera.position = Vector3(7.2, 1.2, 12)
	camera.fov = 70
	world.add_child(camera)
	var fire := FIRE.instantiate() as Node3D
	fire.position = Vector3(7.2, 0, 9.6)
	world.add_child(fire)
	var flames := fire.get_node("Flames") as AnimatedSprite3D
	var base := fire.get_node("Base") as Sprite3D
	var light := fire.get_node("Light") as OmniLight3D
	assert(flames.sprite_frames.get_frame_count("burn") == 6)
	assert(flames.sprite_frames.get_animation_loop("burn"))
	assert(flames.is_playing())
	assert(base.shaded and not flames.shaded)
	assert(not light.shadow_enabled)
	assert(fire.get_node("LightAnimation").is_playing())
	var start_frame := flames.frame
	await create_timer(0.16).timeout
	assert(flames.frame != start_frame, "Autoplay must advance")
	var root_position := fire.position
	await create_timer(0.8).timeout
	assert(fire.position == root_position and flames.is_playing())
	if "--capture" not in OS.get_cmdline_user_args():
		print("CAMPFIRE_RESOURCE_CHECKS_PASS: 8; scene ready")
		quit()
		return
	for phone in [false, true]:
		root.size = Vector2i(1278, 590) if phone else Vector2i(1280, 720)
		var suffix := "phone" if phone else "desktop"
		camera.position = Vector3(7.2, 1.2, 12)
		camera.rotation = Vector3.ZERO
		await _capture("cave-" + suffix)
		camera.position = Vector3(8.15, 1.2, 11.55)
		camera.look_at(fire.position + Vector3(0, 0.45, 0))
		await _capture("angle-" + suffix)
		camera.position = Vector3(7.2, 1.2, 14.4)
		camera.rotation = Vector3.ZERO
		await _capture("distant-" + suffix)
	root.size = Vector2i(1280, 720)
	for view in [["east", Vector3.RIGHT], ["north", Vector3.FORWARD], ["west", Vector3.LEFT]]:
		var direction: Vector3 = view[1]
		camera.position = fire.position + direction * 2.4 + Vector3.UP * 1.2
		camera.look_at(camera.position - direction)
		await _capture("side-" + view[0])
	# Capture a real loop with the renderer; disabling its pulse makes the
	# animation's fixed base registration easy to inspect frame by frame.
	root.size = Vector2i(768, 432)
	camera.position = Vector3(7.2, 1.2, 12)
	camera.rotation = Vector3.ZERO
	flames.pause()
	fire.get_node("LightAnimation").stop()
	light.light_energy = 0.9
	for frame in range(6):
		flames.frame = frame
		await _capture("loop-" + str(frame))
	print("CAMPFIRE_CAVE_RENDERS_SAVED: 15; resource checks pass")
	quit()

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUT + label + ".png")
	assert(error == OK, label)

func _live_opening() -> void:
	# Validate Claude's independently committed hook without editing Main.
	for phone in [false, true]:
		root.size = Vector2i(1278, 590) if phone else Vector2i(1280, 720)
		var main = load("res://scenes/main.tscn").instantiate()
		main.floor_seed = 33
		main.play_opening = true
		main.use_debug_layout = false
		main.simulate_phone_safe_area = phone
		root.add_child(main)
		await create_timer(3.6).timeout
		assert(main._in_opening)
		var fire: Node3D = main._level.get_node("Campfire")
		assert(fire.scene_file_path == "res://art/features/campfire-v1/scene.tscn")
		assert(fire.get_node("Flames").is_playing())
		assert(fire.get_node("LightAnimation").is_playing())
		await _capture("opening-" + ("phone" if phone else "desktop"))
		main.queue_free()
		await process_frame
	print("CAMPFIRE_LIVE_OPENING_CHECKS_PASS: 8; two viewports saved")
	quit()
