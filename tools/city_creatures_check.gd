extends SceneTree
## The Buried City's own creatures (owner asked, 2026-11-27), from the
## approved descent concepts (#151/#152), on stand-in models until theirs are
## made: the Choir of One keens (everyone's nerves) and cuts from the back
## row in turn; the Unfolding curls against blows, then reaches the back row;
## the Hollow Interval drinks the light. The Marrow Shepherd tends its young
## in the city's streets. Args: tag, screenshot dir.

const CombatState := preload("res://scripts/combat_state.gd")
const Recruits := preload("res://scripts/recruits.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _party() -> Variant:
	var party = load("res://scripts/party_state.gd").new()
	for id in ["mara", "corin", "alwen"]:
		party.add_member(load("res://data/companions/%s.tres" % id).duplicate())
	party.members[2].row = "back"
	return party


func _fight(enemy: String):
	var types: Array[EnemyType] = [load("res://data/enemies/%s.tres" % enemy)]
	var state = CombatState.new(_party(), types)
	state.rng.seed = 11
	return state


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[1] if args.size() > 1 else ""
	var I := CombatState.Intent

	# Choir of One.
	var state = _fight("choir_of_one")
	var choir = state.foes[0]
	check("the Choir of One opens by keening", choir.intent == I.KEEN, CombatState.INTENT_TEXT.get(choir.intent))
	var before: Array = state.party.living_members().map(func(h): return h.strain)
	var out: Dictionary = state.enemy_act(choir)
	var after: Array = state.party.living_members().map(func(h): return h.strain)
	check("...and every hero's nerves fray", range(before.size()).all(func(i): return after[i] > before[i]), [before, after])
	check("...then it cuts, in turn", choir.intent == I.ATTACK)
	var back: Array = state.party.living_members().filter(func(h): return not state.hero_in_front(h))
	check("...reaching even the back row", not back.is_empty() and state.foe_can_reach(choir, back[0]))
	state.enemy_act(choir)
	check("...and keens again", choir.intent == I.KEEN)

	# Unfolding.
	state = _fight("unfolding")
	var unfolding = state.foes[0]
	check("the Unfolding reaches the back row when open", state.foe_can_reach(unfolding, state.party.members[2]))
	state.enemy_act(unfolding)
	state.enemy_act(unfolding)
	check("...and curls against blows", unfolding.curled)

	# Hollow Interval.
	state = _fight("hollow_interval")
	var hollow = state.foes[0]
	check("the Hollow Interval goes for the light", hollow.intent == I.DRAIN)
	var oil: float = state.party.supplies.oil
	state.enemy_act(hollow)
	check("...and drinks it", state.party.supplies.oil < oil, [oil, state.party.supplies.oil])

	# The city's fights.
	var Main = load("res://scripts/main.gd")
	var pool: Array = Main.encounter_pool("city", 3)
	var names := {}
	for g in pool:
		for t in g:
			names[t.display_name] = true
	check("the Buried City's fights are its own", names.has("Choir of One") and names.has("Unfolding") and names.has("Hollow Interval") and names.has("Marrow Shepherd"), names.keys())
	check("...with no goblins or cave beasts", not names.keys().any(func(n): return n.to_lower().contains("goblin") or n.to_lower().contains("rat") or n.to_lower().contains("spider")))

	# A real fight in the city's streets.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 72
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_area("city", main.Arrival.FROM_ABOVE)
	var foes: Array[EnemyType] = [main.CHOIR, main.UNFOLDING, main.HOLLOW]
	main._start_combat(main._party.cell, foes)
	await create_timer(1.0).timeout
	check("a city fight starts with them", main._in_combat and main._combat._state.foes.size() == 3)
	if dir != "":
		for i in 6:
			await process_frame
		var image := root.get_texture().get_image()
		if image:
			image.save_png(dir + "/city_fight.png")
	print("fails=", fails)
	quit()
