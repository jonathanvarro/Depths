extends SceneTree
## Chest tiers (owner, 2026-11-22; scripts/chest_tiers.gd): common, silver
## and gold, the rarer the richer. Silver behind puzzles and in lairs; gold
## for named elite packs and the Goblin King. Args: tag, screenshot dir.

const ChestTiers := preload("res://scripts/chest_tiers.gd")

var fails := 0
var shots := ""


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(name: String) -> void:
	if shots == "":
		return
	await create_timer(1.0).timeout
	var image := root.get_texture().get_image()
	if image:
		image.save_png(shots + "/chest_" + name + ".png")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	shots = args[1] if args.size() > 1 else ""
	# --- The loot climbs with the tier --------------------------------------
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var sums := {}
	for tier in ChestTiers.TIERS:
		var s := {"pieces": 0, "mods": 0, "gold": 0, "trinkets": 0}
		for i in 300:
			var loot: Dictionary = ChestTiers.loot(rng, tier, 3)
			s["pieces"] += loot["gear"].size()
			for g in loot["gear"]:
				s["mods"] += g.mods.size()
			s["gold"] += loot["gold"]
			s["trinkets"] += 1 if loot["trinket"] else 0
		sums[tier] = s
	check("silver beats common: more finds, more modifiers, gold", sums["silver"]["pieces"] > sums["common"]["pieces"] and sums["silver"]["mods"] > sums["common"]["mods"] and sums["silver"]["gold"] > sums["common"]["gold"], sums)
	check("gold beats silver on every count", sums["gold"]["pieces"] > sums["silver"]["pieces"] and sums["gold"]["mods"] > sums["silver"]["mods"] and sums["gold"]["gold"] > sums["silver"]["gold"] and sums["gold"]["trinkets"] > sums["silver"]["trinkets"])
	var one: Dictionary = ChestTiers.loot(rng, "gold", 2)
	check("a gold chest always holds a two-modifier find", one["gear"].size() == 2 and one["gear"][0].mods.size() >= 2)
	check("the hoard events never turn up as ordinary chests", load(ChestTiers.HOARD_EVENT % "silver").min_depth > 50 and load(ChestTiers.HOARD_EVENT % "gold").min_depth > 50)

	# --- Where they turn up ---------------------------------------------------
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 500
	root.add_child(main)
	await create_timer(0.5).timeout
	var found := false
	for s in 300:
		main._site_seed = 500 + s
		main._floors.clear()
		main._go_to_floor(1, main.Arrival.FROM_ABOVE)
		if main._map.marks.get("puzzles", []).any(func(p): return p["kind"] != "oneway"):
			found = true
			break
	check("a floor with a puzzle room", found)
	await create_timer(0.3).timeout
	var puzzle: Dictionary = main._map.marks["puzzles"].filter(func(p): return p["kind"] != "oneway")[0]
	var chest: Vector2i = puzzle["chest"]
	check("the chest behind a puzzle is silver", ChestTiers.tier_at(main._map, chest) == "silver" and main._map.events[chest].resource_path.ends_with("chest_silver_hoard.tres"))
	var prop: Node3D = main._props.get(chest)
	check("...and looks it (its art, or a silver glint until the art lands)", prop != null and (ResourceLoader.exists(ChestTiers.ART % "silver") or prop.get_node_or_null("TierGlint") != null))
	var ordinary: Array = main._map.contents.keys().filter(func(c): return main._map.content_at(c) == main.DungeonMap.Content.CHEST and c != chest)
	check("other chests stay common", ordinary.all(func(c): return ChestTiers.tier_at(main._map, c) == "common"))

	var gold: int = main._party_state.supplies.gold
	var held: int = main._party_state.supplies.gear.size()
	main._open_tiered("silver")
	check("opening a silver chest: a find and gold", main._party_state.supplies.gold > gold and main._party_state.supplies.gear.size() > held)

	# A named pack's hoard is a gold chest where it fell; a lair's is silver.
	var stand: Vector2i = main._map.find_content(main.DungeonMap.Content.STAIRS_UP)
	main._party.place(main._map, stand + Vector2i(0, 0))
	main._elite_id = "whisker"
	main._map.marks["elite"] = {"id": "whisker", "cell": stand, "beaten": false}
	var before: Array = main._map.contents.keys()
	main._elite_won()
	var dropped: Array = main._map.contents.keys().filter(func(c): return c not in before)
	check("a beaten named pack leaves a gilded chest beside the party", dropped.size() == 1 and ChestTiers.tier_at(main._map, dropped[0]) == "gold" and main._props.has(dropped[0]), dropped)
	if shots != "" and dropped.size() == 1:
		main._face_toward(dropped[0])
		main._map.reveal_around(main._party.cell, 3)
		await _snap("gold")
	before = main._map.contents.keys()
	main._lair_won()
	dropped = main._map.contents.keys().filter(func(c): return c not in before)
	check("a lair's hoard is a silver chest", dropped.size() == 1 and ChestTiers.tier_at(main._map, dropped[0]) == "silver")
	var data: Dictionary = main._save_data()
	main._restore(data)
	await create_timer(0.3).timeout
	check("a save keeps each chest's tier", ChestTiers.tier_at(main._map, dropped[0]) == "silver" and ChestTiers.tier_at(main._map, chest) == "silver")
	print("fails=", fails)
	quit()
