extends "res://tools/art/check_journal_settings.gd"
## Reuse isolated input/geometry helpers against actual title, Pack and camp.
const SG := preload("res://scripts/save_game.gd")

func named(root_node: Node, title: String) -> Button:
	for button: Button in root_node.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and (button.text == title or button.tooltip_text == title): return button
	return null

func run() -> void:
	SG.set_path("res://build/menu-polish-review/main-save.dat")
	SG.set_continue_requested(false)
	for factor in [1.0, 1.3]:
		Engine.get_meta("depths_settings")["text_size"] = "Larger" if factor > 1 else "Normal"
		root.size = Vector2i(1278, 590); root.content_scale_factor = factor
		var title = load("res://scenes/title.tscn").instantiate()
		title.simulate_phone = true
		root.add_child(title); await settle()
		var button := named(title, "Settings")
		check(button != null, "Title has Settings")
		await click(button, true)
		check(title._settings_screen.visible, "Actual title opens Settings")
		geometry(title._settings_screen, "title")
		check(is_equal_approx(title._settings_screen.content.offset_left, 97), "Title provides phone safe area")
		await snap("title-settings-" + ("larger" if factor > 1 else "normal"))
		await key(KEY_ESCAPE)
		check(not title._settings_screen.visible and button.has_focus(), "Title resumes correct focus")
		title.queue_free(); await settle()
	Engine.get_meta("depths_settings")["text_size"] = "Normal"
	root.content_scale_factor = 1
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false; main.floor_seed = 31; main.simulate_phone_safe_area = true
	root.add_child(main); await create_timer(0.7).timeout
	AudioServer.set_bus_mute(0, true)
	QUESTS.set_stage(main._camp_state, "left_behind", QUESTS.Stage.ACTIVE)
	QUESTS.set_stage(main._camp_state, "iron_sample", QUESTS.Stage.RESOLVED)
	for factor in [1.0, 1.3]:
		Engine.get_meta("depths_settings")["text_size"] = "Larger" if factor > 1 else "Normal"
		root.content_scale_factor = factor
		var tag := "larger" if factor > 1 else "normal"
		main._set_pack(true); await settle()
		var journal_button := named(main._pack, "Quest journal")
		check(journal_button != null, "Pack journal icon")
		await click(journal_button, true)
		check(main._quest_log.visible and main._pack.visible, "Journal opens above Pack")
		geometry(main._quest_log, "Main journal " + tag)
		check(is_equal_approx(main._quest_log.content.offset_left, 97), "Journal receives real Main safe area")
		await snap("main-journal-" + tag)
		await key(KEY_I)
		check(main._quest_log.visible and main._pack.visible, "Pack shortcut cannot close underlying screen")
		await key(KEY_M)
		check(not main._full_map.visible, "Map shortcut blocked by journal")
		await key(KEY_ESCAPE)
		check(not main._quest_log.visible and main._pack.visible and journal_button.has_focus(), "Journal closes alone and restores Pack focus")
		var settings_button := named(main._pack, "Settings")
		await click(settings_button)
		check(main._settings.visible, "Pack gear opens Settings")
		geometry(main._settings, "Pack settings " + tag)
		await snap("main-settings-" + tag)
		await key(KEY_I)
		check(main._settings.visible and main._pack.visible, "Pack shortcut also blocked by Settings")
		await key(KEY_ESCAPE)
		check(not main._settings.visible and main._pack.visible and settings_button.has_focus(), "Settings closes alone and restores Pack focus")
		main._set_pack(false)
	main._end_expedition(main.Expedition.Ending.RETURNED); await settle()
	main._results.continue_pressed.emit(); await create_timer(0.4).timeout
	check(main._camp.visible, "Real expedition return reaches camp")
	var camp_gear := named(main._camp, "Settings")
	check(camp_gear != null, "Camp gear is available")
	await click(camp_gear, true)
	check(main._settings.visible, "Camp opens shared Settings")
	geometry(main._settings, "camp settings")
	await snap("camp-settings-larger")
	await key(KEY_ESCAPE)
	check(not main._settings.visible and main._camp.visible and camp_gear.has_focus(), "Settings returns to camp gear focus")
	main.queue_free(); await create_timer(0.3).timeout
	FileAccess.open(OUT + "main-validation.json", FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "save": "private project-local", "physical_iPhone": false}, "\t") + "\n")
	print("JOURNAL_SETTINGS_MAIN: checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
