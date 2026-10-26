extends SceneTree
## The first campsite pass (#40): arrive after an expedition, use every
## place, rest through the days, and head back into a re-randomized cave.
## Args: tag ("desk" or "phone"), screenshot dir.

var fails := 0
var tag := "desk"
var S := ""
var main


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(name: String) -> void:
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(S + "/camp_" + tag + "_" + name + ".png")


func _press(node, label: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if b.text.begins_with(label) and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false


## In the stash: picks the first item on `side` ("left" stash, "right" pack)
## and presses its action.
func _stash_move(side: String, action: String) -> bool:
	var view = main._camp._stash_view
	for b in view.find_children("*", "Button", true, false):
		if b.has_meta("exchange_side") and b.get_meta("exchange_side") == side and b.get_meta("item") is SupplyItem and b.is_visible_in_tree():
			b.pressed.emit()
			return _press(view, action)
	return false


func _body_text() -> String:
	return " | ".join(main._camp._body.find_children("*", "Label", true, false).map(func(l): return l.text))


func _open(id: String) -> void:
	main._camp._close_activity()
	main._camp._buttons[id].pressed.emit()
	await process_frame


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0]
	S = args[1]
	main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	var hero: Companion = main._party_state.members[0]
	var supplies = main._party_state.supplies
	var ration: SupplyItem = load("res://data/items/ration.tres")
	var wound: Injury = load("res://data/injuries/deep_wound.tres")
	hero.add_injury(wound)
	hero.health = 6
	hero.strain = 60.0
	supplies.take(ration)
	supplies.take(ration)
	var day1_layout: PackedStringArray = main._map._rows

	main._end_expedition(main.Expedition.Ending.RETURNED)
	await process_frame
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout
	check("after the results comes the camp", main._camp.visible and main._camp_state.day == 1)
	check("arriving heals nothing by itself", hero.health == 6 and wound in hero.injuries)
	check("six labelled places", main._camp._buttons.size() == 6 and main._camp._buttons.values().all(func(b): return b.text != "" and b.size.x >= 44 and b.size.y >= 44))
	await _snap("clearing")
	check("keyboard focus starts on a place", main._camp._buttons.values().any(func(b): return b.has_focus()))

	# Merchant: tops up to the starting supplies, once a day.
	await _open("supplies")
	check("merchant view with his portrait", main._camp.is_open("supplies") and main._camp._merchant_view._portrait.texture != null and main._camp._merchant_view.visible)
	await _snap("merchant")
	supplies.gold = 8
	main._camp._refresh_activity()
	var merchant=main._camp._merchant_view
	merchant.select_item(ration,"left")
	merchant._primary.pressed.emit()
	merchant._primary.pressed.emit()
	check("buy rations back for 4g each", supplies.count(ration) == 2 and supplies.gold == 0)

	# Escape goes back to the clearing.
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	await process_frame
	await process_frame
	check("Escape clears merchant inspection first", main._camp._current == "supplies" and merchant._key == null)
	Input.parse_input_event(esc)
	await process_frame
	await process_frame
	check("Escape returns to the clearing", main._camp._current == "" and main._camp._buttons["supplies"].visible)

	# Smith: stock shown, nothing for sale yet.
	await _open("smith")
	check("smith sells plain gear; shield and coat still coming", _body_text().contains(load("res://data/gear/plain_knife.tres").display_name) and _body_text().contains("Coming once"))

	# Nurse: treatment takes Mara out for the wound's days.
	await _open("treatment")
	await _snap("nurse")
	check("treatment warns no one else is fit", _body_text().contains("no one else is fit"))
	check("nurse offers treatment with its ready day", _press(main._camp, "Treat Mara (back on day 3)"))
	check("treated: no injury, recovering until day 3", hero.injuries.is_empty() and main._camp_state.is_recovering(hero) and main._camp_state.ready_on(hero) == 3)

	# Cave path: no one fit.
	await _open("cave")
	await _snap("cave_blocked")
	check("cave path: no one fit, no way down", _body_text().contains("No one is fit") and not _press(main._camp, "Head back down"))

	# Tent: rest (day 2), stash.
	await _open("rest")
	check("rest says injuries need the nurse", _body_text().contains("Injuries need the nurse"))
	var seed_before: int = main._site_seed
	check("a Rest button, without a day count (owner, 2026-10-25)", _press(main._camp, "Rest"))
	check("rest: day 2, full health, calm", main._camp_state.day == 2 and hero.health == hero.effective_max_health() and hero.strain == 0.0)
	check("a new day re-seeds the cave", main._site_seed != seed_before and main._floors.is_empty())
	check("a new contract is posted on the new day", main._camp_state.contract.has("enemy"))
	var stash_total := func() -> int:
		var n: int = main._camp_state.stash.gear.size()
		for item in main._camp_state.stash.items:
			n += main._camp_state.stash.count(item)
		return n
	await _snap("tent")
	check("Store opens the stash, beside the pack", _press(main._camp, "Store") and main._camp._stash_view.visible and not main._camp._activity.visible)
	await process_frame
	check("store an item in the stash", _stash_move("right", "Store") and stash_total.call() == 1)
	await _snap("stash")
	check("take it back", _stash_move("left", "Take") and stash_total.call() == 0)
	main._camp._stash_view.closed.emit()
	await process_frame
	check("closing the stash returns to the tent", main._camp._activity.visible and not main._camp._stash_view.visible)
	check("still recovering on day 2", main._camp_state.is_recovering(hero))
	_press(main._camp, "Rest")
	check("fit again on day 3", main._camp_state.day == 3 and not main._camp_state.is_recovering(hero))

	await _open("fire")
	check("recruits wait by the fire", _body_text().contains("by the fire") and main._camp_state.candidates.size() == 3)

	# Cave path -> preparation -> a new cave.
	await _open("cave")
	check("the cave path names who goes, briefly", _body_text().contains("Going: Mara"))
	check("head back down", _press(main._camp, "Head back down"))
	await create_timer(0.2).timeout
	check("preparation follows the cave path", not main._camp.visible and main._preparation.visible)
	_press(main._preparation, "Enter the mine")
	await create_timer(0.4).timeout
	check("back in the cave on floor 1", main._depth == 1 and not main._party.locked)
	check("a different cave on day 3", main._map._rows != day1_layout)
	check("the message names the day", main._message_label.text.begins_with("Day 3"), main._message_label.text)
	print("fails=", fails)
	quit()
