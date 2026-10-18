extends SceneTree
## Stats, levels and XP (#47), armour (#93) and the first new monsters.
## Args: tag, screenshot dir.

const Progression := preload("res://scripts/progression.gd")
const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0
var main


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _press(node, label: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if b.text.begins_with(label) and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var PS = load("res://scripts/party_state.gd")
	var CS = load("res://scripts/combat_state.gd")
	var Recruits = load("res://scripts/recruits.gd")

	# --- Derived stats keep today's numbers; Strength and Resolve matter.
	var ps = PS.new()
	ps.add_member(load("res://data/companions/corin.tres"))
	ps.add_member(load("res://data/companions/mara.tres"))
	ps.add_member(load("res://data/companions/alwen.tres"))
	var corin: Companion = ps.members[0]
	var mara: Companion = ps.members[1]
	var alwen: Companion = ps.members[2]
	check("heroes keep their numbers", corin.max_health == 26 and mara.max_health == 20 and alwen.max_health == 18 and is_equal_approx(mara.accuracy, 0.8) and mara.initiative == 12)
	var sword: Equipment = load("res://data/gear/iron_sword.tres")
	corin.weapon = sword
	mara.weapon = sword
	check("Strength: the same sword hits harder for Corin", corin.attack_range() == Vector2i(4, 6) and mara.attack_range() == Vector2i(2, 4), "%s %s" % [corin.attack_range(), mara.attack_range()])
	mara.weapon = load("res://data/gear/plain_knife.tres")
	check("a light knife ignores a weak arm", mara.attack_range() == Vector2i(1, 3))
	alwen.strain = 0.0
	alwen.change_strain(10.0)
	check("Resolve: Alwen's nerves hold better", is_equal_approx(alwen.strain, 8.4), "%.2f" % alwen.strain)
	alwen.change_strain(-5.0)
	check("...but relief isn't scaled", is_equal_approx(alwen.strain, 3.4))

	# --- Levels and talents.
	mara.xp = 80
	check("80 XP: ready for level 2", Progression.ready_to_advance(mara))
	var options: Array = Progression.choices(mara)
	check("level 2 offers two rogue talents", options.size() == 2 and options[0][0] == "deadeye")
	var hp_before := mara.max_health
	Progression.advance(mara, "deadeye")
	check("level 2: +2 health, Deadeye +5% to hit", mara.level == 2 and mara.max_health == hp_before + 2 and is_equal_approx(mara.accuracy, 0.85), "%d %.2f" % [mara.max_health, mara.accuracy])
	mara.xp = 220
	check("level 3 offers an attribute", Progression.choices(mara).any(func(c): return c[0] == "stat_vit"))
	Progression.advance(mara, "stat_vit")
	check("level 3: Vitality +1 is +4 health, plus +2 a level (28)", mara.level == 3 and mara.stat_vit == 3 and mara.max_health == 28, str(mara.max_health))

	# --- Armour.
	var coat: Equipment = load("res://data/gear/padded_coat.tres")
	var jerkin: Equipment = load("res://data/gear/leather_jerkin.tres")
	ps.supplies.gear.append(jerkin)
	ps.equip(corin, jerkin)
	check("a jerkin goes on the body", corin.body == jerkin and jerkin not in ps.supplies.gear)
	check("...and slows its wearer", corin.effective_initiative() == corin.initiative - 2)
	var goblin: EnemyType = load("res://data/enemies/goblin.tres")
	var acc := goblin.accuracy
	goblin.accuracy = 1.0
	var p2 = PS.new()
	var bare := Companion.new(); bare.max_health = 40; bare.health = 40
	p2.add_member(bare)
	p2.members[0].body = coat
	var c = CS.new(p2, [goblin] as Array[EnemyType])
	var worst := 0
	for i in 60:
		c.foes[0].intent = CS.Intent.SWING
		var out: Dictionary = c.enemy_act(c.foes[0])
		worst = maxi(worst, out["damage"])
		p2.members[0].health = 40
	check("a padded coat takes 1 off every blow (2-4 -> max 3)", worst == 3, str(worst))
	goblin.accuracy = acc

	# --- The new monsters.
	var p3 = PS.new()
	var target := Companion.new(); target.max_health = 60; target.health = 60
	p3.add_member(target)
	var rat: EnemyType = load("res://data/enemies/great_rat.tres")
	var spinner: EnemyType = load("res://data/enemies/webspinner.tres")
	var drummer: EnemyType = load("res://data/enemies/goblin_drummer.tres")
	var c3 = CS.new(p3, [rat, spinner, drummer, goblin] as Array[EnemyType])
	var r = c3.foes[0]
	check("great rat: rush, then catch its breath", r.intent == CS.Intent.RUSH)
	c3.enemy_act(r)
	check("...then recovers", r.intent == CS.Intent.RECOVER)
	var s = c3.foes[1]
	check("webspinners hang back", s.in_back())
	s.has_webbed = true
	s.intent = CS.Intent.BITE
	rat.accuracy = 1.0
	spinner.accuracy = 1.0
	c3.enemy_act(s)
	check("webspinner bites carry no venom", c3.venom_turns(p3.members[0]) == 0)
	var d = c3.foes[2]
	d.intent = CS.Intent.BEAT
	var beat: Dictionary = c3.enemy_act(d)
	check("the drummer's beat strengthens the others", beat["text"].contains("drum") and c3._drummed.has(c3.foes[3]))
	rat.accuracy = 0.7
	spinner.accuracy = 0.7

	# --- In game: XP from a fight, the floor's limit, levelling at camp,
	# recruits joining behind, and saving it all.
	main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var hero: Companion = main._party_state.members[0]
	var foe_types: Array[EnemyType] = [load("res://data/enemies/rat.tres"), load("res://data/enemies/spider.tres")]
	main._start_combat(main._party.cell, foe_types)
	var guard := 0
	while main._in_combat and guard < 200:
		guard += 1
		if main._combat._actions.visible:
			for foe in main._combat._state.foes:
				foe.health = 0
			main._combat._state._check_end()
			main._combat._action_chosen.emit({"kind": "defend"})
		await create_timer(0.1).timeout
	check("a won fight gives 4 XP per threat (rat 1 + spider 2 = 12)", hero.xp == 12 and main._camp_state.xp_left[1] == 48, "%d XP, %d left" % [hero.xp, main._camp_state.xp_left[1]])
	main._camp_state.xp_left[1] = 0
	main._start_combat(main._party.cell, foe_types)
	guard = 0
	while main._in_combat and guard < 200:
		guard += 1
		if main._combat._actions.visible:
			for foe in main._combat._state.foes:
				foe.health = 0
			main._combat._state._check_end()
			main._combat._action_chosen.emit({"kind": "defend"})
		await create_timer(0.1).timeout
	check("once a floor's lessons run out, fights give no XP", hero.xp == 12)
	hero.xp = 90
	main._end_expedition(main.Expedition.Ending.RETURNED)
	await process_frame
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout
	main._camp._buttons["rest"].pressed.emit()
	await process_frame
	var tent := " | ".join(main._camp._body.find_children("*", "Label", true, false).map(func(l): return l.text))
	check("the tent shows training and a level-up choice", tent.contains("Training") and tent.contains("ready for level 2"))
	if dir != "":
		for i in 4: await process_frame
		root.get_texture().get_image().save_png(dir + "/progression_" + tag + "_training.png")
	check("choose Deadeye at camp", _press(main._camp, "Deadeye") and hero.level == 2 and main._camp_state.best_level == 2)
	main._camp_state.best_level = 3
	main._camp_state.candidates.clear()
	main._camp_state._fill_fire(main._party_state)
	check("recruits now join a level behind (level 2)", main._camp_state.candidates.all(func(c): return c.level == 2 and c.xp >= 80 and c.talents.size() == 1))
	main._camp_state.hire(main._party_state, main._camp_state.candidates[0])
	var smith_coat: Equipment = load("res://data/gear/padded_coat.tres")
	main._party_state.supplies.gear.append(smith_coat)
	main._party_state.equip(hero, smith_coat)
	main._save_now()
	main.queue_free()
	await process_frame
	SaveGame.set_continue_requested(true)
	main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var back: Companion = main._party_state.members[0]
	check("level, XP, talents and armour survive a save", back.level == 2 and back.talents == ["deadeye"] and back.body != null and back.body.armour == 1 and main._camp_state.best_level == 3, "L%d %s" % [back.level, back.talents])
	SaveGame.delete()
	print("fails=", fails)
	quit()
