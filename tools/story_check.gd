extends SceneTree
## The first story slice (docs/first-slice-plan.md): quests, conversations,
## quest packages and their camp payoffs. Grows with each build step.
## Args: tag, screenshot dir.

const SaveGame := preload("res://scripts/save_game.gd")
const Quests := preload("res://scripts/quests.gd")

var fails := 0
var dir := ""


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _game(continue_save: bool):
	SaveGame.set_continue_requested(continue_save)
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 41
	root.add_child(main)
	await create_timer(0.5).timeout
	return main


func _drop(main) -> void:
	main.queue_free()
	await process_frame
	await process_frame


## Presses "Talk to ..." in the open camp activity and answers with
## `replies` (label beginnings) until the conversation closes.
func _talk(main, cs, who: String, a: String = "", b: String = "", c: String = "") -> bool:
	var talk: Button = null
	for button in cs._body.find_children("*", "Button", true, false):
		if button.text.begins_with("Talk to") and button.text.to_lower().contains(who.to_lower()):
			talk = button
	if talk == null:
		return false
	talk.pressed.emit()
	await process_frame
	for reply in [a, b, c]:
		if not main._conversation.visible:
			break
		if reply != "":
			main._conversation.choose(reply)
			await process_frame
	for i in 4:
		if not main._conversation.visible:
			break
		main._conversation.choose("")
		await process_frame
	await create_timer(0.4).timeout  # the conversation fades out
	return not main._conversation.visible


func _snap(name: String) -> void:
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(dir + "/story_" + name + ".png")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	dir = args[1] if args.size() > 1 else ""
	SaveGame.set_path("user://test_save.dat")
	SaveGame.delete()

	# --- Step 1: the commander's conversation sets the first quest.
	var main = await _game(false)
	var camp = main._camp_state
	main._conversation.play(main.COMMANDER_FIRST, main._party_state.members[0], camp)
	await process_frame
	check("the commander's opening offers three answers", main._conversation._replies.get_child_count() == 3)
	main._conversation.choose("\"Find what")
	await process_frame
	check("each answer has its own reply", main._conversation._text.text.contains("didn't tell you"))
	check("...and the hero's name fills in", main._conversation._text.text.contains(main._party_state.members[0].display_name))
	main._conversation.choose("Go on")
	await process_frame
	main._conversation.choose("\"I'll find them")
	await create_timer(0.4).timeout
	check("the order becomes an active quest", Quests.is_active(camp, "left_behind") and Quests.has_flag(camp, "story", "asked_what"))
	check("...and the conversation closes", not main._conversation.visible)
	main._save_now()
	await _drop(main)
	main = await _game(true)
	check("quests survive saving", Quests.is_active(main._camp_state, "left_behind") and Quests.has_flag(main._camp_state, "story", "asked_what"))

	# --- Step 2: camp talk and the quest log.
	camp = main._camp_state
	main._end_expedition(main.Expedition.Ending.RETURNED)
	await process_frame
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout
	var cs = main._camp
	check("the cave path is marked: the commander has something to say", cs._buttons["cave"].icon != null and cs._buttons["cave"].accessibility_name.contains("new conversation"))
	cs.open_activity("cave")
	await process_frame
	var body := " | ".join(cs._body.find_children("*", "Label", true, false).map(func(l): return l.text))
	check("the cave path lists current orders", body.contains("Those Left Behind"))
	check("a talk button for the commander", await _talk(main, cs, "Vael", "Go on"))
	check("...a reminder while the quest is open", Quests.is_active(camp, "left_behind"))
	Quests.set_flag(camp, "left_behind", "found")
	cs._refresh_activity()
	await process_frame
	check("with the evidence found, he hears the report", await _talk(main, cs, "Vael", "Show him", "\"What happens", "\"I'll find a way"))
	check("...which ends the quest and gives the next ones", Quests.stage(camp, "left_behind") == Quests.Stage.RESOLVED and Quests.is_active(camp, "lower_gate") and Quests.is_active(camp, "queen_claim"))
	if dir != "":
		await _snap("camp_orders")
	cs._close_activity()
	cs.open_activity("smith")
	await process_frame
	check("the smith asks for iron", await _talk(main, cs, "smith", "\"I'll bring"))
	check("...and it's an active quest", Quests.is_active(camp, "iron_sample"))
	Quests.set_flag(camp, "iron_sample", "have_ore")
	cs._refresh_activity()
	await process_frame
	check("bringing the ore resolves it", await _talk(main, cs, "smith", "Go on") and Quests.stage(camp, "iron_sample") == Quests.Stage.RESOLVED)
	check("...and the smith sells the camp-forged blade", camp.smith_stock().any(func(g): return g.display_name == "Camp-forged blade"))
	cs._close_activity()
	Quests.set_flag(camp, "three_knocks", "crew_sent")
	main.Story.on_return(camp)
	cs.open_activity("fire")
	await process_frame
	check("a rescued miner waits by the fire after the crew's return", await _talk(main, cs, "miner", "Go on") and Quests.stage(camp, "three_knocks") == Quests.Stage.RESOLVED and Quests.has_flag(camp, "iron_sample", "seam_told"))
	cs._close_activity()
	main._pack.open_quests.emit()
	await process_frame
	var log_text := " | ".join(main._quest_log.find_children("*", "Label", true, false).map(func(l): return l.text))
	check("the quest log lists quests, open ones first", main._quest_log.visible and log_text.contains("The Way Down") and log_text.find("The Way Down") < log_text.find("Those Left Behind"), log_text.substr(0, 200))
	if dir != "":
		await _snap("quest_log")
	main._quest_log.visible = false
	main._save_now()
	await _drop(main)
	main = await _game(true)
	check("the smith's unlock survives saving", main._camp_state.smith_stock().any(func(g): return g.display_name == "Camp-forged blade"))
	await _drop(main)

	await _step3()
	await _steps456()
	SaveGame.delete()
	print("fails=", fails)
	quit()


