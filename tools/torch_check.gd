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
	print("fails=", fails)
	quit()
