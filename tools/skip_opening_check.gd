extends SceneTree
## The title's "Skip the tutorial" (owner, 2026-11-21): a new game that starts
## at camp after the commander's talk, as if the opening escape were done.
## Args: tag, screenshot dir.

const SaveGame := preload("res://scripts/save_game.gd")
const Quests := preload("res://scripts/quests.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	# The title screen offers it.
	var title = load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	await process_frame
	var found: Array = title.find_children("*", "Button", true, false).filter(func(b): return b.text == "Skip the tutorial")
	check("the title has a Skip the tutorial button", found.size() == 1)
	title.queue_free()
	await process_frame

	SaveGame.delete()
	SaveGame.set_new_game_hero("res://data/companions/corin.tres")
	SaveGame.set_skip_opening(true)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.5).timeout
	check("no opening escape", not main._in_opening or main._conversation.visible)
	check("the commander talks first", main._conversation.visible and main._conversation._talk == main.COMMANDER_FIRST)
	for i in 20:
		if not main._conversation.visible:
			break
		main._conversation.choose("")
		await create_timer(0.1).timeout
	await create_timer(0.5).timeout
	var hero: Companion = main._party_state.members[0]
	check("then camp", main._camp.visible and not main._in_opening)
	check("Corin, armed with the fallen companion's weapon and supplied", hero.display_name == "Corin" and hero.weapon != null and hero.health > 0 and main._party_state.supplies.items.size() > 0, hero.weapon.display_name)
	check("the story is where the escape leaves it", Quests.stage(main._camp_state, "left_behind") != Quests.Stage.UNKNOWN and not main._camp_state.site_present("smith"), Quests.stage(main._camp_state, "left_behind"))
	check("no lantern until it is bought, as after the escape", not main._party_state.supplies.has_lantern)
	check("the flag is used once", not SaveGame.skip_opening())
	print("fails=", fails)
	quit()
