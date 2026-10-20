extends SceneTree
## Gold (#42): where it comes from (event coins, treasure, goblin purses,
## contracts) and where it goes (merchant, lantern, smith, stash), plus the
## merchant's two torches for a party with nothing.
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
	root.get_texture().get_image().save_png(S + "/gold_" + tag + "_" + name + ".png")


func _press(node, label: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if b.text.begins_with(label) and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			return true
	return false


func _open(id: String) -> void:
	main._camp._close_activity()
	main._camp._buttons[id].pressed.emit()
	await process_frame


func _to_camp(ending: int) -> void:
	main._end_expedition(ending)
	await process_frame
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	tag = args[0]
	S = args[1]
	main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 31
	main.simulate_phone_safe_area = tag == "phone"
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	var supplies = ps.supplies
	var camp = main._camp_state
	var ore: SupplyItem = load("res://data/items/copper_ore.tres")
	var trinket: SupplyItem = load("res://data/items/silver_trinket.tres")
	var torch: SupplyItem = load("res://data/items/torch.tres")

	# Event coins and treasure.
	var pack: RoomEvent = load("res://data/events/chest_abandoned_pack.tres")
	var coins := EventChoice.new()
	coins.outcomes = [pack.choices[0].outcomes[3]]
	main._room_events.resolve(ps, coins)
	var found_items: Array = supplies.items.filter(func(i): return i.effect == SupplyItem.Effect.TREASURE and supplies.count(i) > 0)
	check("a chest gives coins and a random valuable", supplies.gold == 5 and found_items.size() == 1 and found_items[0].icon != null, str(found_items.map(func(i): return i.display_name)))
	var valuable: SupplyItem = found_items[0]
	check("the expedition counts the gold", main._expedition.gold_found == 5)
	check("treasure can't be used, only sold", ps.cannot_use_reason(valuable) == "Sell it at camp")

	# A goblin's purse.
	var CS = load("res://scripts/combat_state.gd")
	var fight = CS.new(ps, [load("res://data/enemies/goblin.tres")] as Array[EnemyType])
	main._loot_purse(fight.foes[0])
	var after_purse: int = supplies.gold
	check("a goblin's purse holds 2-6 gold", after_purse >= 7 and after_purse <= 11, str(after_purse))
	var rat_fight = CS.new(ps, [load("res://data/enemies/rat.tres")] as Array[EnemyType])
	main._loot_purse(rat_fight.foes[0])
	check("rats carry nothing", supplies.gold == after_purse)

	# A contract: beat 3 goblins, paid at camp.
	camp.contract = camp.CONTRACTS[0].duplicate()
	camp.contract["done"] = 0
	camp.contract["paid"] = false
	for i in 3:
		camp.count_kill("Goblin")
	camp.count_kill("Rat")
	check("contract progress counts only its enemy", camp.contract["done"] == 3)
	supplies.add(ore, 2)
	await _to_camp(main.Expedition.Ending.RETURNED)
	check("results list the gold found", main._camp.visible)
	check("contract paid on arrival", camp.contract["paid"] and supplies.gold == after_purse + 15 and main._camp._note.text.contains("15 gold"), str(supplies.gold))
	await _snap("paid")

	# Merchant: sell treasure, buy supplies, then the lantern.
	await _open("supplies")
	await _snap("merchant")
	var before: int = supplies.gold
	check("sell copper ore for 3g each", _press(main._camp, "Sell 3g") and supplies.gold == before + 3)
	_press(main._camp, "Sell 3g")
	_press(main._camp, "Sell %dg" % valuable.price)
	check("all treasure sold at its value", supplies.count(ore) == 0 and supplies.count(valuable) == 0 and supplies.gold == before + 6 + valuable.price, str(supplies.gold - before))
	var torches: int = supplies.count(torch)
	before = supplies.gold
	check("buy a torch for 3g", camp.buy(ps, torch) and supplies.count(torch) == torches + 1 and supplies.gold == before - 3)
	supplies.has_lantern = false
	supplies.source = 0
	supplies.gold = 39
	main._camp._refresh_activity()
	check("the lantern needs 40g", not camp.buy_lantern(ps) and not _press(main._camp, "Buy 40g"))
	supplies.gold = 45
	main._camp._refresh_activity()
	check("buy the lantern", _press(main._camp, "Buy 40g") and supplies.has_lantern and supplies.source == 1 and supplies.oil == 100.0 and supplies.gold == 5)
	supplies.gold = 6
	main._camp._refresh_activity()
	check("oil is sold once you have a lantern", _press(main._camp, "Buy 6g") and supplies.gold == 0)

	# Smith: buy gear into the pack; the merchant buys it back at 30%.
	supplies.gold = 10
	await _open("smith")
	await _snap("smith")
	check("can't afford the axe", not camp.buy_gear(ps, load("res://data/gear/woodcutters_axe.tres")))
	check("buy a plain knife", _press(main._camp, "Buy 8g") and supplies.gold == 2 and supplies.gear.any(func(g): return g.resource_path == "res://data/gear/plain_knife.tres"))
	await _open("supplies")
	check("sell it back for 2g (30%)", _press(main._camp, "Sell 2g") and supplies.gold == 4)

	# Stash: gold stays safe through a wipe.
	await _open("rest")
	check("store gold", _press(main._camp, "Store gold") and camp.stash.gold == 4 and supplies.gold == 0)
	supplies.gold = 7
	await _open("cave")
	_press(main._camp, "Head back down")
	await create_timer(0.2).timeout
	_press(main._preparation, "Enter the mine")
	await create_timer(0.3).timeout
	for hero: Companion in ps.members:
		hero.min_health = 0
		hero.change_health(-999)
	await create_timer(0.3).timeout
	if main._results.visible:
		main._results.continue_pressed.emit()
	await create_timer(0.3).timeout
	check("a wipe loses carried gold; the stash keeps its gold", supplies.gold == 0 and camp.stash.gold == 4)

	# Nothing to light the way and no money: two torches on account.
	supplies.add(torch, 1)
	camp.store(ps, torch)
	check("no charity while torches sit in the stash", not camp.needs_charity(ps))
	camp.withdraw(ps, torch)
	supplies.take(torch)
	await _open("supplies")
	camp.stash.gold = 2  # too little for a torch, even counting the stash
	await _open("supplies")
	check("the merchant fronts two torches", _press(main._camp, "Take two torches") and supplies.count(torch) == 2)
	check("only once a day", not camp.needs_charity(ps))
	await _open("rest")
	check("take the stash gold back", _press(main._camp, "Take gold") and supplies.gold == 2 and camp.stash.gold == 0)
	check("a new contract each day", camp.contract.has("enemy"))
	print("fails=", fails)
	quit()
