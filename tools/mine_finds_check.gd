extends SceneTree
## Floor 1's places and finds (owner, 2026-11-10): more, rarer landmarks;
## a tool rack with basic mining weapons; coal to sell at camp.
## Args: tag, screenshot dir.

const CampState := preload("res://scripts/camp_state.gd")
const RoomEvents := preload("res://scripts/room_events.gd")
const COAL := preload("res://data/items/coal.tres")
const PICK := preload("res://data/items/pick.tres")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _party():
	var p = load("res://scripts/party_state.gd").new()
	var hero := Companion.new()
	hero.display_name = "Mara"
	hero.max_health = 20
	hero.health = 20
	p.add_member(hero)
	return p


func _initialize() -> void:
	# The landmarks: over many floor 1s, every kind turns up and none dominates.
	var seen := {}
	var floors := 30
	for s in range(1, floors + 1):
		var main = load("res://scenes/main.tscn").instantiate()
		main.play_opening = false
		main.floor_seed = s * 17
		root.add_child(main)
		await process_frame
		await process_frame
		main._floors.clear()
		main._go_to_floor(1, main.Arrival.FROM_ABOVE)
		await process_frame
		for l in main._map.landmarks:
			seen[l["id"]] = seen.get(l["id"], 0) + 1
		main.queue_free()
		await process_frame
	var Landmarks = load("res://scripts/landmarks.gd")
	var floor1: Array = Landmarks.KINDS.keys().filter(func(k): return Landmarks.KINDS[k]["floors"][0] <= 1)
	var missing: Array = floor1.filter(func(k): return not seen.has(k))
	check("every floor-1 landmark turns up over %d floors" % floors, missing.is_empty(), missing)
	check("...and no single one is on most floors", seen.values().all(func(n): return n <= floors * 0.7), seen)
	for id in ["collapsed_shaft", "timbered_drift", "flooded_sump", "old_cave_in"]:
		check("%s is a rare find" % id, seen.get(id, 0) <= floors * 0.45, seen.get(id, 0))

	# The tool rack: a weapon (or the pick), and coal on the shelf.
	var rack: RoomEvent = load("res://data/events/chest_tool_rack.tres")
	var events = RoomEvents.new()
	var gear_names := {}
	for i in 40:
		var p = _party()
		events.resolve(p, rack.choices[0])
		for g in p.supplies.gear:
			gear_names[g.display_name] = true
		if p.supplies.count(PICK) > 0:
			gear_names["Miner's pick (tool)"] = true
	check("a tool rack gives a mattock, a sledge or a pick", gear_names.has("Mattock") and gear_names.has("Miner's sledge") and gear_names.has("Miner's pick (tool)"), gear_names.keys())
	var mattock: Equipment = load("res://data/gear/mattock.tres")
	var sledge: Equipment = load("res://data/gear/miners_sledge.tres")
	check("the mattock hits hard but clumsily, the sledge steadily", mattock.attack_max > sledge.attack_max and mattock.accuracy_bonus < sledge.accuracy_bonus)
	var shelf = _party()
	events.resolve(shelf, rack.choices[1])
	check("its shelf holds coal", shelf.supplies.count(COAL) == 2)

	# The coal seam: by hand a lump or two; a pick works it properly.
	var seam: RoomEvent = load("res://data/events/chest_coal_seam.tres")
	check("working the seam needs a pick", seam.choices[0].requires == PICK)
	var dug = _party()
	events.resolve(dug, seam.choices[0])
	var by_hand = _party()
	events.resolve(by_hand, seam.choices[1])
	check("a pick brings out four lumps, hands one or two", dug.supplies.count(COAL) == 4 and by_hand.supplies.count(COAL) in [1, 2], "%d / %d" % [dug.supplies.count(COAL), by_hand.supplies.count(COAL)])

	# Back at camp: the merchant buys it.
	var camp = CampState.new()
	var seller = _party()
	seller.supplies.add(COAL, 3)
	var gold: int = seller.supplies.gold
	camp.sell(seller, COAL)
	check("the merchant pays %d gold a lump" % COAL.price, seller.supplies.gold == gold + COAL.price and seller.supplies.count(COAL) == 2, seller.supplies.gold - gold)
	print("fails=", fails)
	quit()