## Runs a package's event on the current floor, picking `choice`.
func _do_event(main, title: String, choice: String) -> bool:
	var map = main._map
	var cells: Array = map.events.keys().filter(func(c): return map.events[c].title == title)
	if cells.is_empty():
		return false
	main._run_event(cells[0])
	await process_frame
	var screen = main._event_screen
	for c in screen._event.choices:
		if c.label.begins_with(choice):
			screen._choose(c)
	await process_frame
	if screen._buttons.get_child_count() > 0 and screen._event.choices.any(func(c): return c.label.begins_with(choice) and not c.investigation):
		screen._finish({"left": false, "ambush": [] as Array[EnemyType]})
	elif screen.visible and not screen._event.choices.any(func(c): return c.label.begins_with(choice) and c.investigation):
		screen._finish({"left": false, "ambush": [] as Array[EnemyType]})
	await process_frame
	return true


## Three Knocks, the iron seam, the lower gate and the slice's ending.
func _steps456() -> void:
	SaveGame.delete()
	var main = await _game(false)
	var camp = main._camp_state
	# Three Knocks: hidden on floor 2 until found.
	main._floors.clear()
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	check("Three Knocks waits, unannounced, on floor 2", "three_knocks" in main._map.packages and "three_knocks" not in Quests.in_log(camp))
	var map = main._map
	var knock: Vector2i = map.events.keys().filter(func(c): return map.events[c].title == "Three knocks")[0]
	main._run_event(knock)
	await process_frame
	var screen = main._event_screen
	screen._choose(screen._event.choices[0])  # call out
	await process_frame
	check("calling out finds the quest", "three_knocks" in Quests.in_log(camp) and screen._body.text.contains("Hask"))
	if dir != "":
		await _snap("three_knocks")
	screen._choose(screen._event.choices[2])  # mark it for a crew
	await process_frame
	screen._finish({"left": false, "ambush": [] as Array[EnemyType]})
	await process_frame
	check("marking it sends a crew", Quests.has_flag(camp, "three_knocks", "crew_sent"))
	main.Story.on_return(camp)
	check("...who bring Hask back after the next return", Quests.has_flag(camp, "three_knocks", "miner_at_camp") and main.Story.camp_talk(camp, "fire") == "miner_thanks")
	main._floors.clear()
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	check("once he's safe, the rock fall isn't stamped again", "three_knocks" not in main._map.packages)
	# The iron seam: on floor 1 while the smith's quest is open.
	main._floors.clear()
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	check("no seam before the smith asks", "iron_seam" not in main._map.packages)
	Quests.set_stage(camp, "iron_sample", Quests.Stage.ACTIVE)
	main._floors.clear()
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	check("with his request, floor 1 has the dark seam", "iron_seam" in main._map.packages)
	await _do_event(main, "A dark seam", "Chip out")
	check("chipping out a sample gives the ore", Quests.has_flag(camp, "iron_sample", "have_ore") and main.Story.camp_talk(camp, "smith") == "smith_deliver")
	# The lower gate: reachable without the queen's hall.
	var FG = load("res://scripts/floor_generator.gd")
	var DM = load("res://scripts/dungeon_map.gd")
	var F = load("res://scripts/fortress.gd")
	var Packages = load("res://scripts/packages.gd")
	var gate_pkg: QuestPackage = load("res://data/packages/lower_gate.tres")
	var bad := 0
	for s in 200:
		var fort: Dictionary = F.fortify(FG.generate(s * 104729 + 3, false, 4), false)
		var plain = DM.new(fort["layout"], 4)
		var join: Dictionary = plain.walking_distances(plain.find_content(DM.Content.STAIRS_UP))
		var stamped: Dictionary = Packages.place(fort["layout"], [gate_pkg], s, fort["hall"] + fort["gates"], join)
		var m = DM.new(stamped["layout"], 4)
		var reach: Dictionary = m.walking_distances(m.find_content(DM.Content.STAIRS_UP))
		if not stamped["failed"].is_empty() or not reach.has(stamped["events"].keys()[0]) or fort["hall"].any(func(c): return reach.has(c)):
			bad += 1
	check("over 200 fortresses, the lower gate is reachable without passing the queen's gates", bad == 0, "%d bad" % bad)
	Quests.set_stage(camp, "lower_gate", Quests.Stage.ACTIVE)
	main._floors.clear()
	main._go_to_floor(4, main.Arrival.FROM_ABOVE)
	check("with the order given, floor 4 has the lower gate", "lower_gate" in main._map.packages)
	map = main._map
	var gate_cell: Vector2i = map.events.keys().filter(func(c): return map.events[c].title == "The lower water gate")[0]
	main._run_event(gate_cell)
	await process_frame
	main._event_screen._choose(main._event_screen._event.choices[0])
	await process_frame
	main._event_screen._finish({"left": false, "ambush": [] as Array[EnemyType]})
	await create_timer(0.2).timeout
	check("looking down ends the slice with its card", main._results.visible and main._results._title.text == "The way down continues" and Quests.stage(camp, "lower_gate") == Quests.Stage.RESOLVED)
	if dir != "":
		await _snap("slice_ending")
	main._results.continue_pressed.emit()
	await process_frame
	check("...and play carries on", not main._results.visible and not main._party.locked)
	main._queen_defeated()
	await process_frame
	main._results.continue_pressed.emit()
	await process_frame
	check("the queen's death completes her side quest", Quests.stage(camp, "queen_claim") == Quests.Stage.RESOLVED)
	await _drop(main)


