extends SceneTree
## ChatGPT's 3D props and decor in the live game (2026-11-08: #239, #241,
## #242, #243): events show their 3D props and take the empty state;
## dressing uses the 3D supports, rails, formations, roots, fungi, lanterns
## and bones on the floors they belong to. Args: tag, screenshot dir.

const Dressing := preload("res://scripts/dressing.gd")

var fails := 0
var dir := ""
var tag := "desk"


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(name: String) -> void:
	if dir == "":
		return
	for i in 8:
		await process_frame
	var shot := root.get_texture().get_image()
	if shot:
		shot.save_png("%s/models3d_%s_%s.png" % [dir, tag, name])


## The 3D dressing ids placed on the current floor.
func _ids(main) -> Dictionary:
	var ids := {}
	var dressing = main._level.get_node_or_null("Dressing")
	if dressing == null:
		return ids
	var models: Array = Dressing.MODELS.values() + Dressing.MODELS_BY_PATH.values()
	for piece in dressing.get_children():
		if piece.scene_file_path in models:  # named by its 3D scene
			var id: String = piece.scene_file_path.get_file().get_basename()
			ids[id] = ids.get(id, 0) + 1
	return ids


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""

	# Events: their props are the 3D scenes, and they take the empty state.
	var events := {"chest_strongbox": "strongbox", "chest_old_workings": "old-workings", "rest_dry_alcove": "dry-alcove",
			"rest_old_camp": "cold-camp", "chest_abandoned_pack": "abandoned-pack", "object_miners_shrine": "miners-shrine"}
	for name in events:
		var event: RoomEvent = load("res://data/events/%s.tres" % name)
		var path: String = event.prop.resource_path if event.prop else ""
		var node: Node3D = event.prop.instantiate() if event.prop else null
		var ok: bool = path.contains("-3d-v1/") and path.get_file() == events[name] + ".tscn" and node != null and "state" in node
		if ok:
			root.add_child(node)
			node.set("state", "empty")
			ok = node.get("state") == "empty"
			node.queue_free()
		check("%s shows the 3D %s and empties" % [name, events[name]], ok, path)

	# A lineup of the event props on a lit stage, for the eye.
	if dir != "":
		var stage := Node3D.new()
		root.add_child(stage)
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color(0.06, 0.05, 0.045)
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color(0.55, 0.5, 0.42)
		env.environment.ambient_light_energy = 0.6
		stage.add_child(env)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-40, -30, 0)
		sun.light_energy = 1.1
		stage.add_child(sun)
		var cam := Camera3D.new()
		cam.position = Vector3(0, 1.5, 4.4)
		cam.rotation_degrees = Vector3(-14, 0, 0)
		stage.add_child(cam)
		cam.make_current()
		var i := 0
		for name in events:
			for state in ["closed", "empty"]:
				var node: Node3D = load("res://data/events/%s.tres" % name).prop.instantiate()
				node.set("state", state)
				if node.has_method("set_motion"):
					node.set_motion(false)
				stage.add_child(node)
				node.position = Vector3((i - 2.5) * 1.35, 0.0, -1.6 if state == "empty" else 0.0)
			i += 1
		await _snap("event_props")
		stage.queue_free()
		await process_frame

	# Dressing across floors 1-3, over a few seeds.
	var seen := {}
	var main = null
	for seed in [11, 23, 37]:
		main = load("res://scenes/main.tscn").instantiate()
		main.play_opening = false
		main.floor_seed = seed
		root.add_child(main)
		await create_timer(0.4).timeout
		for depth in [1, 2, 3]:
			main._go_to_floor(depth, main.Arrival.FROM_ABOVE)
			await process_frame
			for id in _ids(main):
				seen[id] = seen.get(id, []) + [depth]
			if seed == 11 and dir != "":
				main._party.rotation.y = main._party._facing_to_yaw(main._party.facing)
				await _snap("floor%d" % depth)
		if seed != 37:
			main.queue_free()
			await process_frame
	var want := {"support": 1, "rails": 1, "stalactite-single": 1, "wall-roots": 1, "hanging-roots": 1,
			"scattered-bones": 1, "rubble-cluster": 1, "shelf-fungus": 2, "mushroom-clump": 2}
	var missing := []
	for id in want:
		if not seen.has(id) or not want[id] in seen[id]:
			missing.append("%s (floor %d)" % [id, want[id]])
	check("the 3D decor turns up on its floors", missing.is_empty(), missing)
	check("lanterns stay on the miners' floor", seen.get("lantern-hanging", [1]).all(func(d): return d == 1) and seen.get("lantern-standing", [1]).all(func(d): return d == 1))
	check("skeletons only from floor 2", seen.get("fallen-skeleton", [2]).all(func(d): return d >= 2) and seen.get("seated-skeleton", [2]).all(func(d): return d >= 2))

	print("fails=", fails)
	quit()
