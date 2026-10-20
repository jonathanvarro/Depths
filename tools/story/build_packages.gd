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


func _package(id: String, depth: Vector2i, quest: String, stages: Array, unless_flags: Array, rows: Array, events: Array, fight: Array = []) -> void:
	var p := QuestPackage.new()
	p.id = id
	p.min_depth = depth.x
	p.max_depth = depth.y
	p.quest = quest
	p.stages.assign(stages)
	p.unless_flags = PackedStringArray(unless_flags)
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
	_package("left_behind", Vector2i(1, 1), "left_behind", [A], ["found"], [
		"#######",
		"#,,,,,#",
		"#,1,2,#",
		"#,,E,,#",
		"#,,,,,#",
		"###.###",
	], [fallen, packs], [great_rat, rat])

	var U := Quests.Stage.UNKNOWN
	var O := Quests.Stage.OFFERED
	var R := Quests.Stage.RESOLVED
	# --- Three Knocks (hidden): a miner trapped behind a rock fall.
	var knocks := _event("three_knocks", "Three knocks",
			"Fresh dust on the floor and an abandoned tin cup. From behind a fall of rubble: three knocks, a pause, three knocks.",
			[_choice("Call out", [_outcome("A hoarse voice answers. \"Hask - I'm Hask - the props went! Get me out!\" One cracked beam holds the whole fall up.",
					{"quest": "three_knocks", "quest_stage": A})], 1, true),
			_choice("Brace the beam and dig him out", [
					_outcome("You wedge the beam, shift stone after stone, and Hask crawls out grey with dust. He swears he'll make his own way to camp - and that he owes you.",
						{"quest": "three_knocks", "quest_stage": A, "quest_flag": "miner_at_camp", "weight": 3}),
					_outcome("Hask crawls out - but the noise of the stones carried. Something comes skittering out of the dark.",
						{"quest": "three_knocks", "quest_stage": A, "quest_flag": "miner_at_camp", "ambush": [rat, rat]}),
				], 8),
			_choice("Mark it for a camp crew", [_outcome("You chalk the king's mark on the rubble and promise to send diggers. \"Don't be long,\" says the voice.",
					{"quest": "three_knocks", "quest_stage": A, "quest_flag": "crew_sent"})], 1)],
			4)
	_package("three_knocks", Vector2i(2, 2), "three_knocks", [U, O, A], ["miner_at_camp", "crew_sent"], [
		"#########",
		"#,,,#,,,#",
		"#,1,B,,,#",
		"#,,,#,,,#",
		"##.######",
	], [knocks])

	# --- Iron for the Apprentice: a seam where the old workings end.
	var copper: SupplyItem = load("res://data/items/copper_ore.tres")
	var seam := _event("iron_seam", "A dark seam",
			"Where the old workings end, a seam of dark rock runs through the wall, streaked rust-red. Real iron.",
			[_choice("Chip out a sample", [_outcome("A fist-sized lump comes away clean. The smith will want this.",
					{"quest": "iron_sample", "quest_flag": "have_ore"})], 3),
			_choice("Work it hard for more", [
					_outcome("Iron for the smith, and a lump of copper besides.", {"quest": "iron_sample", "quest_flag": "have_ore", "loot": {copper: 1}, "weight": 2}),
					_outcome("The face cracks and stones rain down - but you come away with the iron.", {"quest": "iron_sample", "quest_flag": "have_ore", "health": -2, "strain": 6.0}),
				], 6)],
			2)
	_package("iron_seam", Vector2i(1, 1), "iron_sample", [A], ["have_ore"], [
		"#####",
		"#,1,#",
		"#,,,#",
		"##.##",
	], [seam])

	# --- The way down: a water gate below the fortress, past the queen.
	var gate := _event("lower_gate", "The lower water gate",
			"An iron water gate set into stone far older than the fortress. Below the grate, black water slides away down carved channels, into the dark.",
			[_choice("Look down through the grate", [_outcome("Far below, the channels open into flooded galleries - worked stone, pillars, the glint of something that is not water. The way down goes on.",
					{"quest": "lower_gate", "quest_stage": R, "quest_flag": "seen"})], 1)],
			4)
	_package("lower_gate", Vector2i(4, 4), "lower_gate", [A], ["seen"], [
		"#######",
		"#,,,,,#",
		"#,,1,,#",
		"#,,,,,#",
		"###.###",
	], [gate])
	quit()
