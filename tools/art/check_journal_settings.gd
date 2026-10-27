extends SceneTree
## Isolated live widgets, real keyboard/touch, no Main or game save.
const JOURNAL := preload("res://scripts/quest_log.gd")
const OPTIONS := preload("res://scripts/settings_screen.gd")
const SETTINGS := preload("res://scripts/settings.gd")
const QUESTS := preload("res://scripts/quests.gd")
const SAFE := preload("res://scripts/safe_area.gd")
const OUT := "res://art/concepts/interface/journal-settings-v1/"
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var journal
var options
var camp
var _settings_before: PackedByteArray
var _had_test_settings := false

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	Engine.set_meta("depths_settings", SETTINGS.DEFAULTS.duplicate(true))
	Engine.set_meta("depths_settings_loaded", true)
	_had_test_settings = FileAccess.file_exists(SETTINGS.path())
	if _had_test_settings: _settings_before = FileAccess.get_file_as_bytes(SETTINGS.path())
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func settle() -> void:
	for i in 10: await process_frame

func fit(view, phone: bool) -> void:
	view.set_safe_area(SAFE.insets(root, phone))

func snap(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Capture " + name)
	captures.append(name + ".png")

func click(button: BaseButton, touch := false) -> void:
	var parent := button.get_parent()
	while parent and not parent is ScrollContainer: parent = parent.get_parent()
	if parent: parent.ensure_control_visible(button)
	await settle()
	var pos := button.get_global_rect().get_center()
	if touch:
		for pressed in [true, false]:
			var e := InputEventScreenTouch.new()
			e.index = 0; e.position = pos; e.pressed = pressed
			root.push_input(e, true)
			await process_frame
	else:
		var motion := InputEventMouseMotion.new()
		motion.position = pos
		root.push_input(motion, true)
		for pressed in [true, false]:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT; e.position = pos; e.pressed = pressed
			root.push_input(e, true)
			await process_frame
	await settle()

func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func geometry(view, label: String) -> void:
	var safe: Rect2 = view.content.get_global_rect()
	check(safe.encloses(view._panel.get_global_rect()), "Panel stays in safe area " + label)
	check(safe.encloses(view._close.get_global_rect()), "Close stays visible " + label)
	check(view._close.size.x >= 44 and view._close.size.y >= 44, "Close touch target " + label)
	check(view._body.size.x > 0 and view._body.size.y > 0, "Body has room " + label)

func run() -> void:
	preload("res://scripts/ui_theme.gd").install()
	SETTINGS.ensure_buses()
	camp = preload("res://scripts/camp_state.gd").new()
	QUESTS.set_stage(camp, "left_behind", QUESTS.Stage.ACTIVE)
	QUESTS.set_stage(camp, "iron_sample", QUESTS.Stage.OFFERED)
	QUESTS.set_stage(camp, "queen_claim", QUESTS.Stage.RESOLVED)
	var opener := Button.new()
	opener.text = "Open menu"; opener.position = Vector2(20, 20); opener.size = Vector2(140, 50)
	root.add_child(opener)
	journal = JOURNAL.new(); root.add_child(journal)
	options = OPTIONS.new(); root.add_child(options)
	var before := JSON.stringify(camp.quests)
	for shape in [Vector2i(1280, 720), Vector2i(1278, 590), Vector2i(1334, 750), Vector2i(844, 390)]:
		for scale in [1.0, 1.3]:
			root.size = shape
			root.content_scale_factor = scale
			Engine.get_meta("depths_settings")["text_size"] = "Larger" if scale > 1 else "Normal"
			var phone: bool = shape.x != 1280
			fit(journal, phone); fit(options, phone)
			opener.grab_focus()
			journal.open(camp)
			await settle()
			var tag := "%d-%s" % [shape.x, "larger" if scale > 1 else "normal"]
			geometry(journal, "journal " + tag)
			check(journal._buttons.size() == 3 and not journal._buttons.has("three_knocks"), "Unknown hidden quest stays absent " + tag)
			check(journal._buttons.keys() == ["left_behind", "iron_sample", "queen_claim"], "Open before completed " + tag)
			await snap("journal-" + tag)
			await click(journal._buttons["iron_sample"], true)
			check(journal._selected_id == "iron_sample", "Touch selects quest " + tag)
			if journal._compact:
				check(journal._back.visible and journal._paper.visible and not journal._list_scroll.visible, "Compact detail " + tag)
				await snap("journal-detail-" + tag)
				await key(KEY_ESCAPE)
				check(journal.visible and journal._list_scroll.visible, "Compact Escape returns to list " + tag)
			await key(KEY_ESCAPE)
			check(not journal.visible and opener.has_focus(), "Journal Escape restores opener " + tag)
			options.open(); await settle()
			geometry(options, "settings " + tag)
			check(options._workspace.visible and not options._credits_scroll.visible, "Settings workspace " + tag)
			check(options._sizes["Larger" if scale > 1 else "Normal"].button_pressed, "Text-size choice matches preview " + tag)
			await snap("settings-" + tag)
			for widget: Control in options._sliders.values() + options._toggles.values() + options._sizes.values():
				widget.grab_focus()
				await settle()
				var scroll := widget.get_parent()
				while scroll and not scroll is ScrollContainer: scroll = scroll.get_parent()
				check(scroll != null and scroll.get_global_rect().encloses(widget.get_global_rect()), "Every setting reachable by focus " + tag + widget.name)
			for i in 14:
				var focused := root.gui_get_focus_owner()
				await key(KEY_TAB)
				check(options.is_ancestor_of(root.gui_get_focus_owner()), "Tab stays in modal " + tag)
				check(root.gui_get_focus_owner() != focused, "Tab advances focus " + tag)
			await click(options._credits, true)
			check(options._credits_scroll.visible and not options._workspace.visible, "Touch opens credits " + tag)
			await snap("credits-" + tag)
			await key(KEY_ESCAPE)
			check(options.visible and not options._credits_open, "Credits Escape returns " + tag)
			await key(KEY_ESCAPE)
			check(not options.visible and opener.has_focus(), "Settings Escape restores opener " + tag)
	check(JSON.stringify(camp.quests) == before, "Browsing never changes quest state")
	# Empty, newly discovered and completed entries share the real quest model.
	var empty := preload("res://scripts/camp_state.gd").new()
	journal.open(empty); await settle()
	check(journal._buttons.is_empty() and journal._selected_id.is_empty(), "Empty journal has no stale quest")
	await snap("journal-empty-phone")
	journal.finish()
	for id: String in QUESTS.INFO: QUESTS.set_stage(camp, id, QUESTS.Stage.ACTIVE)
	QUESTS.set_flag(camp, "left_behind", "found")
	journal.open(camp); await settle()
	check(journal._buttons.has("three_knocks"), "Discovered hidden quest appears")
	journal.select_quest("left_behind"); await settle()
	check(journal._detail.find_children("*", "Label", true, false).any(func(l): return l.text == "Report to Commander Vael at camp."), "Updated quest flag refreshes actual next step")
	journal._show_list(); await settle()
	journal._buttons["queen_claim"].grab_focus(); await settle()
	check(journal._list_scroll.scroll_vertical > 0, "Long quest list follows keyboard focus")
	await snap("journal-scrolled-phone")
	journal.finish()
	# Real controls apply/save immediately. The test settings file is restored below.
	root.size = Vector2i(1280, 720); root.content_scale_factor = 1
	Engine.get_meta("depths_settings")["text_size"] = "Normal"
	fit(options, false); options.open(); await settle()
	options._sliders["Music"].grab_focus()
	var previous: float = SETTINGS.get_value("Music")
	await key(KEY_LEFT)
	check(SETTINGS.get_value("Music") < previous, "Keyboard changes real volume")
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(SETTINGS.get_value("Music"))), "Volume applies to correct audio bus")
	await click(options._toggles["flashes"], true)
	check(not SETTINGS.get_value("flashes") and options._toggles["flashes"].text == "Off", "Touch toggles flashes and visible state")
	await click(options._sizes["Larger"])
	check(is_equal_approx(root.content_scale_factor, 1.3) and options._sizes["Larger"].has_focus(), "Text size applies without losing focus")
	geometry(options, "live text-size switch")
	var config := ConfigFile.new()
	check(config.load(SETTINGS.path()) == OK and config.get_value("settings", "text_size") == "Larger" and not config.get_value("settings", "flashes"), "Settings persist immediately")
	options.finish()
	Engine.remove_meta("depths_settings")
	Engine.remove_meta("depths_settings_loaded")
	options.open(); await settle()
	check(options._sizes["Larger"].button_pressed and options._toggles["flashes"].text == "Off", "Reopen reflects saved values")
	await click(options._close)
	check(not options.visible, "Mouse closes Settings")
	root.size = Vector2i(1000, 590)
	SETTINGS.set_value("text_size", "Normal", self)
	fit(options, true); options.open(); await settle()
	await click(options._sizes["Larger"])
	check(options._display_panel.get_parent() != options._display_scroll and options._sizes["Larger"].has_focus(), "Focus survives text-size breakpoint into one column")
	geometry(options, "one-column breakpoint")
	await snap("settings-breakpoint-larger")
	await click(options._sizes["Normal"])
	check(options._display_panel.get_parent() == options._display_scroll and options._sizes["Normal"].has_focus(), "Focus survives return to two columns")
	options.finish()
	if _had_test_settings:
		FileAccess.open(SETTINGS.path(), FileAccess.WRITE).store_buffer(_settings_before)
	else: DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS.path()))
	journal.free(); options.free(); opener.free(); camp = null; empty = null
	await settle()
	FileAccess.open(OUT + "godot-validation.json", FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "physical_iPhone": false, "test_settings_restored": true}, "\t") + "\n")
	print("JOURNAL_SETTINGS: checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
