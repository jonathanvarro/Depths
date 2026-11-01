extends SceneTree
## The expedition loop (owner decisions 2026-10-30/31): levels reset each
## expedition and are chosen underground (#172); a wipe loses worn gear and
## the camp hands out a plain kit (#174); unknown brews (#175); the monster
## journal (#176); a foe that downs a hero turns Savage (#177).
## Args: tag, screenshot dir.

const Progression := preload("res://scripts/progression.gd")
const CombatState := preload("res://scripts/combat_state.gd")
const Brews := preload("res://scripts/brews.gd")
const Bestiary := preload("res://scripts/bestiary.gd")
const GearModel := preload("res://scripts/gear_model.gd")
const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _party(ids := ["mara"]):
	var party = load("res://scripts/party_state.gd").new()
	for id in ids:
		party.add_member(load("res://data/companions/%s.tres" % id))
	return party


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[1] if args.size() > 1 else ""

	# #172: quick levels, undone by a fresh expedition.
	var party = _party(["corin"])
	var corin: Companion = party.members[0]
	var vit := corin.stat_vit
	corin.xp = Progression.THRESHOLDS[3]
	Progression.advance(corin, Progression.choices(corin)[0][0])
	Progression.advance(corin, "stat_vit")
	check("quick early levels: level 3 at %d XP" % Progression.THRESHOLDS[3], corin.level == 3 and corin.stat_vit == vit + 1 and corin.talents.size() == 1)
	Progression.reset(corin)
	check("a fresh expedition: level 1, no talents, the attribute point undone", corin.level == 1 and corin.xp == 0 and corin.talents.is_empty() and corin.stat_vit == vit and corin.raised.is_empty())
	corin.xp = Progression.THRESHOLDS[2]
	Progression.advance(corin, "bulwark")
	Progression.reset(corin)
	check("...Bulwark's guard comes back off", corin.guard_factor > 0.15, corin.guard_factor)

	# #177: a killer turns Savage, keeping its wounds.
	party = _party(["mara"])
	var mara: Companion = party.members[0]
	var state = CombatState.new(party, [load("res://data/enemies/rat.tres")] as Array[EnemyType])
	state.prepare(1)
	var rat = state.foes[0]
	rat.type = rat.type.duplicate()
	rat.type.accuracy = 1.0
	rat.intent = CombatState.Intent.ATTACK
	rat.health = 2
	mara.min_health = 0
	mara.health = 1
	var out: Dictionary = state.enemy_act(rat)
	check("a rat that downs a hero becomes a Savage rat", not mara.is_alive() and rat.elite == "Savage" and rat.name.begins_with("Savage") and out.get("evolved", false), out.get("text", ""))
	check("...keeping its wounds", rat.health == 2)

	# #176: the journal fills in from the fight.
	var camp = load("res://scripts/camp_state.gd").new()
	Bestiary.record(camp, state, 1)
	var page := Bestiary.page(camp, "Rat")
	check("the journal notes the rat, the move it made, and ? for the rest", camp.bestiary.has("Rat") and page.size() > 2 and "Moves seen: attacking, ?" in page, page)
	check("...weaknesses wait for a kill", page[-1].begins_with("Weaknesses: ?"))
	rat.health = 0
	Bestiary.record(camp, state, 1)
	page = Bestiary.page(camp, "Rat")
	check("...killed: what it's weak to", Array(page).any(func(l): return l.begins_with("Weak to:")) and camp.bestiary["Rat"]["met"] == 2, page)

	# #175: brews.
	party = _party(["mara"])
	mara = party.members[0]
	var supplies = party.supplies
	Brews.shuffle(supplies, 11)
	var looks: Dictionary = supplies.brew_looks.duplicate(true)
	var shapes := {}
	for kind in looks:
		shapes[looks[kind][0]] = true
	check("each kind has its own look (shape, colour and mark)", looks.size() == 5 and shapes.size() == 5)
	var heal := Brews.item("restorative")
	check("unknown: named by its look", not heal.display_name.contains("Restorative") and heal.icon != null, heal.display_name)
	supplies.add(heal, 2)
	mara.health = mara.max_health
	var said: String = party.use_item(heal, false, mara)
	check("drunk unhurt: nothing to show, nothing named", not Brews.known(supplies, "restorative") and supplies.count(heal) == 1, said)
	mara.health = 3
	said = party.use_item(heal, false, mara)
	check("drunk hurt: it heals, and the kind is named", Brews.known(supplies, "restorative") and heal.display_name == "Restorative brew", said)
	check("not drunk in a fight: thrown", party.cannot_use_reason(Brews.item("caustic"), true) != "")
	state = CombatState.new(party, [load("res://data/enemies/goblin_guard.tres")] as Array[EnemyType])
	state.prepare(3)
	var guard = state.foes[0]
	guard.health = 20
	supplies.add(Brews.item("caustic"), 1)
	out = state.hero_throw_brew(mara, guard, Brews.item("caustic"))
	check("a thrown caustic brew: 6 through the guard's armour, and named", guard.health == 14 and Brews.known(supplies, "caustic"), out["text"])
	supplies.add(Brews.item("slumber"), 1)
	state.hero_throw_brew(mara, guard, Brews.item("slumber"))
	guard.intent = CombatState.Intent.ATTACK
	out = state.enemy_act(guard)
	check("slumber: the foe loses its next turn", out["target"] == null, out["text"])
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	Brews.shuffle(ps.supplies, 5)
	Brews.identify(ps.supplies, "frenzy")
	var saved_looks: Dictionary = ps.supplies.brew_looks.duplicate(true)
	main._save_now()
	ps.supplies.brew_looks = {}
	ps.supplies.brews_known = []
	main._restore(SaveGame.read())
	await create_timer(0.3).timeout
	ps = main._party_state
	check("the looks and what's named survive a save", ps.supplies.brew_looks == saved_looks and Brews.known(ps.supplies, "frenzy"))
	var found := false
	var rooms = load("res://scripts/room_events.gd").new()
	for i in 200:
		if Brews.is_brew(rooms.random_treasure(1)):
			found = true
			break
	check("brews turn up among treasure finds", found)

	# #172 in the game: a level-up is chosen there and then.
	var hero: Companion = ps.members[0]
	hero.xp = Progression.THRESHOLDS[2]
	main._offer_level_ups()
	check("ready underground: the choice is offered at once", main._prompt.visible and main._prompt_label.text.contains("level 2"), main._prompt_label.text)
	if dir != "":
		await create_timer(0.3).timeout
		root.get_viewport().get_texture().get_image().save_png(dir.path_join("level_up.png"))
	main._answer_prompt(true)
	check("...and taken", hero.level == 2)

	# #174: a wipe loses worn gear; a plain spare kit.
	hero.weapon = GearModel.generate(RandomNumberGenerator.new(), "iron_sword", "fine", 1)
	GearModel.award(hero.weapon, 60.0)
	hero.health = 0
	main._main_heroes_wake_at_camp()
	check("after a wipe: a plain weapon and coat, no mastery, nothing on the back", hero.weapon.quality == "ordinary" and hero.weapon.mods.is_empty() and hero.weapon.mastery == 0.0 \
			and hero.body != null and hero.body.base_id == "quilted_coat" and hero.back == null and hero.trinket == null, "%s / %s" % [hero.weapon.display_name, hero.body.display_name if hero.body else "-"])

	# #176: the journal in the quest log.
	main._camp_state.bestiary = camp.bestiary
	var log = main._quest_log if "_quest_log" in main else null
	if log:
		log.open(main._camp_state)
		log._mode.pressed.emit()
		await create_timer(0.2).timeout
		check("the quest log opens the monster journal", log._monsters and log._buttons.has("Rat"))
		if dir != "":
			log.select_quest("Rat")
			await create_timer(0.3).timeout
			root.get_viewport().get_texture().get_image().save_png(dir.path_join("journal.png"))
	else:
		check("the quest log is reachable from main", false)
	print("fails=", fails)
	quit()
