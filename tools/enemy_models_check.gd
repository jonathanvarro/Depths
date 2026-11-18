extends SceneTree
## 3D enemy models in real fights (#251, 2026-11-11): model-aware poses,
## falls, facing, framing and the dark stage, with the painted sprites kept
## as the fallback (Settings "enemy_models" off). Light still hides what it
## doesn't reach. Args: tag, screenshot dir.

const FoeView := preload("res://scripts/foe_view.gd")
const Settings := preload("res://scripts/settings.gd")

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
		shot.save_png("%s/models_%s_%s.png" % [dir, tag, name])


func _end_fight(main) -> void:
	for foe in main._combat._state.foes:
		foe.health = 0
	main._combat._state._check_end()
	var g := 0
	while main._in_combat and g < 120:
		if main._chest.visible:
			main._chest.closed.emit()  # leave overflow from the forced wins
		elif main._combat.awaiting_field_action:
			main._combat._action_chosen.emit({"kind": "wait"})
		elif main._combat._actions.visible:
			main._combat._action_chosen.emit({"kind": "defend"})
		await create_timer(0.1).timeout
		g += 1
	check("the fixture leaves the fight", not main._in_combat)


func _check_goblin_elites(main) -> void:
	var brute: EnemyType = load("res://data/enemies/goblin_brute.tres")
	var captain: EnemyType = load("res://data/enemies/gate_captain.tres")
	main._fight_kind = ""
	main._start_combat(main._party.cell, [brute] as Array[EnemyType])
	await create_timer(1.2).timeout
	var foe = main._combat._state.foes[0]
	var intent = main.CombatState.Intent
	main._combat.keep_clear.text = ""
	check("the Brute uses its 3D model on the board", main._combat._state.field and FoeView.is_model(foe.node))
	foe.intent = intent.HEAVY
	await process_frame
	await process_frame
	check("heavy intent shows the Brute's held wind-up instead of its attack", FoeView.current(foe.node) == "wind-up")
	var camera := root.get_camera_3d()
	var body := camera.unproject_position(foe.node.global_position + Vector3.UP)
	var tag_rect: Rect2 = main._combat._tags[foe].get_global_rect()
	check("the Brute's board tag sits beside the body", body.x < tag_rect.position.x or body.x > tag_rect.end.x)
	check("the Brute has a distinct heavy swing", main._combat._action_pose(foe, intent.HEAVY, {}) == "heavy")
	await _snap("brute_wind_up")
	foe.intent = intent.RECOVER
	await process_frame
	await process_frame
	check("recover intent shows the Brute's lowered maul", FoeView.current(foe.node) == "recover")
	await _snap("brute_recover")
	await _end_fight(main)
	await create_timer(1.0).timeout

	var lair: QuestPackage = load("res://data/packages/lair_captain.tres")
	var eye: Camera3D = main._party.camera
	var cave_mask := eye.cull_mask
	for enabled in [true, false]:
		Settings.set_value("enemy_models", enabled)
		main._lair_fight(main._party.cell, lair)
		await create_timer(1.2).timeout
		var state = main._combat._state
		foe = state.foes.filter(func(f): return f.type == captain)[0]
		check("the Captain's lair stays on the dark stage", not state.field)
		if enabled:
			main._combat.keep_clear.text = ""
			check("the Captain's lair has the grounded model and its ally", FoeView.is_model(foe.node)
				and absf(foe.node.global_position.y - main._party.global_position.y) < .05 and state.foes.size() > 1)
			check("local light and a clear stage keep the Captain visible", eye.cull_mask != cave_mask
				and foe.node.find_children("*", "OmniLight3D", true, false).size() == 2)
			foe.intent = intent.RALLY
			await process_frame
			await process_frame
			check("the Captain holds the horn up before rallying", FoeView.current(foe.node) == "rally")
			check("rally dispatches to the horn clip", main._combat._action_pose(foe, intent.RALLY, {}) == "horn")
			check("the Captain has a distinct heavy cleave", main._combat._action_pose(foe, intent.HEAVY, {}) == "heavy")
			await _snap("captain_rally")
		else:
			check("with models off the Captain's lair uses the existing sprite", FoeView.sprite_of(foe.node) != null)
		main._fight_kind = ""  # skip the hoard overlay in the fixture
		await _end_fight(main)
		await create_timer(1.0).timeout
		check("the Captain's stage restores the cave camera", eye.cull_mask == cave_mask)
	Settings.set_value("enemy_models", true)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""
	Settings.set_value("enemy_models", true)
	Settings.set_value("tactical_view", true)
	var rat_type: EnemyType = load("res://data/enemies/rat.tres")
	check("the rat has a 3D model and keeps its sprite", rat_type.model != null and rat_type.scene != null and rat_type.view_scene() == rat_type.model)

	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout

	# On the board: an ambush of rats.
	main._clear_groups()
	main._fight_kind = ""
	main._start_combat(main._party.cell, [rat_type, rat_type] as Array[EnemyType])
	await create_timer(1.2).timeout
	var state = main._combat._state
	var foe = state.foes[0]
	check("on the board, a rat is its 3D model", FoeView.is_model(foe.node) and state.field and main._tactical.active)
	var climbs: Array = main._level.find_children("*", "Node3D", true, false).filter(
		func(node): return node.get_meta("asset_id", "") == "root-climb-up")
	check("hanging climb roots clear the board", not climbs.is_empty() and climbs.all(
		func(node): return not node.is_visible_in_tree()))
	check("Mara uses the new board figure and material",
		main._tactical._figure.scene_file_path.ends_with("/mara.tscn") and main._tactical._figure.palette_material.emission_enabled)
	check("...feet on its tile", absf(foe.node.position.y) < 0.01 and Vector2i(roundi(foe.node.position.x / main.CELL_SIZE), roundi(foe.node.position.z / main.CELL_SIZE)) == foe.cell, foe.node.position)
	var to_party: Vector3 = (main._party.global_position - foe.node.global_position)
	to_party.y = 0.0
	var forward: Vector3 = foe.node.global_transform.basis.z
	check("...facing the party", forward.normalized().dot(to_party.normalized()) > 0.9, forward)
	check("...its tag sized by the model's height", is_equal_approx(FoeView.height(foe.node), 0.47))
	main._combat._play(foe, "attack", 0.4)
	await process_frame
	check("an attack plays its bite clip", FoeView.current(foe.node) == "attack")
	await create_timer(0.6).timeout
	check("...and it settles back to idle", FoeView.current(foe.node) == "idle")
	main._combat._play(foe, "set-snare", 0.2)
	await process_frame
	check("a pose it lacks falls back to its attack", FoeView.current(foe.node) == "attack")
	await create_timer(0.4).timeout
	# The light decides what's seen, model or not.
	var supplies = main._party_state.supplies
	var source_was = supplies.source
	supplies.source = supplies.Source.NONE
	main._tactical._last_key = ""
	main._tactical._update_marks()
	var hidden: Array = state.living_foes().filter(func(f): return not main._tactical.seen.has(f.cell))
	check("in the dark, unseen models are hidden", hidden.all(func(f): return not f.node.visible))
	supplies.source = source_was
	main._tactical._last_key = ""
	main._tactical._update_marks()
	await _snap("board")
	var falling = foe
	falling.health = 0
	main._combat._fade_out(falling)
	await process_frame
	check("a fallen model plays its fall", FoeView.current(falling.node) == "fall")
	await create_timer(FoeView.fade_time(falling.node) + 0.2).timeout
	check("...then leaves the board", not falling.node.visible)
	await _end_fight(main)
	await create_timer(1.2).timeout
	if main._tactical.active:  # exploring from above after the fight (#248): back to the party's eyes
		main._toggle_view()
		await create_timer(1.2).timeout
	check("climb roots return in first person", climbs.all(
		func(node): return is_instance_valid(node) and node.is_visible_in_tree()))

	# First person, on the dark stage (a lair, the gate, the queen, or the
	# view off): the painted art, which the stage is framed for.
	Settings.set_value("tactical_view", false)
	main._fight_kind = ""
	main._start_combat(main._party.cell, [rat_type] as Array[EnemyType])
	await create_timer(1.2).timeout
	state = main._combat._state
	foe = state.foes[0]
	check("on the dark stage, the painted sprite stays", not state.field and FoeView.sprite_of(foe.node) != null)
	await _snap("stage")
	await _end_fight(main)
	await create_timer(1.0).timeout

	# The spiders: their models, and the web gesture for a web.
	Settings.set_value("tactical_view", true)
	main._fight_kind = ""
	main._start_combat(main._party.cell, [load("res://data/enemies/webspinner.tres")] as Array[EnemyType])
	await create_timer(1.2).timeout
	foe = main._combat._state.foes[0]
	check("a web-spinner is its 3D model on the board", FoeView.is_model(foe.node))
	check("...and spins with its own web clip", main._combat._action_pose(foe, main.CombatState.Intent.WEB, {}) == "web")
	for path in ["great_rat", "spider", "venom_spider", "goblin_drummer", "goblin_trapper", "broodmother"]:
		var t: EnemyType = load("res://data/enemies/%s.tres" % path)
		var node: Node3D = t.view_scene().instantiate()
		root.add_child(node)
		check("%s has a 3D model with idle, attack, hurt and fall" % path, FoeView.is_model(node) and ["idle", "attack", "hurt", "fall"].all(func(p): return FoeView.has_pose(node, p)))
		node.queue_free()
	await _end_fight(main)
	await create_timer(1.0).timeout

	# The sprite fallback.
	Settings.set_value("enemy_models", false)
	main._fight_kind = ""
	main._start_combat(main._party.cell, [rat_type] as Array[EnemyType])
	await create_timer(1.0).timeout
	foe = main._combat._state.foes[0]
	check("with 3D enemies off, the painted sprite is back", FoeView.sprite_of(foe.node) != null and not FoeView.is_model(foe.node))
	await _end_fight(main)
	Settings.set_value("enemy_models", true)

	# The fortress goblins and the Goblin King (#257).
	for path in ["goblin", "goblin_guard", "goblin_archer", "goblin_king"]:
		var t: EnemyType = load("res://data/enemies/%s.tres" % path)
		var node: Node3D = t.view_scene().instantiate()
		root.add_child(node)
		check("%s has a 3D model with idle, attack, hurt and fall" % path, FoeView.is_model(node) and ["idle", "attack", "hurt", "fall"].all(func(p): return FoeView.has_pose(node, p)))
		node.queue_free()
	var guard_view: Node3D = load("res://data/enemies/goblin_guard.tres").model.instantiate()
	var archer_view: Node3D = load("res://data/enemies/goblin_archer.tres").model.instantiate()
	root.add_child(guard_view)
	root.add_child(archer_view)
	check("the guard braces and the archer draws with their own clips", FoeView.has_pose(guard_view, "brace") and FoeView.has_pose(archer_view, "draw"))
	guard_view.queue_free()
	archer_view.queue_free()
	check("the boss fight is the Goblin King's", main.QUEEN.display_name == "Goblin King" and main.QUEEN_FIGHT[0] == main.QUEEN)
	# Seen from above, his hall is fought on the board, models all round,
	# and nobody loses the trail: there's no turning back.
	main._fight_kind = ""
	main._queen_fight(main._party.cell)
	await create_timer(1.4).timeout
	state = main._combat._state
	var board_king = state.foes.filter(func(f): return f.type.tactic == EnemyType.Tactic.QUEEN)[0]
	check("the King's fight is on the board", state.field and main._tactical.active and main._combat.no_retreat)
	check("...the King and his guards are 3D models on their tiles", state.foes.all(func(f): return FoeView.is_model(f.node) and absf(f.node.position.y) < 0.01))
	check("...and never lose the trail", not main._field_lost(board_king))
	await _snap("king_board")
	main._fight_kind = ""
	main._combat.no_retreat = false
	await _end_fight(main)
	await create_timer(1.0).timeout
	# With the board off he has no painting: on the dark stage he is his
	# model, standing on the floor (never lifted like a sprite).
	Settings.set_value("tactical_view", false)
	var eye: Camera3D = main._party.camera
	var cave_mask := eye.cull_mask
	main._queen_fight(main._party.cell)
	await create_timer(1.4).timeout
	state = main._combat._state
	var king = state.foes.filter(func(f): return f.type.tactic == EnemyType.Tactic.QUEEN)[0]
	check("on the dark stage, the King is his 3D model", FoeView.is_model(king.node) and not state.field)
	check("...feet at the party's floor", absf(king.node.global_position.y - main._party.global_position.y) < 0.05, king.node.global_position.y)
	check("...planting his staff to call his guards", main._combat._action_pose(king, main.CombatState.Intent.CALL, {}) == "plant")
	check("...and raising his staff for the coin blow", main.CombatState.INTENT_TEXT[main.CombatState.Intent.CLEAVER] == "raising his staff")
	var king_x := eye.unproject_position(king.node.global_position).x
	var guard_x: Array = state.foes.filter(func(f): return f != king).map(
		func(f): return eye.unproject_position(f.node.global_position).x)
	check("...the guards flank the King on the dark stage", guard_x.min() < king_x and king_x < guard_x.max())
	check("...the stage clears cave geometry and lights the King",
		eye.cull_mask != cave_mask and king.node.find_children("*", "OmniLight3D", true, false).size() == 2)
	await _snap("king")
	main._fight_kind = ""  # no victory card in this check
	main._combat.no_retreat = false
	await _end_fight(main)
	check("...the cave is visible again after the stage", eye.cull_mask == cave_mask)
	Settings.set_value("tactical_view", true)
	await _check_goblin_elites(main)
	print("fails=", fails)
	quit()
