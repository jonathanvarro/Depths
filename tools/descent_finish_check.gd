extends SceneTree
## #168/#166 finish: the Black Reservoir's own surfaces, the black-water
## edges beside its deep water, the wet stairs by the flow gate once the
## water is diverted, and the story pictures (the vision, the lower gate,
## the galleries draining, the reservoir's end, and the fire at camp).
## Args: tag, screenshot dir.

const Galleries := preload("res://scripts/galleries.gd")
const Quests := preload("res://scripts/quests.gd")

var fails := 0
var main


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(dir: String, name: String) -> void:
	if dir == "":
		return
	for i in 12:
		await process_frame
	var shot := root.get_texture().get_image()
	if shot:
		shot.save_png("%s/%s.png" % [dir, name])


func _finish() -> Node3D:
	return main._level.get_node_or_null("ReservoirFinish") if main._level else null


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	# Surfaces.
	var cave: EnvironmentTheme = load("res://themes/cave.tres")
	var galleries := Galleries.theme_from(cave, Galleries.DEPTH)
	var reservoir := Galleries.theme_from(cave, Galleries.RESERVOIR)
	check("the reservoir has its own walls, floor and ceiling", reservoir.wall_material == Galleries.RESERVOIR_WALL and reservoir.floor_material == Galleries.RESERVOIR_FLOOR and reservoir.ceiling_material == Galleries.RESERVOIR_CEILING)
	check("...one wall, so its waterline lines up", reservoir.wall_variant_material == null)
	check("...while the galleries keep their wet slate", galleries.wall_material == Galleries.WET_WALL)

	# Pictures.
	check("the stonework vision shows its painting", load("res://data/conversations/vision_stonework.tres").backdrop.resource_path.ends_with("vision.png"))
	check("the fire talks sit by the fire", ["fire_keeper", "miner_thanks"].all(func(id): return load("res://data/conversations/%s.tres" % id).backdrop.resource_path.ends_with("by-the-fire.png")))

	main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.wandering = false
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout

	# Floor 6, flooded.
	main._go_to_floor(Galleries.RESERVOIR, main.Arrival.FROM_ABOVE)
	await process_frame
	var finish := _finish()
	var edges: Array = finish.get_children().filter(func(n): return n.scene_file_path.ends_with("water-edge.tscn")) if finish else []
	check("floor 6 uses the reservoir's walls", main.environment_theme.wall_material == Galleries.RESERVOIR_WALL)
	check("black water shows past some walls beside the deep water", not edges.is_empty() and not main._map.water.is_empty(), "%d edges, %d water cells" % [edges.size(), main._map.water.size()])
	var against_walls := edges.all(func(e):
		var cell := Vector2i(roundi(e.position.x / main.CELL_SIZE), roundi(e.position.z / main.CELL_SIZE))
		return main._map.is_water(cell))
	check("...each one on a wall of a flooded cell", against_walls)
	check("...and no stairs while it's flooded", not finish.get_children().any(func(n): return n.scene_file_path.ends_with("stairs.tscn")))
	# Look at one.
	if not edges.is_empty():
		var edge: Node3D = edges[0]
		var cell := Vector2i(roundi(edge.position.x / main.CELL_SIZE), roundi(edge.position.z / main.CELL_SIZE))
		var facing: Vector3 = (Vector3(cell.x * main.CELL_SIZE, 0, cell.y * main.CELL_SIZE) - edge.position).normalized()
		var party = main._party
		var from := cell + Vector2i(roundi(facing.x), roundi(facing.z))
		if not main._map.is_passable(from):
			from = cell
		party.cell = from
		party.facing = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)].find(Vector2i(roundi(-facing.x), roundi(-facing.z)))
		party.position = party._cell_to_world(from)
		party.rotation.y = party._facing_to_yaw(party.facing)
		await _snap(dir, "reservoir_%s_edge" % tag)

	# Diverted: the stairs by the flow gate (the floor's own, else one placed here).
	var gate: RoomEvent = load("res://data/events/quest_flow_gate.tres")
	var spot := Vector2i(-1, -1)
	for c in main._map.events:
		if main._map.events[c].resource_path == gate.resource_path:
			spot = c
	for y in main._map.height:
		for x in main._map.width:
			var c := Vector2i(x, y)
			if spot == Vector2i(-1, -1) and main._map._is_room_cell(c) and main._map.content_at(c) == 0 and not main._map.events.has(c) and load("res://scripts/dressing.gd")._wall_sides(main._map, c).size() >= 2:
				spot = c
	main._map.events[spot] = gate
	print("flow gate at ", spot)
	Quests.set_flag(main._camp_state, "reservoir", "diverted")
	main._map.water.clear()
	main._build_level()
	await process_frame
	finish = _finish()
	var stairs: Array = finish.get_children().filter(func(n): return n.scene_file_path.ends_with("stairs.tscn")) if finish else []
	check("diverted: wet stairs go down beside the flow gate", stairs.size() == 1, stairs.size())
	check("...and the water's edges are gone with the water", not finish.get_children().any(func(n): return n.scene_file_path.ends_with("water-edge.tscn")))

	# The cards.
	main._slice_ending()
	await process_frame
	check("the lower gate's card has its picture", main._results._illustration.visible and main._results._illustration.texture.resource_path.ends_with("lower-gate-card.png"))
	await _snap(dir, "card_%s_lower_gate" % tag)
	main._results.continue_pressed.emit()
	await process_frame
	Quests.set_flag(main._camp_state, "dry_passage", "ending_shown")
	main._depth = Galleries.RESERVOIR
	main._drain_galleries()
	await process_frame
	check("the reservoir's end has its picture", main._results._illustration.visible and main._results._illustration.texture.resource_path.ends_with("reservoir-ending.png"))
	main._results.continue_pressed.emit()
	await process_frame
	print("fails=", fails)
	quit()
