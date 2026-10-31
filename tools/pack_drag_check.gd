extends SceneTree
## Drag and drop in the Pack (owner, 2026-10-31): drag gear from the pack
## onto its slot to put it on; drag it from the slot back to the pack to take
## it off. The buttons' rules apply: the right slot only, no curses off, the
## founder's weapon stays in hand. Args: tag, screenshot dir.

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	var mara: Companion = ps.members[0]
	var jerkin: Equipment = load("res://data/gear/leather_jerkin.tres").duplicate()
	var sword: Equipment = load("res://data/gear/iron_sword.tres").duplicate()
	ps.supplies.gear.append(jerkin)
	ps.supplies.gear.append(sword)
	ps.supplies.changed.emit()
	main._set_pack(true)
	await process_frame
	var pack = main._pack
	pack.select_hero(mara)
	await process_frame

	var data = pack._drag_from_bag(Vector2.ZERO, jerkin)
	check("gear in the pack can be picked up and dragged", data is Dictionary and data["item"] == jerkin)
	check("...onto its own slot", pack._can_drop_on_slot(Vector2.ZERO, data, "body"))
	check("...not another slot", not pack._can_drop_on_slot(Vector2.ZERO, data, "weapon"))
	check("a ration isn't gear: nothing to drag", pack._drag_from_bag(Vector2.ZERO, load("res://data/items/ration.tres")) == null)
	pack._drop_on_slot(Vector2.ZERO, data, "body")
	await process_frame
	check("dropped on the armour slot: it's worn", mara.body == jerkin and not ps.supplies.gear.has(jerkin))

	data = pack._drag_from_slot(Vector2.ZERO, "body", jerkin)
	check("worn gear can be dragged off its slot", data is Dictionary and data["slot"] == "body")
	check("...into the pack", pack._can_drop_on_bag(Vector2.ZERO, data))
	pack._drop_on_bag(Vector2.ZERO, data)
	await process_frame
	check("dropped in the pack: taken off", mara.body == null and ps.supplies.gear.has(jerkin))

	var held: Equipment = mara.weapon
	data = pack._drag_from_slot(Vector2.ZERO, "weapon", held)
	check("the founder's weapon won't go back in the pack", held == null or not pack._can_drop_on_bag(Vector2.ZERO, data))
	data = pack._drag_from_bag(Vector2.ZERO, sword)
	pack._drop_on_slot(Vector2.ZERO, data, "weapon")
	await process_frame
	check("...but a new one dragged onto the slot replaces it", mara.weapon == sword)

	var cursed: Equipment = load("res://data/gear/leather_jerkin.tres").duplicate()
	cursed.curse = load("res://data/boons/" + DirAccess.get_files_at("res://data/boons")[0].trim_suffix(".remap")) if DirAccess.get_files_at("res://data/boons").size() > 0 else null
	if cursed.curse:
		ps.equip(mara, cursed)
		await process_frame
		data = pack._drag_from_slot(Vector2.ZERO, "body", cursed)
		check("cursed gear won't come off by dragging either", not pack._can_drop_on_bag(Vector2.ZERO, data))
	print("fails=", fails)
	quit()
