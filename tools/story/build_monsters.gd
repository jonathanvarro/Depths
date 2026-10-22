extends SceneTree
## Writes the first new monsters (#140, owner 2026-10-21) into data/enemies,
## on tinted placeholders until ChatGPT's art (#141) lands. Rerun to
## rebuild:  Godot --headless --path . --script tools/story/build_monsters.gd
##
## Numbers for the bat and brute follow ChatGPT's research (#97); the
## breach creatures' are Claude's first guesses. All are to tune.

const DEEP_WOUND := preload("res://data/injuries/deep_wound.tres")
const LIMP := preload("res://data/injuries/limp.tres")


func _monster(id: String, fields: Dictionary) -> void:
	var e := EnemyType.new()
	for key in fields:
		if key == "injuries":
			e.injuries.assign(fields[key])
		else:
			e.set(key, fields[key])
	var path := "res://data/enemies/%s.tres" % id
	print(path, " ", "ok" if ResourceSaver.save(e, path) == OK else "FAILED")


func _initialize() -> void:
	_monster("cave_bat", {
		"display_name": "Cave bat", "scene": load("res://art/enemies/campaign-v1/webspinner/scene.tscn"),
		"tint": Color(0.45, 0.36, 0.42), "sprite_scale": 0.8,
		"max_health": 5, "damage_min": 1, "damage_max": 2, "accuracy": 0.7, "initiative": 14,
		"attack_verb": "bites", "tactic": EnemyType.Tactic.SWOOPER, "threat": 2, "injury_chance": 0.0,
		"intro": "A cave bat flits overhead: only reach can touch it in the air, but it lands after it swoops.",
	})
	_monster("goblin_brute", {
		"display_name": "Goblin brute", "scene": load("res://art/enemies/cave-simple-v1/goblin/scene.tscn"),
		"tint": Color(0.78, 0.55, 0.45), "sprite_scale": 1.3,
		"max_health": 18, "damage_min": 3, "damage_max": 5, "accuracy": 0.65, "initiative": 7,
		"attack_verb": "pounds", "tactic": EnemyType.Tactic.BRUTE, "threat": 5, "fears_fire": false,
		"purse": Vector2i(2, 6), "injuries": [DEEP_WOUND, LIMP], "injury_chance": 0.15,
		"intro": "A goblin brute hefts its maul. Brace when it winds up; hit it while it catches its breath.",
	})
	_monster("gas_bloat", {
		"display_name": "Gas-bloat", "scene": load("res://art/enemies/campaign-v1/webspinner/scene.tscn"),
		"tint": Color(0.78, 0.86, 0.42), "sprite_scale": 1.1,
		"max_health": 6, "damage_min": 1, "damage_max": 2, "accuracy": 0.6, "initiative": 6,
		"attack_verb": "puffs at", "tactic": EnemyType.Tactic.BLOAT, "threat": 3, "fears_fire": false,
		"injury_chance": 0.0,
		"intro": "A gas-bloat drifts closer. Kill it from the back row, or set it alight - but never let it swell.",
	})
	_monster("hollow_miner", {
		"display_name": "Hollow miner", "scene": load("res://art/enemies/cave-simple-v1/goblin/scene.tscn"),
		"tint": Color(0.55, 0.62, 0.68), "sprite_scale": 1.15,
		"max_health": 16, "damage_min": 2, "damage_max": 4, "accuracy": 0.7, "initiative": 7,
		"attack_verb": "swings its pick at", "tactic": EnemyType.Tactic.GRABBER, "threat": 4, "fears_fire": false,
		"injuries": [DEEP_WOUND], "injury_chance": 0.1,
		"drop": load("res://data/items/pick.tres"), "drop_chance": 0.2,
		"intro": "One of the gassed shift, risen. It grabs and won't let go - hit it to break the hold.",
	})
	print("done")
	quit()
