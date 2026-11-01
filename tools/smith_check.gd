extends SceneTree
## The smith on the merchant's exchange (owner, 2026-10-31): today's wares
## (eight, no scrolling, new each day, rolled by the gear tables) beside the
## pack; buy, sell gear back, and the forge offer as a button. Before the
## forge: plain, rough work; after it: finer pieces with modifiers.
## Args: tag (desk|phone), screenshot dir.

const Quests := preload("res://scripts/quests.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _shot(dir: String, name: String) -> void:
	if dir == "":
		return
	for i in 6:
		await process_frame
	var image := root.get_texture().get_image()
	if image:
		image.save_png("%s/%s.png" % [dir, name])


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	root.add_child(main)
	await create_timer(0.5).timeout
	main._end_expedition(main.Expedition.Ending.RETURNED)
	await process_frame
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout
	var camp = main._camp_state
	var ps = main._party_state
	camp.set_site_present("smith", true)
	ps.supplies.gold = 200

	var wares: Array = camp.smith_wares().duplicate()
	check("eight pieces of work today", wares.size() == camp.SMITH_WARES, wares.size())
	check("...items of their own, plain before the forge", wares.all(func(w): return w.base_id != "" and w.mods.is_empty() and w.quality in ["cracked", "bent", "ordinary"]), wares.map(func(w): return w.display_name))
	check("...the same all day", camp.smith_wares() == wares)
	main._camp.open_activity("smith")
	await process_frame
	var view = main._camp._smith_view
	check("the smith opens on the exchange, not a list", view.visible and not main._camp._activity.visible)
	var left_tiles: Array = view._left_grid.get_children().filter(func(c): return c is Button) if "_left_grid" in view else []
	await _shot(dir, "smith_%s" % tag)
	var piece: Equipment = wares[0]
	var gold: int = ps.supplies.gold
	check("buy a piece", camp.buy_gear(ps, piece) and ps.supplies.gold < gold and piece in ps.supplies.gear and piece not in camp.smith_wares())
	gold = ps.supplies.gold
	check("...and sell it back at the smith, at half", camp.sell_gear(ps, piece, true) and ps.supplies.gold == gold + floori(piece.price * camp.GEAR_RESALE))
	Quests.set_stage(camp, "iron_sample", Quests.Stage.RESOLVED)
	view.refresh()
	check("the forge offer is a button on the exchange", view._extra.visible and view._extra.text.begins_with("Build a forge"))
	camp.build_forge(ps)
	var forge_wares: Array = camp.smith_wares().duplicate()
	check("the forge's first work: finer pieces, some with something extra", forge_wares.size() == camp.SMITH_WARES and forge_wares != wares)
	view.refresh()
	await _shot(dir, "smith_%s_forge" % tag)
	camp.day += 1
	check("tomorrow, new work", camp.smith_wares() != forge_wares)
	print("fails=", fails)
	quit()
