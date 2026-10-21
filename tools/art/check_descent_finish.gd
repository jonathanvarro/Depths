extends SceneTree
## #139: actual LevelBuilder surfaces and mounted scenes. No Main or saves.
const OUT := "res://art/concepts/descent-finish-v1/"
const DIR := "res://art/dressing/cave-v2/"
const DM := preload("res://scripts/dungeon_map.gd")
const BUILDER := preload("res://scripts/level_builder.gd")
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var world: Node3D
var dressing: Node3D
var level: Node3D
var camera: Camera3D
var environment: Environment
var lantern: OmniLight3D
var title: Label
var families: Dictionary = {}
var original: EnvironmentTheme
var map

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func attach(id: String, point: Vector3) -> Node3D:
	var scene: Node3D = load(DIR + id + ".tscn").instantiate()
	dressing.add_child(scene)
	scene.position = point
	return scene

func build_family(id: String) -> void:
	if is_instance_valid(level):
		level.free()
	if is_instance_valid(dressing):
		dressing.free()
	var theme: EnvironmentTheme = original.duplicate()
	var entry: Dictionary = families[id]
	theme.wall_material = load(entry.wall_material)
	theme.wall_variant_material = theme.wall_material
	theme.floor_material = load(entry.floor_material)
	theme.ceiling_material = load(entry.ceiling_material)
	level = BUILDER.new()
	world.add_child(level)
	level.build(map, theme, 2.0, 2.4)
	dressing = Node3D.new()
	world.add_child(dressing)
	check(level.get_child_count() > 0, "Actual LevelBuilder geometry: " + id)

func snap(name: String) -> void:
	title.text = name.replace("-", " ") + "  /  standalone art review"
	for tick in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Capture: " + name)
	captures.append(name + ".png")

func audit_scene(entry: Dictionary) -> void:
	var scene: Node3D = load(entry.scene).instantiate()
	check(scene.get_meta("dressing_id") == entry.id, "Scene identity: " + entry.id)
	check(scene.find_children("*", "CollisionObject3D", true, false).is_empty(), "No collision: " + entry.id)
	check(scene.find_children("*", "Light3D", true, false).is_empty(), "No party or local light: " + entry.id)
	check(scene.get_script() == null, "No controller attached: " + entry.id)
	var sprite: Sprite3D = scene.get_node("Sprite")
	check(sprite.texture.get_size() == Vector2(128, 128), "Native texture imported: " + entry.id)
	check(sprite.shaded and sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "Shaded nearest sprite: " + entry.id)
	check(is_equal_approx(sprite.pixel_size, entry.pixel_size), "Measured pixel scale: " + entry.id)
	var hanging: bool = entry.mount in ["ceiling", "floor-edge"]
	check(sprite.billboard == (2 if hanging else 0), "Correct mount orientation: " + entry.id)
	if entry.mount == "ceiling-plane":
		check(is_equal_approx(sprite.rotation_degrees.x, 90.0) and is_equal_approx(sprite.position.y, -0.012), "Underside points down, below ceiling")
	elif entry.mount == "wall":
		check(is_equal_approx(sprite.position.z, 0.012), "Wall surface offset: " + entry.id)
	else:
		check(is_equal_approx(sprite.position.y, (entry.pivot[1] - 64.0) * entry.pixel_size), "Native pivot: " + entry.id)
	if entry.has("glow_scene"):
		var lit: Node3D = load(entry.glow_scene).instantiate()
		var base: Sprite3D = lit.get_node("Sprite")
		var glow: AnimatedSprite3D = lit.get_node("Glow")
		check(base.texture == sprite.texture and base.position == sprite.position, "Neutral base unchanged in lit scene: " + entry.id)
		check(glow.position.x == base.position.x and glow.position.y == base.position.y and glow.pixel_size == base.pixel_size and glow.billboard == base.billboard, "Glow canvas registration: " + entry.id)
		check(not glow.shaded and glow.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "Separate native emission sprite: " + entry.id)
		check(lit.find_children("*", "Light3D", true, false).is_empty(), "Mood glow adds no Light3D: " + entry.id)
		var frames: SpriteFrames = glow.sprite_frames
		check(frames.get_frame_count("loop") == 8 and frames.get_animation_speed("loop") == 4.0 and frames.get_animation_loop("loop"), "Eight-frame four-fps pulse: " + entry.id)
		var support: Image = base.texture.get_image()
		for frame in 8:
			var image: Image = frames.get_frame_texture("loop", frame).get_image()
			var registered := image.get_size() == support.get_size()
			for y in image.get_height():
				for x in image.get_width():
					if image.get_pixel(x, y).a > 0.0 and support.get_pixel(x, y).a == 0.0:
						registered = false
			check(registered, "Imported pulse frame %d registered: %s" % [frame, entry.id])
		lit.free()
	scene.free()

