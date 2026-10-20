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
	await _drop(main)

	SaveGame.delete()
	print("fails=", fails)
	quit()
