extends SceneTree
## The cave as a network of areas (owner direction 2026-11-25, #300): the
## Damp Caves fork to the Cavern and the Fungal Hollows, the fortress to the
## Drowned Galleries and the Jail, and two boss lairs sit at the ends of side
## routes. Args: tag, screenshot dir.

const Areas := preload("res://scripts/areas.gd")
const Q := preload("res://scripts/quests.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _downs(main) -> Array:
	var out: Array = []
	for y in main._map.height:
		for x in main._map.width:
			if main._map.content_at(Vector2i(x, y)) == main.DungeonMap.Content.STAIRS_DOWN:
				out.append(Vector2i(x, y))
	return out


func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 31
	root.add_child(main)
	await create_timer(0.5).timeout
	Q.set_stage(main._camp_state, "left_behind", Q.Stage.RESOLVED)

	# The graph itself.
	check("the Damp Caves fork to the Cavern and the Fungal Hollows", Areas.children("damp") == ["cavern", "hollows"])
	check("the fortress leads on to the Galleries and the Jail", Areas.children("fortress") == ["galleries", "jail"])
	check("the Rest Area sits between the Cavern and the fortress", Areas.info("cavern")["main"] == "rest" and Areas.info("rest")["main"] == "fortress")
	check("a scouts' route to floor 3 arrives at the Rest Area", Areas.route_area(3) == "rest" and Areas.route_area(2) == "damp")
	check("old floor numbers still name the main path", Areas.main_for(1) == "mines" and Areas.main_for(4) == "fortress" and Areas.main_for(6) == "reservoir")

	# The first junction.
	main._go_to_area("damp", main.Arrival.FROM_ABOVE)
	var downs: Array = _downs(main)
	var dests: Array = downs.map(func(c): return main._exit_destination(c))
	check("the Damp Caves have two ways down, one to each branch", downs.size() == 2 and "cavern" in dests and "hollows" in dests, [downs, dests])
	check("...each named on the full map", main._map.marks.get("exit_names", {}).size() == 2 and main._map.marks["exit_names"].values().has("Fungal Hollows"), main._map.marks.get("exit_names"))
	var hollows_exit: Vector2i = main._exit_to("hollows")
	main._go_to_area("hollows", main.Arrival.FROM_ABOVE)
	check("the Fungal Hollows are their own area, with the fungal look for now", main._area == "hollows" and main.environment_theme == main.FUNGAL_THEME and main._floors.has("hollows"), main.environment_theme.display_name)
	check("...with no story sites (they belong to the main path)", main._map.marks.get("sites", {}).is_empty())
	main._go_to_area("damp", main.Arrival.FROM_BELOW, "hollows")
	check("climbing back up arrives at the way down to the Hollows", main._area == "damp" and main._party.cell == hollows_exit, [main._party.cell, hollows_exit])
	check("...on the same Damp Caves floor as before", main._map == main._floors[2])

	# The Rest Area: a safe camp on the way to the fortress.
	main._go_to_area("rest", main.Arrival.FROM_ABOVE)
	var fights: int = main._map.contents.values().filter(func(c): return c == main.DungeonMap.Content.ENCOUNTER).size()
	check("the Rest Area holds the scouts' camp and no fights", main._map.marks.has("refuge") and fights == 0 and main._map.marks.get("elite", {}).is_empty(), [main._map.marks.keys(), fights])
	main._go_to_area("cavern", main.Arrival.FROM_ABOVE)
	check("the Cavern no longer holds the refuge itself", not main._map.marks.has("refuge"))

	# The fortress forks; the Jail leads to a boss lair, with a warning first.
	main._go_to_area("fortress", main.Arrival.FROM_ABOVE)
	var jail_exit: Vector2i = main._exit_to("jail")
	check("the fortress has a way down to the Jail", main._exit_destination(jail_exit) == "jail", jail_exit)
	main._go_to_area("jail", main.Arrival.FROM_ABOVE)
	check("the Jail borrows the fortress's look for now", main._area == "jail" and main.environment_theme == main.FORTRESS_THEME)
	var lair_exit: Vector2i = main._exit_to("execution")
	check("the Jail has a way down to the Execution Halls", main._exit_destination(lair_exit) == "execution", lair_exit)
	main._party.place(main._map, lair_exit)
	main._on_party_entered_cell(lair_exit)
	await process_frame
	check("the way into a boss lair warns and lets you turn back", main._prompt.visible and main._prompt_label.text.contains("Execution Halls") and main._prompt_buttons[1].text == "Back away", main._prompt_label.text)
	check("...saying how the party stands", main._prompt_label.text.contains("Your party:") and main._prompt_label.text.contains("torches spare"), main._prompt_label.text)
	main._prompt_buttons[1].pressed.emit()
	await process_frame
	check("...and turning back stays put", main._area == "jail")
	main._go_to_area("execution", main.Arrival.FROM_ABOVE)
	var boss: Vector2i = main._map.marks.get("boss", Vector2i(-1, -1))
	var group: Array = main._map.fight_groups.get(boss, [])
	check("the Execution Halls hold the Headsman (placeholder) and his guards", not group.is_empty() and group[0].display_name == "The Headsman", group.map(func(t): return t.display_name))
	check("...and no way on but back up", _downs(main).is_empty() and main._map.find_content(main.DungeonMap.Content.STAIRS_UP) != Vector2i(-1, -1))
	main._party.place(main._map, boss)
	main._area_boss_won()
	var tiers: int = main._map.marks.get("chest_tiers", {}).size()
	check("beating the boss leaves its gilded hoard", tiers == 1 and "lair:headsman" in main._camp_state.elites_looted)
	main._map.marks["boss_beaten"] = false
	main._area_boss_won()
	check("...won once only", main._map.marks.get("chest_tiers", {}).size() == tiers)
	main._go_to_area("grove", main.Arrival.FROM_ABOVE)
	check("the Grove holds the Heartrot (placeholder)", main._map.fight_groups.get(main._map.marks.get("boss"), [null])[0].display_name == "The Heartrot")

	# Saving keeps the area; saves from before the network still load.
	main._go_to_area("jail", main.Arrival.FROM_ABOVE)
	main._save_now()
	var data: Dictionary = main.SaveGame.read()
	check("a save remembers the area, not just the depth", data.get("area") == "jail" and data["floors"].any(func(p): return str(p[0]) == "jail"), data.get("area"))
	data.erase("area")
	data["depth"] = 4
	data["at_camp"] = false
	data["resume"] = false
	main._restore(data)
	await process_frame
	check("an old save (no area) continues on its main-path floor", main._area == "fortress", main._area)

	# The way up from the Mines still leaves the cave.
	main._go_to_area("mines", main.Arrival.FROM_ABOVE)
	check("the Mines' way up is still the way out", Areas.info("mines")["parent"] == "")
	print("fails=", fails)
	quit()