func _run() -> void:
	var surfaces: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/textures/descent-surfaces-v1/catalog.json"))
	var pieces: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "catalog.json"))
	for entry: Dictionary in pieces.assets:
		audit_scene(entry)
	for entry: Dictionary in surfaces.assets:
		var material: StandardMaterial3D = load(entry.material)
		check(material.albedo_texture.get_size() == Vector2(128, 128), "Native material texture: " + entry.id)
		check(material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST and material.texture_repeat, "Nearest repeat material: " + entry.id)
		check(not material.emission_enabled and material.roughness == 1.0 and not material.normal_enabled, "Simple diffuse material: " + entry.id)
	for entry: Dictionary in surfaces.families:
		families[entry.id] = entry
	original = load("res://themes/cave.tres")
	var original_floor := original.floor_material
	var original_ceiling := original.ceiling_material
	world = Node3D.new()
	root.add_child(world)
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("111510")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	var env := WorldEnvironment.new()
	env.environment = environment
	world.add_child(env)
	camera = Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(4, 1.2, 6.4)
	camera.fov = 70
	camera.current = true
	lantern = OmniLight3D.new()
	world.add_child(lantern)
	lantern.position = Vector3(4.25, 1.4, 6.5)
	lantern.omni_range = 10
	lantern.light_color = Color(1, 0.78, 0.53)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	title = Label.new()
	layer.add_child(title)
	title.position = Vector2(16, 12)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	map = DM.new(PackedStringArray(["#####", "#,,,#", "#,,,#", "#,,,#", "#####"]))
	for id: String in families:
		build_family(id)
		for setting: String in ["neutral", "lantern", "phone-lantern"]:
			root.size = Vector2i(1278, 590) if setting == "phone-lantern" else Vector2i(1280, 720)
			environment.ambient_light_energy = 0.75 if setting == "neutral" else 0.28
			lantern.light_energy = 0.0 if setting == "neutral" else 1.2
			await snap(id + "-" + setting)
	for phone: bool in [false, true]:
		root.size = Vector2i(1278, 590) if phone else Vector2i(1280, 720)
		var tag := "phone" if phone else "desktop"
		environment.ambient_light_energy = 0.28
		lantern.light_energy = 1.2
		build_family("worked-cave")
		attach("mine-ring-chain", Vector3(2.7, 1.4, 1.0))
		attach("lantern-hook", Vector3(5.0, 1.5, 1.0))
		attach("broken-rail-end", Vector3(3.7, 0.6, 1.0))
		attach("old-remains", Vector3(1.8, 0, 2.0))
		attach("stranger-mark", Vector3(5.7, 1.0, 1.0))
		await snap("mine-fittings-" + tag)
		build_family("goblin-hold")
		attach("goblin-hide", Vector3(2.8, 1.25, 1.0))
		attach("goblin-banner", Vector3(4.1, 1.4, 1.0))
		attach("wall-spikes", Vector3(5.7, 1.15, 1.0))
		attach("chained-cage", Vector3(5.5, 2.4, 3.0))
		attach("overhead-walkway", Vector3(4, 2.4, 3.4))
		await snap("goblin-fixtures-" + tag)
		build_family("drowned-masonry")
		attach("waterline-stain", Vector3(3.0, 0.7, 1.0))
		attach("drip-curtain", Vector3(5.0, 1.4, 1.0))
		await snap("drowned-details-" + tag)
		build_family("fungal-stone")
		attach("moss-curtain", Vector3(3.0, 2.4, 3.0))
		attach("moss-curtain-lit", Vector3(5.0, 2.4, 3.2))
		attach("floor-fungus", Vector3(2.6, 0, 3.0))
		attach("floor-fungus-lit", Vector3(5.8, 0, 2.8))
		await snap("fungal-details-" + tag)
		environment.ambient_light_energy = 0.035
		lantern.light_energy = 0.0
		await snap("fungal-dark-" + tag)
		environment.ambient_light_energy = 0.28
		lantern.light_energy = 1.2
		build_family("buried-city")
		attach("relief-fragment", Vector3(3.1, 1.3, 1.0))
		attach("empty-lamp-niche", Vector3(5.0, 1.2, 1.0))
		attach("inscription-band", Vector3(4.0, 0.8, 1.0))
		await snap("buried-details-" + tag)
		build_family("sealed-temple")
		attach("ward-niche", Vector3(4.0, 1.25, 1.0))
		attach("seal-ornament", Vector3(4.0, 1.25, 1.02))
		await snap("sealed-details-" + tag)
	check(original.floor_material == original_floor and original.ceiling_material == original_ceiling, "Original theme resources unchanged")
	var report := {"issue":139,"checks":checks,"failures":failures,"captures":captures,"geometry":"Actual unchanged LevelBuilder BoxMesh walls and PlaneMesh floor/ceiling, 2m cells / 2.4m walls.","limits":"Standalone art only, no Main, saves or gameplay state. Phone-shaped desktop rendering, not physical iPhone. Existing wall-box UV density/stretch remains."}
	var file := FileAccess.open(OUT + "godot-validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("DESCENT_FINISH checks=%d failures=%d captures=%d" % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
