extends SceneTree
## Isolated #70 art checks/captures; never loads Main or changes room contents.
const DungeonMap := preload("res://scripts/dungeon_map.gd")
const LevelBuilder := preload("res://scripts/level_builder.gd")
const OUT := "res://art/concepts/opening-tutorial-v1/"
const CHEST := "res://art/props/tutorial-chest-v1/"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var knife: Equipment = load("res://data/gear/broken_knife.tres")
	check(knife.icon.resource_path == "res://art/items/opening-tutorial-v1/broken-knife.png", "Broken knife uses its own icon")
	check(knife.attack_min == 1 and knife.attack_max == 2 and is_equal_approx(knife.accuracy_bonus, -0.05), "Weapon values unchanged")
	for item in ["broken-knife", "damaged-armour"]:
		var texture: Texture2D = load("res://art/items/opening-tutorial-v1/" + item + ".png")
		check(texture.get_size() == Vector2(64,64), item + " exact 64px canvas")
		check(texture.get_image().get_pixel(0,0).a == 0, item + " transparent margins")
	for state in ["closed", "open", "empty"]:
		var instance = load(CHEST + state + ".tscn").instantiate()
		root.add_child(instance)
		var sprite: AnimatedSprite3D = instance.get_node("Sprite")
		check(sprite.animation == StringName(state), state + " convenience scene selects its state")
		check(sprite.sprite_frames.get_frame_count(StringName(state)) == 1 and not sprite.is_playing(), state + " is a static state")
		var texture := sprite.sprite_frames.get_frame_texture(StringName(state), 0)
		check(texture.get_size() == Vector2(128,128), state + " exact 128px canvas")
		check(sprite.shaded and sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, state + " lit nearest material")
		check(sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y and sprite.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD, state + " upright cutout")
		check(is_zero_approx(sprite.position.y + (64-120)*sprite.pixel_size), state + " floor registration")
		var position_before: Vector3 = instance.position
		for target in ["closed", "open", "empty"]:
			instance.set_state(target)
			check(sprite.animation == StringName(target) and instance.position == position_before, state + " swaps without moving")
		instance.queue_free()
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await _capture_cave()
	var report := {"godot":"4.7.2", "checks": checks, "failures": failures,
		"viewports":[[1280,720],[1278,590]], "physical_phone_test":false,
		"integration":"Broken knife icon connected; chest scenes and armour art ready; Main/room implementation preserved."}
	FileAccess.open(OUT + "godot-validation.json", FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("OPENING_TUTORIAL_ART_CHECKS: ",checks," failures: ",failures.size())
	quit(0 if failures.is_empty() else 1)

func _capture_cave() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var map = DungeonMap.new(PackedStringArray(["#######","###.###","##,,,##","##,,,##","##,,,##","###S###","#######"]))
	var level := LevelBuilder.new()
	world.add_child(level)
	level.build(map, load("res://themes/cave.tres"), 2.4, 2.4)
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
	var lantern := OmniLight3D.new()
	lantern.position = camera.position + Vector3(0.3,-0.2,-0.4)
	lantern.light_color = Color("e8a84a")
	lantern.omni_range = 8.4
	world.add_child(lantern)
	var chest = load(CHEST + "scene.tscn").instantiate()
	chest.position = Vector3(7.2,0,9.6)
	world.add_child(chest)
	for phone in [false,true]:
		root.size = Vector2i(1278,590) if phone else Vector2i(1280,720)
		var suffix := "phone" if phone else "desktop"
		for state in ["closed","open","empty"]:
			chest.set_state(state)
			lantern.light_energy = 1.6
			var bright := await _capture(state + "-" + suffix)
			lantern.light_energy = 0.35
			var dim := await _capture(state + "-dim-" + suffix)
			check(_sample_light(dim) < _sample_light(bright), state + " responds to dim light at " + suffix)
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
	check(image.save_png(OUT + label + ".png") == OK, "Capture " + label)
	return image
