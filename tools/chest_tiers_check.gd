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


func main_kind_chest() -> int:
	return load("res://scripts/dungeon_map.gd").Content.CHEST


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
	# The old containers keep their own families, below a chest (owner, 2026-11-22).
	var room_events = load("res://scripts/room_events.gd").new()
	for id in ChestTiers.CONTAINERS:
		check("%s is still a container that turns up" % id, ResourceLoader.exists("res://data/events/%s.tres" % id) and load("res://data/events/%s.tres" % id).min_depth < 50)
	var family_gear := 0
	var family_items := {}
	var container_value := 0
	for id in ChestTiers.CONTAINERS:
		for i in 200:
			var l: Dictionary = ChestTiers.loot(rng, "common", 3, id)
			family_gear += l["gear"].size() + (1 if l["trinket"] else 0)
			container_value += l["gold"]
			for item in l["items"]:
				family_items[item.resource_path.get_file().get_basename()] = id
				container_value += item.price * l["items"][item]
				if item.resource_path.get_file().get_basename() not in ChestTiers.CONTAINERS[id]["items"]:
					check("%s gives only its own family" % id, false, item.resource_path)
	check("containers never hold a piece of gear: that's the chests'", family_gear == 0, family_gear)
	check("...but do add from their families: supplies, tools, ore, valuables, scrap", ["ration", "spade", "copper_ore", "old_coin_purse", "goblin_scrap"].all(func(i): return family_items.has(i)), family_items.keys())
	var chest_value := 0
	for i in 200 * ChestTiers.CONTAINERS.size():
		var l: Dictionary = ChestTiers.loot(rng, "common", 3, "chest_common")
		chest_value += l["gold"] + l["gear"].reduce(func(a, g): return a + g.price, 0)
	check("a common chest is worth more than an old container", chest_value > container_value, [chest_value, container_value])
	var common_event: RoomEvent = load("res://data/events/chest_common.tres")
	check("the common chest is ChatGPT's chest art", common_event.prop.resource_path == ChestTiers.ART % "common")
	var picks := {}
	for i in 400:
		var e: RoomEvent = room_events.pick(main_kind_chest(), 2)
		picks[e.resource_path.get_file().get_basename()] = picks.get(e.resource_path.get_file().get_basename(), 0) + 1
	check("chests and containers share the floor: chests most often", picks.get("chest_common", 0) > 60 and picks.size() >= 5 and picks.get("chest_common", 0) == picks.values().max(), picks)
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
	# Opening an old pack: its own find, added to the pack.
	var rations: int = main._party_state.supplies.count(load("res://data/items/ration.tres")) + main._party_state.supplies.count(load("res://data/items/oil_flask.tres")) + main._party_state.supplies.count(load("res://data/items/dressing.tres")) + main._party_state.supplies.count(load("res://data/items/torch.tres"))
	var held_gear: int = main._party_state.supplies.gear.size()
	for i in 12:
		main._open_tiered("common", "chest_abandoned_pack")
	var after: int = main._party_state.supplies.count(load("res://data/items/ration.tres")) + main._party_state.supplies.count(load("res://data/items/oil_flask.tres")) + main._party_state.supplies.count(load("res://data/items/dressing.tres")) + main._party_state.supplies.count(load("res://data/items/torch.tres"))
	check("searching old packs turns up supplies, never gear", after > rations and main._party_state.supplies.gear.size() == held_gear, [rations, after])
	if shots != "":
		var spot: Vector2i = main._party.cell
		for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			if main._map.is_passable(spot + d) and main._map.content_at(spot + d) == main.DungeonMap.Content.NONE:
				main._map.contents[spot + d] = main.DungeonMap.Content.CHEST
				main._map.events[spot + d] = common_event
				main._create_room_prop(spot + d, common_event)
				main._face_toward(spot + d)
				break
		await _snap("common")
	# A container's finds are laid out beside the pack (owner, 2026-11-22):
	# point at one to read it, take one, or take them all; the rest stays.
	var box: Vector2i = Vector2i(-1, -1)
	for c in main._map.walking_distances(main._party.cell):
		if c != main._party.cell and main._map.content_at(c) == main.DungeonMap.Content.NONE and not main._map.solid.has(c) and main._map.door_at(c) == 0:
			box = c
			break
	main._map.contents[box] = main.DungeonMap.Content.CHEST
	main._map.events[box] = load("res://data/events/chest_abandoned_pack.tres")
	main._map.triggered.erase(box)
	var before_items: int = main._party_state.supplies.slots_used()
	main._run_event(box)
	await process_frame
	for tries in 6:
		if not main._event_screen.visible:
			break
		var choice: Array = main._event_screen._buttons.get_children().filter(func(b): return b is Button and not b.disabled)
		if not choice.is_empty():
			choice[0].pressed.emit()
		await create_timer(0.2).timeout
	check("an old pack's finds open beside the pack, not straight into it", main._chest.visible and not main._chest.is_empty() and main._party_state.supplies.slots_used() == before_items, [main._chest.visible, main._chest.contents])
	if not main._chest.contents.is_empty():
		var first = main._chest.contents.keys()[0]
		main._chest.select_item(first, "left", false)
		await process_frame
		check("...pointing at one shows its card", main._chest._detail_text.get_child_count() > 1)
		var strip: float = main._chest._details.size.y
		main._chest.take_all()
		await process_frame
		await process_frame
		check("...take all fills the pack, and the card strip keeps its height", main._chest.is_empty() and main._party_state.supplies.slots_used() > before_items and absf(main._chest._details.size.y - strip) < 1.0, [strip, main._chest._details.size.y])
	main._chest.closed.emit()
	await create_timer(0.2).timeout
	var data: Dictionary = main._save_data()
	main._restore(data)
	await create_timer(0.3).timeout
	check("a save keeps each chest's tier", ChestTiers.tier_at(main._map, dropped[0]) == "silver" and ChestTiers.tier_at(main._map, chest) == "silver")
	print("fails=", fails)
	quit()
