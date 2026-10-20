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
	await process_frame
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
	await process_frame
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
	check("the cave path is marked: the commander has something to say", cs._buttons["cave"].text.ends_with("(!)"))
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

	SaveGame.delete()
	print("fails=", fails)
	quit()
