extends SceneTree
## Drag and drop in the Pack (owner, 2026-10-31): drag gear from the pack
## onto its slot to put it on; drag it from the slot back to the pack to take
## it off. The buttons' rules apply: the right slot only, no curses off, the
## founder's weapon stays in hand. Args: tag, screenshot dir.
## This checks drop policies with payloads; check_pack_context.gd exercises real
## input gestures (calling a drag-preview callback outside a GUI drag is invalid).

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

	var data = {"kit_drag":"bag","item":jerkin,"party":ps}
	check("gear in the pack is a valid drag source", pack._valid_bag_drag(data))
	check("...onto its own slot", pack._can_drop_on_slot(Vector2.ZERO, data, "body"))
	check("...not another slot", not pack._can_drop_on_slot(Vector2.ZERO, data, "weapon"))
	var ration:SupplyItem=load("res://data/items/ration.tres")
	ps.supplies.add(ration)
	check("a ration can now be dragged to the selected hero", pack._can_drop_on_hero(Vector2.ZERO,{"kit_drag":"bag","item":ration,"party":ps},mara))
	pack._drop_on_slot(Vector2.ZERO, data, "body")
	await process_frame
	check("dropped on the armour slot: it's worn", mara.body == jerkin and not ps.supplies.gear.has(jerkin))

	data = {"kit_drag":"slot","slot":"body","item":jerkin,"party":ps,"hero":mara}
	check("worn gear can be dragged off its slot", pack._can_drop_on_bag(Vector2.ZERO,data))
	check("...into the pack", pack._can_drop_on_bag(Vector2.ZERO, data))
	pack._drop_on_bag(Vector2.ZERO, data)
	await process_frame
	check("dropped in the pack: taken off", mara.body == null and ps.supplies.gear.has(jerkin))

	var held: Equipment = mara.weapon
	data = {"kit_drag":"slot","slot":"weapon","item":held,"party":ps,"hero":mara}
	check("the founder's weapon won't go back in the pack", held == null or not pack._can_drop_on_bag(Vector2.ZERO, data))
	data = {"kit_drag":"bag","item":sword,"party":ps}
	pack._drop_on_slot(Vector2.ZERO, data, "weapon")
	await process_frame
	check("...but a new one dragged onto the slot replaces it", mara.weapon == sword)

	var cursed: Equipment = load("res://data/gear/leather_jerkin.tres").duplicate()
	cursed.curse = load("res://data/boons/" + DirAccess.get_files_at("res://data/boons")[0].trim_suffix(".remap")) if DirAccess.get_files_at("res://data/boons").size() > 0 else null
	if cursed.curse:
		ps.equip(mara, cursed)
		await process_frame
		data = {"kit_drag":"slot","slot":"body","item":cursed,"party":ps,"hero":mara}
		check("cursed gear won't come off by dragging either", not pack._can_drop_on_bag(Vector2.ZERO, data))
	print("fails=", fails)
	quit(0 if fails==0 else 1)
