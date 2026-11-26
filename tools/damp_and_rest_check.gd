extends SceneTree
## Owner, 2026-11-26, while the art is made: the Damp Caves' rules (water,
## three creatures with stand-in models, the Drowned Mother), the Rest Area
## as an earned destination, the Sapper's perks, the tent's records and the
## Jail's locked cell. Args: tag, screenshot dir.

const Q := preload("res://scripts/quests.gd")
const Elites := preload("res://scripts/elites.gd")
const EnemyType := preload("res://scripts/enemy_type.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	# The creatures.
	var newt: Resource = load("res://data/enemies/pale_newt.tres")
	var crawler: Resource = load("res://data/enemies/blind_crawler.tres")
	var leeches: Resource = load("res://data/enemies/leech_swarm.tres")
	check("the pale newt darts at the weakest from the back", newt.tactic == EnemyType.Tactic.DARTING and newt.row == "back")
	check("the blind crawler grabs and holds", crawler.tactic == EnemyType.Tactic.GRABBER)
	check("the leech swarm drains over turns, without webs, and fears fire", leeches.venomous and leeches.web_chance == 0.0 and leeches.fears_fire)

	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 52
	root.add_child(main)
	await create_timer(0.5).timeout
	Q.set_stage(main._camp_state, "left_behind", Q.Stage.RESOLVED)

	var pool: Array = main.encounter_pool(2, 3)
	var names := {}
	for group in pool:
		for t in group:
			names[t.display_name] = true
	check("the Damp Caves' fights include newts, crawlers and leeches", names.has("Pale newt") and names.has("Blind crawler") and names.has("Leech swarm"), names.keys())
	check("the Fungal Hollows draw their own fights", main.encounter_pool("hollows", 3).size() > 3 and not main.encounter_pool("hollows", 3).any(func(g): return g.any(func(t): return t.display_name == "Pale newt")))
	check("the Drowned Mother's brood walks the Damp Caves", Elites.PACKS.has("drowned") and Elites.PACKS["drowned"]["floors"] == [2] and Elites.types("drowned")[0].display_name == "Pale newt")

	# Water: deep stretches to wade, puddles that are only for looks.
	main._go_to_area("damp", main.Arrival.FROM_ABOVE)
	check("the Damp Caves have deep water to wade", not main._map.water.is_empty(), main._map.water.size())
	check("...and shallow puddles in rooms (looks only)", not main._map.marks.get("shallow", {}).is_empty() and main._map.marks["shallow"].keys().all(func(c): return not main._map.is_water(c)), main._map.marks.get("shallow", {}).size())
	main._go_to_area("hollows", main.Arrival.FROM_ABOVE)
	check("the Fungal Hollows stay dry", main._map.water.is_empty() and not main._map.marks.has("shallow"))

	# The Rest Area: an earned route.
	check("no route to the Rest Area before it's reached", not main._camp_state.route_open(3))
	main._go_to_area("rest", main.Arrival.FROM_ABOVE)
	check("reaching the Rest Area opens the route there", main._camp_state.rest_secured and main._camp_state.route_open(3) and main.Areas.route_area(3) == "rest")

	# The Sapper.
	var sapper: Companion = load("res://scripts/recruits.gd").make(RandomNumberGenerator.new(), [], [], 1, "Fixer")
	var saw_before: bool = main._party_state.sees_traps()
	main._party_state.add_member(sapper)
	check("a Sapper doesn't spot traps (that's the Scout's)", main._party_state.sapper() != null and main._party_state.sees_traps() == saw_before)
	# ...but disarms them on a favourable coin flip; stepping over stays a roll.
	var screen = main._event_screen
	var wire: RoomEvent = load("res://data/events/trap_tripwire.tres")
	screen._event = wire
	screen._party = main._party_state
	check("...disarms a trap on a coin flip in the party's favour", screen._disarmer(wire.choices[1]) == main._party_state.sapper() and screen._disarmer(wire.choices[1]) != null and screen.SAPPER_DISARM >= 0.85 and screen.SAPPER_DISARM < 1.0, [screen._disarmer(wire.choices[1]), wire.kind, wire.choices[1].bypass, wire.choices[1].outcomes.size(), screen.SAPPER_DISARM])
	check("...but stepping over is still a plain roll", screen._disarmer(wire.choices[0]) == null)
	check("...and no longer haggles", main._camp_state.price_for(main._party_state, 20) == 20)
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	var map = main._map
	var trap_cell := Vector2i(-1, -1)
	for c in map.walking_distances(main._party.cell):
		if c != main._party.cell and map.content_at(c) == 0 and not map.solid.has(c) and map.door_at(c) == 0 and not map.encounter_zones.has(c):
			trap_cell = c
			break
	var tripwire: RoomEvent = load("res://data/events/trap_tripwire.tres")
	map.contents[trap_cell] = main.DungeonMap.Content.TRAP
	map.events[trap_cell] = tripwire
	map.triggered[trap_cell] = true
	map.marks["set_traps"] = {trap_cell: true}
	main._groups.clear()
	var resolved: int = main._expedition.events_resolved
	main._party.place(map, trap_cell)
	main._on_party_entered_cell(trap_cell)
	await create_timer(0.3).timeout
	check("...and jams a set trap as the party passes", not map.marks["set_traps"].has(trap_cell) and main._expedition.events_resolved == resolved and not main._in_combat)

	# The tent's records.
	var records: Array = main._camp_state.records()
	check("the tent keeps records, the days among them", records.any(func(r): return r[0] == "Days at the camp") and records.any(func(r): return r[0] == "Trips into the mine"), records)
	check("...on the papers on its table", load("res://scripts/tent_interior.gd").TARGETS.has("records"))

	# The Jail: a locked cell, always.
	main._go_to_area("jail", main.Arrival.FROM_ABOVE)
	var keys: Array = main._map.marks.get("puzzles", []).filter(func(p): return p.has("key"))
	check("the Jail always has a locked cell and its key", not keys.is_empty(), main._map.marks.get("puzzles", []).map(func(p): return p.keys()))
	print("fails=", fails)
	quit()
