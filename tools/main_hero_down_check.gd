extends SceneTree
## Owner playtest 2026-10-31: Corin fell in a fight with a bat, with two
## recruits still standing, and the expedition seemed to end at once. A main
## hero who falls is knocked out; the others fight on, and win or lose
## without him. A fight on the map (#171). Args: tag, screenshot dir.

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.wandering = false
	main.starting_hero = load("res://data/companions/corin.tres")
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var R = load("res://scripts/recruits.gd")
	ps.add_member(R.make(rng, [], [], 1, "Warden"))
	ps.add_member(R.make(rng, [], [], 1, "Scout"))
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	await process_frame
	for gr in main._groups.duplicate():
		main._groups.erase(gr)
	main._spawn_wanderer()
	var g = main._groups[-1]
	g.types.assign([load("res://data/enemies/cave_bat.tres")])
	for i in 20:
		if main._in_combat: break
		main._wait()
	check("a bat finds Corin and two recruits: a fight on the map", main._in_combat and main._combat._state.field)
	var fight = main._combat._state
	for i in 60:
		if main._combat.awaiting_field_action: break
		await create_timer(0.1).timeout
	ps.members[0].health = 1
	var corin = ps.members[0]
	for r in 12:
		if fight.result != 0: break
		main._combat._action_chosen.emit({"kind": "wait"})
		for i in 80:
			if main._combat.awaiting_field_action or fight.result != 0: break
			await create_timer(0.1).timeout
		if corin.health <= 0:
			break
	check("Corin falls mid-fight: knocked out, and the fight goes on", corin.health <= 0 and corin.is_unconscious() and fight.result == 0 and ps.living_members().size() == 2, "result %d" % fight.result)
	for r in 30:
		if fight.result != 0: break
		var near = fight.living_foes().filter(func(f): return fight.side_of(f) != "far")
		if not near.is_empty():
			fight.facing = near[0].cell - fight.party_cell
			main._combat._action_chosen.emit({"kind": "strike"})
		else:
			main._combat._action_chosen.emit({"kind": "wait"})
		for i in 80:
			if main._combat.awaiting_field_action or fight.result != 0: break
			await create_timer(0.1).timeout
	check("...the recruits finish it", fight.result == 1, ps.members.map(func(h): return "%s %d" % [h.display_name, h.health]))
	for i in 40:
		await create_timer(0.1).timeout
		if main._results.visible: break
	await create_timer(1.0).timeout
	check("...and the expedition carries on", not main._results.visible and not main._ending)
	print("fails=", fails)
	quit()
