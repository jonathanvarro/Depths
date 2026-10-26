extends SceneTree
## Real Main prop mounting, visibility, resolution and save roundtrip; private save.
const OUT := "res://art/concepts/traps-lamps-v1/"
const DM := preload("res://scripts/dungeon_map.gd")
const SG := preload("res://scripts/save_game.gd")
const SETTINGS := preload("res://scripts/settings.gd")
const SPECS := [["snare", "trap_snare"], ["dart", "trap_dart"], ["bell", "trap_bell_wire"], ["lamp", "territory_lamp_eaters"]]
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	SG.set_path("res://build/traps-lamps-review/save.dat")
	Engine.set_meta("depths_settings", SETTINGS.DEFAULTS.duplicate(true))
	Engine.set_meta("depths_settings_loaded", true)
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func settle() -> void:
	for i in 12:
		await process_frame

func snap(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Capture " + name)
	captures.append(name + ".png")

func fixture(event: RoomEvent):
	var map = DM.new(PackedStringArray(["#########", "#.......#", "#.......#", "#.......#", "#.......#", "#.......#", "#########"]), 2)
	map.contents[Vector2i(4, 2)] = event.kind
	map.events[Vector2i(4, 2)] = event
	return map

func run() -> void:
	# Exercise all wall orientations, independently of the north-facing captures.
	for side in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var rows := PackedStringArray(["#######", "#.....#", "#.....#", "#.....#", "#.....#", "#.....#", "#######"])
		var wall: Vector2i = Vector2i(3, 3) + side
		rows[wall.y] = rows[wall.y].substr(0, wall.x) + "#" + rows[wall.y].substr(wall.x + 1)
		var map = DM.new(rows, 2)
		for name in ["snare", "dart", "bell"]:
			var prop = load("res://art/props/traps-lamps-v1/" + name + ".tscn").instantiate()
			prop.mount_in_cell(map, Vector2i(3, 3), 2.0)
			var sprite: Sprite3D = prop.get_node("Sprite")
			var half_width := sprite.texture.get_width() * sprite.pixel_size / 2
			check(absf(sprite.position.x) + half_width < 1 and absf(sprite.position.z) + (half_width if sprite.billboard == 0 else 0) < 1, "Trap stays inside cell " + name + str(side))
			if name == "dart":
				var ports: Sprite3D = prop.get_node("Ports")
				check(ports.position.is_equal_approx(Vector3(side.x * 0.985, 0.48, side.y * 0.985)), "Port wall coordinate " + str(side))
				var facing := Vector3.BACK.rotated(Vector3.UP, ports.rotation.y)
				check(facing.is_equal_approx(Vector3(-side.x, 0, -side.y)), "Ports face inward " + str(side))
			prop.free()
	for phone in [false, true]:
		root.size = Vector2i(1278, 590) if phone else Vector2i(1280, 720)
		var shape := "phone" if phone else "desktop"
		var main = load("res://scenes/main.tscn").instantiate()
		main.play_opening = false
		main.floor_seed = 31
		main.simulate_phone_safe_area = phone
		root.add_child(main)
		await create_timer(0.6).timeout
		AudioServer.set_bus_mute(0, true)
		main.environment_theme = load("res://themes/cave.tres")
		main._message_label.modulate.a = 0
		main._depth = 2
		var hero: Companion = main._party_state.members[0]
		var cell := Vector2i(4, 2)
		for spec in SPECS:
			var name: String = spec[0]
			var event: RoomEvent = load("res://data/events/" + spec[1] + ".tres")
			check(event.prop.resource_path == "res://art/props/traps-lamps-v1/" + name + ".tscn", "Live dedicated scene " + name)
			hero.trait_id = "keen_eyes"
			var viewing_cell := Vector2i(4, 4) if name in ["dart", "snare"] else Vector2i(4, 3)
			main._map = fixture(event)
			main._party.place(main._map, viewing_cell)
			main._build_level()
			await settle()
			check(main._props.has(cell), "Fresh visible " + name)
			var node: Node3D = main._props[cell]
			var sprite: Sprite3D = node.get_node("Sprite")
			check(node.state == "closed" and sprite.texture == node.closed_texture, "Fresh art " + name)
			check(sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST and sprite.shaded, "Lit native sprite " + name)
			check(sprite.billboard == 0 and is_equal_approx(sprite.rotation.x, -PI / 2) if name in ["snare", "dart"] else sprite.billboard == 2, "Correct mount " + name)
			if name == "dart":
				var ports: Sprite3D = node.get_node("Ports")
				check(ports.visible and is_equal_approx(ports.position.y, 0.48), "Ports mounted at knee height")
				check(ports.position.is_equal_approx(Vector3(0, 0.48, -2.985)), "Ports against nearest north wall, not floating over plate")
				check(is_zero_approx(ports.rotation.y) and ports.billboard == 0, "Ports face room without billboard")
			if name == "lamp":
				check(node.find_children("*", "Light3D", true, false).is_empty(), "Dead lamps emit no light")
			await snap(name + "-closed-" + shape)
			if name in ["snare", "dart"]:
				main._party.place(main._map, Vector2i(4, 3))
				await snap(name + "-closed-near-" + shape)
				main._party.place(main._map, viewing_cell)
			main._map.enter(cell)
			main._run_event(cell)
			await settle()
			main._event_screen._finish({"left": true, "ambush": [] as Array[EnemyType]})
			await settle()
			check(not main._map.triggered.has(cell) and node.state == "closed", "Leave retains ready art " + name)
			if event.kind == DM.Content.TRAP:
				hero.trait_id = "grudge"
				main._map.spotted.erase(cell)
				main._build_level()
				await settle()
				check(not main._props.has(cell), "Unseen trap hidden " + name)
			# Main's actual resolution path creates spent props even when previously hidden.
			main._map.enter(cell)
			main._run_event(cell)
			await settle()
			main._event_screen._finish({"left": false, "ambush": [] as Array[EnemyType]})
			await settle()
			node = main._props[cell]
			check(node.state == "empty" and node.get_node("Sprite").texture == node.empty_texture, "Resolved switches art " + name)
			check(node.closed_texture != node.empty_texture, "Distinct states " + name)
			await snap(name + "-used-" + shape)
			if name in ["snare", "dart"]:
				main._party.place(main._map, Vector2i(4, 3))
				await snap(name + "-used-near-" + shape)
				main._party.place(main._map, viewing_cell)
			var packed: Dictionary = SG.pack_object(main._map)
			var restored = fixture(event)
			SG.unpack_into(restored, packed)
			main._map = restored
			main._party.place(restored, viewing_cell)
			main._build_level()
			await settle()
			check(main._props[cell].state == "empty", "Save/rebuild restores used art " + name)
			check(restored.enter(cell) == DM.Content.NONE, "Resolved event cannot repeat " + name)
		main.queue_free()
		await create_timer(0.3).timeout
	FileAccess.open(OUT + "godot-validation.json", FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "physical_iPhone": false, "save": "project-local private fixture"}, "\t") + "\n")
	print("TRAPS_LAMPS: checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
