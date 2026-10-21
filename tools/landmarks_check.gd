extends SceneTree
## Landmarks (#117): each mine floor gets up to two recognisable set pieces
## that suit its depth, on clear cells the dressing then leaves alone; they
## are the same on a second visit, named the first time the party walks in,
## and marked on the map after. Args: tag, screenshot dir.

const Landmarks := preload("res://scripts/landmarks.gd")
const Dressing := preload("res://scripts/dressing.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _cell_of(main, node: Node3D) -> Vector2i:
	var at := node.global_position
	return Vector2i(roundi(at.x / main.CELL_SIZE), roundi(at.z / main.CELL_SIZE))


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var kinds_seen := {}
	var floors_with := 0
	var floors_total := 0
	for seed in [11, 23, 57]:
		var main = load("res://scenes/main.tscn").instantiate()
		main.play_opening = false
		main.floor_seed = seed
		root.add_child(main)
		await create_timer(0.4).timeout
		for depth in [1, 2, 3, 4]:
			main._go_to_floor(depth, main.Arrival.FROM_ABOVE)
			await process_frame
			var map = main._map
			var landmarks: Array = map.landmarks
			floors_total += 1
			if not landmarks.is_empty():
				floors_with += 1
			var wrong := []
			for landmark in landmarks:
				kinds_seen[landmark["id"]] = true
				var floors: Array = Landmarks.KINDS[landmark["id"]]["floors"]
				if depth < floors[0] or depth > floors[1]:
					wrong.append(landmark["id"])
				for cell in landmark["cells"]:
					if not Dressing._clear(map, cell):
						wrong.append("%s on %s" % [landmark["id"], cell])
			check("seed %d floor %d: landmarks fit the depth, on clear cells" % [seed, depth], wrong.is_empty() and landmarks.size() <= Landmarks.PER_FLOOR, "%s %s" % [landmarks.map(func(l): return l["id"]), wrong])
			# The dressing leaves landmark cells alone.
			var taken := {}
			for landmark in landmarks:
				for cell in landmark["cells"]:
					taken[cell] = true
			var dressing: Node3D = main._level.get_node_or_null("Dressing")
			var crowded := dressing.get_children().filter(func(p): return taken.has(_cell_of(main, p))).size() if dressing else 0
			check("seed %d floor %d: no ordinary dressing inside a landmark" % [seed, depth], crowded == 0, crowded)
			if dir != "" and seed == 57:
				map.encounter_zones.clear()
				for landmark in landmarks.filter(func(l): return l["id"] == "working_face"):
					await _snap(main, landmark, dir + "/landmark_%s_floor%d_%s.png" % [tag, depth, landmark["id"]])
			if seed != 11 or landmarks.is_empty():
				continue
			# The same on a second visit, and remembered once seen.
			map.encounter_zones.clear()  # look around in peace
			var first: Dictionary = landmarks[0]
			var cell: Vector2i = first["cells"][0]
			main._party.place(map, cell)
			main._on_party_entered_cell(cell)
			check("floor %d: walking into %s names it" % [depth, first["name"]], main._message_label.text.begins_with(first["name"]) and first["seen"], main._message_label.text)
			var before: Array = landmarks.map(func(l): return l["cells"])
			main._go_to_floor(depth, main.Arrival.FROM_ABOVE)
			await process_frame
			map.encounter_zones.clear()
			check("floor %d: the same landmarks on a second visit, still seen" % depth, map.landmarks.map(func(l): return l["cells"]) == before and map.landmarks[0]["seen"])
			check("floor %d: listed on the map" % depth, main._full_map_view._notes().any(func(n): return n["title"] == first["name"]))
			if dir != "":
				for landmark in map.landmarks:
					await _snap(main, landmark, dir + "/landmark_%s_floor%d_%s.png" % [tag, depth, landmark["id"]])
		main.queue_free()
		await create_timer(0.3).timeout
	check("most floors have a landmark", floors_with * 4 >= floors_total * 3, "%d of %d" % [floors_with, floors_total])
	check("every kind turns up somewhere", kinds_seen.size() == Landmarks.KINDS.size(), str(kinds_seen.keys()))
	print("fails=", fails)
	quit()


## Stands a couple of cells off a landmark, looking at it.
func _snap(main, landmark: Dictionary, path: String) -> void:
	var map = main._map
	var centre: Vector2i = landmark["centre"]
	for distance in [2, 1, 3]:
		for f in 4:
			var step: Vector2i = main._party.DIRECTIONS[f]
			var stand: Vector2i = centre - step * distance
			if not map.is_passable(stand) or map.content_at(stand) != main.DungeonMap.Content.NONE:
				continue
			var clear := true
			for i in range(1, distance):
				if not map.is_passable(stand + step * i):
					clear = false
			if not clear:
				continue
			main._party.place(map, stand)
			main._party.facing = f
			main._party.rotation.y = main._party._facing_to_yaw(f)
			main._party_state.supplies.oil = main._party_state.supplies.LANTERN_CAPACITY
			for i in 8:
				await process_frame
			root.get_texture().get_image().save_png(path)
			return
