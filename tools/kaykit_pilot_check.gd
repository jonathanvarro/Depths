extends SceneTree
## #224: floor 1 dressing from the CC0 KayKit pack, adopted 2026-11-03.
## Miners' stores stand against room walls, every piece shares
## one recoloured texture and stays within a phone budget. Saves the same
## view with and without the pilot. Args: tag, screenshot dir.

const Pilot := preload("res://scripts/kaykit_pilot.gd")
const DIRECTIONS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

var fails := 0
var main


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _pilot() -> Node3D:
	return main._level.get_node_or_null("KayKitPilot") if main._level else null


## A cell one or two steps from the piece's cell, facing it down a clear line.
func _viewpoint(piece_cell: Vector2i) -> Array:
	for steps in [1, 2]:
		for f in DIRECTIONS.size():
			var from: Vector2i = piece_cell - DIRECTIONS[f] * steps
			if main._map.is_passable(from) and main._map.is_passable(piece_cell - DIRECTIONS[f]):
				return [from, f]
	return []


func _snap(dir: String, name: String) -> void:
	if dir == "":
		return
	for i in 12:
		await process_frame
	var shot := root.get_texture().get_image()
	if shot:
		shot.save_png("%s/%s.png" % [dir, name])


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.wandering = false
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	if main._depth != 1:
		main._go_to_floor(1, main.Arrival.FROM_ABOVE)
		await process_frame
	await process_frame
	var pilot := _pilot()
	check("adopted: floor 1's rooms get miners' stores by default", pilot != null and pilot.get_child_count() >= 6, pilot.get_child_count() if pilot else 0)
	var meshes: Array = pilot.find_children("*", "MeshInstance3D", true, false) if pilot else []
	var triangles := 0
	for m: MeshInstance3D in meshes:
		for s in m.mesh.get_surface_count():
			triangles += m.mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX].size() / 3
	var shared: Material = meshes[0].material_override if not meshes.is_empty() else null
	check("every piece shares one material", shared != null and meshes.all(func(m): return m.material_override == shared))
	check("...with the recoloured 256 texture", shared != null and shared.albedo_texture.get_width() == 256)
	check("...and the walls' grain over it, in world space", shared != null and shared.detail_enabled and shared.detail_albedo != null and shared.uv2_world_triplanar)
	check("the floor's pieces stay within a phone budget", triangles < 60000, "%d triangles in %d pieces" % [triangles, pilot.get_child_count() if pilot else 0])
	var cells := {}  # cell -> its biggest piece's name, biggest first below
	for piece: Node3D in pilot.get_children():
		cells[Vector2i(roundi(piece.position.x / main.CELL_SIZE), roundi(piece.position.z / main.CELL_SIZE))] = piece.name
	check("...only in room cells, never on stairs, doors or events", cells.keys().all(func(c): return main._map._is_room_cell(c) and main._map.content_at(c) == main.DungeonMap.Content.NONE and not main._map.events.has(c)))

	# The same view, with and without.
	var view: Array = []
	var big := cells.keys().filter(func(c): return ["crates", "keg", "barrel_large", "barrel_small_stack"].any(func(n): return String(cells[c]).begins_with(n)))
	for c in big + cells.keys():
		view = _viewpoint(c)
		if not view.is_empty():
			break
	check("found a view of the pilot pieces", not view.is_empty())
	if not view.is_empty():
		var party = main._party
		party.cell = view[0]
		party.facing = view[1]
		party.position = party._cell_to_world(view[0])
		party.rotation.y = party._facing_to_yaw(view[1])
		await _snap(dir, "kaykit_%s_on" % tag)
		main.kaykit_pilot = false
		main._build_level()
		await process_frame
		check("...and switched off, they're gone", _pilot() == null)
		await _snap(dir, "kaykit_%s_off" % tag)
	print("fails=", fails)
	quit()
