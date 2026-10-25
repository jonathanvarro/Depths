extends SceneTree
## Monster states and elites at a glance (#147): each elite kind carries its
## own mark, not just the shared plate; a bat in the air, a curled beetle, a
## miner holding someone and a venom spider are marked on their tags and
## spelled out on the selected enemy's line; tags stay on screen and clear
## of the action panel. Args: tag ("desk" or "phone"), screenshot dir.

const Settings := preload("res://scripts/settings.gd")

var fails := 0
var tag := "desk"
var dir := ""


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _e(id: String) -> EnemyType:
	return load("res://data/enemies/%s.tres" % id)


func _fight(ids: Array, seed: int):
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = seed
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(3, main.Arrival.FROM_ABOVE)
	await process_frame
	var types: Array[EnemyType] = []
	for id in ids:
		types.append(_e(id))
	main._start_combat(main._party.cell, types)
	var w := 0
	while not main._combat._actions.visible and w < 80:
		await create_timer(0.1).timeout
		w += 1
	return main


func _settle() -> void:
	for i in 8:
		await process_frame


func _marks(main, foe) -> Array:
	return main._combat._tags[foe].get_node("Marks").get_children().map(func(c): return c.texture)


## Every shown tag on screen and clear of the action panel.
func _bounds(main, label: String) -> void:
	var view: Rect2 = root.get_visible_rect()
	var panel: Rect2 = main._combat._actions.get_global_rect() if main._combat._actions.visible else Rect2()  # hidden while a foe acts
	var bad := []
	for foe in main._combat._tags:
		var t: Button = main._combat._tags[foe]
		if not t.visible:
			continue
		var r: Rect2 = t.get_global_rect()
		if not view.encloses(r) or r.intersects(panel):
			bad.append("%s %s" % [foe.name, r])
	check(label + ": tags on screen and clear of the actions", bad.is_empty(), str(bad))


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""
	var sizes := ["Normal", "Larger"] if tag == "phone" else ["Normal"]
	for size in sizes:
		Settings.set_value("text_size", size, self)
		await _elites(size)
		await _states(size)
	Settings.set_value("text_size", "Normal", self)
	print("fails=", fails)
	quit()


func _elites(size: String) -> void:
	var main = await _fight(["goblin", "goblin", "goblin_archer", "goblin_brute"], 11)
	var combat = main._combat
	var state = combat._state
	var kinds := ["Hardened", "Savage", "Swift", "Venomous"]
	for i in 4:
		var foe = state.foes[i]
		if foe.elite == "":
			state.make_elite(foe, kinds[i])
		foe.elite = kinds[i]  # one of each, whatever the dice gave
		combat._tags[foe].queue_free()
		combat._tags.erase(foe)
		combat._add_tag(foe)
	await _settle()
	var firsts := []
	for i in 4:
		var marks := _marks(main, state.foes[i])
		firsts.append(marks[0] if not marks.is_empty() else null)
	check("each elite kind has its own mark", firsts.all(func(m): return m != null) and firsts.duplicate().filter(func(m): return firsts.count(m) == 1).size() == 4, str(kinds))
	combat._select_target(state.foes[1])
	combat._update_intent_line()
	check("the selected elite's edge is spelled out", combat._intent_label.text.contains(combat.ELITE_ABOUT[state.foes[1].elite]), combat._intent_label.text)
	await _bounds(main, "elites, " + size)
	if dir != "":
		root.get_texture().get_image().save_png("%s/readability_%s_%s_elites.png" % [dir, tag, size.to_lower()])
	main.queue_free()
	await process_frame


func _states(size: String) -> void:
	var main = await _fight(["cave_bat", "rock_beetle", "hollow_miner", "venom_spider"], 12)
	var combat = main._combat
	var state = combat._state
	var bat = state.foes[0]
	var beetle = state.foes[1]
	var miner = state.foes[2]
	var spider = state.foes[3]
	for foe in state.foes:
		if foe.elite != "":  # plain ones here: the marks under test come first
			foe.elite = ""
	bat.row_override = "back"  # in the air
	beetle.curled = true
	var mara: Companion = state.party.members[0]
	state._grabbed[mara] = miner
	await _settle()
	check("a bat in the air is marked", combat.STATE_MARKS["airborne"] in _marks(main, bat))
	check("a curled beetle is marked", combat.STATE_MARKS["curled"] in _marks(main, beetle))
	check("a miner holding someone is marked", combat.STATE_MARKS["holding"] in _marks(main, miner))
	check("a venom spider stands apart from a common one", combat.MARKS["venom"] in _marks(main, spider))
	var lines := {}
	for foe in [bat, beetle, miner, spider]:
		combat._select_target(foe)
		combat._update_intent_line()
		lines[foe.name] = combat._intent_label.text
	check("...and each says so on the selected line", lines[beetle.name].contains("Curled") and lines[miner.name].contains("Holding " + mara.display_name) and lines[spider.name].contains("venom") and lines[bat.name].contains("In the air"), str(lines))
	await _settle()
	await _bounds(main, "states, " + size)
	# How it fights, again (#146): "?" by its move shows the intro line,
	# for whichever enemy is picked, at no cost of a turn.
	combat._select_target(miner)
	var actor = state.current_actor()
	var before_events: int = state.events.size()
	combat._rules_button.button_pressed = true
	await process_frame
	check("? shows how the selected enemy fights", combat._rules_card.visible and combat._rules_label.text.contains(miner.type.intro), combat._rules_label.text)
	combat._select_target(beetle)
	await process_frame
	check("...and stays open as another is picked", combat._rules_card.visible and combat._rules_label.text.contains(beetle.type.intro))
	check("...without spending a turn", state.current_actor() == actor and state.events.size() == before_events)
	await _settle()
	check("...in a card just above the actions, on screen", root.get_visible_rect().encloses(combat._rules_card.get_global_rect()) and combat._rules_card.get_global_rect().end.y <= combat._actions.get_global_rect().position.y, str(combat._rules_card.get_global_rect()))
	if dir != "":
		root.get_texture().get_image().save_png("%s/readability_%s_%s_rules.png" % [dir, tag, size.to_lower()])
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SLASH
	key.pressed = true
	combat._unhandled_input(key)
	await process_frame
	check("the ? key closes it again", not combat.show_rules and not combat._rules_card.visible)
	# The floor's line at the top doesn't cover a back-row tag.
	main._show_message("Goblin marks daubed on the rock. Somewhere below: drums.")
	await _settle()
	var words: Rect2 = main._message_label.get_global_rect()
	var covered: Array = combat._tags.keys().filter(func(f): return combat._tags[f].visible and combat._tags[f].get_global_rect().intersects(words))
	check(size + ": no tag hides under the top message", covered.is_empty(), str(covered.map(func(f): return f.name)))
	if dir != "":
		root.get_texture().get_image().save_png("%s/readability_%s_%s_states.png" % [dir, tag, size.to_lower()])
	state._grabbed.clear()
	main.queue_free()
	await process_frame
