extends SceneTree
## Floor 5, the Drowned Galleries (story slice 2, owner 2026-10-26): the
## lower water gate opens a stair; the galleries flood their passages;
## wading costs time, nerves and torch; the main sluice drains them for
## good (The Dry Passage); a wounded keeper waits among the pools; the
## commander, the smith and the fire each have something to say.
## Placeholder art until #166. Args: tag, screenshot dir.

const Quests := preload("res://scripts/quests.gd")
const Story := preload("res://scripts/story.gd")
const Packages := preload("res://scripts/packages.gd")
const Galleries := preload("res://scripts/galleries.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")
const Supplies := preload("res://scripts/supplies.gd")
const S := Quests.Stage

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _ids(list: Array) -> Array:
	return list.map(func(p): return p.id)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var camp = main._camp_state
	var ps = main._party_state

	# The story's gates.
	check("before the lower gate, no stair on floor 4", "gate_stair" not in _ids(Packages.active(camp, 4)))
	check("...and no galleries quests from camp", Story.camp_talk(camp, "cave") != "commander_galleries")
	Quests.set_stage(camp, "left_behind", S.RESOLVED)
	Quests.set_stage(camp, "iron_sample", S.RESOLVED)
	Quests.set_stage(camp, "lower_gate", S.RESOLVED)
	Quests.set_flag(camp, "lower_gate", "seen")
	Quests.set_flag(camp, "lower_gate", "ending_shown")
	check("the gate seen: its stair is on floor 4 from now on", "gate_stair" in _ids(Packages.active(camp, 4)))
	check("the sluice and the keeper wait on floor 5", "sluice" in _ids(Packages.active(camp, 5)) and "keeper" in _ids(Packages.active(camp, 5)))
	check("the commander asks for the sluice", Story.camp_talk(camp, "cave") == "commander_galleries")
	Story.after_talk(camp, "commander_galleries")
	check("...The Dry Passage is on", Quests.is_active(camp, "dry_passage") and Quests.current(camp) == "dry_passage")
	var smith_talk: String = Story.camp_talk(camp, "smith")
	check("the smith finds the black feather", smith_talk == "smith_arrow" or not camp.site_present("smith"), smith_talk)
	for id in ["commander_galleries", "smith_arrow", "fire_keeper"]:
		var talk: Conversation = Story.conversation(id)
		check("conversation %s loads" % id, talk != null and not talk.pages.is_empty())
	check("floor 5 has foes for one, two and three", [1, 2, 3].all(func(n): return not main.encounter_pool(5, n).is_empty()))

	# Floor 4's stair, and the galleries.
	main._go_to_floor(4, main.Arrival.FROM_ABOVE)
	await process_frame
	check("floor 4 has a way down", main._map.find_content(DungeonMap.Content.STAIRS_DOWN) != Vector2i(-1, -1))
	main._go_to_floor(5, main.Arrival.FROM_ABOVE)
	await process_frame
	var map = main._map
	check("floor 5 is the Drowned Galleries", main.environment_theme.display_name == "The Drowned Galleries" and main._deepest_open() == 5, main.environment_theme.display_name)
	check("its passages run deep with water", map.water.size() >= 8, map.water.size())
	check("ChatGPT's wet walls and drowned floors (#166)", main.environment_theme.wall_material == Galleries.WET_WALL and main.environment_theme.floor_material == Galleries.DROWNED_FLOOR and main.environment_theme.wall_face_uv)
	check("...and deep water over each flooded cell", main._level.find_children("*", "", true, false).filter(func(n): return n.has_method("set_motion") and n.has_method("configure")).size() == map.water.size())
	check("the keeper speaks with her own portrait", Story.conversation("keeper_talk") != null and Story.conversation("keeper_talk").portrait != null)
	check("...only passages: no rooms, doors or anything in them", map.water.keys().all(func(c): return not map._is_room_cell(c) and not map.doors.has(c) and map.content_at(c) == DungeonMap.Content.NONE))
	check("no way further down yet", map.find_content(DungeonMap.Content.STAIRS_DOWN) == Vector2i(-1, -1))
	var sluice_cell := Vector2i(-1, -1)
	var keeper_cell := Vector2i(-1, -1)
	for cell in map.events:
		if map.events[cell].title == "The main sluice":
			sluice_cell = cell
		if map.events[cell].title == "A wounded elf":
			keeper_cell = cell
	check("the sluice and the keeper are placed", sluice_cell != Vector2i(-1, -1) and keeper_cell != Vector2i(-1, -1))
	if dir != "":
		var wet: Vector2i = map.water.keys()[0]
		main._party.place(map, wet)
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png("%s/galleries_%s_water.png" % [dir, tag])
		for c in map.water:
			map.explored[c] = true
		main._minimap.setup(map)
		main._full_map_view.setup(map)
		main._set_full_map(true)
		for i in 4:
			await process_frame
		root.get_texture().get_image().save_png("%s/galleries_%s_map.png" % [dir, tag])
		main._set_full_map(false)

	# Wading.
	var supplies = ps.supplies
	supplies.light_torch(load("res://data/items/torch.tres")) if supplies.count(load("res://data/items/torch.tres")) > 0 else null
	var hero: Companion = ps.living_members()[0]
	var time_before: int = ps.time_elapsed
	var strain_before: float = hero.strain
	var torch_before: float = supplies.torch_left
	var wet_cell: Vector2i = map.water.keys()[0]
	main._wade(wet_cell)
	check("wading takes time and nerves", ps.time_elapsed == time_before + Galleries.WADE_TIME and hero.strain > strain_before)
	check("...and soaks a torch", supplies.source != Supplies.Source.TORCH or supplies.torch_left < torch_before - Galleries.WADE_TIME, "%.1f -> %.1f" % [torch_before, supplies.torch_left])
	var dry: Vector2i = map.start_cell
	time_before = ps.time_elapsed
	main._wade(dry)
	check("dry ground costs nothing extra", ps.time_elapsed == time_before)

	# The keeper.
	ps.supplies.add(load("res://data/items/restorative_draught.tres"), 1)
	var keeper: RoomEvent = map.events[keeper_cell]
	main._room_events.resolve(ps, keeper.choices[0])
	check("given a draught, the keeper talks", Quests.has_flag(camp, "keeper", "helped") and Quests.stage(camp, "keeper") == S.RESOLVED)
	check("...and the fire argues over her", Story.camp_talk(camp, "fire") == "fire_keeper")
	Quests.set_stage(camp, "the_arrow", S.ACTIVE)
	Story.after_talk(camp, "fire_keeper")
	check("...which settles the black fletching", Quests.stage(camp, "the_arrow") == S.RESOLVED and Story.camp_talk(camp, "fire") != "fire_keeper")

	# The sluice.
	var sluice: RoomEvent = map.events[sluice_cell]
	main._room_events.resolve(ps, sluice.choices[0])
	check("turning the wheel opens the sluice", main._room_events.drained and Quests.has_flag(camp, "dry_passage", "opened") and Quests.stage(camp, "dry_passage") == S.RESOLVED)
	main._room_events.drained = false
	main._drain_galleries.call(sluice_cell)  # waits on the card; answered below
	await process_frame
	check("...an ending card", main._results.visible)
	if dir != "":
		root.get_texture().get_image().save_png("%s/galleries_%s_drained.png" % [dir, tag])
	main._results.continue_pressed.emit()
	await process_frame
	check("...and the galleries are dry", map.water.is_empty())
	check("...with a stair down where the wheel was", map.content_at(sluice_cell) == DungeonMap.Content.STAIRS_DOWN)
	check("the sluice isn't placed again", "sluice" not in _ids(Packages.active(camp, 5)))
	main._floors.erase(5)
	main._go_to_floor(5, main.Arrival.FROM_ABOVE)
	await process_frame
	check("they stay dry on later days", main._map.water.is_empty())

	# Floor 6, the Black Reservoir.
	check("the drained sluice opens floor 6", main._deepest_open() == 6 and Quests.is_active(camp, "reservoir") and "sluice_stair" in _ids(Packages.active(camp, 5)))
	check("the flow gate and the stonework wait there", "flow_gate" in _ids(Packages.active(camp, 6)) and "stonework" in _ids(Packages.active(camp, 6)))
	main._go_to_floor(6, main.Arrival.FROM_ABOVE)
	await process_frame
	map = main._map
	check("floor 6 is the Black Reservoir, deeper in water", main.environment_theme.display_name == "The Black Reservoir" and map.water.size() >= 12, map.water.size())
	var gate_cell := Vector2i(-1, -1)
	var stone_cell := Vector2i(-1, -1)
	for cell in map.events:
		if map.events[cell].title == "The flow gate":
			gate_cell = cell
		if map.events[cell].title == "Old stonework":
			stone_cell = cell
	check("...with the flow gate and the stonework placed", gate_cell != Vector2i(-1, -1) and stone_cell != Vector2i(-1, -1))
	main._room_events.resolve(ps, map.events[stone_cell].choices[0])
	main._stonework_vision.call()
	await process_frame
	check("touching the stonework plays the vision, in the blue tint", main._conversation.visible and Story.conversation("vision_stonework").vision)
	if dir != "":
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png("%s/galleries_%s_vision.png" % [dir, tag])
	main._conversation.finished.emit()
	await process_frame
	check("...once", Quests.has_flag(camp, "reservoir", "vision_shown"))
	main._room_events.resolve(ps, map.events[gate_cell].choices[0])
	check("hauling the chains diverts the flow", main._room_events.drained and Quests.has_flag(camp, "reservoir", "diverted"))
	main._room_events.drained = false
	main._drain_galleries.call(gate_cell)
	await process_frame
	check("...the reservoir falls: the slice's ending card", main._results.visible and main._results._title.text.contains("reservoir") if "_title" in main._results else main._results.visible)
	main._results.continue_pressed.emit()
	await process_frame
	check("...and no stair yet below floor 6", map.water.is_empty() and map.find_content(DungeonMap.Content.STAIRS_DOWN) == Vector2i(-1, -1))
	check("the commander hears of it at camp", Story.camp_talk(camp, "cave") == "commander_reservoir" and Story.conversation("commander_reservoir") != null)
	Story.after_talk(camp, "commander_reservoir")
	check("...and the slice is done", Quests.stage(camp, "reservoir") == S.RESOLVED and Story.camp_talk(camp, "cave") != "commander_reservoir")

	# The gate's stair, the day it's found.
	main._go_to_floor(4, main.Arrival.FROM_BELOW)
	await process_frame
	var spot: Vector2i = main._map.start_cell
	main._open_gate_stair(spot)
	check("the lower gate opens into a stair at once", main._map.content_at(spot) == DungeonMap.Content.STAIRS_DOWN)
	print("fails=", fails)
	quit()
