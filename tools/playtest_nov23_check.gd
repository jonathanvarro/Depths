extends SceneTree
## Owner playtest, 2026-11-23: calming ends panic, less bolting, glows at
## both ways, the king's lost cache always holds a cache, and a trap only
## stepped round springs when walked onto again. Args: tag, screenshot dir.

const StrainRules := preload("res://scripts/strain.gd")
const Q := preload("res://scripts/quests.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	# Panic.
	var hero: Companion = load("res://data/companions/corin.tres").duplicate()
	hero.strain = 90.0
	hero.change_strain(-5.0)
	check("ordinary relief can leave a hero panicking", hero.strain_state() == StrainRules.State.PANICKING, hero.strain)
	hero.change_strain(-5.0, true)
	check("calming relief (a shrine, herbs, food, rest) ends panic", hero.strain_state() == StrainRules.State.SHAKEN, hero.strain)
	check("panic bolts less often: 8% a step", is_equal_approx(StrainRules.PANIC_BOLT_CHANCE, 0.08))

	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 77
	root.add_child(main)
	await create_timer(0.5).timeout
	Q.set_stage(main._camp_state, "left_behind", Q.Stage.RESOLVED)  # floor 1's way down open
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	await process_frame
	check("the way down glows", main._level.find_children("DescentGlow", "", true, false).size() == 1)
	check("...and so does the way up", main._level.find_children("AscentGlow", "", true, false).size() == 1)

	# The king's lost cache always has a cache to dig out.
	var found := false
	for s in 120:
		main._site_seed = 1000 + s
		main._floors.clear()
		main._go_to_floor(1 + s % 2, main.Arrival.FROM_ABOVE)
		if main._map.landmarks.any(func(l): return l["id"] == "lost_cache"):
			found = true
			var spot: Vector2i = main._map.marks.get("lost_cache", Vector2i(-1, -1))
			var landmark: Dictionary = main._map.landmarks.filter(func(l): return l["id"] == "lost_cache")[0]
			check("the king's lost cache holds a buried cache", spot in landmark["cells"] and main._map.events.get(spot) == main.LOST_CACHE_EVENT and main._props.has(spot), spot)
			var kept: Vector2i = spot
			main._build_level()
			check("...the same one when the level is rebuilt", main._map.marks.get("lost_cache") == kept and main._map.events.get(kept) == main.LOST_CACHE_EVENT)
			break
	check("a floor with the king's lost cache turns up", found)

	# A trap only stepped round stays set and springs on the next pass.
	var map = main._map
	var here: Vector2i = main._party.cell
	var trap_cell := Vector2i(-1, -1)
	for c in map.walking_distances(here):
		if c != here and map.content_at(c) == main.DungeonMap.Content.NONE and not map.solid.has(c) and map.door_at(c) == 0 and not map.encounter_zones.has(c):
			trap_cell = c
			break
	var tripwire: RoomEvent = load("res://data/events/trap_tripwire.tres")
	check("stepping over is marked as passing a trap by, cutting it isn't", tripwire.choices[0].bypass and not tripwire.choices[1].bypass)
	map.contents[trap_cell] = main.DungeonMap.Content.TRAP
	map.events[trap_cell] = tripwire
	map.triggered[trap_cell] = true  # already dealt with once
	map.marks["set_traps"] = {trap_cell: true}
	main._groups.clear()  # no monsters about to start a fight there
	var resolved: int = main._expedition.events_resolved
	main._party.place(map, trap_cell)
	main._on_party_entered_cell(trap_cell)
	for i in 40:  # the fall plays out first
		await create_timer(0.2).timeout
		if main._expedition.events_resolved > resolved:
			break
	check("walking onto it again springs it, once", main._expedition.events_resolved == resolved + 1 and not map.marks["set_traps"].has(trap_cell), [resolved, main._expedition.events_resolved, map.marks["set_traps"], main._in_combat])
	print("fails=", fails)
	quit()
