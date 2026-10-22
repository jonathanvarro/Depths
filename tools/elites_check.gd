extends SceneTree
## Elites and depth scaling (#140, owner 2026-10-21): deeper foes are
## tougher (floor 3 +10%, floor 4 +20%, the queen too); from floor 2 some
## foes are elites with one modifier and a hot nameplate, worth a little
## more and carrying most of the drop chance. Args: tag, screenshot dir.

const CS := preload("res://scripts/combat_state.gd")
const Trinkets := preload("res://scripts/trinkets.gd")
const GearGen := preload("res://scripts/gear_gen.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _e(id: String) -> EnemyType:
	return load("res://data/enemies/%s.tres" % id)


func _party():
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres"))
	return party


func _fight(ids: Array, depth: int, kind := ""):
	var types: Array[EnemyType] = []
	for id in ids:
		types.append(_e(id))
	var fight = CS.new(_party(), types)
	fight.rng.seed = 3
	fight.prepare(depth, kind)
	return fight


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	# Depth scaling.
	var shallow = _fight(["goblin"], 2)
	check("floors 1-2: foes as written", shallow.foes[0].type.max_health == 10 or shallow.foes[0].elite == "Hardened")
	var deep = _fight(["goblin", "goblin", "goblin"], 3, "gate")  # a set fight: no elites
	var g = deep.foes[0]
	check("floor 3: +10%, rounded (a goblin 11 health, 2-4 damage)", g.type.max_health == 11 and g.health == 11 and g.type.damage_min == 2 and g.type.damage_max == 4, "%d %d-%d" % [g.type.max_health, g.type.damage_min, g.type.damage_max])
	check("set fights have no elites", deep.foes.all(func(f): return f.elite == ""))
	var queen = _fight(["goblin_queen"], 4, "queen")
	check("floor 4: +20%, the queen too (32 -> 38 health, 3-6 -> 4-7 damage)", queen.foes[0].type.max_health == 38 and queen.foes[0].type.damage_min == 4 and queen.foes[0].type.damage_max == 7, queen.foes[0].type.max_health)
	check("...and the written queen isn't changed", _e("goblin_queen").max_health == 32)
	var q = queen.foes[0]
	queen._call_guard(q)
	check("a guard she calls is scaled too", queen.foes[-1].type.max_health == roundi(12 * 1.2))

	# Elites.
	var fight = _fight(["goblin"], 2)
	var foe = fight.foes[0]
	foe.elite = ""
	foe.type = _e("goblin")
	foe.name = "Goblin"
	fight.make_elite(foe, "Hardened")
	check("hardened: half again as much health, and named for it", foe.type.max_health == 15 and foe.health == 15 and foe.name == "Hardened goblin")
	check("...its kind keeps its own name (for contracts and the record)", foe.type.display_name == "Goblin")
	check("...worth a little more", foe.type.threat == _e("goblin").threat + 1)
	var savage = _fight(["goblin"], 2).foes[0]
	savage.type = _e("goblin")
	_fight(["goblin"], 2).make_elite(savage, "Savage")
	check("savage: hits 1 harder", savage.type.damage_min == 3 and savage.type.damage_max == 5)
	var swift_fight = _fight(["goblin"], 2)
	var swift = swift_fight.foes[0]
	swift.type = _e("goblin")
	swift_fight.make_elite(swift, "Swift")
	check("swift: acts sooner", swift.type.initiative == _e("goblin").initiative + 3)
	var venom_fight = _fight(["goblin_brute"], 3)
	var venomous = venom_fight.foes[0]
	venom_fight.make_elite(venomous, "Venomous")
	var brute_type: EnemyType = venomous.type.duplicate()
	brute_type.accuracy = 1.0
	venomous.type = brute_type
	venomous.intent = CS.Intent.SWING
	var hero: Companion = venom_fight.party.members[0]
	hero.health = 99
	hero.max_health = 99
	venom_fight.enemy_act(venomous)
	check("venomous: its hits poison", venom_fight.venom_turns(hero) > 0)
	var counts := {2: 0, 4: 0}
	for depth in [2, 4]:
		for i in 400:
			var f = CS.new(_party(), [_e("goblin"), _e("goblin")] as Array[EnemyType])
			f.prepare(depth)
			counts[depth] += f.foes.filter(func(x): return x.elite != "").size()
	check("elites: rarer on floor 2 (about 1 foe in 10) than floor 4 (1 in 5)", counts[2] > 40 and counts[2] < 120 and counts[4] > counts[2] * 1.4, str(counts))
	var none := 0
	for i in 200:
		var f = CS.new(_party(), [_e("rat"), _e("rat")] as Array[EnemyType])
		f.prepare(1)
		none += f.foes.filter(func(x): return x.elite != "").size()
	check("no elites on floor 1", none == 0)

	# Drops favour elites.
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	var elite_drops := 0
	var plain_drops := 0
	for i in 4000:
		if Trinkets.drop(rng, 3, 12, true) != null:
			elite_drops += 1
		if Trinkets.drop(rng, 3, 12, false) != null:
			plain_drops += 1
	check("elites leave trinkets about 6 times as often as ordinary tougher foes", elite_drops > plain_drops * 4, "%d vs %d" % [elite_drops, plain_drops])
	var small := 0
	for i in 2000:
		if GearGen.drop(rng, 3, "foe", 5, true) != null:
			small += 1
	check("even a small elite can drop gear: about 1 in 4 on floor 3", small > 300 and small < 700, small)

	# In the game: an elite's nameplate.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(3, main.Arrival.FROM_ABOVE)
	await process_frame
	main._start_combat(main._party.cell, [_e("goblin"), _e("hollow_miner")] as Array[EnemyType])
	var state = main._combat._state
	if state.foes.all(func(f): return f.elite == ""):
		state.make_elite(state.foes[0], "Savage")
		main._combat._tags[state.foes[0]].queue_free()
		main._combat._tags.erase(state.foes[0])
		main._combat._add_tag(state.foes[0])
	var w := 0
	while not main._combat._actions.visible and w < 60:
		await create_timer(0.1).timeout
		w += 1
	var elite = state.foes.filter(func(f): return f.elite != "")[0]
	var plate: StyleBox = main._combat._tags[elite].get_theme_stylebox("normal")
	check("an elite has a hot nameplate", plate is StyleBoxFlat and plate.border_color == main._combat.ELITE_COLOUR)
	if dir != "":
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png(dir + "/elites_" + tag + "_fight.png")
	print("fails=", fails)
	quit()
