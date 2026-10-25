extends SceneTree
## Writes the first new monsters (#140, owner 2026-10-21) into data/enemies,
## with the delivered monster art (#141). Rerun to
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
		"display_name": "Cave bat", "scene": load("res://art/enemies/monsters-v1/cave-bat/scene.tscn"),
		"tint": Color.WHITE, "sprite_scale": 1.0,
		"max_health": 5, "damage_min": 1, "damage_max": 2, "accuracy": 0.7, "initiative": 14,
		"attack_verb": "bites", "tactic": EnemyType.Tactic.SWOOPER, "threat": 2, "injury_chance": 0.0,
		"intro": "A cave bat flits overhead: only reach can touch it in the air, but it lands after it swoops.",
		"loot_line": "Under its roost, half-buried in droppings: %s.",
	})
	_monster("goblin_brute", {
		"display_name": "Goblin brute", "scene": load("res://art/enemies/monsters-v1/goblin-brute/scene.tscn"),
		"tint": Color.WHITE, "sprite_scale": 1.0,
		"max_health": 18, "damage_min": 3, "damage_max": 5, "accuracy": 0.65, "initiative": 7,
		"attack_verb": "pounds", "tactic": EnemyType.Tactic.BRUTE, "threat": 5, "fears_fire": false,
		"purse": Vector2i(2, 6), "injuries": [DEEP_WOUND, LIMP], "injury_chance": 0.15,
		"intro": "A goblin brute hefts its maul. Brace when it winds up; hit it while it catches its breath.",
		"loot_line": "Among the brute's stolen things: %s.",
	})
	_monster("gas_bloat", {
		"display_name": "Gas-bloat", "scene": load("res://art/enemies/monsters-v1/gas-bloat/scene.tscn"),
		"tint": Color.WHITE, "sprite_scale": 1.0,
		"max_health": 6, "damage_min": 1, "damage_max": 2, "accuracy": 0.6, "initiative": 6,
		"attack_verb": "puffs at", "tactic": EnemyType.Tactic.BLOAT, "threat": 3, "fears_fire": false,
		"injury_chance": 0.0,
		"intro": "A gas-bloat drifts closer. Kill it from the back row, or set it alight - but never let it swell.",
		"loot_line": "Its burst leaves %s on the floor, swallowed long ago.",
	})
	_monster("hollow_miner", {
		"display_name": "Hollow miner", "scene": load("res://art/enemies/monsters-v1/hollow-miner/scene.tscn"),
		"tint": Color.WHITE, "sprite_scale": 1.0,
		"max_health": 16, "damage_min": 2, "damage_max": 4, "accuracy": 0.7, "initiative": 7,
		"attack_verb": "swings its pick at", "tactic": EnemyType.Tactic.GRABBER, "threat": 4, "fears_fire": false,
		"injuries": [DEEP_WOUND], "injury_chance": 0.1,
		"drop": load("res://data/items/pick.tres"), "drop_chance": 0.2,
		"intro": "One of the gassed shift, risen. It grabs and won't let go: hit it to break the hold, or lose a turn struggling free.",
		"loot_line": "Still strapped to the hollow miner from its last shift: %s.",
	})
	# The rest of #140's catalogue, on #141's art. The first five follow the
	# #97 research numbers; the lamp-eater and breach hound are first guesses.
	var art := func(id: String) -> PackedScene: return load("res://art/enemies/monsters-v1/%s/scene.tscn" % id)
	_monster("rock_beetle", {
		"display_name": "Rock beetle", "scene": art.call("rock-beetle"),
		"max_health": 10, "damage_min": 2, "damage_max": 3, "accuracy": 0.65, "initiative": 6,
		"attack_verb": "bites", "tactic": EnemyType.Tactic.CURLER, "threat": 3, "injury_chance": 0.05, "injuries": [LIMP],
		"intro": "A rock beetle: curled up, blows barely scratch it. Hit its partner, or brace, until it unfolds.",
		"loot_line": "Wedged under the beetle's shell, scraped up from the rock: %s.",
	})
	_monster("venom_spider", {
		"display_name": "Venom spider", "scene": art.call("venom-spider"), "row": "back", "reach_back": true,
		"max_health": 8, "damage_min": 2, "damage_max": 3, "accuracy": 0.75, "initiative": 9,
		"attack_verb": "bites", "tactic": EnemyType.Tactic.WEB_AND_VENOM, "threat": 3, "venom_damage": 2, "web_chance": 0.15,
		"injury_chance": 0.0,
		"intro": "A venom spider, its colours a warning: its bite burns twice as hard. An antidote will help.",
		"loot_line": "Wrapped in old webbing behind it, from some earlier meal: %s.",
	})
	_monster("goblin_trapper", {
		"display_name": "Goblin trapper", "scene": art.call("goblin-trapper"), "row": "back", "reach_back": true,
		"max_health": 10, "damage_min": 2, "damage_max": 3, "accuracy": 0.7, "initiative": 10,
		"attack_verb": "throws a knife at", "tactic": EnemyType.Tactic.TRAPPER, "threat": 3, "fears_fire": false,
		"purse": Vector2i(1, 4), "injury_chance": 0.05, "injuries": [LIMP],
		"intro": "A goblin trapper lays snares: whoever it catches acts last next round.",
		"loot_line": "In the trapper's sack of stolen things: %s.",
	})
	_monster("lamp_eater", {
		"display_name": "Lamp-eater", "scene": art.call("lamp-eater"),
		"max_health": 7, "damage_min": 1, "damage_max": 3, "accuracy": 0.7, "initiative": 12,
		"attack_verb": "bites", "tactic": EnemyType.Tactic.DRAINER, "threat": 3, "fears_fire": false, "injury_chance": 0.0,
		"intro": "A lamp-eater, drawn to your light: it drinks oil and torch-flame. Kill it before it leaves you in the dark.",
		"loot_line": "Among the broken lamp-glass where it fed: %s.",
	})
	_monster("breach_hound", {
		"display_name": "Breach hound", "scene": art.call("breach-hound"),
		"max_health": 9, "damage_min": 2, "damage_max": 3, "accuracy": 0.75, "initiative": 13,
		"attack_verb": "savages", "tactic": EnemyType.Tactic.PACK, "threat": 3, "injury_chance": 0.1, "injuries": [DEEP_WOUND],
		"intro": "Breach hounds hunt together and go for the weakest. Each hits harder while another stands.",
		"loot_line": "Near where the hound fell, among gnawed bones: %s.",
	})
	_monster("broodmother", {
		"display_name": "Broodmother", "scene": art.call("broodmother"),
		"max_health": 20, "damage_min": 2, "damage_max": 4, "accuracy": 0.75, "initiative": 8,
		"attack_verb": "bites", "tactic": EnemyType.Tactic.BROOD, "threat": 6, "venom_damage": 1,
		"summons": load("res://data/enemies/small_spider.tres"), "injury_chance": 0.1, "injuries": [DEEP_WOUND],
		"intro": "The Broodmother: she calls her hatchlings once, her bite poisons, and below half health she rages.",
		"loot_line": "Wrapped in the Broodmother's nest, among older meals: %s.",
	})
	_monster("gate_captain", {
		"display_name": "Gate captain", "scene": art.call("gate-captain"),
		"max_health": 22, "damage_min": 3, "damage_max": 4, "accuracy": 0.75, "initiative": 9,
		"attack_verb": "cleaves", "tactic": EnemyType.Tactic.CAPTAIN, "threat": 6, "fears_fire": false,
		"purse": Vector2i(6, 10), "injury_chance": 0.15, "injuries": [DEEP_WOUND, LIMP],
		"intro": "A gate captain: its horn braces an ally, then it winds up a heavy blow. Brace for it.",
		"loot_line": "Among the captain's spoils: %s.",
	})
	print("done")
	quit()
