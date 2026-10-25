extends SceneTree
## Lamp-eater territory (#149): an old lamp store placed by chance on
## floors 2-3. Its dead lamps warn before anything is decided; going in
## with the light up wins three oil flasks and draws two lamp-eaters;
## creeping in with the light hooded frays nerves for one flask and maybe
## one lamp-eater; leaving costs nothing and it waits for a return.
## Args: tag, screenshot dir.

const Packages := preload("res://scripts/packages.gd")
const RoomEvents := preload("res://scripts/room_events.gd")
const OIL := preload("res://data/items/oil_flask.tres")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _press(node: Node, label: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if b.text.begins_with(label) and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	# Where and how often.
	var counts := {1: 0, 2: 0, 3: 0, 4: 0}
	for seed in 500:
		for depth in [1, 2, 3, 4]:
			counts[depth] += Packages.territories(depth, seed * 17 + depth).size()
	check("on floors 2-3, about 2 floors in 5", counts[1] == 0 and counts[4] == 0 and [2, 3].all(func(d): return counts[d] > 160 and counts[d] < 240), str(counts))
	var camp = load("res://scripts/camp_state.gd").new()
	check("not a quest's package, nor a mini-boss lair", not Packages.active(camp, 2).any(func(p): return p.id == "territory_lamp_eaters") and not Packages.lairs(2, 5).any(func(p): return p.id == "territory_lamp_eaters"))
	var events = RoomEvents.new()
	var drawn := false
	for i in 300:
		for depth in [1, 2, 3, 4]:
			var e = events.pick(4, depth)
			if e and e.title == "Dead lamps":
				drawn = true
	check("never drawn as an ordinary random event", not drawn)

	# The choices.
	var event: RoomEvent = load("res://data/events/territory_lamp_eaters.tres")
	check("its clue warns before anything is decided", event.clue.contains("drinks light") and event.clue.contains("sealed flasks"))
	var bold: EventChoice = event.choices[0]
	var creep: EventChoice = event.choices[1]
	check("light held high: three flasks and two lamp-eaters", bold.outcomes[0].loot.get(OIL, 0) == 3 and bold.outcomes[0].ambush.size() == 2 and bold.outcomes[0].ambush.all(func(t): return t.display_name == "Lamp-eater"))
	check("hooded: nerves fray for one flask; a third of the time one lamp-eater", creep.outcomes.size() == 2 and creep.outcomes.all(func(o): return o.loot.get(OIL, 0) == 1 and o.strain > 0.0) and creep.outcomes[1].ambush.size() == 1 and creep.outcomes[0].weight == 2 and creep.outcomes[1].weight == 1)

	# In the game: a floor 2 with the territory.
	var site := 0
	for s in range(1, 800):
		if not Packages.territories(2, s + 2 * 7919 + 31).is_empty():
			site = s
			break
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = site
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	var map = main._map
	check("the lamp store is on the floor", "territory_lamp_eaters" in map.packages, str(map.packages))
	var cell := Vector2i(-1, -1)
	for c in map.events:
		if map.events[c] == event:
			cell = c
	check("...with its event in place", cell != Vector2i(-1, -1))
	main._run_event(cell)
	await process_frame
	check("arriving shows the dead lamps", main._event_screen.visible)
	if dir != "":
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png("%s/territory_%s.png" % [dir, tag])
	_press(main._event_screen, "Leave it")
	await process_frame
	await process_frame
	check("leaving costs nothing; it waits for a return", not main._event_screen.visible and not map.triggered.has(cell) and not main._in_combat)
	var flasks: int = main._party_state.supplies.count(OIL)
	main._run_event(cell)
	await process_frame
	_press(main._event_screen, "Go in")
	await create_timer(0.3).timeout
	for i in 3:
		_press(main._event_screen, "Continue")
		_press(main._event_screen, "OK")
		await create_timer(0.2).timeout
	check("going in: the flasks, then the lamp-eaters", main._party_state.supplies.count(OIL) >= flasks + 1 and main._in_combat, "%d -> %d, fight %s" % [flasks, main._party_state.supplies.count(OIL), main._in_combat])
	print("fails=", fails)
	quit()
