extends SceneTree
## Smaller items (2026-10-22): a limp costs that hero 2 pack slots until
## dressed (#104); spare gear that doesn't fit is offered beside the pack,
## not lost; a forge at camp sells fine gear; and some magic weapons and
## armour are secretly cursed until cleansed. Args: tag, screenshot dir.

const GearGen := preload("res://scripts/gear_gen.gd")
const Quests := preload("res://scripts/quests.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _party(ids := ["mara"]):
	var party = load("res://scripts/party_state.gd").new()
	for id in ids:
		party.add_member(load("res://data/companions/%s.tres" % id))
	return party


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var limp: Injury = load("res://data/injuries/limp.tres")

	# A limp (#104).
	var party = _party()
	var mara: Companion = party.members[0]
	check("a lone hero: 8 slots", party.supplies.capacity == 8)
	mara.add_injury(limp)
	party.update_capacity()
	check("limping, the pack loses 2", party.supplies.capacity == 6 and party.pack_lost() == 2)
	mara.dress_injury()
	party.update_capacity()
	check("dressed, the space comes back", party.supplies.capacity == 8)
	mara.dressed.clear()
	party.advance_time(1)
	check("...and the limp takes it again as time passes", party.supplies.capacity == 6)

	# The forge.
	var camp = load("res://scripts/camp_state.gd").new()
	check("no forge offered before the iron project", not camp.forge_offered())
	Quests.set_stage(camp, "iron_sample", Quests.Stage.RESOLVED)
	check("after it, the smith offers a forge", camp.forge_offered())
	party = _party()
	party.supplies.gold = 100
	check("it costs 60 gold", camp.build_forge(party) and party.supplies.gold == 40 and camp.forge_built)
	var stock: Array = camp.smith_fine_stock()
	check("the forge sells fine versions of the smith's weapons and armour", stock.size() == 7 and stock.all(func(g): return g.tier == "fine"), str(stock.map(func(g): return g.display_name)))
	check("...the same pieces all day", camp.smith_fine_stock() == stock)
	var piece: Equipment = stock[0]
	party.supplies.gold = 200
	check("bought, it's gone for today", camp.buy_gear(party, piece) and piece not in camp.smith_fine_stock())
	camp.day += 1
	check("tomorrow the forge has new work", camp.smith_fine_stock().size() == 7)

	# Cursed weapons and armour.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var cursed: Equipment = null
	var shallow_curses := 0
	for i in 6000:
		var find := GearGen.drop(rng, 3, "chest")
		if find and find.curse and cursed == null:
			cursed = find
		var early := GearGen.drop(rng, 1, "chest")
		if early and early.curse:
			shallow_curses += 1
	check("deeper, some magic gear hides a curse", cursed != null and cursed.tier == "magic")
	check("never on floor 1", shallow_curses == 0)
	party = _party()
	mara = party.members[0]
	var plain_weapon: Equipment = mara.weapon
	if cursed.slot == "weapon":
		party.supplies.gear.append(cursed)
		party.equip(mara, cursed)
		check("put on, it holds fast: no swapping back", mara.weapon == cursed and mara.cursed_gear() == cursed)
		if plain_weapon:
			party.equip(mara, plain_weapon)
			check("...the old weapon can't replace it", mara.weapon == cursed)
	else:
		party.supplies.gear.append(cursed)
		party.equip(mara, cursed)
		check("put on, it holds fast", mara.body == cursed and mara.cursed_gear() == cursed)
		var coat: Equipment = load("res://data/gear/padded_coat.tres")
		party.supplies.gear.append(coat)
		party.equip(mara, coat)
		check("...no swapping it for other armour", mara.body == cursed)
	check("its bane counts", mara.has_bane() and mara.effects().has(cursed.curse))
	party.supplies.add(load("res://data/items/holy_water.tres"))
	party.use_item(load("res://data/items/holy_water.tres"))
	check("holy water lifts it, and the piece stays", cursed.curse == null and mara.cursed_gear() == null and (mara.weapon == cursed or mara.body == cursed))

	# Spare gear that doesn't fit is offered, not lost.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	ps.supplies.add_what_fits(load("res://data/items/torch.tres"), 999)
	var sword := GearGen.make(load("res://data/gear/iron_sword.tres"), "magic", rng)
	main._found_gear(sword, "Underneath: a sword.")
	check("a find with a full pack waits, not lost", main._overflow.has(sword))
	main._offer_overflow()
	await process_frame
	check("...offered beside the pack", main._chest.visible and sword in main._chest.contents)
	main._chest.put_back(load("res://data/items/torch.tres"))
	main._chest.take(sword)
	check("leave a stack, take the sword", sword in ps.supplies.gear and not sword in main._chest.contents)
	main._chest.put_back(sword)
	check("...and gear can be left in its place too", sword in main._chest.contents and not sword in ps.supplies.gear)
	if dir != "":
		for i in 4:
			await process_frame
		root.get_texture().get_image().save_png(dir + "/small_" + tag + "_overflow.png")
	main._chest.closed.emit()
	await process_frame
	var outcome := EventOutcome.new()
	outcome.gear.assign([GearGen.make(load("res://data/gear/padded_coat.tres"), "fine", rng)])
	var choice := EventChoice.new()
	choice.outcomes.assign([outcome])
	ps.supplies.add_what_fits(load("res://data/items/torch.tres"), 999)
	var result: Dictionary = main._room_events.resolve(ps, choice)
	check("event gear that doesn't fit is offered too", result["no_room"].has(outcome.gear[0]))
	print("fails=", fails)
	quit()
