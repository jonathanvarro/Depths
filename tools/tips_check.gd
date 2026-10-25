extends SceneTree
## First-time tips (2026-10-25): past the opening, each newer system is
## explained once when it first matters - a monster's first sighting,
## elites, a full pack, banes - one card at a time, and never again once
## seen. Args: tag, screenshot dir.

const Settings := preload("res://scripts/settings.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _e(id: String) -> EnemyType:
	return load("res://data/enemies/%s.tres" % id)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	Engine.set_meta("depths_tips", true)  # test runs skip tips otherwise
	Settings.set_value("tips_seen", [])

	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(3, main.Arrival.FROM_ABOVE)
	await process_frame

	# First sight of a monster: its own intro, one card at a time.
	main._start_combat(main._party.cell, [_e("hollow_miner"), _e("gas_bloat"), _e("goblin")] as Array[EnemyType])
	var state = main._combat._state
	var miner_first: bool = state.foes.all(func(f): return f.elite == "")
	if miner_first:
		check("first sight of a hollow miner explains it", main._hint == "tip_foe_hollow_miner" and main._hint_mode == "ok" and main._hint_text.begins_with(_e("hollow_miner").intro) and main._hint_text.contains("? beside its move"), main._hint)
	else:
		check("an elite in the fight is explained first", main._hint == "tip_elite", main._hint)
	check("...one card at a time: the rest wait", main._tip_queue.size() >= 1)
	if dir != "":
		var w := 0
		while not main._combat._actions.visible and w < 60:
			await create_timer(0.1).timeout
			w += 1
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png(dir + "/tips_" + tag + "_fight.png")
	while main._hint_mode == "ok":
		main._finish_hint()
	check("the gas-bloat had its turn", "foe_gas_bloat" in Settings.get_value("tips_seen"))
	check("a plain goblin, taught by the opening, gets none", not Settings.get_value("tips_seen").any(func(k): return k.begins_with("foe_goblin")))
	main._fight_tips(state)
	check("seen once, never again", main._hint == "" and main._tip_queue.is_empty())

	# Elites.
	state.make_elite(state.foes[2], "Savage")
	main._fight_tips(state)
	if miner_first:
		check("an elite is explained the first time", main._hint == "tip_elite", main._hint)
	while main._hint_mode == "ok":
		main._finish_hint()

	# A bane.
	var mara: Companion = main._party_state.members[0]
	mara.add_boon(load("res://data/boons/sickness.tres"))
	check("a bane is explained when it lands", main._hint == "tip_bane", main._hint)
	main._finish_hint()
	mara.add_boon(load("res://data/boons/marked.tres"))
	check("...once", main._hint == "")

	# A full pack.
	main._offer_no_room({load("res://data/items/ration.tres"): 1})
	check("a full pack explains leaving something to make room", main._hint == "tip_pack_full", main._hint)
	if dir != "":
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png(dir + "/tips_" + tag + "_pack.png")
	main._finish_hint()
	main._chest.closed.emit()

	# Persisted for the next campaign.
	var seen: Array = Settings.get_value("tips_seen")
	Engine.remove_meta(Settings.STATE)
	Engine.remove_meta(Settings.STATE + "_loaded")
	check("remembered in the settings file", Settings.get_value("tips_seen") == seen, str(seen))
	Settings.set_value("tips_seen", [])
	print("fails=", fails)
	quit()
