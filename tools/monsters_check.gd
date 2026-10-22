extends SceneTree
## New monsters (#140, owner 2026-10-21): the cave bat swoops and lands, the
## goblin brute winds up and is wide open after, the gas-bloat bursts (less
## from the back row, a flash with fire, and it swells when hurt), and the
## hollow miner grabs and holds until it's hit. Args: tag, screenshot dir.

const CS := preload("res://scripts/combat_state.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _e(id: String) -> EnemyType:
	return load("res://data/enemies/%s.tres" % id)


func _party(ids := ["mara", "corin"]):
	var party = load("res://scripts/party_state.gd").new()
	for id in ids:
		party.add_member(load("res://data/companions/%s.tres" % id))
	for hero in party.members:
		hero.health = hero.max_health
		hero.strain = 0.0
	return party


func _fight(party, ids: Array):
	var types: Array[EnemyType] = []
	for id in ids:
		types.append(_e(id))
	return CS.new(party, types)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	# Cave bat.
	var party = _party()
	var mara: Companion = party.members[0]
	var corin: Companion = party.members[1]
	corin.row = "back"
	var fight = _fight(party, ["cave_bat", "rat"])
	var bat = fight.foes[0]
	check("a bat starts in the air", bat.in_back() and bat.intent == CS.Intent.SWOOP)
	check("...out of reach of a sword while the rat stands in front", not fight.can_hit(mara, bat))
	check("its swoop can reach the back row", fight.foe_can_reach(bat, corin))
	fight.enemy_act(bat)
	check("after swooping it lands, within reach, and will bite", not bat.in_back() and fight.can_hit(mara, bat) and bat.intent == CS.Intent.BITE)
	check("...but its bite reaches only the front", not fight.foe_can_reach(bat, corin))
	fight.enemy_act(bat)
	check("after biting it rises again", bat.in_back() and bat.intent == CS.Intent.SWOOP)

	# Goblin brute.
	party = _party()
	mara = party.members[0]
	fight = _fight(party, ["goblin_brute"])
	var brute = fight.foes[0]
	var cycle := []
	for i in 4:
		cycle.append(brute.intent)
		fight.rng.seed = 5
		fight.enemy_act(brute)
	check("a brute swings, winds up, recovers, swings", cycle == [CS.Intent.SWING, CS.Intent.HEAVY, CS.Intent.RECOVER, CS.Intent.SWING], str(cycle))
	brute.intent = CS.Intent.HEAVY
	fight.hero_defend(mara)
	var before: int = mara.health
	fight.rng.seed = 1
	var heavy: Dictionary = fight.enemy_act(brute)
	check("bracing turns its heavy blow aside", mara.health == before, heavy.get("text", ""))
	mara.accuracy = 5.0
	brute.health = 18
	brute.intent = CS.Intent.SWING
	fight.rng.seed = 9
	var normal: int = fight.hero_attack(mara, brute)["damage"]
	brute.health = 18
	brute.intent = CS.Intent.RECOVER
	fight.rng.seed = 9
	check("while it catches its breath, blows land 2 harder", fight.hero_attack(mara, brute)["damage"] == normal + 2)

	# Gas-bloat.
	party = _party(["mara", "corin"])
	mara = party.members[0]
	corin = party.members[1]
	corin.row = "back"
	fight = _fight(party, ["gas_bloat", "goblin"])
	var bloat = fight.foes[0]
	mara.accuracy = 5.0
	bloat.health = 1
	var front_before: int = mara.health
	var back_before: int = corin.health
	fight.hero_attack(mara, bloat)
	check("killed up close, it bursts: front 2, back 1, nerves fray", mara.health == front_before - 2 and corin.health == back_before - 1 and mara.strain >= 5.0, "%d %d %.1f" % [front_before - mara.health, back_before - corin.health, mara.strain])
	party = _party(["mara", "corin"])
	mara = party.members[0]
	corin = party.members[1]
	corin.row = "back"
	corin.weapon = load("res://data/gear/simple_spear.tres")  # reach, from the back row
	corin.accuracy = 5.0
	fight = _fight(party, ["gas_bloat"])
	bloat = fight.foes[0]
	bloat.health = 1
	front_before = mara.health
	fight.hero_attack(corin, bloat)
	check("killed from the back row, the gas mostly rolls past", mara.health == front_before - 1 and corin.health == corin.max_health)
	party = _party(["mara"])
	mara = party.members[0]
	party.supplies.add(load("res://data/items/torch.tres"))
	party.supplies.light_torch(load("res://data/items/torch.tres"))
	fight = _fight(party, ["gas_bloat", "goblin"])
	var goblin = fight.foes[1]
	var out: Dictionary = fight.hero_throw_torch(mara, fight.foes[0])
	check("a thrown torch sets it off: the goblin is scorched for 3, the party for 1, no gas", out["killed"] and goblin.health == goblin.type.max_health - 3 and mara.health == mara.max_health - 1 and mara.strain < 3.0, out["text"])  # only the scorch's own strain
	party = _party(["mara"])
	fight = _fight(party, ["gas_bloat"])
	bloat = fight.foes[0]
	bloat.health = 2
	fight.plan(bloat)
	check("hurt, it swells", bloat.intent == CS.Intent.SWELL)
	fight.enemy_act(bloat)
	check("...and if left, tears open on its own", not bloat.is_alive() and party.members[0].health < party.members[0].max_health)

	# Hollow miner.
	party = _party(["mara", "corin"])
	mara = party.members[0]
	corin = party.members[1]
	fight = _fight(party, ["hollow_miner"])
	var miner = fight.foes[0]
	check("a hollow miner reaches to grab", miner.intent == CS.Intent.GRAB)
	fight.hero_defend(mara)
	fight.hero_defend(corin)
	fight.rng.seed = 2
	fight.enemy_act(miner)
	check("a braced hero twists free", not fight.is_grabbed(mara) and not fight.is_grabbed(corin))
	fight._defending.clear()
	miner.intent = CS.Intent.GRAB
	var miner_type: EnemyType = miner.type.duplicate()
	miner_type.accuracy = 1.0
	miner.type = miner_type
	fight.enemy_act(miner)
	var held: Companion = mara if fight.is_grabbed(mara) else corin
	check("an exposed hero is seized", fight.is_grabbed(held))
	check("...and it swings next, at whoever it holds", miner.intent == CS.Intent.SWING and fight._choose_target(miner) == held)
	# The held hero's turn passes them by.
	fight._order = [held, miner]
	fight._turn = -1
	fight.advance()
	check("a held hero's turn is spent struggling", fight.current_actor() == miner and fight.events.size() > 0 and fight.events[-1].contains("struggles"), str(fight.events))
	var free: Companion = corin if held == mara else mara
	free.accuracy = 5.0
	fight.hero_attack(free, miner)
	check("hitting the miner breaks the hold", not fight.is_grabbed(held))
	check("it may leave a pick", _e("hollow_miner").drop == load("res://data/items/pick.tres") and _e("hollow_miner").drop_chance > 0.0)

	# The rest of the catalogue (#140).
	party = _party(["mara", "corin"])
	mara = party.members[0]
	fight = _fight(party, ["rock_beetle", "rat"])
	var beetle = fight.foes[0]
	fight.enemy_act(beetle)
	check("a beetle bites, then curls up", beetle.intent == CS.Intent.CURL)
	fight.enemy_act(beetle)
	mara.accuracy = 5.0
	check("curled, a blow barely scratches it", beetle.curled and fight.hero_attack(mara, beetle)["damage"] <= 1)
	party = _party(["mara"])
	fight = _fight(party, ["venom_spider"])
	var vs = fight.foes[0]
	vs.has_webbed = true
	vs.intent = CS.Intent.BITE
	var vt: EnemyType = vs.type.duplicate()
	vt.accuracy = 1.0
	vs.type = vt
	party.members[0].health = 99
	party.members[0].max_health = 99
	fight.enemy_act(vs)
	var hp: int = party.members[0].health
	fight._tick_venom(party.members[0])
	check("a venom spider's poison burns 2 a turn", hp - party.members[0].health == 2)
	party = _party(["mara", "corin"])
	fight = _fight(party, ["goblin_trapper"])
	var trapper = fight.foes[0]
	check("a trapper lays a snare first", trapper.intent == CS.Intent.SNARE)
	fight.enemy_act(trapper)
	var snared: Companion = party.members[0] if fight.is_snared(party.members[0]) else party.members[1]
	fight._build_order()
	check("the snared hero acts last next round", fight._order[-1] == snared or fight._order.filter(func(a): return a is Companion)[-1] == snared)
	party = _party(["mara"])
	party.supplies.has_lantern = true
	party.supplies.source = party.supplies.Source.LANTERN
	party.supplies.oil = 60.0
	fight = _fight(party, ["lamp_eater"])
	var lamp = fight.foes[0]
	check("a lamp-eater is drawn to the light", lamp.intent == CS.Intent.DRAIN)
	var drink: Dictionary = fight.enemy_act(lamp)
	check("...and drinks the lantern's oil", party.supplies.oil < 60.0 and drink.get("drained", false), party.supplies.oil)
	party.supplies.oil = 0.0
	party.supplies.source = party.supplies.Source.NONE
	fight.plan(lamp)
	check("in the dark, it bites instead", lamp.intent == CS.Intent.BITE)
	party = _party(["mara", "corin"])
	party.members[0].health = 3
	fight = _fight(party, ["breach_hound", "breach_hound"])
	check("hounds go for the weakest", fight._choose_target(fight.foes[0]) == party.members[0])
	party = _party(["mara"])
	fight = _fight(party, ["broodmother"])
	var mother = fight.foes[0]
	check("the Broodmother calls her brood", mother.intent == CS.Intent.BROOD)
	fight.enemy_act(mother)
	check("...two hatchlings join", fight.foes.size() == 3 and fight.foes[1].type.display_name == "Small spider")
	check("...only once", mother.intent == CS.Intent.BITE)
	mother.health = 5
	fight.plan(mother)
	check("below half health she rages", mother.enraged)
	party = _party(["mara"])
	fight = _fight(party, ["gate_captain", "goblin"])
	var captain = fight.foes[0]
	check("a gate captain rallies first", captain.intent == CS.Intent.RALLY)
	fight.enemy_act(captain)
	check("...bracing its ally", fight.foes[1].shielded and captain.intent == CS.Intent.HEAVY)

	# Where they turn up.
	var main_script = load("res://scripts/main.gd")
	var groups: Dictionary = main_script.ENCOUNTER_GROUPS
	var on := func(floor: int, id: String) -> bool:
		return groups[floor].any(func(g): return g.any(func(t): return t == _e(id)))
	check("bats on floors 1-2, not 3-4", on.call(1, "cave_bat") and on.call(2, "cave_bat") and not on.call(3, "cave_bat"))
	check("the brute on floors 3-4", on.call(3, "goblin_brute") and on.call(4, "goblin_brute") and not on.call(2, "goblin_brute"))
	check("breach creatures on floor 3, not in the fortress", on.call(3, "gas_bloat") and on.call(3, "hollow_miner") and not on.call(4, "hollow_miner"))
	check("beetles and trappers from floor 2; hounds and lamp-eaters on 3", on.call(2, "rock_beetle") and on.call(2, "goblin_trapper") and on.call(3, "breach_hound") and on.call(3, "lamp_eater") and not on.call(2, "breach_hound"))
	check("the Broodmother on floors 2-3; the gate captain on 3-4", on.call(2, "broodmother") and on.call(3, "broodmother") and on.call(4, "gate_captain") and not on.call(4, "broodmother"))

	# In the game: a fight with all four, on their placeholders.
	var main = main_script.new() if false else load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(3, main.Arrival.FROM_ABOVE)
	await process_frame
	var types: Array[EnemyType] = [_e("goblin_brute"), _e("hollow_miner"), _e("gas_bloat"), _e("cave_bat")]
	main._start_combat(main._party.cell, types)
	var g := 0
	while not main._combat._actions.visible and g < 60:
		await create_timer(0.1).timeout
		g += 1
	check("a fight with all four starts, each on its placeholder", main._combat._state.foes.size() == 4 and main._combat._state.foes.all(func(f): return f.node != null))
	if dir != "":
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png(dir + "/monsters_" + tag + "_fight.png")
	print("fails=", fails)
	quit()
