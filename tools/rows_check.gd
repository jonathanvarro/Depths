extends SceneTree
## Front and back rows (#72): who can reach whom, moving, and a live fight
## with three heroes. Args: tag ("desk" or "phone"), screenshot dir.

var fails := 0
var CS
var PS


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _hero(name: String, row: String, reach := false) -> Companion:
	var hero := Companion.new()
	hero.display_name = name
	hero.row = row
	hero.reach = reach
	hero.accuracy = 1.0
	return hero


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	CS = load("res://scripts/combat_state.gd")
	PS = load("res://scripts/party_state.gd")
	var rat: EnemyType = load("res://data/enemies/rat.tres")
	var spider: EnemyType = load("res://data/enemies/spider.tres")
	var p = PS.new()
	p.add_member(_hero("Front", "front"))
	p.add_member(_hero("Warden", "front"))
	p.add_member(_hero("Scout", "back", true))
	var front: Companion = p.members[0]
	var warden: Companion = p.members[1]
	var scout: Companion = p.members[2]
	var c = CS.new(p, [rat, spider] as Array[EnemyType])
	var r = c.foes[0]
	var s = c.foes[1]
	check("spiders hang back, rats stand in front", not r.in_back() and s.in_back())
	check("melee can't reach the back row past the rat", c.can_hit(front, r) and not c.can_hit(front, s))
	check("a sling reaches the spider from the back", c.can_hit(scout, s) and c.can_hit(scout, r))
	var at_scout := 0
	for i in 200:
		r.intent = CS.Intent.LUNGE
		var out: Dictionary = c.enemy_act(r)
		if out.get("target") == scout: at_scout += 1
		for h in p.members: h.health = h.max_health
	check("the rat never reaches the back row", at_scout == 0)
	var spider_back := 0
	for i in 300:
		s.intent = CS.Intent.BITE
		if c.enemy_act(s).get("target") == scout: spider_back += 1
		for h in p.members: h.health = h.max_health
	check("the spider drops on anyone, back row included", spider_back > 50, "%d/300" % spider_back)
	r.health = 0
	check("with the rat down, melee reaches the spider", c.can_hit(front, s))
	r.health = r.type.max_health
	check("moving takes a hero to the back", c.hero_move(warden).contains("back") and warden.row == "back")
	check("from the back without reach, a hero can't attack", c.targets_for(warden).is_empty())
	c.hero_move(warden)
	front.row = "back"; warden.row = "back"
	check("a row standing alone counts as the front", c.hero_in_front(front) and c.can_hit(front, r))
	front.row = "front"; warden.row = "front"
	var lone = PS.new()
	lone.add_member(_hero("Mara", "back"))
	var c2 = CS.new(lone, [spider] as Array[EnemyType])
	check("a lone hero and a lone spider still fight", c2.can_hit(lone.members[0], c2.foes[0]))

	# A live fight with three heroes against a rat and a spider.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	var camp = main._camp_state
	for recruit in camp.candidates.duplicate():
		camp.hire(main._party_state, recruit)
	var ps = main._party_state
	main._refresh_cards()
	var types: Array[EnemyType] = [rat, spider]
	main._start_combat(main._party.cell, types)
	var guard := 0
	while not main._combat._actions.visible and guard < 100:
		await create_timer(0.1).timeout
		guard += 1
	await create_timer(0.3).timeout
	check("a Move button with company", main._combat._action_buttons.get_children().any(func(b): return b.text == "Move" and b.visible))
	check("cards show rows", main._cards.any(func(card): return card._row_label.text in ["front", "back"]))
	if dir != "":
		for i in 4:
			await process_frame
		root.get_texture().get_image().save_png(dir + "/rows_" + tag + "_fight.png")
	print("fails=", fails)
	quit()
