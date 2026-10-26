extends SceneTree
## Worsening condition while exploring (#64): the first time nerves, hunger,
## an injury or the light gets worse, a tip says what it does and what
## helps; tapping a hero's card reads out every condition in words, so touch
## isn't left with hover-only icons. Args: tag ("desk" or "phone"), dir.

const Settings := preload("res://scripts/settings.gd")
const Supplies := preload("res://scripts/supplies.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _clear(main) -> void:
	while main._hint_mode == "ok":
		main._finish_hint()


func _tap(card) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	card._gui_input(click)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	Engine.set_meta("depths_tips", true)
	Settings.set_value("tips_seen", [])
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	var mara: Companion = main._party_state.members[0]
	var card = main._cards[0]
	mara.strain = 0.0
	mara.hunger = 0
	mara.emit_changed()
	await process_frame
	_clear(main)
	Settings.set_value("tips_seen", [])

	_tap(card)
	check("a steady, unhurt hero's card says so", main._message_label.text == "Mara is steady and unhurt.", main._message_label.text)

	# Nerves.
	mara.strain = 55.0
	mara.emit_changed()
	await process_frame
	check("frayed nerves are explained the first time", main._hint == "tip_nerves" and main._hint_text.contains("Light, food and rest"), main._hint)
	_clear(main)
	mara.strain = 80.0
	mara.emit_changed()
	check("...once", main._hint == "")

	# Hunger.
	mara.hunger = 90
	mara.emit_changed()
	check("hunger is explained, with its remedy", main._hint == "tip_hunger" and main._hint_text.contains("ration"), main._hint)
	_clear(main)

	# An injury: its own effect and remedy.
	mara.add_injury(load("res://data/injuries/limp.tres"))
	check("a first injury explains itself", main._hint == "tip_injury" and main._hint_text.contains("2 fewer slots"), main._hint_text)
	_clear(main)

	# The light failing.
	main._on_light_band_changed(Supplies.Light.DIM)
	check("failing light says what it does and what helps", main._hint == "tip_dark" and main._hint_text.contains("oil"), main._hint)
	_clear(main)

	# The card, tapped: everything in words.
	await process_frame
	_tap(card)
	var words: String = main._message_label.text
	check("a tap reads the card out: nerves, hunger, the limp", words.contains("Panicking: fights at") and words.contains("Hungry") and words.contains("Limp: Each step"), words)
	if dir != "":
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png("%s/condition_%s.png" % [dir, tag])
	# Now and then, a hero says what the party needs (owner playtest).
	main._on_light_band_changed(Supplies.Light.STEADY)
	main._party_state.supplies.oil = 80.0
	mara.strain = 0.0
	mara.injuries.clear()
	mara.health = mara.effective_max_health()
	mara.hunger = 120
	main._last_spoke_at = -100.0
	main._banter_steps = main.BANTER_EVERY - 1
	main._on_party_entered_cell(main._party.cell)
	var hunger_lines: PackedStringArray = mara.dialogue.lines.get("need_hunger", PackedStringArray())
	check("a hungry hero says so, now and then", main._last_line in hunger_lines, main._last_line)
	main._last_spoke_at = -100.0
	main._on_party_entered_cell(main._party.cell)
	check("...but not every step", main._banter_steps == 1)
	# Right-click a pack item to use it (owner playtest).
	var ration: SupplyItem = load("res://data/items/ration.tres")
	main._party_state.supplies.add(ration, 1)
	mara.hunger = 120
	main._set_pack(true)
	await process_frame
	var rations: int = main._party_state.supplies.count(ration)
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	var clicked := false
	for b in main._pack.find_children("*", "Button", true, false):
		if not clicked and b.has_meta("item") and b.get_meta("item") == ration:
			b.gui_input.emit(right)
			clicked = true
	if not clicked:
		main._pack._quick_use(ration)
	check("right-clicking a ration eats it", clicked and main._party_state.supplies.count(ration) == rations - 1, "%d -> %d (button found: %s)" % [rations, main._party_state.supplies.count(ration), clicked])
	main._set_pack(false)
	# With light, the map shows one tile further - but not through rock.
	var map = main._map
	var here: Vector2i = main._party.cell
	map.explored.clear()
	map.reveal_around(here, false)
	var dark_seen: int = map.explored.size()
	map.explored.clear()
	map.reveal_around(here, true)
	var behind_rock: Array = map.explored.keys().filter(func(c): return maxi(absi(c.x - here.x), absi(c.y - here.y)) == 2 and not [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)].any(func(d): return map.is_passable(here + d) and maxi(absi(c.x - here.x - d.x), absi(c.y - here.y - d.y)) <= 1))
	check("lit, the map shows one tile further", map.explored.size() > dark_seen, "%d vs %d" % [map.explored.size(), dark_seen])
	check("...never through rock", behind_rock.is_empty(), str(behind_rock))
	Settings.set_value("tips_seen", [])
	print("fails=", fails)
	quit()