## Quest packages (#123) and Those Left Behind.
func _step3() -> void:
	var FG = load("res://scripts/floor_generator.gd")
	var DM = load("res://scripts/dungeon_map.gd")
	var Packages = load("res://scripts/packages.gd")
	var package: QuestPackage = load("res://data/packages/left_behind.tres")
	var problems := 0
	var unreached := 0
	for s in 400:
		var layout: PackedStringArray = FG.generate(s * 7919 + 5, true, 1)
		var before = DM.new(layout, 1)
		var stamped: Dictionary = Packages.place(layout, [package], s)
		var map = DM.new(stamped["layout"], 1)
		if not stamped["failed"].is_empty() or map.find_content(DM.Content.STAIRS_UP) != before.find_content(DM.Content.STAIRS_UP) 				or map.find_content(DM.Content.STAIRS_DOWN) != before.find_content(DM.Content.STAIRS_DOWN) or map.contents.size() != before.contents.size() + 3:
			problems += 1
			continue
		var reach: Dictionary = map.walking_distances(map.find_content(DM.Content.STAIRS_UP))
		for cell in stamped["events"].keys() + stamped["fights"].keys():
			if not reach.has(cell):
				unreached += 1
		for cell in before.contents:
			if not reach.has(cell) and before.walking_distances(before.find_content(DM.Content.STAIRS_UP)).has(cell):
				unreached += 1
	check("over 400 floors, the package always fits and leaves the floor intact", problems == 0, "%d problems" % problems)
	check("...and its fight, the fallen and every old room stay reachable", unreached == 0, "%d unreachable" % unreached)

	SaveGame.delete()
	var main = await _game(false)
	var camp = main._camp_state
	Quests.set_stage(camp, "left_behind", Quests.Stage.ACTIVE)
	main._floors.clear()
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	var map = main._map
	check("with the order given, floor 1 holds the ambush site", "left_behind" in map.packages and map.fight_groups.size() == 1)
	var fight_cell: Vector2i = map.fight_groups.keys()[0]
	var room: Array = map.room_around(fight_cell)
	main._party.place(map, room.filter(func(c): return map.content_at(c) == 0)[0])
	main._on_party_entered_cell(main._party.cell)
	await create_timer(0.3).timeout
	var names: Array = main._combat._state.foes.map(func(f): return f.type.display_name) if main._in_combat else []
	check("scavengers guard it (its own fight, not a random one)", names == ["Great rat", "Rat"], str(names))
	if main._in_combat:
		for foe in main._combat._state.foes:
			foe.health = 0
		main._combat._state._check_end()
		var g := 0
		while main._in_combat and g < 100:
			if main._combat._actions.visible:
				main._combat._action_chosen.emit({"kind": "defend"})
			await create_timer(0.1).timeout
			g += 1
	var fallen: Vector2i = map.events.keys().filter(func(c): return map.events[c].title == "Where they fell")[0]
	main._run_event(fallen)
	await process_frame
	var screen = main._event_screen
	check("the fallen are there to search", screen.visible and screen._title.text == "Where they fell")
	screen._choose(screen._event.choices[1])
	await process_frame
	check("gathering their maps finds the evidence", Quests.has_flag(camp, "left_behind", "found") and screen._body.text.contains("arrow"))
	if dir != "":
		await _snap("evidence")
	screen._finish({"left": false, "ambush": [] as Array[EnemyType]})
	await process_frame
	main._save_now()
	await _drop(main)
	main = await _game(true)
	check("the find survives saving", Quests.has_flag(main._camp_state, "left_behind", "found"))
	main._floors.clear()
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	check("once found, the site isn't stamped into new floors", "left_behind" not in main._map.packages)
	await _drop(main)
