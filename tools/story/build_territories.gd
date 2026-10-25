extends SceneTree
## Writes the creature territories (#149, owner 2026-10-25) into data/events
## and data/packages. The first trial: lamp-eater territory, an old lamp
## store where the light-drinkers roost. Its dead lamps warn before you
## commit; a sealed oil cache rewards going in. Rerun to rebuild:
## Godot --headless --path . --script tools/story/build_territories.gd

const OIL := preload("res://data/items/oil_flask.tres")


func _e(id: String) -> EnemyType:
	return load("res://data/enemies/%s.tres" % id)


func _outcome(fields: Dictionary) -> EventOutcome:
	var o := EventOutcome.new()
	for key in fields:
		if key == "loot":
			o.loot.assign(fields[key])
		elif key == "ambush":
			o.ambush.assign(fields[key])
		else:
			o.set(key, fields[key])
	return o


func _choice(label: String, outcomes: Array) -> EventChoice:
	var c := EventChoice.new()
	c.label = label
	c.outcomes.assign(outcomes)
	return c


func _initialize() -> void:
	var event := RoomEvent.new()
	event.kind = 4  # a strange object
	event.title = "Dead lamps"
	event.min_depth = 99  # never drawn at random: only its territory places it
	event.max_depth = 99
	event.prop = load("res://art/props/cave-events-v1/old-workings.tscn")
	event.clue = "An old lamp store. Every lamp is dead - glass smashed, wicks gnawed, the oil licked dry - and moth-wings drift in the dust. Something here drinks light. On a high shelf, sealed flasks still glint."
	event.choices.assign([
		_choice("Go in, light held high", [_outcome({
			"text": "You stride in with your light up. The sealed flasks are yours - and pale shapes unfold from the ceiling, drawn to the flame.",
			"loot": {OIL: 3}, "ambush": [_e("lamp_eater"), _e("lamp_eater")],
		})]),
		_choice("Hood the light and creep in", [
			_outcome({"weight": 2, "target": EventOutcome.Target.EVERYONE, "strain": 6.0,
				"text": "In the dark you find one sealed flask by touch and back out. Something shifts overhead, but doesn't follow.",
				"loot": {OIL: 1}}),
			_outcome({"weight": 1, "target": EventOutcome.Target.EVERYONE, "strain": 6.0,
				"text": "A flask clinks against the shelf. Something drops from the ceiling, hungry for the light you're hiding.",
				"loot": {OIL: 1}, "ambush": [_e("lamp_eater")]}),
		]),
	])
	var event_path := "res://data/events/territory_lamp_eaters.tres"
	print(event_path, " ", "ok" if ResourceSaver.save(event, event_path) == OK else "FAILED")

	var p := QuestPackage.new()
	p.id = "territory_lamp_eaters"
	p.min_depth = 2
	p.max_depth = 3
	p.chance = 0.4
	p.rows = PackedStringArray(["#######", "#,,,,,#", "#,,1,,#", "#,,,,,#", "###.###"])
	p.events.assign([load(event_path)])
	var path := "res://data/packages/territory_lamp_eaters.tres"
	print(path, " ", "ok" if ResourceSaver.save(p, path) == OK else "FAILED")
	quit()
