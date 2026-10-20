extends SceneTree
## Unconscious main heroes (#83), the secured route (#79), visible room
## contents (#46) and Settings (#52). Args: tag, screenshot dir.

const Settings := preload("res://scripts/settings.gd")

var fails := 0
var main
var dir := ""
var tag := "desk"


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _press(node, label: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		# Icon buttons (the Pack's gear) are found by their tooltip.
		var named: bool = b.text.begins_with(label) or (b.text == "" and b.tooltip_text == label)
		if named and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false


func _snap(name: String) -> void:
	if dir == "":
		return
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(dir + "/batch_" + tag + "_" + name + ".png")


func _body_text() -> String:
	return " | ".join(main._camp._body.find_children("*", "Label", true, false).map(func(l): return l.text))


func _to_camp() -> void:
	main._end_expedition(main.Expedition.Ending.RETURNED)
	await process_frame
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout


func _head_down(label := "Head back down") -> void:
	main._camp._close_activity()
	main._camp._buttons["cave"].pressed.emit()
	await process_frame
	_press(main._camp, label)
	await create_timer(0.2).timeout
	_press(main._preparation, "Enter the cave")
	await create_timer(0.3).timeout


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""
	main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	var mara: Companion = ps.members[0]
	var camp = main._camp_state

	# --- #46: room contents are visible, traps and enemies aren't.
	var shown := 0
	var traps_shown := 0
	for cell in main._map.events:
		if main._props.has(cell):
			shown += 1
			if main._map.events[cell].kind == main.DungeonMap.Content.TRAP:
				traps_shown += 1
	check("room contents stand in their rooms", shown > 0, "%d props" % shown)
	check("traps stay hidden", traps_shown == 0)
	var box: RoomEvent = load("res://data/events/chest_strongbox.tres")
	var cell: Vector2i = main._party.cell + main.Party.DIRECTIONS[main._party.facing]
	main._map.events[cell] = box
	main._map.contents[cell] = main.DungeonMap.Content.CHEST
	main._build_level()
	check("a chest shows closed", main._props.has(cell) and main._props[cell].get("state") == "closed")
	await _snap("chest")
	main._map.enter(cell)
	main._run_event(cell)
	await process_frame
	main._event_screen.coin = null  # no coin overlay in this quick check
	_press(main._event_screen, "Force the lid")
	await process_frame
	_press(main._event_screen, "Continue")
	await process_frame
	check("an emptied chest shows empty", main._props[cell].get("state") == "empty")

	# --- #83: Mara falls unconscious, not dead.
	var recruit: Companion = camp.candidates[0]
	camp.hire(ps, recruit)
	var CS = load("res://scripts/combat_state.gd")
	var c = CS.new(ps, [load("res://data/enemies/goblin.tres")] as Array[EnemyType])
	mara.health = 1
	var g = c.foes[0]
	g.intent = CS.Intent.KILLING_BLOW
	g.marked = mara
	c.coin = 0
	var out: Dictionary = c.enemy_act(g)
	check("a main hero collapses unconscious", mara.is_unconscious() and out["text"].contains("unconscious"), out["text"])
	check("the fight goes on with the others", c.result == CS.Result.ONGOING)
	main._refresh_cards()
	check("her card says unconscious", main._cards[0]._icons.get_children().any(func(i): return i.tooltip_text.begins_with("Unconscious")))
	check("a draught goes to her first", ps.most_hurt() == mara)
	ps.supplies.add(load("res://data/items/restorative_draught.tres"))
	ps.use_item(load("res://data/items/restorative_draught.tres"))
	ps.advance_time(3)
	check("a draught revives her", mara.is_alive())
	mara.health = 0
	ps.rest()
	check("a rest revives her too", mara.is_alive())
	# A full wipe: she wakes at camp, hurt; the recruit is lost.
	mara.health = 0
	ps.members[1].min_health = 0
	ps.members[1].change_health(-999)
	await create_timer(0.3).timeout
	if main._results.visible:
		main._results.continue_pressed.emit()
	await create_timer(0.3).timeout
	check("after a wipe she wakes at camp, injured", main._camp.visible and ps.members.size() == 1 and ps.members[0] == mara and mara.is_alive() and not mara.injuries.is_empty())

	# --- #79: the secured route after two trips to floor 2.
	await _head_down()
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await _to_camp()
	check("one trip to floor 2 counted", camp.floor2_reached == 1)
	main._camp._buttons["cave"].pressed.emit()
	await process_frame
	check("the route isn't offered yet", not _body_text().contains("Secured route") and _body_text().contains("(1 of 2)"))
	await _head_down()
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await _to_camp()
	ps.supplies.gold = 45
	main._camp._close_activity()
	main._camp._buttons["cave"].pressed.emit()
	await process_frame
	await _snap("route")
	check("after two trips the route is offered", _body_text().contains("scouts") or main._camp._body.find_children("*", "Button", true, false).any(func(b): return b.text.begins_with("Secured route")))
	await _head_down("Secured route")
	check("it costs 40g and starts on floor 2", ps.supplies.gold == 5 and main._depth == 2, "gold %d depth %d" % [ps.supplies.gold, main._depth])

	# --- #52: Settings from the Pack.
	main._set_pack(true)
	await process_frame
	check("Settings opens from the Pack", _press(main._pack, "Settings") and main._settings.visible)
	await _snap("settings")
	Settings.set_value("Music", 0.3, self)
	var music := AudioServer.get_bus_index("Music")
	check("music volume applies to its own bus", music != -1 and absf(AudioServer.get_bus_volume_db(music) - linear_to_db(0.3)) < 0.1)
	check("the ambience plays on the music bus", main._ambience_player.bus == "Music")
	Settings.set_value("text_size", "Large", self)
	check("text size scales the interface", is_equal_approx(root.content_scale_factor, 1.15))
	Settings.set_value("text_size", "Normal", self)
	Settings.set_value("flashes", false, self)
	main._wound_overlay.material.set_shader_parameter("flash", 0.0)
	main._bleed_pulse(mara)
	await process_frame
	check("screen flashes can be turned off", main._wound_overlay.material.get_shader_parameter("flash") == 0.0)
	Settings.set_value("flashes", true, self)
	Settings.set_value("Music", 0.8, self)
	check("settings are saved to a file", FileAccess.file_exists(Settings.path()))
	print("fails=", fails)
	quit()
