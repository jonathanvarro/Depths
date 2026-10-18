extends SceneTree
## Isolated resource and cave-lighting review; does not load or modify Main.
const DungeonMap := preload("res://scripts/dungeon_map.gd")
const LevelBuilder := preload("res://scripts/level_builder.gd")
const DIR := "res://art/props/cave-room-props-v1/"
const OUT := "res://art/concepts/cave-room-props-v1/"
const NAMES := ["abandoned-pack", "pack-searched", "pale-idol", "still-pool", "cold-camp"]
var checks := 0
var failures: Array[String] = []
var captures := 0

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	for name in NAMES:
		var instance = load(DIR + name + ".tscn").instantiate()
		root.add_child(instance)
		var sprite: SpriteBase3D = instance.get_node("Sprite")
		var texture: Texture2D
		if sprite is AnimatedSprite3D:
			texture = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
			check(sprite.animation == (&"searched" if name == "pack-searched" else &"unsearched"), name + " correct initial state")
			check(not sprite.is_playing(), name + " static state")
			var before: Transform3D = instance.transform
			instance.set_searched(true)
			check(sprite.animation == &"searched" and instance.transform == before, name + " searches without moving")
			instance.set_searched(false)
			check(sprite.animation == &"unsearched" and instance.transform == before, name + " resets without moving")
		else:
			texture = sprite.texture
		check(texture.get_size() == Vector2(128,128), name + " exact canvas")
		check(texture.get_image().get_pixel(0,0).a == 0, name + " transparent exterior")
		check(sprite.shaded and sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, name + " lit nearest material")
		check(sprite.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD and is_equal_approx(sprite.alpha_scissor_threshold,0.5), name + " crisp alpha")
		if name == "still-pool":
			check(sprite.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "Pool remains in floor plane")
			check(sprite.transform.basis.z.is_equal_approx(Vector3.UP), "Pool faces upwards")
			check(sprite.position.y > 0 and sprite.position.y < 0.02, "Pool avoids floor z-fighting")
			check(texture.get_image().get_pixel(64,64).a == 1, "Pool water is opaque, not a shaft")
		else:
			check(sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y, name + " upright fixed-Y")
			check(is_zero_approx(sprite.position.y + (64-120)*sprite.pixel_size), name + " support-surface registration")
		check(instance.find_children("*", "Light3D", true, false).is_empty(), name + " no built-in light")
		check(instance.find_children("*", "CollisionObject3D", true, false).is_empty(), name + " no movement rules")
		check(instance.find_children("*", "GPUParticles3D", true, false).is_empty(), name + " no particles")
		instance.queue_free()
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await _capture_cave()
	var report := {"godot":"4.7.2", "checks":checks, "failures":failures, "captures":captures,
		"viewports":[[1280,720],[1278,590]], "physical_phone_test":false,
		"integration":"Reusable art scenes only; event placement and state wiring remain #46."}
	FileAccess.open(OUT + "godot-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("CAVE_ROOM_PROP_CHECKS: ", checks, " failures: ", failures.size(), " captures: ", captures)
	quit(0 if failures.is_empty() else 1)

func _capture_cave() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var map = DungeonMap.new(PackedStringArray(["#######","###.###","##,,,##","##,,,##","##,,,##","###S###","#######"]))
	var level := LevelBuilder.new()
	world.add_child(level)
	level.build(map,load("res://themes/cave.tres"),2.4,2.4)
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
	camera.position = Vector3(7.2,1.2,12)
	camera.fov = 70
	world.add_child(camera)
	var lantern := OmniLight3D.new()
	lantern.position = camera.position + Vector3(0.3,-0.2,-0.4)
	lantern.light_color = Color("e8a84a")
	lantern.omni_range = 8.4
	world.add_child(lantern)
	for name in NAMES:
		var prop = load(DIR + name + ".tscn").instantiate()
		prop.position = Vector3(7.2,0,9.6)
		world.add_child(prop)
		for phone in [false,true]:
			root.size = Vector2i(1278,590) if phone else Vector2i(1280,720)
			var suffix := "phone" if phone else "desktop"
			lantern.light_energy = 1.6
			var bright := await _capture(name + "-" + suffix)
			lantern.light_energy = 0.35
			var dim := await _capture(name + "-dim-" + suffix)
			check(_sample_light(dim) < _sample_light(bright),name + " dims in " + suffix)
		prop.queue_free()
		await process_frame
	world.queue_free()
	await process_frame

func _sample_light(image: Image) -> float:
	var total := 0.0
	for y in range(16,image.get_height(),32):
		for x in range(16,image.get_width(),32):
			total += image.get_pixel(x,y).get_luminance()
	return total

func _capture(label: String) -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.save_png(OUT + label + ".png") == OK,"Capture " + label)
	captures += 1
	return image
