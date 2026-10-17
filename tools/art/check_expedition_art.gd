extends SceneTree
## Resource and live portrait integration checks for #31.
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		return
	checks += 1

func _run() -> void:
	var portrait: PortraitSet = load("res://data/portraits/mara.tres")
	check(portrait.blink_frames.size() == 2, "Two blink frames")
	check(portrait.talk_frames.size() == 3, "Three talk frames")
	for texture in portrait.blink_frames + portrait.talk_frames:
		check(texture.get_size() == Vector2(192, 192), "Expression canvas")
	for name in ["blood", "dirt", "bandage", "pallor"]:
		check(portrait.conditions.has(name), "Condition name: " + name)
		check(portrait.conditions[name].get_size() == Vector2(192, 192), "Condition canvas")
	var view = load("res://scripts/portrait_view.gd").new()
	root.add_child(view)
	view.show_portrait(portrait)
	view.set_condition("blood", true)
	check(view._overlays["blood"].visible, "Overlay switches on")
	view.set_condition("blood", false)
	view.blink()
	await create_timer(0.06).timeout
	check(view._eyes.texture in portrait.blink_frames, "Blink swaps drawing")
	await create_timer(0.2).timeout
	check(view._eyes.texture == portrait.eyes, "Blink restores resting eyes")
	view.talk(0.4)
	await create_timer(0.1).timeout
	check(view._mouth.texture in portrait.talk_frames, "Talk swaps drawing")
	await create_timer(0.5).timeout
	check(view._mouth.texture == portrait.mouth, "Talk restores resting mouth")
	for item in ["oil_flask", "ration", "restorative_draught"]:
		var definition = load("res://data/items/" + item + ".tres")
		check(definition.icon != null and definition.icon.get_size() == Vector2(64, 64), "Pack icon " + item)
	var cave: EnvironmentTheme = load("res://themes/cave.tres")
	for material in [cave.wall_material, cave.floor_material, cave.ceiling_material]:
		check(material.albedo_texture.get_size() == Vector2(64, 64), "Cave surface size")
		check("cave-v1" in material.resource_path, "Cave uses cave material")
	for scene in [cave.closed_scene,cave.opened_scene,cave.blocked_scene,cave.descent_scene,cave.ascent_scene]:
		check(scene != null, "Feature assigned")
		var node = scene.instantiate()
		check(node is Node3D, "Feature instantiates at cell origin")
		node.free()
	for enemy in ["rat", "spider", "goblin"]:
		var frames: SpriteFrames = load("res://art/enemies/cave-v1/" + enemy + "/frames.tres")
		for pose in ["idle", "attack", "hurt"]:
			check(frames.has_animation(pose) and frames.get_frame_count(pose) == 1, "Enemy pose: " + enemy + " " + pose)
		var node = load("res://art/enemies/cave-v1/" + enemy + "/scene.tscn").instantiate()
		check(node.get_node("Sprite").sprite_frames == frames, "Enemy scene frames")
		node.free()
	view.queue_free()
	await process_frame
	print("ART_RESOURCE_CHECKS_PASSED: ", checks)
	quit()
