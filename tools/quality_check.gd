extends SceneTree
## Item quality borders (owner, 2026-10-21): common has none, fine pale
## bronze, magic blue, rare cold silver with studs, unique amber gold, and
## a cursed trinket violet only once worn. Shown in the Pack, chests, shops
## and on the cards. Args: tag, screenshot dir.

const Quality := preload("res://scripts/quality.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _t(id: String) -> Equipment:
	return load("res://data/trinkets/%s.tres" % id)


func _item(id: String) -> SupplyItem:
	return load("res://data/items/%s.tres" % id)


func _border(control: Control) -> Color:
	var box = control.get_theme_stylebox("panel") if control is PanelContainer else null
	return box.border_color if box is StyleBoxFlat else Color(0, 0, 0, 0)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	check("a ration is common", Quality.tier_of(_item("ration")) == "common")
	check("a smith's sword is common", Quality.tier_of(load("res://data/gear/iron_sword.tres")) == "common")
	check("jewellery takes its trinket's tier: magic", Quality.tier_of(_item("amber_pendant")) == "magic")
	check("the reliquary is rare", Quality.tier_of(_item("small_reliquary")) == "rare")
	check("a unique is unique", Quality.tier_of(_t("bloodstone")) == "unique")
	var hero := Companion.new()
	var torc := _t("goblin_torc_cursed")
	check("a cursed trinket passes for magic until worn", Quality.tier_of(torc, hero) == "magic")
	hero.trinket = torc
	check("...and shows as cursed once it is", Quality.tier_of(torc, hero) == "cursed")
	var plain := Quality.framed(_item("ration").icon, "common", Vector2(40, 40))
	check("common: no border", plain is TextureRect)
	var blue := Quality.framed(_item("amber_pendant").icon, "magic", Vector2(40, 40))
	check("magic: a blue border", _border(blue) == Quality.COLOURS["magic"] and blue.get_theme_stylebox("panel").border_width_left == 2)
	var silver := Quality.framed(_item("small_reliquary").icon, "rare", Vector2(40, 40))
	check("rare: silver, with corner studs", _border(silver) == Quality.COLOURS["rare"] and silver.get_child_count() == 2)
	var gold := Quality.framed(_t("bloodstone").icon, "unique", Vector2(40, 40))
	check("unique: amber gold, thicker", _border(gold) == Quality.COLOURS["unique"] and gold.get_theme_stylebox("panel").border_width_left == 3)
	check("fine and magic differ in colour and weight", Quality.COLOURS["fine"] != Quality.COLOURS["magic"] and Quality.WIDTHS["fine"] != Quality.WIDTHS["magic"])

	# In the game.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	ps.supplies.add(_item("amber_pendant"))
	ps.supplies.add(_item("small_reliquary"))
	ps.supplies.gear.append(_t("bloodstone"))
	main._set_pack(true)
	await process_frame
	var frames: Array = main._pack._list.find_children("*", "PanelContainer", true, false).filter(func(p): return p.has_meta("tier"))
	var tiers: Array = frames.map(func(p): return p.get_meta("tier"))
	check("the Pack frames magic, rare and unique finds", "magic" in tiers and "rare" in tiers and "unique" in tiers, str(tiers))
	if dir != "":
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png(dir + "/quality_" + tag + "_pack.png")
	main._set_pack(false)
	ps.wear_treasure(ps.members[0], _item("amber_pendant"))
	await process_frame
	var card_frames: Array = main._cards[0]._icons.get_children().filter(func(c): return c.has_meta("tier"))
	check("the card frames a worn trinket", card_frames.any(func(c): return c.get_meta("tier") == "magic"))
	main._chest.open("A test chest", {_item("small_reliquary"): 1, _item("ration"): 1}, ps)
	await process_frame
	var tiles: Array = main._chest._chest_grid.get_children().filter(func(t): return t.has_meta("tier"))
	check("a chest frames its rare find, not the ration", tiles.size() == 1 and tiles[0].get_meta("tier") == "rare")
	if dir != "":
		for i in 4:
			await process_frame
		root.get_texture().get_image().save_png(dir + "/quality_" + tag + "_chest.png")
	main._chest.closed.emit()
	print("fails=", fails)
	quit()
