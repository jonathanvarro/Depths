extends SceneTree
## Shrines, boons and banes, and items that open event choices (#133, owner
## 2026-10-21): the pack has limited space; a pick, spade, holy water or an
## antidote opens a better choice (greyed "needs ..." without it); boons
## and banes change a hero for some fights or until camp, show on the card,
## and the nurse lifts a bane for a price. Args: tag, screenshot dir.

const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0
var dir := ""
var tag := "desk"


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _item(id: String) -> SupplyItem:
	return load("res://data/items/%s.tres" % id)


func _boon(id: String) -> Boon:
	return load("res://data/boons/%s.tres" % id)


func _event(id: String) -> RoomEvent:
	return load("res://data/events/%s.tres" % id)


func _choice(event: RoomEvent, label: String) -> EventChoice:
	for choice in event.choices:
		if choice.label.begins_with(label):
			return choice
	return null


func _snap(name: String) -> void:
	if dir == "":
		return
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(dir + "/boons_" + tag + "_" + name + ".png")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0] if args.size() > 0 else "desk"
	dir = args[1] if args.size() > 1 else ""
	var PartyState = load("res://scripts/party_state.gd")
	var RoomEvents = load("res://scripts/room_events.gd")
	var CampState = load("res://scripts/camp_state.gd")
	var ration := _item("ration")
	var torch := _item("torch")
	var spade := _item("spade")
	var pick := _item("pick")
	var holy := _item("holy_water")
	var antidote := _item("antidote")
	var goblet := _item("silver_goblet")

	# --- The pack's space.
	var party = PartyState.new()
	party.add_member(load("res://data/companions/mara.tres"))
	var supplies = party.supplies
	check("a lone hero's pack has 8 slots", supplies.capacity == 8, supplies.capacity)
	supplies.add(ration, 6)
	check("rations stack five to a slot", supplies.slots_used() == 2)
	supplies.add(spade)
	supplies.add(goblet, 4)
	check("a tool fills a slot; treasure stacks three", supplies.slots_used() == 5, supplies.slots_used())
	check("room for 4 more rations: the open stack, nothing else... plus free slots", supplies.room_for(ration) == 4 + 3 * 5, supplies.room_for(ration))
	check("only fits what there's room for", supplies.add_what_fits(torch, 99) == 15 and supplies.slots_used() == 8)
	check("a full pack has no room for gear", not supplies.has_room_for_gear())
	supplies.drop(torch, 5)
	check("dropping a stack frees a slot", supplies.slots_used() == 7)
	var stash = load("res://scripts/supplies.gd").new()
	stash.add(torch, 500)
	check("the camp stash has no limit", stash.room_for(torch) > 1000)
	var two = PartyState.new()
	for hero in ["mara", "corin", "alwen"]:
		two.add_member(load("res://data/companions/%s.tres" % hero))
	check("three heroes carry 12 slots", two.supplies.capacity == 12)
	two.remove_member(two.members[2])
	check("two carry 8", two.supplies.capacity == 8)

	# --- Choices that need something.
	party = PartyState.new()
	party.add_member(load("res://data/companions/mara.tres"))
	var rules = RoomEvents.new()
	var shrine := _event("object_defiled_shrine")
	var bless := _choice(shrine, "Bless it")
	check("without holy water, blessing shows what it needs", bless.missing(party) == "needs holy water", bless.missing(party))
	party.supplies.add(holy)
	check("with it, the choice is open", bless.missing(party) == "")
	rules.resolve(party, bless)
	var mara: Companion = party.members[0]
	check("holy water is used up", party.supplies.count(holy) == 0)
	check("blessed: +1 damage", mara.boons.size() == 1 and mara.attack_range() == _range_without(mara) + Vector2i.ONE, str(mara.attack_range()))
	party.supplies.add(pick)
	var smash := _choice(shrine, "Smash")
	rules.resolve(party, smash)
	check("a tool is kept", party.supplies.count(pick) == 1)

	# The cache's pick reward, from the file on disk (#137): treasure and ore.
	var digger = PartyState.new()
	digger.add_member(load("res://data/companions/mara.tres"))
	digger.supplies.add(pick)
	RoomEvents.new().resolve(digger, _choice(_event("chest_buried_cache"), "Break the rock"))
	check("breaking the cache with a pick finds the ore it promises (#137)", digger.supplies.count(_item("copper_ore")) == 1)

	# --- Boons and banes.
	mara.boons.clear()
	var aim := mara.hit_accuracy()
	mara.add_boon(_boon("miners_luck"))
	check("miners' luck: +8% to hit", is_equal_approx(mara.hit_accuracy(), aim + 0.08))
	for i in 2:
		mara.fight_ended()
	check("...still there after two fights", mara.boons.size() == 1 and mara.boons[0]["fights_left"] == 1)
	mara.fight_ended()
	check("...gone after the third", mara.boons.is_empty())
	mara.add_boon(_boon("quiet_heart"))
	mara.strain = 10.0
	var calm_before := mara.strain
	mara.change_strain(10.0)
	var calm_gain := mara.strain - calm_before
	mara.boons.clear()
	mara.strain = 10.0
	mara.change_strain(10.0)
	check("quiet heart: nerves fray half as fast", is_equal_approx(calm_gain * 2.0, mara.strain - 10.0), "%.2f vs %.2f" % [calm_gain, mara.strain - 10.0])
	mara.add_boon(_boon("quiet_heart"))
	mara.add_boon(_boon("withering"))
	check("withering: 4 less maximum health", mara.effective_max_health() == mara.max_health - 4)
	mara.trip_ended()
	check("back at camp, trip-long boons end; fight-long banes stay", mara.boons.size() == 1 and mara.boons[0]["boon"] == _boon("withering"))
	# Saved and loaded.
	var copy := Companion.new()
	SaveGame.unpack_into(copy, SaveGame.pack_object(mara))
	check("boons survive a save", copy.boons.size() == 1 and copy.boons[0]["boon"].display_name == "Withering" and copy.boons[0]["fights_left"] == 3)
	# Lifting.
	party.supplies.add(holy)
	check("holy water can be used on a bane", party.cannot_use_reason(holy) == "")
	party.use_item(holy)
	check("...and lifts it", not mara.has_bane())
	mara.add_boon(_boon("withering"))
	var camp = CampState.new()
	party.supplies.gold = 25
	check("the nurse lifts a bane for 20 gold", camp.lift_bane(party, mara) != null and not mara.has_bane() and party.supplies.gold == 5)
	# Party-wide effects.
	mara.add_boon(_boon("lamp_blessing"))
	check("lamp blessing: the lantern burns slower", is_equal_approx(party.oil_rate(), 0.75))
	mara.add_boon(_boon("deep_eyes"))
	check("deep eyes: traps show", party.sees_traps())
	mara.boons.clear()
	mara.add_boon(_boon("marked"))
	var test_choice := EventChoice.new()
	var ambush_outcome := EventOutcome.new()
	ambush_outcome.ambush.assign([load("res://data/enemies/rat.tres")])
	test_choice.outcomes.assign([EventOutcome.new(), ambush_outcome])
	var ambushes := 0
	for i in 600:
		if rules._pick_outcome(test_choice, [], true) == ambush_outcome:
			ambushes += 1
	check("marked: ambushes come about twice as often", ambushes > 340 and ambushes < 460, ambushes)
	mara.boons.clear()
	mara.add_boon(_boon("hearty"))
	mara.add_effect_over_time("health", 10, 10)
	check("hearty: healing does half again as much", mara.pending_effects[-1]["per_unit"] * 10 == 15.0)

	# --- In the game: the event screen, the cards, the pack, a passage.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	var lead: Companion = main._party_state.members[0]
	lead.add_boon(_boon("blessed"))
	lead.add_boon(_boon("sickness"))
	await process_frame
	var tips: Array = main._cards[0]._icons.get_children().map(func(c): return c.tooltip_text)
	check("the card shows boons and banes with what they do", tips.any(func(t): return t.begins_with("Blessed (3 fights left)")) and tips.any(func(t): return t.begins_with("Sickness (until camp)")), str(tips))
	main._event_screen.show_event(_event("object_defiled_shrine"), main._party_state, main._room_events)
	await process_frame
	var buttons: Array = main._event_screen._buttons.get_children()
	var greyed: Array = buttons.filter(func(b): return b.disabled)
	check("choices you can't take show greyed, saying what they need", greyed.size() == 2 and greyed.all(func(b): return b.text.contains("needs")), str(buttons.map(func(b): return b.text)))
	await _snap("shrine")
	main._event_screen._finish({"left": true, "ambush": [] as Array[EnemyType]})
	# The pack shows its space and lets you drop things.
	main._party_state.supplies.add(spade)
	main._set_pack(true)
	await process_frame
	var labels: Array = main._pack._list.find_children("*", "Label", true, false).map(func(l): return l.text)
	check("the pack shows its space", labels.any(func(t): return t.begins_with("Pack space:")), str(labels.slice(0, 3)))
	check("supplies can be dropped", main._pack._list.find_children("*", "Button", true, false).any(func(b): return b.text == "Drop"))
	await _snap("pack")
	main._set_pack(false)
	# A full pack after an event: what's left over is offered like a chest.
	var ps = main._party_state
	ps.supplies.add_what_fits(torch, 999)
	var result: Dictionary = main._room_events.resolve(ps, _choice(_event("chest_buried_cache"), "Dig it out"))
	check("finds that don't fit are offered, not lost silently", not result["no_room"].is_empty(), str(result["no_room"]))
	main._offer_no_room(result["no_room"])
	await process_frame
	check("...beside the pack, to swap", main._chest.visible and main._chest._pack_heading.text.contains("full"))
	var leftover: SupplyItem = result["no_room"].keys()[0]
	main._chest.put_back(torch)
	main._chest.take(leftover)
	check("leaving a torch makes room for the find", ps.supplies.count(leftover) >= 1)
	await _snap("no_room")
	main._chest.closed.emit()
	await process_frame
	# The real route (#136): choose, Continue, and the swap view opens.
	var cache := _event("chest_buried_cache")
	var spot := Vector2i(-1, -1)
	for c in main._map.contents:
		if not main._map.events.has(c):
			spot = c
			break
	if spot == Vector2i(-1, -1):
		spot = main._map.contents.keys()[0]
	main._map.events[spot] = cache
	main._map.triggered.erase(spot)
	ps.supplies.add_what_fits(torch, 999)  # full again
	main._run_event(spot)
	await process_frame
	main._event_screen._choose(_choice(cache, "Dig it out"))
	await process_frame
	var go_on: Array = main._event_screen._buttons.get_children().filter(func(b): return b.text == "Continue")
	check("the event ends with Continue", not go_on.is_empty())
	if not go_on.is_empty():
		go_on[0].pressed.emit()
	for i in 4:
		await process_frame
	check("after Continue, what didn't fit is offered beside the pack (#136)", main._chest.visible and main._chest._title.text == "No room in your pack" and not main._chest.is_empty(), main._chest._title.text)
	main._chest.closed.emit()
	await process_frame
	# A blocked passage, cleared with the spade.
	var map = main._map
	var blocked := Vector2i(-1, -1)
	for cell in map.doors:
		if map.doors[cell] == main.DungeonMap.Door.BLOCKED:
			blocked = cell
			break
	if blocked != Vector2i(-1, -1):
		var time_before: int = ps.time_elapsed
		main._clear_passage(blocked)
		check("a spade clears a blocked passage", map.door_at(blocked) == main.DungeonMap.Door.OPEN and ps.time_elapsed == time_before + main.CLEAR_PASSAGE_TIME)
	else:
		check("a blocked passage to clear on this floor", false)
	print("fails=", fails)
	quit()


func _range_without(hero: Companion) -> Vector2i:
	var saved := hero.boons.duplicate()
	hero.boons.clear()
	var span := hero.attack_range()
	hero.boons = saved
	return span
