extends SceneTree
## Out of light (owner, 2026-11-22): the glow reaches only the next square,
## the map shows only where you are and the way up, and walking in the dark maps only the squares you
## stand on. Args: tag, screenshot dir.

var fails := 0
var shots := ""


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(name: String) -> void:
	if shots == "":
		return
	await create_timer(1.0).timeout
	var image := root.get_texture().get_image()
	if image:
		image.save_png(shots + "/dark_" + name + ".png")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	shots = args[1] if args.size() > 1 else ""
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 77
	root.add_child(main)
	await create_timer(0.5).timeout
	var supplies = main._party_state.supplies
	supplies.source = supplies.Source.TORCH
	supplies.torch_left = 50.0
	supplies.changed.emit()
	check("lit: the map can be read", not main._minimap.dark and main._party.lit)
	await _snap("lit")
	supplies.has_lantern = false
	supplies.source = supplies.Source.NONE
	supplies.torch_left = 0.0
	supplies.changed.emit()
	check("out of light: too dark to read the map", main._minimap.dark and main._full_map_view.dark)
	# A partial map in the dark (owner, 2026-11-22): the room or hallway
	# you're in and the room with the way up, as far as explored, nothing else.
	var map = main._map
	var all_seen: Dictionary = map.explored.duplicate()
	for y in map.height:
		for x in map.width:
			if not map.is_wall(Vector2i(x, y)):
				map.explored[Vector2i(x, y)] = true
	var shown: Dictionary = main._minimap.dark_cells()
	var here: Array = map.area_around(main._party.cell)
	var up: Vector2i = map.find_content(main.DungeonMap.Content.STAIRS_UP)
	var exit_room: Array = map.area_around(up)
	check("in the dark the map keeps the room or hallway you're in", here.all(func(c): return shown.has(c)) and shown.has(main._party.cell), here.size())
	check("...and the room with the way up", exit_room.all(func(c): return shown.has(c)), [up, exit_room.size()])
	check("...and nothing else", shown.keys().all(func(c): return c in here or c in exit_room) and shown.size() < map.explored.size(), [shown.size(), map.explored.size()])
	map.explored = all_seen
	var unexplored_only: Dictionary = main._minimap.dark_cells()
	check("...only as far as explored", unexplored_only.keys().all(func(c): return map.explored.has(c)))
	check("...a faint glow that dies past the next square", main._party._lantern.omni_range <= main.CELL_SIZE * 2.5 and main._party._lantern.omni_attenuation >= 2.0)
	var before: int = main._map.explored.size()
	var party = main._party
	var stepped := false
	for f in 4:
		var next: Vector2i = party.cell + party.DIRECTIONS[party.facing]
		if main._map.is_passable(next) and main._map.content_at(next) == main.DungeonMap.Content.NONE and main._map.door_at(next) == 0:
			party._reveal(next)
			stepped = true
			break
		party.facing = (party.facing + 1) % 4
	check("walking in the dark maps only the square you stand on", stepped and main._map.explored.size() <= before + 1, [before, main._map.explored.size()])
	await _snap("out")
	supplies.source = supplies.Source.TORCH
	supplies.torch_left = 50.0
	supplies.changed.emit()
	check("light again: the map is back", not main._minimap.dark)
	print("fails=", fails)
	quit()
