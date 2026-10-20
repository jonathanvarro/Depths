extends SceneTree
## Full tutorial play-through after the second playtest (#69): solid bodies
## searched from beside, centred cards, the second web, chest with take /
## take-all, draught, the stumble and relight, the glancing spider (thrown
## at on the hint, or forced at low health), panic, sealed-off daylight.
## Args: tag, screenshot dir, seed, "force" (keep attacking the spider).

var fails := 0
var tag := "desk"
var S := ""
var main
var force := false
var hints_seen := {}
var cards_seen := {}
var lines := {}
var fights := 0
var _last_state = null
var throw_used := false
var lowest := 99
var health_at_throw := -1
var forced_seen := false
var snapped := {}
var paused_frames := 0
var dimmed := false


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(name: String) -> void:
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(S + "/op4_" + tag + "_" + name + ".png")


func _snap_once(name: String) -> void:
	if snapped.has(name):
		return
	snapped[name] = true
	await _snap(name)


func _tap(action: String) -> void:
	Input.action_press(action)
	for i in 2:
		await process_frame
	Input.action_release(action)
	await create_timer(0.5).timeout


func _press(node, label: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if b.text.begins_with(label) and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false


func _press_in_row(item_name: String, label: String) -> bool:
	for row in main._pack._list.get_children():
		var titles: Array = row.find_children("*", "Label", true, false).map(func(l): return l.text)
		if titles.any(func(t): return t.begins_with(item_name)):
			for b in row.find_children("*", "Button", true, false):
				if (b.text == label or b.text.begins_with(label + " ·")) and not b.disabled:
					b.pressed.emit()
					return true
	return false


func _watch() -> void:
	if main._hint_box.visible:
		hints_seen[main._hint] = main._hint_label.text
		if main._hint_mode != "":
			cards_seen[main._hint] = main._hint_mode
	if main._dialogue_box.modulate.a > 0.5:
		lines[main._dialogue_box._text.text] = true
	lowest = mini(lowest, main._party_state.members[0].health)
	if main._party.paused:
		paused_frames += 1
	if main._wound_overlay.material.get_shader_parameter("flash") > 0.4:
		_snap_once("flash")
	if main._wound_overlay.material.get_shader_parameter("dim") > 0.0:
		dimmed = true
		_snap_once("dim")


## Handles whatever the game is waiting on: cards, fights, events, pack
## steps. Returns once the party can walk.
func _settle() -> void:
	var guard := 0
	while guard < 900:
		guard += 1
		_watch()
		if main._results.visible:
			return
		if main._hint_mode == "ok":
			await _snap_once("card_" + main._hint)
			main._finish_hint()
			await process_frame
			continue
		if main._chest.visible:
			await _loot_chest()
			continue
		if main._in_combat:
			if main._combat._state != _last_state:
				_last_state = main._combat._state
				fights += 1
			if main._combat._actions.visible:
				var spider: bool = main._opening_fights_done == 2
				var throw_now: bool = main._combat.only_action == "throw" or (main._hint == "throw" and not force)
				if spider and main._combat.only_action == "throw":
					forced_seen = true
				if spider and throw_now and main._party_state.supplies.torch_lit():
					await _snap_once("throw")
					health_at_throw = main._party_state.members[0].health
					main._combat._show_items()
					await process_frame
					if _press(main._combat, "Throw torch"):
						throw_used = true
				else:
					main._combat._show_actions(true)
					_press(main._combat, "Attack")
		elif main._event_screen.visible:
			if not _press(main._event_screen, "Search them"):
				_press(main._event_screen, "Continue")
		elif main._prompt.visible:
			main._answer_prompt(true)
		elif main._hint_mode == "pack" and main._hint in ["equip", "drop", "light", "relight", "draught"]:
			await _do_pack_step()
		elif not main._party.locked and not main._party.paused:
			return
		await create_timer(0.1).timeout


func _do_pack_step() -> void:
	var key: String = main._hint
	await _snap_once("card_" + key)
	main._set_pack(true)
	await process_frame
	await _snap_once("pack_" + key)
	match key:
		"equip": _press_in_row(main._opening_weapon.display_name, "Equip")
		"drop": _press_in_row(main._starting_weapon.display_name, "Drop")
		"light", "relight": _press_in_row(main.TORCH.display_name, "Use")
		"draught": _press_in_row("Restorative draught", "Use")
	await process_frame
	if main._hint not in ["equip", "drop", "light", "relight", "draught"] or main._hint == key:
		main._set_pack(false)
	await process_frame


func _loot_chest() -> void:
	await _snap_once("chest")
	var chest = main._chest
	# Tap one item, then take the rest with the take-all icon.
	var tiles: Array = chest._chest_grid.get_children().filter(func(c): return c is Button)
	if not tiles.is_empty():
		tiles[0].pressed.emit()
		await process_frame
	check("tapping a chest item moves it to the pack", chest.contents.size() == main.OPENING_CHEST.size() - 1)
	chest._take_all.pressed.emit()
	await process_frame
	check("take-all empties the chest", chest.is_empty() and main._party_state.supplies.count(main.DRAUGHT) == 1)
	await _snap_once("chest_taken")
	chest.closed.emit()
	await create_timer(0.2).timeout


func _path_to(goal: Vector2i) -> Array:
	var path: Array = main._map.walking_path(main._party.cell, goal)
	if not path.is_empty():
		path.pop_front()
	return path


func _face(dir: int) -> void:
	var tries := 0
	while main._party.facing != dir:
		tries += 1
		if tries > 6:
			return
		await _tap("turn_right" if wrapi(dir - main._party.facing, 0, 4) <= 2 else "turn_left")
		_watch()


func _walk_to(goal: Vector2i) -> void:
	var guard := 0
	while main._party.cell != goal and guard < 60:
		guard += 1
		await _settle()
		if main._results.visible:
			return
		var path := _path_to(goal)
		if path.is_empty():
			return
		await _face(main.Party.DIRECTIONS.find(path[0] - main._party.cell))
		await _tap("move_forward")
	await _settle()


## Walks beside a solid cell and steps into it.
func _use_solid(cell: Vector2i) -> void:
	for d in main.Party.DIRECTIONS:
		var side: Vector2i = cell + d
		if main._map.is_passable(side) and not main._map.walking_path(main._party.cell, side).is_empty():
			await _walk_to(side)
			await _face(main.Party.DIRECTIONS.find(-d))
			await _tap("move_forward")
			await _settle()
			return


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0]
	S = args[1]
	force = args.size() > 3 and args[3] == "force"
	# Optional 5th arg: the starting hero to choose (#95), e.g. corin.
	if args.size() > 4:
		load("res://scripts/save_game.gd").set_new_game_hero("res://data/companions/%s.tres" % args[4])
	main = load("res://scenes/main.tscn").instantiate()
	main.floor_seed = int(args[2]) if args.size() > 2 else 11
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(3.0).timeout
	await _snap("waking")
	await create_timer(5.0).timeout
	var hero: Companion = main._party_state.members[0]
	var supplies = main._party_state.supplies
	check("starts at half health, bleeding, blood and dirt", hero.health == roundi(hero.max_health / 2.0) and hero.bleeding and "blood" in hero.appearance and "dirt" in hero.appearance, "%s %d/%d" % [hero.display_name, hero.health, hero.max_health])
	check("only Mara's card shows", main._cards.filter(func(c): return c.visible).size() == 1)
	check("starts with no supplies", supplies.items.filter(func(i): return supplies.count(i) > 0).is_empty())
	check("bodies and fire are solid", main._opening_body_cells().all(func(c): return main._map.solid.has(c)) and main._map.solid.has(main._opening_fire_cell()))
	await _snap("room")

	# Walking into the fire doesn't put her in it.
	var before: Vector2i = main._party.cell
	await _use_solid(main._opening_fire_cell())
	check("can't walk onto the fire", main._party.cell != main._opening_fire_cell())

	# Too dark to leave yet.
	var web: Vector2i = main._opening["web"]
	await _walk_to(web - Vector2i(1, 0))
	await _face(1)
	await _tap("move_forward")
	_watch()
	check("refuses to leave in the dark", main._party.cell == web - Vector2i(1, 0) and main._said.has("too_dark"))

	# Search both bodies from beside them.
	for body in main._opening_body_cells():
		await _use_solid(body)
		check("never stood on a body", main._party.cell != body)
	check("both bodies searched: 2 torches + sword", supplies.count(main.TORCH) + (1 if supplies.torch_lit() else 0) == 2 and (main._opening_weapon in supplies.gear or hero.weapon == main._opening_weapon))
	await _settle()  # equip / drop / light via pack cards
	check("sword equipped, broken weapon dropped, torch lit", hero.weapon == main._opening_weapon and main._starting_weapon not in supplies.gear and supplies.torch_lit())
	await _snap("torch_lit")
	# Out through the web first: the wandering below never re-enters the room.
	await _walk_to(web + Vector2i(1, 0))

	# Explore until daylight.
	var safety := 0
	var heading_out := false
	while safety < 1400 and not main._results.visible:
		safety += 1
		await _settle()
		if main._results.visible:
			break
		if main._opening_chest_cell != Vector2i(-1, -1) and not main._map.triggered.has(main._opening_chest_cell):
			await _snap_once("chest_in_view")
			await _use_solid(main._opening_chest_cell)
			continue
		if main._exit_cell != Vector2i(-1, -1):
			if not heading_out:
				heading_out = true
				await _snap("daylight")
				var reach: Dictionary = main._map.reachable_from(main._party.cell)
				check("daylight can't be avoided: the way is sealed off", reach.size() <= main.EXIT_DISTANCE.y + 2, "%d cells reachable" % reach.size())
			var path := _path_to(main._exit_cell)
			if path.is_empty():
				continue
			await _face(main.Party.DIRECTIONS.find(path[0] - main._party.cell))
			await _tap("move_forward")
			continue
		var f: int = main._party.facing
		var right := wrapi(f + 1, 0, 4)
		var left := wrapi(f - 1, 0, 4)
		var here: Vector2i = main._party.cell
		var room: Rect2i = main._opening["room"]
		var ok := func(c: Vector2i) -> bool: return main._map.is_passable(c) and not room.has_point(c)
		if ok.call(here + main.Party.DIRECTIONS[right]):
			await _face(right)
		elif ok.call(here + main.Party.DIRECTIONS[f]):
			pass
		elif ok.call(here + main.Party.DIRECTIONS[left]):
			await _face(left)
		else:
			await _face(wrapi(f + 2, 0, 4))
		await _tap("move_forward")
		_watch()
	await _settle()
	print("  hints: ", hints_seen.keys())
	print("  cards: ", cards_seen)
	print("  fights: %d  steps: %d  web2 at %d  threw: %s at %d health  lowest: %d  forced: %s" % [fights, main._steps_taken, main._web2_at, throw_used, health_at_throw, lowest, forced_seen])
	print("  Mara said: ", lines.size(), " lines; situations: ", main._said.keys())
	check("broke the second web before any fight", main._web2_at > 0)
	check("chest card when it came into view", cards_seen.has("chest_find") and main._said.has("chest_seen"))
	check("chest found and looted", main._chest_looted and main._map.triggered.has(main._opening_chest_cell))
	check("draught drunk", main._hints_done.has("draught"))
	check("tripped and relit the spare", main._tripped and main._hints_done.has("relight"))
	check("threw the torch at the spider", throw_used)
	if force:
		check("forced throw at low health", forced_seen and health_at_throw <= main.FORCE_THROW_HEALTH, "%d" % health_at_throw)
	check("darkness started the panic", main._panic_started and cards_seen.get("panic") == "ok")
	check("cards were centred pauses", cards_seen.get("bleeding") == "ok" and cards_seen.get("fight") == "ok" and cards_seen.get("equip") == "pack" and paused_frames > 0)
	check("exactly 3 fights", fights == 3)
	check("never below 2 health", lowest >= 2)
	check("each bleed tick flashed and thumped (#71)", main._bleed_ticks > 0 and main._said.has("bleeding"), "%d ticks" % main._bleed_ticks)
	check("edges darkened at low health while bleeding", dimmed)
	check("the darkening cleared once bleeding stopped", main._wound_overlay.material.get_shader_parameter("dim") == 0.0)
	check("Barely survived", main._results.visible and main._results._title.text == "Barely survived")
	await _snap("survived")
	_press(main._results, "To camp")
	await create_timer(0.2).timeout
	# The commander waits outside (#122): answer, then on to camp.
	check("the commander meets the survivor", main._conversation.visible and main._conversation._name.text.contains("Vael"))
	await _snap("commander")
	main._conversation.choose("\"We were ambushed")
	for i in 6:
		await process_frame
		if not main._conversation.visible:
			break
		main._conversation.choose("")  # "Go on" / "I'll find them"
	await create_timer(0.2).timeout
	check("his order becomes the first quest", main.Quests.is_active(main._camp_state, "left_behind") and main.Quests.has_flag(main._camp_state, "story", "told_ambush"))
	check("the camp follows the escape", main._camp.visible)
	await _snap("camp")
	main._camp._buttons["cave"].pressed.emit()
	await process_frame
	_press(main._camp, "Head back down")
	await create_timer(0.2).timeout
	_press(main._preparation, "Enter the cave")
	await create_timer(0.3).timeout
	check("camp: torches not a lantern, restocked, all three slots, not bleeding", not supplies.has_lantern and supplies.torch_lit() and supplies.count(main.TORCH) == 3 and main._cards.all(func(c): return c.visible) and not hero.bleeding)
	check("keeps the companion's weapon", hero.weapon == main._opening_weapon)
	print("fails=", fails)
	quit()
