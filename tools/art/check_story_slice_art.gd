extends SceneTree
## Review the commissioned art through actual Main props and conversation UI.
const OUT := "res://art/concepts/story-slice-v1/"
const DM := preload("res://scripts/dungeon_map.gd")
const Quests := preload("res://scripts/quests.gd")
var failures: Array[String] = []
var checks := 0
var captures: Array[String] = []

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func settle() -> void:
	for tick in 6:
		await process_frame

func snap(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Saved " + name)
	captures.append(name)

func fixture(event: RoomEvent):
	var map = DM.new(PackedStringArray(["#########", "#.......#", "#.......#", "#.......#", "#.......#", "#.......#", "#########"]), 2)
	map.contents[Vector2i(4, 3)] = event.kind
	map.events[Vector2i(4, 3)] = event
	return map

func finish_talk(screen) -> void:
	for page in 6:
		if not screen.visible:
			break
		screen.choose("")
		await process_frame
	check(not screen.visible, "Conversation closed normally")

func _run() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/props/story-slice-v1/catalog.json"))
	for entry: Dictionary in catalogue.assets:
		var texture: Texture2D = load(entry.texture)
		check(texture != null and texture.get_size() == Vector2(entry.canvas[0], entry.canvas[1]), "Imported " + entry.id)
	for phone in [false, true]:
		root.size = Vector2i(1278, 590) if phone else Vector2i(1280, 720)
		var tag := "phone" if phone else "desktop"
		var main = load("res://scenes/main.tscn").instantiate()
		main.play_opening = false
		main.floor_seed = 31
		main.simulate_phone_safe_area = phone
		root.add_child(main)
		await create_timer(.4).timeout
		main._message_label.modulate.a = 0
		main._depth = 2
		main.environment_theme = load("res://themes/cave.tres")
		var cell := Vector2i(4, 3)
		for id in ["three_knocks", "iron_seam", "lower_gate"]:
			var event: RoomEvent = load("res://data/events/quest_" + id + ".tres")
			check(event.prop != null, "Story event has art " + id)
			main._map = fixture(event)
			main._party.place(main._map, Vector2i(4, 4))
			main._build_level()
			var prop: Node3D = main._props[cell]
			var sprite: Sprite3D = prop.get_node("Sprite")
			check(sprite.shaded and sprite.billboard == 2, "World-lit prop " + id)
			check(prop.find_children("*", "CollisionObject3D", true, false).is_empty(), "Art adds no new movement barrier " + id)
			await snap(id + "-before-" + tag)
			if "state" in prop:
				main._empty_prop(cell)
				check(prop.state == "empty" and sprite.texture == prop.empty_texture, "Main switches used art " + id)
				await snap(id + "-used-" + tag)
		var camp = main._camp_state
		main._camp.open(camp, main._party_state)
		main._conversation.play(load("res://data/conversations/commander_first.tres"), main._party_state.members[0], camp)
		await settle()
		check(main._conversation._backdrop.visible and main._conversation._backdrop.texture != null, "Opening backdrop loaded")
		await snap("commander-" + tag)
		await finish_talk(main._conversation)
		main._conversation.play(load("res://data/conversations/miner_thanks.tres"), main._party_state.members[0], camp)
		await settle()
		check(not main._conversation._backdrop.visible, "Miner does not inherit commander backdrop")
		await snap("hask-" + tag)
		await finish_talk(main._conversation)
		main._camp._update_site_art()
		check(main._camp._buttons.cave.icon != null, "Active commander news has a glyph")
		await snap("camp-news-" + tag)
		Quests.set_stage(camp, "left_behind", Quests.Stage.RESOLVED)
		main._camp._update_site_art()
		check(main._camp._buttons.cave.icon == null, "Completed commander news removes its glyph")
		main._camp.visible = false
		for id in ["companion_short_sword", "companion_mace", "camp_forged_blade"]:
			var gear: Equipment = load("res://data/gear/" + id + ".tres")
			main._party_state.supplies.gear.append(gear)
			check(gear.icon.resource_path.contains("story-slice-v1"), "Live weapon icon " + id)
		main._pack.visible = true
		main._pack.refresh()
		check(main._pack._list.find_children("*", "TextureRect", true, false).filter(func(icon): return icon.texture.resource_path.contains("story-slice-v1")).size() == 3, "Pack builds all three weapon rows")
		var journal: Button = null
		for button in main._pack.find_children("*", "Button", true, false):
			if button.accessibility_name == "Quest journal":
				journal = button
		check(journal != null and journal.icon != null, "Named journal control has its icon")
		await snap("pack-items-" + tag)
		await settle()
		var scroll: ScrollContainer = main._pack._inventory_scroll
		var first_weapon: Control = main._pack._list.get_child(2)
		scroll.scroll_vertical += int(first_weapon.global_position.y - scroll.global_position.y)
		await snap("pack-weapons-" + tag)
		scroll.ensure_control_visible(main._pack._list.get_child(4))
		await snap("pack-camp-blade-" + tag)
		if journal != null:
			journal.pressed.emit()
			check(main._quest_log.visible, "Journal glyph still opens the real quest log")
		main.queue_free()
		await settle()
	var file := FileAccess.open(OUT + "godot-validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures,
		"phone": "1278x590 desktop simulation; physical iPhone remains untested."}, "\t") + "\n")
	file.close()
	print("STORY_SLICE_ART checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
