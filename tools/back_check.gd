extends SceneTree
## The back slot (owner, 2026-10-21): a backpack adds pack slots (a big one
## slows you), a cloak or cape carries an effect like a trinket's. Bought
## from the smith, worn and taken off from the Pack. Args: tag, screenshot
## dir.

const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _gear(id: String) -> Equipment:
	return load("res://data/gear/%s.tres" % id)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres"))
	var mara: Companion = party.members[0]
	var supplies = party.supplies
	check("a lone hero starts with 8 slots", supplies.capacity == 8)
	supplies.gear.append(_gear("satchel"))
	check("a carried satchel takes a slot like any gear", supplies.slots_used() == 1)
	party.equip(mara, _gear("satchel"))
	check("worn, a satchel adds 2 slots and takes none", supplies.capacity == 10 and supplies.slots_used() == 0 and mara.back == _gear("satchel"))
	var speed := mara.effective_initiative()
	supplies.gear.append(_gear("frame_pack"))
	party.equip(mara, _gear("frame_pack"))
	check("a frame pack adds 4, and the satchel goes back in the pack", supplies.capacity == 12 and _gear("satchel") in supplies.gear)
	check("...but slows you by 1", mara.effective_initiative() == speed - 1)
	supplies.add(load("res://data/items/torch.tres"), 55)
	check("filled up", supplies.slots_used() == 12, supplies.slots_used())
	check("taken off, the pack is over-full: nothing lost, nothing more fits", party.take_off_back(mara) and supplies.capacity == 8 and supplies.count(load("res://data/items/torch.tres")) == 55 and supplies.room_for(load("res://data/items/ration.tres")) == 0)
	supplies.gear.append(_gear("oilcloth_cloak"))
	party.equip(mara, _gear("oilcloth_cloak"))
	check("an oilcloth cloak: nerves fray slower, the lantern burns slower", is_equal_approx(mara.boon_product("strain_rate"), 0.9) and is_equal_approx(party.oil_rate(), 0.9))
	supplies.gear.append(_gear("wool_cape"))
	party.equip(mara, _gear("wool_cape"))
	check("a wool cape: +2 maximum health, and the cloak comes off", mara.effective_max_health() == mara.max_health + 2 and _gear("oilcloth_cloak") in supplies.gear)
	var copy := Companion.new()
	SaveGame.unpack_into(copy, SaveGame.pack_object(mara))
	check("what's on the back survives a save", copy.back == _gear("wool_cape"))

	# In the game: the smith sells them, the Pack shows and wears them.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var stock: Array = main._camp_state.smith_stock()
	check("the smith sells backpacks, a cloak and a cape", ["satchel", "frame_pack", "oilcloth_cloak", "wool_cape"].all(func(id): return _gear(id) in stock))
	var ps = main._party_state
	ps.supplies.gear.append(_gear("satchel"))
	main._set_pack(true)
	await process_frame
	var labels: Array = main._pack._list.find_children("*", "Label", true, false).map(func(l): return l.text)
	check("the Pack says what a back item does", labels.any(func(t): return t == "Worn: +2 pack slots"), str(labels.slice(0, 8)))
	ps.equip(ps.members[0], _gear("satchel"))
	main._pack.refresh()
	await process_frame
	labels = main._pack._list.find_children("*", "Label", true, false).map(func(l): return l.text)
	check("...and what's worn", labels.any(func(t): return t.contains("On the back: leather satchel (+2 pack slots)")) and labels.any(func(t): return t == "Pack space: 0 of 10" or t.begins_with("Pack space:") and t.ends_with("of 10")), str(labels.slice(0, 8)))
	if dir != "":
		for i in 4:
			await process_frame
		root.get_texture().get_image().save_png(dir + "/back_" + tag + "_pack.png")
	print("fails=", fails)
	quit()
