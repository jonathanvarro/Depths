extends SceneTree
## The Damp Caves' second art pass (#302 C-F, 2026-11-27): their own
## dressing (the Hollows exit room's growth only there), the Mines' last flat
## pieces in 3D, the composed landmarks, and five new events with their
## props. Args: tag, screenshot dir.

const DIR := "res://art/dressing/damp-dressing-v1/"
const SITES := "res://art/props/damp-sites-v1/"
const Landmarks := preload("res://scripts/landmarks.gd")
const Dressing := preload("res://scripts/dressing.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(path: String) -> void:
	for i in 6:
		await process_frame
	var image := root.get_texture().get_image()
	if image:
		image.save_png(path)


## Stands a step or two away from `cell`, looking at it.
func _look(main, cell: Vector2i, back := 2) -> void:
	for b in range(back, 0, -1):
		for f in 4:
			var from: Vector2i = cell - main._party.DIRECTIONS[f] * b
			if main._map.is_passable(from) and main._map.content_at(from) == 0:
				main._party.place(main._map, from)
				main._party.facing = f
				main._party.rotation.y = -f * PI / 2.0
				return


func _pieces(main) -> Array:
	var dressing: Node = main._level.get_node_or_null("Dressing")
	return dressing.get_children() if dressing else []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var shots: String = args[1] if args.size() > 1 else ""
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 3021
	root.add_child(main)
	await create_timer(0.5).timeout

	# Dressing.
	main._go_to_area("damp", main.Arrival.FROM_ABOVE)
	var pieces := _pieces(main)
	check("the Damp Caves dress with their own wet pieces", pieces.size() > 20 and pieces.all(func(p): return p.scene_file_path.begins_with(DIR)), pieces.size())
	var exit_cell := Vector2i(-1, -1)
	for c in main._map.marks.get("exits", {}):
		if main._map.marks["exits"][c] == "hollows":
			exit_cell = c
	var room: Array = main._map.room_around(exit_cell)
	var growth := pieces.filter(func(p): return String(p.get_meta("dressing_id", "")).begins_with("exit-"))
	check("...mushrooms and mold only in the room with the way to the Hollows", not growth.is_empty() and growth.all(func(p): return room.any(func(c): return Vector2(c.x * 2.0, c.y * 2.0).distance_to(Vector2(p.position.x, p.position.z)) < 1.6)), growth.size())
	check("...and fights' rooms left clear (but for the Hollows cue)", pieces.all(func(p): var c: Vector2i = p.get_meta("cell", Vector2i.ZERO); return c == Vector2i.ZERO or not main._map.encounter_zones.has(c)))

	# Landmarks: across seeds, only the area's own (and the wet lost cache).
	var ids := {}
	var fitted := true
	for s in 8:
		main._site_seed = 5100 + s * 37
		main._floors.clear()
		main._go_to_area("damp", main.Arrival.FROM_ABOVE)
		for l in main._map.landmarks:
			ids[l["id"]] = true
			var holder: Node = main._level.get_node_or_null("Landmarks/" + l["id"])
			var node: Node = holder.get_child(0) if holder and holder.get_child_count() > 0 else null
			if l["cells"].size() == 9 and Landmarks._far_wall(main._map, l["cells"][4]) == Vector2i.ZERO:
				fitted = false
			if node == null or not node.scene_file_path.begins_with(SITES):
				fitted = false
	check("the Damp Caves' landmarks are their own composed scenes", not ids.is_empty() and ids.keys().all(func(i): return i in ["sump", "weeping_wall", "rimstone_stair", "bone_silt", "drowned_drift", "lost_cache"]), ids.keys())
	check("...each against a whole wall or along a drift", fitted)
	main._site_seed = 77
	main._floors.clear()
	main._go_to_area("mines", main.Arrival.FROM_ABOVE)
	check("the Mines keep their own landmarks", main._map.landmarks.all(func(l): return not l["id"] in ["sump", "weeping_wall", "rimstone_stair", "bone_silt", "drowned_drift"]))
	var flat := _pieces(main).filter(func(p): return String(p.get_meta("dressing_id", "")) in ["chalk-arrow", "chalk-cross", "chalk-tally", "puddle-small", "puddle-wide", "floor-crack", "tracks-drag", "rat-nest", "cracks-rubble"])
	check("the Mines' last flat pieces are solid 3D now", not flat.is_empty() and flat.all(func(p): return p.scene_file_path.begins_with(DIR + "mine-")), flat.size())

	# Events.
	var events = main._room_events
	var damp_names := ["A sunken satchel", "Cave pearls", "A seep", "A slick ledge", "Blind fish"]
	var seen := {}
	for i in 300:
		var e: RoomEvent = events.pick(4, 2, "damp")
		if e:
			seen[e.title] = true
	check("the Damp Caves' strange objects include all five new ones", damp_names.all(func(n): return seen.has(n)), seen.keys())
	var elsewhere := false
	for i in 300:
		var e: RoomEvent = events.pick(4, 2, "")
		if e and e.title in damp_names:
			elsewhere = true
	check("...and they stay in the Damp Caves", not elsewhere)

	# Put each on the floor and look at it.
	main._go_to_area("damp", main.Arrival.FROM_ABOVE)
	var spots: Array = []
	for c in main._map.walking_distances(main._party.cell):
		if main._map._is_room_cell(c) and Dressing._clear(main._map, c) and not main._map.encounter_zones.has(c) and not Dressing._wall_sides(main._map, c).is_empty() and main._map.room_around(c).size() >= 9:
			spots.append(c)
	var made := {}
	var taken := {}
	for name in ["damp_sunken_satchel", "damp_cave_pearls", "damp_seep", "damp_slick_ledge", "damp_blind_fish", "chest_goblin_stash"]:
		var cell := Vector2i(-1, -1)
		for c in spots:
			if not taken.keys().any(func(t): return main._map.room_around(t).has(c)):
				cell = c
				break
		if cell == Vector2i(-1, -1):
			cell = spots[0]
		spots.erase(cell)
		taken[cell] = true
		var e: RoomEvent = load("res://data/events/%s.tres" % name)
		main._map.contents[cell] = e.kind
		main._map.events[cell] = e
		made[name] = cell
	var ledge: Vector2i = made["damp_slick_ledge"]
	main._map.marks["floor_cut"] = {ledge: true}
	main._build_level()
	for name in made:
		var prop = main._props.get(made[name])
		check("%s stands in the room" % name, prop != null and (prop.scene_file_path.begins_with(SITES) or prop.scene_file_path.begins_with(DIR)), prop.scene_file_path if prop else null)
	check("the seep fits itself to a real wall", main._props[made["damp_seep"]].get_node("Mount").visible)
	check("the goblin stash in the Damp Caves is the wet one", main._props[made["chest_goblin_stash"]].scene_file_path.ends_with("damp-dressing-v1/goblin-stash.tscn"))
	if shots != "":
		for name in made:
			_look(main, made[name])
			await _snap("%s/%s.png" % [shots, name])
	main._map.event_flags[ledge] = ["slipped"]
	check("a fall shows the ledge slipped", main._ledge_state(ledge) == "slipped" and main._props[ledge].set_state("slipped"))
	main._map.event_flags[ledge] = []
	check("...a safe crossing shows it passed", main._ledge_state(ledge) == "passed" and main._props[ledge].set_state("passed"))
	main._map.triggered[made["damp_cave_pearls"]] = true
	main._empty_prop(made["damp_cave_pearls"])
	check("gathered pearls leave the basin empty", String(main._props[made["damp_cave_pearls"]].state) in ["gathered", "empty"], main._props[made["damp_cave_pearls"]].state)
	# Three Knocks: the outcome decides what the fall shows.
	var Quests = load("res://scripts/quests.gd")
	var knock_cell: Vector2i = spots.pop_back()
	main._map.contents[knock_cell] = 4
	main._map.events[knock_cell] = load("res://data/events/quest_three_knocks.tres")
	main._map.triggered[knock_cell] = true
	Quests.set_flag(main._camp_state, "three_knocks", "crew_sent")
	main._build_level()
	var knocks: Node3D = main._props[knock_cell]
	check("Three Knocks uses its 3D fall", knocks.scene_file_path.ends_with("damp-dressing-v1/three-knocks.tscn"))
	check("...marked for a crew, the fall stays", knocks.get_node("Fresh").visible and not knocks.get_node("Used").visible)
	Quests.set_flag(main._camp_state, "three_knocks", "miner_at_camp")
	main._empty_prop(knock_cell)
	check("...once Hask is out, it's dug away", knocks.get_node("Used").visible and not knocks.get_node("Fresh").visible)
	if shots != "":
		for l in main._map.landmarks:
			_look(main, l["centre"], 2)
			await _snap("%s/landmark_%s.png" % [shots, l["id"]])
		if exit_cell != Vector2i(-1, -1):
			_look(main, exit_cell, 2)
			await _snap("%s/hollows_exit_room.png" % shots)
	print("fails=", fails)
	quit()
