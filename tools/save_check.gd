extends SceneTree
## Saving and loading (#45): save in the cave, at camp, mid-fight and after
## a wipe, then Continue in a fresh game and compare. Uses its own save file,
## never the player's. Args: tag, screenshot dir.

const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0
var S := ""


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _press(node, label: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if b.text.begins_with(label) and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false


func _game(continue_save: bool):
	SaveGame.continue_requested = continue_save
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


func _to_camp(main, ending: int) -> void:
	main._end_expedition(ending)
	await process_frame
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	S = args[1] if args.size() > 1 else ""
	SaveGame.path = "user://test_save.dat"
	SaveGame.delete()

	# 1. In the cave: a floor change autosaves; save again after walking.
	var main = await _game(false)
	check("a floor change autosaves", SaveGame.exists())
	var ps = main._party_state
	var hero: Companion = ps.members[0]
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	ps.supplies.gold = 17
	hero.health = 9
	hero.add_injury(load("res://data/injuries/deep_wound.tres"))
	ps.time_elapsed = 33
	var explored: int = main._map.explored.size()
	var cell: Vector2i = main._party.cell
	var layout: PackedStringArray = main._map._rows
	main._save_now()
	await _drop(main)
	main = await _game(true)
	ps = main._party_state
	hero = ps.members[0]
	check("continue: same floor, cell and layout", main._depth == 2 and main._party.cell == cell and main._map._rows == layout)
	check("continue: health, injury, gold, time", hero.health == 9 and hero.injuries.size() == 1 and ps.supplies.gold == 17 and ps.time_elapsed == 33, "%d %d %d" % [hero.health, ps.supplies.gold, ps.time_elapsed])
	check("continue: what was explored", main._map.explored.size() == explored)
	check("continue: floor 1 is remembered too", main._floors.has(1))
	check("continue: Mara is still Mara", hero.display_name == "Mara" and hero.founder and hero.portrait_set != null and hero.dialogue != null)

	# 2. At camp: recruits, treatment, stash and the day survive.
	await _to_camp(main, main.Expedition.Ending.RETURNED)
	var camp = main._camp_state
	check("returning to camp autosaves at camp", SaveGame.read().get("at_camp", false))
	var recruit: Companion = camp.candidates[0]
	camp.hire(ps, recruit)
	camp.treat(hero)
	ps.supplies.gold = 12
	camp.store_gold(ps)
	camp.rest(ps)
	await process_frame
	await process_frame
	var day: int = camp.day
	var waiting: Array = camp.candidates.map(func(c): return c.display_name)
	var contract: Dictionary = camp.contract.duplicate()
	await _drop(main)
	main = await _game(true)
	ps = main._party_state
	camp = main._camp_state
	check("continue at camp: the camp is open", main._camp.visible)
	check("continue at camp: day and contract", camp.day == day and camp.contract.get("enemy") == contract.get("enemy"))
	check("continue at camp: the recruit with their face and traits", ps.members.size() == 2 and ps.members[1].display_name == recruit.display_name and ps.members[1].portrait_set != null and ps.members[1].strength == recruit.strength)
	check("continue at camp: who waits by the fire", camp.candidates.map(func(c): return c.display_name) == waiting)
	check("continue at camp: Mara still recovering", camp.is_recovering(ps.members[0]))
	check("continue at camp: stash gold", camp.stash.gold == 12)

	# 3. Mid-fight: the fight happens again on Continue.
	camp.recovering.clear()
	main._camp._buttons["cave"].pressed.emit()
	await process_frame
	_press(main._camp, "Head back down")
	await create_timer(0.2).timeout
	_press(main._preparation, "Enter the cave")
	await create_timer(0.3).timeout
	var fight_cell: Vector2i = main._party.cell + main.Party.DIRECTIONS[main._party.facing]
	main._map.contents[fight_cell] = main.DungeonMap.Content.ENCOUNTER
	main._map.encounter_zones[fight_cell] = fight_cell
	main._party.place(main._map, fight_cell)
	main._on_party_entered_cell(fight_cell)  # as if walking in
	await create_timer(0.2).timeout
	main._save_now()
	check("saved mid-fight, marked to resume", SaveGame.read().get("resume", false))
	await _drop(main)
	main = await _game(true)
	await create_timer(0.5).timeout
	check("continue: back in the cave, and the fight starts again", not main._camp.visible and main._depth == 1 and main._in_combat)

	# 4. A wipe: the save already holds the aftermath.
	await _drop(main)
	main = await _game(true)
	ps = main._party_state
	for h: Companion in ps.members:
		h.min_health = 0
		h.change_health(-999)
	var guard := 0
	while not main._results.visible and guard < 100:  # a fight in progress ends first
		if main._in_combat and main._combat._actions.visible:
			_press(main._combat, "Defend")
		await create_timer(0.1).timeout
		guard += 1
	var after := SaveGame.read()
	check("a wipe saves at camp with nobody and nothing", after.get("at_camp", false) and after["party"].is_empty())
	await _drop(main)
	main = await _game(true)
	check("continue after a wipe: the camp, empty-handed", main._camp.visible and main._party_state.members.is_empty() and main._party_state.supplies.gold == 0)
	await _drop(main)

	# 5. The title offers Continue when there's a save.
	var title = load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	await process_frame
	check("title shows Continue", title.find_children("*", "Button", true, false).any(func(b): return b.text == "Continue"))
	title.queue_free()
	SaveGame.delete()
	print("fails=", fails)
	quit()
