extends SceneTree
## The coin flip (#77): a rigged strongbox and a goblin's killing blow are
## decided by the coin; defending and luck bend the odds.
## Args: tag, screenshot dir.

var fails := 0


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
	var CS = load("res://scripts/combat_state.gd")
	var PS = load("res://scripts/party_state.gd")
	var goblin: EnemyType = load("res://data/enemies/goblin.tres")

	# Rules: odds, defending, luck, and both sides of the coin.
	var p = PS.new()
	var hero := Companion.new(); hero.display_name = "Bryn"; hero.max_health = 30; hero.health = 30
	p.add_member(hero)
	var c = CS.new(p, [goblin] as Array[EnemyType])
	var g = c.foes[0]
	var target: Companion = p.members[0]
	check("plain odds are 50%", is_equal_approx(c.killing_blow_odds(target), 0.5))
	c.hero_defend(target)
	check("defending adds 20%", is_equal_approx(c.killing_blow_odds(target), 0.7))
	target.luck = 0.3
	check("luck adds, capped at 85%", is_equal_approx(c.killing_blow_odds(target), 0.85))
	target.luck = 0.0
	c._defending.clear()
	g.intent = CS.Intent.KILLING_BLOW
	c.prepare_killing_blow(g)
	c.coin = 1
	var out: Dictionary = c.enemy_act(g)
	check("heads: the blow misses", not out["hit"] and target.health == 30, out["text"])
	g.intent = CS.Intent.KILLING_BLOW
	c.prepare_killing_blow(g)
	c.coin = 0
	out = c.enemy_act(g)
	check("tails: double damage and an injury", out["hit"] and out["damage"] == goblin.damage_max * 2 and out["injury"] != null, out["text"])
	var killing := 0
	for i in 2000:
		g.intent = CS.Intent.SWING
		c.plan(g)
		if g.intent == CS.Intent.KILLING_BLOW: killing += 1
	check("killing blows are rare (~10% of goblin plans)", killing > 100 and killing < 320, "%d/2000" % killing)
	var lucky := 0
	var Recruits = load("res://scripts/recruits.gd")
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	for i in 300:
		if Recruits.make(rng).luck > 0.0: lucky += 1
	check("some recruits are Lucky", lucky > 20, "%d/300" % lucky)

	# In game: the strongbox, flipped by the player.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	var box: RoomEvent = load("res://data/events/chest_strongbox.tres")
	var cell: Vector2i = main._party.cell
	main._map.events[cell] = box
	main._run_event(cell)
	await process_frame
	var gold_before: int = main._party_state.supplies.gold
	var health_before: int = main._party_state.members[0].health
	_press(main._event_screen, "Force the lid")
	await create_timer(0.2).timeout
	var coin = main._combat.coin
	check("the coin appears with both sides and the odds", coin.visible and coin._sides.text.contains("Heads: the trap misfires") and coin._odds.text.begins_with("Heads 50%"))
	if dir != "":
		for i in 4: await process_frame
		root.get_texture().get_image().save_png(dir + "/coin_" + tag + "_before.png")
	check("no way out but to flip", not coin._done.visible and coin._flip.visible)
	coin._flip.pressed.emit()
	await create_timer(2.6).timeout
	if dir != "":
		root.get_texture().get_image().save_png(dir + "/coin_" + tag + "_landed.png")
	var heads: bool = coin._result.text == "Heads!"
	coin._done.pressed.emit()
	await process_frame
	await process_frame
	var hero2: Companion = main._party_state.members[0]
	if heads:
		check("heads: gold and a valuable", main._party_state.supplies.gold == gold_before + 15)
	else:
		check("tails: the needle hurts", hero2.health < health_before)
	check("the event shows the coin's outcome", main._event_screen._body.text.contains("spring snaps") if heads else main._event_screen._body.text.contains("needle"))
	print("fails=", fails)
	quit()
