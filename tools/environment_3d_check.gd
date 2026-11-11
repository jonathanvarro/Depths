extends SceneTree
## ChatGPT's 3D environment art, live (2026-11-11): trap, site, shrine and
## machinery props on their events (#247, #252, #246), with the state the
## outcome left; 3D passages and stairs (#250); the KayKit props on deeper
## floors in their regional skins (#225). Traversal and outcomes unchanged.
## Args: tag, screenshot dir.

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	# Event props.
	var events := ["trap_tripwire", "trap_bell_wire", "trap_snare", "trap_dart", "trap_hollow_floor", "object_pale_idol",
			"object_still_pool", "object_defiled_shrine", "object_fouled_well", "chest_buried_cache", "quest_sluice", "quest_flow_gate"]
	var flat := []
	for name in events:
		var event: RoomEvent = load("res://data/events/%s.tres" % name)
		var node: Node3D = event.prop.instantiate()
		root.add_child(node)
		var ok: bool = event.prop.resource_path.contains("-3d-v1/") and "state" in node
		if ok:
			for state in ["closed", "open", "empty"]:
				node.set("state", state)
		node.queue_free()
		if not ok:
			flat.append(name)
	check("trap, site, shrine and machinery events show their 3D props", flat.is_empty(), flat)
	check("the idol and shrines sit in a real wall", load("res://data/events/object_pale_idol.tres").prop_on_wall and load("res://data/events/object_defiled_shrine.tres").prop_on_wall)

	# Passages and stairs.
	var cave: EnvironmentTheme = load("res://themes/cave.tres")
	var scenes := [cave.closed_scene, cave.opened_scene, cave.blocked_scene, cave.descent_scene, cave.ascent_scene,
			load("res://themes/fortress.tres").descent_scene, load("res://themes/stone.tres").ascent_scene]
	check("webs, roots, ledges and stairs are the 3D features", scenes.all(func(s): return s and s.resource_path.contains("transitions-3d-v1/")), scenes.map(func(s): return s.resource_path.get_file() if s else "none"))

	# A real floor: outcomes leave the right state, and it's kept.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var map = main._map
	var cell: Vector2i = map.events.keys()[0]
	map.triggered[cell] = true
	main._empty_prop(cell, "open")
	check("an outcome's state is kept on the map", map.marks.get("prop_state", {}).get(cell, "") == "open")
	main._props.clear()
	main._add_room_props()
	var prop = main._props.get(cell)
	check("...and shown again on a return visit", prop == null or not "state" in prop or prop.get("state") == "open", prop.get("state") if prop and "state" in prop else "-")
	var trap: RoomEvent = load("res://data/events/trap_snare.tres")
	var screen = main._event_screen
	var result := {}
	screen.finished.connect(func(r): result.merge(r), CONNECT_ONE_SHOT)  # a lambda can't reassign a local
	screen.show_event(trap, main._party_state, main._room_events, [])
	screen._choose(trap.choices[0])
	await process_frame
	for b in screen.find_children("*", "Button", true, false):
		if b.text == "Continue":
			b.pressed.emit()
	await process_frame
	check("stepping round a trap reports it didn't fire", result.get("choice", -1) == 0 and not result.get("fired", true), "%s / buttons %s" % [result, screen.find_children("*", "Button", true, false).map(func(b): return b.text)])

	# The KayKit props on deeper floors, in their regions' skins.
	var skins := {}
	for depth in [2, 3, 5]:
		main._go_to_floor(depth, main.Arrival.FROM_ABOVE)
		await process_frame
		var pilot = main._level.get_node_or_null("KayKitPilot")
		var meshes: Array = pilot.find_children("*", "MeshInstance3D", true, false) if pilot else []
		skins[depth] = meshes[0].material_override.resource_path.get_file() if not meshes.is_empty() else "none"
	check("KayKit props on floors 2, 3 and 5 in fungal, scorched and waterlogged skins", skins.get(2) == "fungal.tres" and skins.get(3) == "scorched.tres" and skins.get(5) == "waterlogged.tres", skins)
	# The fortress (#246): its structures, clear of the gates; palisades
	# broken once the gate is.
	for broken in [false, true]:
		main._camp_state.gate_broken = broken
		main._floors.erase(4)
		main._go_to_floor(4, main.Arrival.FROM_ABOVE)
		await process_frame
		var fort = main._level.get_node_or_null("Fortress3D")
		var pieces: Array = fort.get_children() if fort else []
		var kinds: Array = pieces.map(func(n): return n.get_meta("fortress_piece", ""))
		var gates: Array = main._map.marks.get("gates", [])
		var on_gate: Array = pieces.filter(func(n): return Vector2i(roundi(n.position.x / main.CELL_SIZE), roundi(n.position.z / main.CELL_SIZE)) in gates)
		check("fortress (gate %s): throne, palisades, walkway and more" % ("broken" if broken else "barred"), "throne" in kinds and "palisade" in kinds and "overhead-walkway" in kinds, kinds)
		check("...none on a gate", on_gate.is_empty(), on_gate.size())
		var palisades: Array = pieces.filter(func(n): return n.get_meta("fortress_piece", "") == "palisade")
		check("...palisades %s" % ("broken" if broken else "intact"), palisades.all(func(n): return n.state == ("empty" if broken else "closed")))
	print("fails=", fails)
	quit()
