extends SceneTree
## Every foe stands clear of the fight's action panel (batch fix,
## 2026-10-20): small ones (rats) and the bottom of a guard's shield used to
## sit behind it. Args: tag, screenshot dir.

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


## The lowest on-screen point of a foe's sprites.
func _feet(main, node: Node3D) -> float:
	var camera: Camera3D = main._party.camera
	var lowest := -INF
	for sprite: SpriteBase3D in node.find_children("*", "SpriteBase3D", true, false):
		var box := sprite.get_aabb()
		lowest = maxf(lowest, camera.unproject_position(sprite.global_transform * Vector3(box.get_center().x, box.position.y, 0.0)).y)
	return lowest


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var groups := {
		"rats": ["rat", "rat", "great_rat", "rat"],
		"guards": ["goblin_guard", "goblin_guard", "goblin_archer"],
		"mixed": ["goblin", "webspinner", "rat"],
	}
	for name in groups:
		# A fresh game for each fight.
		var main = load("res://scenes/main.tscn").instantiate()
		main.play_opening = false
		main.floor_seed = 11
		root.add_child(main)
		await create_timer(0.5).timeout
		for hero in main._party_state.members:
			hero.initiative = 50  # the party acts first, so the panel shows
		var types: Array[EnemyType] = []
		for id in groups[name]:
			types.append(load("res://data/enemies/%s.tres" % id))
		main._start_combat(main._party.cell, types)
		var guard := 0
		while not main._combat._actions.visible and guard < 100:
			guard += 1
			await create_timer(0.1).timeout
		await create_timer(0.5).timeout
		var panel: Control = main._combat._actions
		var top: float = panel.get_global_rect().position.y
		var hidden := []
		for foe in main._combat._state.foes:
			var feet := _feet(main, foe.node)
			if feet > top:
				hidden.append("%s %.0f > %.0f" % [foe.type.display_name, feet, top])
		check("%s: every foe stands clear of the action panel" % name, panel.visible and hidden.is_empty(), str(hidden))
		if dir != "":
			root.get_texture().get_image().save_png(dir + "/framing_" + tag + "_" + name + ".png")
		main.queue_free()
		await create_timer(0.3).timeout
	print("fails=", fails)
	quit()
