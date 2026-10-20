extends SceneTree
## Writes the first slice's quest packages and their events
## (docs/first-slice-plan.md) into data/packages and data/events. Rerun to
## rebuild:  Godot --headless --path . --script tools/story/build_packages.gd

const Quests := preload("res://scripts/quests.gd")


func _outcome(text: String, extra := {}) -> EventOutcome:
	var o := EventOutcome.new()
	o.text = text
	for key in extra:
		o.set(key, extra[key])
	return o


func _choice(label: String, outcomes: Array, time := 2, investigation := false) -> EventChoice:
	var c := EventChoice.new()
	c.label = label
	c.time_cost = time
	c.investigation = investigation
	c.outcomes.assign(outcomes)
	return c


func _event(name: String, title: String, clue: String, choices: Array, kind := 2, prop := "") -> RoomEvent:
	var e := RoomEvent.new()
	e.title = title
	e.clue = clue
	e.kind = kind
	e.min_depth = 99  # only ever placed by its package, never picked at random
	e.max_depth = 99
	e.choices.assign(choices)
	if prop != "":
		e.prop = load(prop)
	var path := "res://data/events/quest_%s.tres" % name
	print(path, " ", "ok" if ResourceSaver.save(e, path) == OK else "FAILED")
	return load(path)


func _package(id: String, depth: Vector2i, quest: String, stage: int, unless_flag: String, rows: Array, events: Array, fight: Array = []) -> void:
	var p := QuestPackage.new()
	p.id = id
	p.min_depth = depth.x
	p.max_depth = depth.y
	p.quest = quest
	p.stage = stage
	p.unless_flag = unless_flag
	p.rows = PackedStringArray(rows)
	p.events.assign(events)
	p.fight.assign(fight)
	var path := "res://data/packages/%s.tres" % id
	print(path, " ", "ok" if ResourceSaver.save(p, path) == OK else "FAILED")


func _initialize() -> void:
	var A := Quests.Stage.ACTIVE
	var rat: EnemyType = load("res://data/enemies/rat.tres")
	var great_rat: EnemyType = load("res://data/enemies/great_rat.tres")
	var ration: SupplyItem = load("res://data/items/ration.tres")
	var dressing: SupplyItem = load("res://data/items/dressing.tres")

	# --- Those Left Behind: where the rest of the hero's party fell.
	var fallen := _event("left_behind_fallen", "Where they fell",
			"The rest of your party lies where the ambush caught them. Rats have been at the packs. A survey case lies open beside the guide's hand.",
			[_choice("Look them over", [_outcome("The guide, the surveyor, the two porters. None of them ran. Whatever came, it came from both sides at once.")], 1, true),
			_choice("Gather their maps and anything strange", [_outcome(
					"The survey map is rolled tight in its case - and someone has marked it in a hand none of your party used. Wedged under the guide is an arrow: a goblin shaft, fletched with something black and glossy that no goblin you know would use.",
					{"quest": "left_behind", "quest_flag": "found"})], 3)],
			2, "res://art/props/opening-bodies-v1/fallen-a.tscn")
	var packs := _event("left_behind_packs", "Their packs",
			"Torn packs, half emptied by rats. Some of it is still worth carrying.",
			[_choice("Take what's left", [_outcome("A ration in waxed cloth, clean linen, and a few coins the rats couldn't eat.",
					{"loot": {ration: 1, dressing: 1}, "gold": 6})], 2)],
			2, "res://art/props/opening-bodies-v1/fallen-b.tscn")
	_package("left_behind", Vector2i(1, 1), "left_behind", A, "found", [
		"#######",
		"#,,,,,#",
		"#,1,2,#",
		"#,,E,,#",
		"#,,,,,#",
		"###.###",
	], [fallen, packs], [great_rat, rat])
	quit()
