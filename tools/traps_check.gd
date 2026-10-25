extends SceneTree
## Traps (#94, owner 2026-10-25): spotted traps offer their choices;
## unspotted ones spring as the party walks in, with the shared fall;
## spotting comes down to the light unless someone has keen eyes, a boon or
## a Scout's Trap sense; the bell wire's ring means the next fight is
## waiting and moves first; snare limps, dart stings.
## Args: tag, screenshot dir.

const Progression := preload("res://scripts/progression.gd")
const Supplies := preload("res://scripts/supplies.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	# The data.
	var bell: RoomEvent = load("res://data/events/trap_bell_wire.tres")
	var snare: RoomEvent = load("res://data/events/trap_snare.tres")
	var dart: RoomEvent = load("res://data/events/trap_dart.tres")
	check("every trap springs on its own if unseen", ["trap_bell_wire", "trap_snare", "trap_dart", "trap_tripwire", "trap_hollow_floor"].all(func(id): return load("res://data/events/%s.tres" % id).sprung != null))
	check("bell wire: rings, no harm", bell.sprung.alarm and bell.sprung.health == 0)
	check("snare: a limp", snare.sprung.injury != null and snare.sprung.injury.display_name == "Limp")
	check("dart: 3 damage", dart.sprung.health == -3)
	check("Trap sense is a Scout's level-4 talent, in place of Slip the web", Progression.TALENTS["Scout"][4].map(func(t): return t[0]) == ["trap_sense", "opening_shot"] and "slip_web" in Progression.TALENTS["Rogue"][4].map(func(t): return t[0]))

	# In the game: a floor with a trap, and Mara without keen eyes.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 21
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	var ps = main._party_state
	var mara: Companion = ps.living_members()[0]
	mara.trait_id = ""  # without her keen eyes, spotting is down to the light
	var map = main._map
	var trap_cell := Vector2i(-1, -1)
	for y in map.height:
		for x in map.width:
			var c := Vector2i(x, y)
			if trap_cell == Vector2i(-1, -1) and map.is_passable(c) and map.content_at(c) == 0 and not map.events.has(c) and not map.encounter_zones.has(c) and map.is_passable(c + Vector2i.LEFT):
				trap_cell = c
	check("a place for the snare", trap_cell != Vector2i(-1, -1))
	map.events[trap_cell] = snare
	var sees: bool = ps.sees_traps()
	check("without keen eyes, no one sees every trap", not sees)

	# Spotting by light: none in the dark.
	ps.supplies.oil = 0.0
	ps.supplies.torch_left = 0.0
	map.spotted.erase(trap_cell)
	if not sees:
		main._look_for_traps(trap_cell + Vector2i.LEFT)
		check("in the dark, no one spots it", map.spotted.get(trap_cell, true) == false, str(map.spotted.get(trap_cell)))
		# Walk in unseen: it springs.
		var injuries: int = mara.injuries.size()
		map.enter(trap_cell)
		await main._spring_trap(trap_cell, snare)
		check("unseen, it springs with a fall: a limp", mara.injuries.size() == injuries + 1 and not main._party.locked, "%d -> %d, locked %s, %s" % [injuries, mara.injuries.size(), main._party.locked, main._message_label.text])

	# Trap sense sees everything.
	var scout: Companion = load("res://data/companions/corin.tres").duplicate()
	scout.role = "Scout"
	scout.talents.assign(["trap_sense"])
	ps.add_member(scout)
	check("a Scout with Trap sense sees every trap", ps.sees_traps())

	# The bell: the next fight was waiting.
	map.alarmed = true
	var fight_cell := Vector2i(-1, -1)
	var door := Vector2i(-1, -1)
	for c in map.encounter_zones:
		var f: Vector2i = map.encounter_zones[c]
		if not map.lairs.has(f) and not map.fight_groups.has(f) and not map.triggered.has(f):
			fight_cell = f
			door = c
			break
	check("after a bell, they can't be heard first", not main._hears_first(fight_cell))
	main._on_party_entered_cell(door)
	await process_frame
	var state = main._combat._state
	check("...and they move first", main._in_combat and state != null and state.opening == "foes" and not map.alarmed, "%s %s" % [main._in_combat, state.opening if state else "-"])
	if dir != "":
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png("%s/traps_%s.png" % [dir, tag])
	print("fails=", fails)
	quit()
