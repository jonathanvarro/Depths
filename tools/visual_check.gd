extends SceneTree
## Show, don't tell (#105): a fight shows slashes, numbers and icons, with no
## sentence log. Args: tag ("desk" or "phone"), screenshot dir.

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	var camp = main._camp_state
	for recruit in camp.candidates.duplicate():
		camp.hire(main._party_state, recruit)
	main._refresh_cards()
	for hero in main._party_state.members:
		hero.accuracy = 1.0
		hero.aim_base = 1.0
		hero.initiative = 50
	# An event's result: the story line, then chips for what changed.
	var outcome := EventOutcome.new()
	outcome.text = "Behind a loose stone: a pouch, and a rusty nail that bites."
	outcome.target = EventOutcome.Target.EVERYONE
	outcome.health = -2
	outcome.gold = 7
	outcome.loot = {load("res://data/items/ration.tres"): 2}
	var choice := EventChoice.new()
	choice.label = "Reach in"
	choice.outcomes = [outcome] as Array[EventOutcome]
	var event := RoomEvent.new()
	event.title = "A loose stone"
	event.clue = "One stone in the wall sits proud of the rest."
	event.choices = [choice] as Array[EventChoice]
	main._event_screen.show_event(event, main._party_state, main._room_events)
	main._event_screen._choose(choice)
	await create_timer(0.2).timeout
	var chips: int = main._event_screen._chips.get_child_count()
	check("an event shows its story and chips, not a bracketed list", chips == 5 and not main._event_screen._body.text.contains("("), "%d chips" % chips)
	if dir != "":
		root.get_texture().get_image().save_png(dir + "/visual_" + tag + "_event.png")
	main._event_screen._finish({"left": true, "ambush": [] as Array[EnemyType]})
	for hero in main._party_state.members:
		hero.health = hero.max_health
	# Exploring (#64): worse nerves and hunger show on the card.
	var lead: Companion = main._party_state.members[0]
	lead.strain = 10.0
	main._on_party_state_changed(false)
	lead.change_strain(50.0)
	lead.hunger = 100
	lead.emit_changed()
	await create_timer(0.3).timeout
	var card = main._cards[0]
	var tips: Array = card._icons.get_children().map(func(c): return c.tooltip_text)
	check("a shaken hero's card shows nerves and what helps", tips.any(func(s): return s.begins_with("Shaken") and s.contains("rest")), str(tips))
	check("a hungry hero's card shows hunger", tips.any(func(s): return s.begins_with("Hungry")))
	check("the worsening pops over the card", card.get_children().any(func(c): return c is TextureRect and c.top_level))
	if dir != "":
		root.get_texture().get_image().save_png(dir + "/visual_" + tag + "_strain.png")
	lead.strain = 10.0
	lead.hunger = 0
	lead.emit_changed()
	var goblin: EnemyType = load("res://data/enemies/goblin.tres").duplicate()
	goblin.accuracy = 1.0
	goblin.initiative = 1
	goblin.max_health = 200
	var types: Array[EnemyType] = [goblin, load("res://data/enemies/webspinner.tres")]
	main._start_combat(main._party.cell, types)
	var combat = main._combat
	# Exercise a normal damaging blow, not the random, interactive coin flip.
	# CUNNING can otherwise choose KILLING_BLOW and wait for player input here.
	combat._state.foes[0].intent = main.CombatState.Intent.SWING
	var guard := 0
	while not combat._actions.visible and guard < 100:
		await create_timer(0.1).timeout
		guard += 1
	await create_timer(0.3).timeout
	check("a fight switches to the combat music (#54)", main._music.place == "combat", main._music.place)
	check("no sentence log on the fight screen", not "_log_label" in combat and combat._turn_label.text.begins_with("Round"))
	var first: Button = combat._tags[combat._state.foes[0]]
	check("tags carry an icon, a name and a health bar", first.icon != null and first.text == combat._state.foes[0].name and first.get_node("Health").visible)
	var line: String = combat._intent_label.text
	check("the selected enemy's intention is spelled out without hover (#116)", combat._intent_label.is_visible_in_tree() and line.contains(main.CombatState.intent_text(combat._target)), line)
	var before = combat._target
	var tab := InputEventAction.new()
	tab.action = "ui_focus_next"
	tab.pressed = true
	combat._unhandled_input(tab)
	check("Tab picks the next enemy", combat._target != before and combat._intent_label.text != line, combat._intent_label.text)
	check("the intention's words are on hover", first.tooltip_text.contains(main.CombatState.intent_text(combat._state.foes[0])) if "CombatState" in main else first.tooltip_text != "")
	if dir != "":
		root.get_texture().get_image().save_png(dir + "/visual_" + tag + "_tags.png")
	combat._action_chosen.emit({"kind": "attack"})
	await create_timer(0.2).timeout
	var heard: bool = combat.get_children().any(func(c): return c is AudioStreamPlayer and c.stream in [main.Sounds.EFFECTS["hit"], main.Sounds.EFFECTS["block"]])
	check("a landed blow is heard (#54)", heard or combat._fx.get_children().any(func(c): return c is Label and c.text == "miss"))
	check("an attack draws a slash and a number, or a miss", combat._fx.get_children().any(func(c): return c is Label), str(combat._fx.get_child_count()))
	if dir != "":
		root.get_texture().get_image().save_png(dir + "/visual_" + tag + "_slash.png")
	# Defend with everyone else, then catch the goblin's blow on a card.
	var saw_claw := false
	guard = 0
	while main._in_combat and guard < 120 and not saw_claw:
		guard += 1
		if combat._actions.visible:
			combat._action_chosen.emit({"kind": "defend"})
		await create_timer(0.03).timeout
		var labels: Array = combat._fx.get_children().filter(func(c): return c is Label and c.text.begins_with("-"))
		if not labels.is_empty():
			saw_claw = true
			await create_timer(0.12).timeout
			print("  ", labels.map(func(l): return l.text))
			if dir != "":
				root.get_texture().get_image().save_png(dir + "/visual_" + tag + "_claw.png")
	check("an enemy's hit shows a red number on the card", saw_claw)
	# Let the awaited fight finish before releasing Main and quitting.
	combat._state.result = main.CombatState.Result.VICTORY
	if combat._actions.visible:
		combat._action_chosen.emit({"kind": "defend"})
	guard = 0
	while main._in_combat and guard < 100:
		await create_timer(0.05).timeout
		guard += 1
	main.queue_free()
	await create_timer(0.2).timeout
	print("fails=", fails)
	quit(1 if fails else 0)
