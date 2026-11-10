extends SceneTree
## A thrown torch (#115): beasts that fear fire flee; goblins - the queen
## included - are burned but stand their ground, so the queen can't be
## driven off and her death story can't fire while she lives.

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _party():
	var PS = load("res://scripts/party_state.gd")
	var p = PS.new()
	var hero := Companion.new()
	hero.display_name = "Mara"
	hero.max_health = 20
	hero.health = 20
	p.add_member(hero)
	p.supplies.add(load("res://data/items/torch.tres"), 3)
	p.supplies.light_torch(load("res://data/items/torch.tres"))
	return p


func _initialize() -> void:
	var CS = load("res://scripts/combat_state.gd")
	for name in ["rat", "spider", "great_rat", "webspinner", "small_spider"]:
		var p = _party()
		var c = CS.new(p, [load("res://data/enemies/%s.tres" % name)] as Array[EnemyType])
		var out: Dictionary = c.hero_throw_torch(p.members[0], c.foes[0])
		check("a %s flees the flames" % name.replace("_", " "), out["fled"] and c.foes[0].fled)
	for name in ["goblin", "goblin_archer", "goblin_guard", "goblin_drummer", "goblin_queen"]:
		var p = _party()
		var c = CS.new(p, [load("res://data/enemies/%s.tres" % name)] as Array[EnemyType])
		var foe = c.foes[0]
		var out: Dictionary = c.hero_throw_torch(p.members[0], foe)
		check("a %s is burned but stays" % name.replace("_", " "), not out["fled"] and not foe.fled and out["damage"] >= 3 and out["damage"] <= 5 and foe.health == foe.type.max_health - out["damage"], str(out))
		check("...and the torch is spent", not p.supplies.torch_lit())
	# The queen's fight can't be won by scaring her off.
	var p = _party()
	var c = CS.new(p, [load("res://data/enemies/goblin_queen.tres"), load("res://data/enemies/goblin_guard.tres")] as Array[EnemyType])
	c.hero_throw_torch(p.members[0], c.foes[0])
	c.foes[1].health = 0
	c._check_end()
	check("with the queen still standing, the fight goes on", c.result == CS.Result.ONGOING and c.foes[0].is_alive())
	# A fresh torch before the old one is out (#230): the stub is lost.
	var torch: SupplyItem = load("res://data/items/torch.tres")
	var r = _party()
	check("a torch just lit can't be replaced", r.cannot_use_reason(torch) != "" and not r.supplies.light_torch(torch))
	r.supplies.torch_left = 10.0
	var left: int = r.supplies.count(torch)
	var said: String = r.use_item(torch)
	check("a burning one can: full again, one torch spent", r.supplies.torch_left > r.supplies.TORCH_BURN_TIME - 5.0 and r.supplies.count(torch) == left - 1 and said.contains("stub"), said)

	# T lights a torch from the pack (owner, 2026-11-09).
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var supplies = main._party_state.supplies
	supplies.add(torch, 2)
	supplies.source = supplies.Source.NONE
	var press := InputEventKey.new()
	press.physical_keycode = KEY_T
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	await process_frame
	check("T lights a torch from the pack", supplies.torch_lit(), main._message_label.text)
	var count: int = supplies.count(torch)
	Input.parse_input_event(press)
	await process_frame
	await process_frame
	check("...and won't waste a fresh one", supplies.count(torch) == count and main._message_label.text.begins_with("Torch:"), main._message_label.text)
	print("fails=", fails)
	quit()
