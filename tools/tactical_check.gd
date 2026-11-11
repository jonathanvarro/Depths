extends SceneTree
## Tactical view prototype (owner, 2026-11-08): a fight on the map lifts
## the camera above the room, shows the party, the foes, the tiles they
## threaten and who can be struck, then drops back into first person.
## Args: tag, screenshot dir.

var fails := 0
var dir := ""
var tag := "desk"


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(name: String) -> void:
	if dir == "":
		return
	for i in 4:
		await process_frame
	var shot := root.get_texture().get_image()
	if shot:
		shot.save_png("%s/tactical_%s_%s.png" % [dir, tag, name])


## Starts a fight with the first room group, the party two tiles off.
func _fight(main) -> bool:
	if main._groups.is_empty():
		return false
	var group = main._groups[0]
	for side in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		var at: Vector2i = group.cell + side * 2
		if main._map.is_passable(at) and main._map.is_passable(group.cell + side):
			main._party.place(main._map, at)
			main._party.facing = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT].find(-side)
			main._party.rotation.y = -main._party.facing * PI / 2.0
			break
	main._engaged = group
	group.noticed = true
	main._start_combat(group.cell, group.types)
	return true


func _ceilings_hidden(main) -> bool:
	var ceilings: Array = main._level.get_tree().get_nodes_in_group("ceiling")
	return not ceilings.is_empty() and ceilings.all(func(c): return not c.visible)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""
	var Settings = load("res://scripts/settings.gd")
	Settings.set_value("tactical_view", true)
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	await _snap("explore")
	check("a fight on the map begins", await _fight(main) and main._in_combat and main._combat._state.field)
	await create_timer(1.2).timeout
	var tactical = main._tactical
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	check("the camera lifts above the room", tactical.active and cam == tactical._camera and cam.global_position.y > 6.0, cam.global_position)
	check("...looking down on the party", cam.global_transform.basis.z.y > 0.8, cam.global_transform.basis.z)
	check("ceilings are out of the way", _ceilings_hidden(main))
	check("the party has a token, facing its way", is_instance_valid(tactical._party_token))
	check("...with the lead hero's 3D figure in it (#251)", is_instance_valid(tactical._figure) and tactical._figure.scene_file_path.ends_with("mara.tscn"), tactical._figure.scene_file_path if tactical._figure else "none")
	tactical._on_hero_acted(null, {"kind": "strike"}, {})
	check("...who strikes with the party", tactical._figure.current_pose == "attack")
	check("tiles show what the foes threaten", not tactical._marks.is_empty(), tactical._marks.size())
	await _snap("board")

	# Light rules the board (owner, 2026-11-09).
	var supplies = main._party_state.supplies
	var source_was = supplies.source
	var torch_was: float = supplies.torch_left
	var heights := {}
	for band in [["dark", 0], ["torch", 2], ["bright", 3]]:
		supplies.glow_left = 0.0
		match band[1]:
			0: supplies.source = supplies.Source.NONE
			2:
				supplies.source = supplies.Source.TORCH
				supplies.torch_left = supplies.TORCH_BURN_TIME
			3: supplies.glow_left = 50.0
		tactical._last_key = ""
		tactical._update_marks()
		await create_timer(0.6).timeout
		heights[band[0]] = tactical._camera.global_position.y - main._party.global_position.y
		var at: Vector2i = main._combat._state.party_cell
		var beside_seen: bool = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].all(func(s): return tactical.seen.has(at + s) or not main._map.is_passable(at + s))
		check("%s: the light band is as set" % band[0], tactical.light_band() == band[1], tactical.light_band())
		check("%s: the tiles beside you are seen" % band[0], beside_seen)
		var far := at + Vector2i(2, 2)
		check("%s: a diagonal two away is %s" % [band[0], "seen if open" if band[1] == 3 else "shrouded"], tactical.seen.has(far) == (band[1] == 3 and tactical._clear_line(at, far)) or (band[1] == 3 and not tactical.seen.has(far)))
		var unseen_foe = null
		for foe in main._combat._state.living_foes():
			if not tactical.seen.has(foe.cell):
				unseen_foe = foe
		if unseen_foe:
			check("%s: a foe out of the light is hidden, tag and all" % band[0], not unseen_foe.node.visible and not main._combat._tags[unseen_foe].visible)
		await _snap("light_" + band[0])
	check("less light draws the camera in", heights["dark"] < heights["torch"] and heights["torch"] < heights["bright"], heights)
	supplies.glow_left = 0.0
	supplies.source = source_was
	supplies.torch_left = torch_was
	tactical._last_key = ""
	tactical._update_marks()

	# Tapping the board (#248): a step, then a strike.
	var state = main._combat._state
	var g0 := 0
	while not main._combat.awaiting_field_action and g0 < 50:
		await create_timer(0.1).timeout
		g0 += 1
	var free: Vector2i = Vector2i(-1, -1)
	for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var next: Vector2i = state.party_cell + side
		if main._map.is_passable(next) and not state.living_foes().any(func(f): return f.cell == next):
			free = next
			break
	var screen_point: Vector2 = tactical._camera.unproject_position(Vector3(free.x * main.CELL_SIZE, 0.0, free.y * main.CELL_SIZE))
	check("a tap on screen finds its tile", tactical.cell_at(screen_point) == free, "%s vs %s" % [tactical.cell_at(screen_point), free])
	check("the tiles you can step to are outlined", tactical._marks.size() > 0)
	check("tapping a free tile beside you steps there", tactical.act_on(free))
	await create_timer(0.8).timeout
	check("...and the party moved, using its action", main._party.cell == free, main._party.cell)
	var g1 := 0
	while not main._combat.awaiting_field_action and main._in_combat and g1 < 60:
		await create_timer(0.1).timeout
		g1 += 1
	if main._in_combat:
		var foe = state.living_foes()[0]
		var beside: Vector2i = Vector2i(-1, -1)
		for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if main._map.is_passable(state.party_cell + side) and not state.living_foes().any(func(f): return f != foe and f.cell == state.party_cell + side):
				beside = state.party_cell + side
				break
		foe.cell = beside
		var health_before: int = foe.health
		for h in main._party_state.members:
			h.aim_base = 2.0
			h.refresh_stats()
		state._webbed.clear()  # a spider's web spoils one blow: not what this tests
		check("tapping a foe beside you turns to it and strikes", tactical.act_on(beside) and state.foe_ahead() == foe)
		await create_timer(1.0).timeout
		check("...the blow lands", foe.health < health_before or not foe.is_alive(), "%d -> %d" % [health_before, foe.health])

	# The fight ends: back into the party's eyes.
	for foe in main._combat._state.foes:
		foe.health = 0
	main._combat._state._check_end()
	var g := 0
	while main._in_combat and g < 100:
		if main._combat._actions.visible:
			main._combat._action_chosen.emit({"kind": "defend"})
		await create_timer(0.1).timeout
		g += 1
	await create_timer(1.2).timeout
	cam = root.get_viewport().get_camera_3d()
	check("when it ends, the view drops back into first person", not tactical.active and cam == main._party.camera and not _ceilings_hidden(main))
	check("...and the board's marks are gone", tactical._marks.is_empty())
	await _snap("after")

	# An ambush from an event takes the board too, facing open ground.
	main._clear_groups()
	main._engaged = null
	main._fight_kind = ""
	main._start_combat(main._party.cell, [load("res://data/enemies/rat.tres")] as Array[EnemyType])
	await create_timer(1.0).timeout
	var ahead: Vector2i = main._party.cell + main._party.DIRECTIONS[main._party.facing]
	check("an event's ambush is fought on the board", main._in_combat and main._combat._state.field and tactical.active)
	check("...never facing a wall", main._map.is_passable(ahead))
	for foe in main._combat._state.foes:
		foe.health = 0
	main._combat._state._check_end()
	var g2 := 0
	while main._in_combat and g2 < 100:
		if main._combat.awaiting_field_action:
			main._combat._action_chosen.emit({"kind": "wait"})
		await create_timer(0.1).timeout
		g2 += 1
	await create_timer(1.2).timeout
	check("...and it ends like any other", not main._in_combat and not tactical.active)

	# Switched off: fights stay in first person.
	Settings.set_value("tactical_view", false)
	main._spawn_room_groups()
	if await _fight(main):
		await create_timer(0.5).timeout
		check("switched off in Settings, a fight stays in first person", not tactical.active and root.get_viewport().get_camera_3d() == main._party.camera, "active %s, camera %s" % [tactical.active, root.get_viewport().get_camera_3d()])
	Settings.set_value("tactical_view", true)
	print("fails=", fails)
	quit()
