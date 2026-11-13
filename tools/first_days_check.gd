extends SceneTree
## Owner playtest fixes for camp and screens (#227, #229): the merchant,
## nurse and smith arrive on day 3; a guide points at the fire, then the
## mine path; the Pack opens at camp; trades show sale prices, hover text
## and sell on a right-click; the results and expedition screens are
## centred. Args: tag, screenshot dir.

var fails := 0
var main
var dir := ""
var tag := "desk"


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _snap(name: String) -> void:
	if dir == "":
		return
	for i in 10:
		await process_frame
	var shot := root.get_texture().get_image()
	if shot:
		shot.save_png("%s/first_days_%s_%s.png" % [dir, tag, name])


## How far a control's centre sits from the screen's, as a share of the width.
func _off_centre(control: Control) -> float:
	var width: float = root.get_visible_rect().size.x
	return absf(control.get_global_rect().get_center().x - width / 2.0) / width


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""
	main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	var camp = main._camp_state
	var party = main._party_state
	camp.begin_arrivals()  # a new story's camp, as after the opening

	# The opening's short ending: centred.
	main._results.show_brief("Barely survived", "You stagger out into the daylight, alone.", "To camp")
	await process_frame
	await process_frame
	check("a short ending sits mid-screen, its button too (#227)", _off_centre(main._results._title) < 0.05 and _off_centre(main._results._button) < 0.05)
	await _snap("brief")
	main._results.visible = false

	# Day 1 at camp.
	main._end_expedition(main.Expedition.Ending.RETURNED)
	await process_frame
	check("a trip's results: centred too", _off_centre(main._results._button) < 0.05 and _off_centre(main._results._title) < 0.05)
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout
	var screen = main._camp
	check("day 1: no merchant, nurse or smith yet (#229)", camp.day == 1 and not camp.site_present("supplies") and not camp.site_present("treatment") and not camp.site_present("smith"))
	check("...and their places can't be opened", not screen._buttons.supplies.visible and not screen._buttons.treatment.visible and not screen._buttons.smith.visible)
	check("first, the guide points at your tent (#235)", screen.guide_target() == "rest" and screen._guide.visible and screen._guide.text.contains("Start here"))
	await _snap("day1_tent")
	screen.open_activity("rest")
	screen._close_activity()
	check("then, alone, at the fire", screen.guide_target() == "fire" and screen._guide.visible and screen._guide.text.contains("company"))
	await _snap("day1_fire")
	camp.hire(party, camp.candidates[0])
	screen._refresh_activity()
	screen._close_activity()
	check("with a companion: the guide points into the mine", screen.guide_target() == "cave" and screen._guide.text.contains("mine"))
	await _snap("day1_mine")

	# The Pack at camp.
	screen._pack_button.pressed.emit()
	await process_frame
	check("the Pack opens at camp (#229)", main._pack.visible and main._pack.get_index() > screen.get_index())
	await _snap("pack")
	main._set_pack(false)
	screen.open_activity("rest")
	await process_frame
	main._set_pack(true)
	check("...but not over a place's own screen", not main._pack.visible)
	screen._close_activity()

	# Days 2 and 3.
	camp.rest(party)
	check("day 2: still no traders", camp.day == 2 and not camp.site_present("supplies") and not camp.site_present("treatment"))
	camp.explored_today = true
	screen._update_site_art()
	check("after going down today, no guide", not screen._guide.visible)
	camp.rest(party)
	screen._update_site_art()
	check("day 3: only the smith arrives by day", not camp.site_present("treatment") and camp.site_present("smith") and not camp.site_present("supplies"))
	check("...and the guide is gone", screen.guide_target() == "" and not screen._guide.visible)

	# The first order: floor 1's way down waits for the report (#237).
	var Story = load("res://scripts/story.gd")
	main.Quests.set_stage(camp, "left_behind", main.Quests.Stage.ACTIVE)
	check("floor 2 is shut while the first order is unreported (#237)", not Story.way_down_open(camp, 1) and Story.way_down_open(camp, 2))
	main.Quests.set_flag(camp, "left_behind", "found")
	Story.after_talk(camp, "commander_report")
	screen._update_site_art()
	check("the report opens it, and brings the merchant, unloading", Story.way_down_open(camp, 1) and camp.site_present("supplies") and camp.merchant_unloading and not camp.can_trade())
	check("...he has news at his stall", Story.camp_talk(camp, "supplies") == "merchant_arrival")

	# His arrival: he introduces himself, then the stall opens.
	var gear: Equipment = load("res://data/gear/iron_sword.tres").duplicate()
	party.supplies.gear.append(gear)
	screen.open_activity("supplies")
	await process_frame
	check("walking up to him plays his arrival", main._conversation.visible and main._conversation._talk.speaker == "The merchant")
	await _snap("merchant_arrival")
	for i in 8:
		if not main._conversation.visible:
			break
		main._conversation.choose("")
		await process_frame
	await create_timer(0.5).timeout
	check("...after which he trades", camp.can_trade() and main.Quests.has_flag(camp, "story", "merchant_met") and screen._merchant_view.visible)
	var merchant = screen._merchant_view
	var tile: Button = null
	for slot: Button in merchant._bag.slots:
		if slot.has_meta("item") and slot.get_meta("item") == gear:
			tile = slot
	var price: int = main.CampState.sell_price(party, gear)
	check("a pack item shows what it sells for (#229)", tile != null and tile.find_children("*", "Label", true, false).any(func(l): return l.text == str(price)), price)
	check("...and hovering says what it is and what it fetches", tile != null and tile.tooltip_text.contains(gear.display_name) and tile.tooltip_text.contains("Sells for %d" % price) and tile.tooltip_text.contains("Right-click"))
	await _snap("merchant")
	var gold: int = party.supplies.gold
	if tile:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_RIGHT
		click.pressed = true
		tile.gui_input.emit(click)
	await process_frame
	check("a right-click sells it", gear not in party.supplies.gear and party.supplies.gold == gold + price, party.supplies.gold - gold)
	screen._close_activity()

	# The expedition screen: centred.
	main._preparation.show_for(2, party)
	await process_frame
	await process_frame
	check("the expedition screen's title and button are centred (#227)", _off_centre(main._preparation._title) < 0.05 and _off_centre(main._preparation._enter) < 0.05)
	await _snap("expedition")
	print("fails=", fails)
	quit()
