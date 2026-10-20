extends SceneTree
## Mine dressing (#128): every mine floor gets a sparse, seeded scatter of
## wall, ceiling and floor pieces that suit its depth, none on a cell with
## something on it, and the same scatter on a second visit. Args: tag,
## screenshot dir.

const Dressing := preload("res://scripts/dressing.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _pieces(main) -> Array:
	var root: Node3D = main._level.get_node_or_null("Dressing")
	return root.get_children() if root else []


func _ids(pieces: Array) -> Dictionary:
	var ids := {}
	for piece: Node3D in pieces:
		var id: String = piece.get_meta("dressing_id", piece.name)
		ids[id] = ids.get(id, 0) + 1
	return ids


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	for depth in [1, 2, 3, 4]:
		main._go_to_floor(depth, main.Arrival.FROM_ABOVE)
		await process_frame
		var pieces := _pieces(main)
		var ids := _ids(pieces)
		var floor_cells: int = main._map.floor_cell_count()
		check("floor %d is dressed, sparsely" % depth, pieces.size() >= 12 and pieces.size() <= floor_cells, "%d pieces on %d cells: %s" % [pieces.size(), floor_cells, ids])
		var bad := []
		for piece: Node3D in pieces:
			var cell := Vector2i(roundi(piece.position.x / main.CELL_SIZE), roundi(piece.position.z / main.CELL_SIZE))
			if not Dressing._clear(main._map, cell):
				bad.append(cell)
		check("floor %d: nothing on stairs, doors or events" % depth, bad.is_empty(), str(bad))
		var themed := true
		for id in ids:
			for table in [Dressing.WALL, Dressing.CEILING, Dressing.EDGE, Dressing.DECAL]:
				if table.has(id) and (depth < table[id][0] or depth > table[id][1]):
					themed = false
		check("floor %d: only pieces meant for its depth" % depth, themed, str(ids.keys()))
		if depth == 1:
			check("floor 1 has pit props", ids.has("mine-support"))
		if depth >= 3:
			check("floor %d has goblin torches or marks" % depth, ids.has("goblin-torch-lit") or ids.has("goblin-daubs") or ids.has("goblin-litter"))
		# A second visit looks the same.
		var before: Array = pieces.map(func(p): return p.position)
		main._go_to_floor(depth, main.Arrival.FROM_ABOVE)
		await process_frame
		var after: Array = _pieces(main).map(func(p): return p.position)
		check("floor %d looks the same on a second visit" % depth, before == after)
		if dir != "":
			for i in 3:
				await _snap(dir + "/dressing_%s_floor%d_%d.png" % [tag, depth, i], main, i)
	print("fails=", fails)
	quit()


## Stands two cells from a dressed spot, facing it, and saves a picture.
func _snap(path: String, main, index: int) -> void:
	var pieces := _pieces(main)
	var map = main._map
	var found := 0
	for piece: Node3D in pieces:
		var cell := Vector2i(roundi(piece.position.x / main.CELL_SIZE), roundi(piece.position.z / main.CELL_SIZE))
		for side in Dressing.SIDES:
			var stand: Vector2i = cell - side * 2
			if map.is_passable(stand) and map.is_passable(cell - side) and map.content_at(stand) == main.DungeonMap.Content.NONE:
				if found < index * 7:
					found += 1
					continue
				main._party.place(map, stand)
				main._party.facing = main._party.DIRECTIONS.find(side)
				main._party.rotation.y = main._party._facing_to_yaw(main._party.facing)
				for i in 6:
					await process_frame
				root.get_texture().get_image().save_png(path)
				return
