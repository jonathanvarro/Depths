extends SceneTree
## Save/load safety for the newer systems (2026-10-25): boons and banes,
## a cursed trinket, the back slot, a cursed weapon, made gear in the pack,
## a limp's lost pack space, routes, and the forge's stock all survive
## Continue. Uses its own save file. Args: tag, screenshot dir.

const SaveGame := preload("res://scripts/save_game.gd")
const GearGen := preload("res://scripts/gear_gen.gd")
const Trinkets := preload("res://scripts/trinkets.gd")
const Quests := preload("res://scripts/quests.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _game(continue_save: bool):
	SaveGame.set_continue_requested(continue_save)
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 41
	root.add_child(main)
	await create_timer(0.5).timeout
	return main


func _drop(main) -> void:
	main.queue_free()
	await process_frame
	await process_frame


func _initialize() -> void:
	SaveGame.set_path("user://test_systems_save.dat")
	SaveGame.delete()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var cursed_weapon: Equipment = null
	var made: Equipment = null
	while cursed_weapon == null or made == null:
		var find := GearGen.drop(rng, 3, "chest")
		if find == null:
			continue
		if find.curse and find.slot == "weapon" and cursed_weapon == null:
			cursed_weapon = find
		elif not find.curse and find.tier == "magic" and made == null:
			made = find
	var cursed_trinket: Equipment = Trinkets.all().filter(func(t): return t.curse != null)[0]

	# In the cave.
	var main = await _game(false)
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	var ps = main._party_state
	var mara: Companion = ps.members[0]
	mara.add_boon(load("res://data/boons/sickness.tres"))
	mara.boons[0]["fights_left"] = 2
	mara.trinket = cursed_trinket
	mara.back = load("res://data/gear/satchel.tres")
	mara.weapon = cursed_weapon
	ps.supplies.gear.append(made)
	mara.add_injury(load("res://data/injuries/limp.tres"))
	main._on_party_state_changed(false)
	var capacity: int = ps.supplies.capacity
	var made_name: String = made.display_name
	var made_effect: String = made.effect.effects_text()
	var weapon_name: String = cursed_weapon.display_name
	var weapon_range: Vector2i = mara.attack_range()
	main._save_now()
	await _drop(main)

	main = await _game(true)
	ps = main._party_state
	mara = ps.members[0]
	check("a bane and its count", mara.boons.size() == 1 and mara.boons[0]["boon"].resource_path.ends_with("sickness.tres") and mara.boons[0]["fights_left"] == 2, str(mara.boons))
	check("a cursed trinket, still cursed", mara.trinket != null and mara.trinket.display_name == cursed_trinket.display_name and mara.is_cursed())
	check("...and its clean self, for when it's lifted", mara.trinket.cleansed != null)
	check("the back slot", mara.back != null and mara.back.resource_path.ends_with("satchel.tres"))
	check("a cursed weapon: name, curse and damage", mara.weapon and mara.weapon.display_name == weapon_name and mara.cursed_gear() == mara.weapon and mara.attack_range() == weapon_range, "%s %s" % [mara.weapon.display_name if mara.weapon else "none", mara.attack_range()])
	var carried: Array = ps.supplies.gear.filter(func(g): return g.display_name == made_name)
	check("made gear in the pack keeps its tier and effect", carried.size() == 1 and carried[0].tier == "magic" and carried[0].effect != null and carried[0].effect.effects_text() == made_effect, str(ps.supplies.gear.map(func(g): return g.display_name)))
	check("a limp's lost space, and the satchel's extra", ps.supplies.capacity == capacity and ps.pack_lost() == 2, "%d vs %d" % [ps.supplies.capacity, capacity])
	check("a cursed weapon still can't be swapped out", not ps.equip(mara, load("res://data/gear/simple_spear.tres")) or mara.weapon.display_name == weapon_name)
	var gone: Boon = mara.lift_bane()
	check("lifting works after loading: the trinket first", gone == cursed_trinket.curse and not mara.is_cursed())

	# At camp: the forge, its stock, and routes.
	main._end_expedition(main.Expedition.Ending.RETURNED)
	await process_frame
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout
	var camp = main._camp_state
	Quests.set_stage(camp, "iron_sample", Quests.Stage.RESOLVED)
	ps.supplies.gold = 400
	check("the forge is built", camp.build_forge(ps))
	var stock: Array = camp.smith_fine_stock()
	var bought: Equipment = stock[0]
	camp.buy_gear(ps, bought)
	var left: Array = camp.smith_fine_stock().map(func(g): return g.display_name)
	var routes: Dictionary = camp.floors_reached.duplicate()
	main._save_now()
	await _drop(main)

	main = await _game(true)
	camp = main._camp_state
	ps = main._party_state
	check("continue at camp: the forge stands", camp.forge_built)
	check("...with today's stock, less what was bought", camp.smith_fine_stock().map(func(g): return g.display_name) == left, str(camp.smith_fine_stock().map(func(g): return g.display_name)))
	check("...and what was bought is carried", ps.supplies.gear.any(func(g): return g.display_name == bought.display_name and g.tier == "fine"))
	check("routes remembered", camp.floors_reached == routes, str(camp.floors_reached))
	check("the lifted curse stays lifted", not ps.members[0].is_cursed() and ps.members[0].trinket != null)
	await _drop(main)
	SaveGame.delete()
	print("fails=", fails)
	quit()
