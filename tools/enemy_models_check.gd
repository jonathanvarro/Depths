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
		if main._combat.awaiting_field_action:
			main._combat._action_chosen.emit({"kind": "wait"})
		elif main._combat._actions.visible:
			main._combat._action_chosen.emit({"kind": "defend"})
		await create_timer(0.1).timeout
		g += 1


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
	Settings.set_value("tactical_view", true)
	print("fails=", fails)
	quit()
