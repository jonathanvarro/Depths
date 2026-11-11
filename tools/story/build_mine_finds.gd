extends SceneTree
## Writes floor 1-2's mine finds (owner, 2026-11-10): a tool rack where
## basic mining weapons can be had, and a coal seam - a common resource the
## merchant buys back at camp. Rerun to rebuild:
##   Godot --headless --path . --script tools/story/build_mine_finds.gd

const MATTOCK := "res://data/gear/mattock.tres"
const SLEDGE := "res://data/gear/miners_sledge.tres"
const PICK := preload("res://data/items/pick.tres")
const COAL := preload("res://data/items/coal.tres")
const ORE := preload("res://data/items/copper_ore.tres")
## Art: the old workings' 3D prop stands in until a tool rack and a coal
## face are modelled (art requests on GitHub).
const RACK_PROP := "res://art/props/expedition-3d-v1/old-workings.tscn"
const SEAM_PROP := "res://art/props/expedition-3d-v1/old-workings.tscn"
const CHEST := 2  # DungeonMap.Content.CHEST: finds


func _outcome(text: String, extra := {}) -> EventOutcome:
	var o := EventOutcome.new()
	o.text = text
	for key in extra:
		if key == "loot":
			o.loot.assign(extra[key])  # a typed dictionary: set() would drop it silently (#137)
		elif key == "gear":
			o.gear.assign(extra[key])
		else:
			o.set(key, extra[key])
	return o


func _choice(label: String, outcomes: Array, time := 1, extra := {}) -> EventChoice:
	var c := EventChoice.new()
	c.label = label
	c.time_cost = time
	c.outcomes.assign(outcomes)
	for key in extra:
		c.set(key, extra[key])
	return c


func _event(name: String, title: String, clue: String, choices: Array, depths: Vector2i, prop: String, weight := 1) -> void:
	var e := RoomEvent.new()
	e.title = title
	e.clue = clue
	e.kind = CHEST
	e.min_depth = depths.x
	e.max_depth = depths.y
	e.weight = weight
	e.choices.assign(choices)
	e.prop = load(prop)
	var path := "res://data/events/%s.tres" % name
	print(path, " ", "ok" if ResourceSaver.save(e, path) == OK else "FAILED")


func _initialize() -> void:
	# The tool rack: one sound weapon (or the pick), and a little coal.
	_event("chest_tool_rack", "A tool rack",
			"Picks, hammers and mattocks hang from wooden pegs where the miners left them. Most have rusted through.",
			[
				_choice("Take what's still good", [
					_outcome("Most of what hangs here has rusted through, but one mattock is still sound, its haft dark with old hands.", {"weight": 2, "gear": [load(MATTOCK)]}),
					_outcome("Behind the rotten picks hangs a miner's sledge, its iron head still true.", {"weight": 2, "gear": [load(SLEDGE)]}),
					_outcome("Only a short miner's pick is fit to use. Not much in a fight, but it works a seam or breaks through fallen rock.", {"weight": 1, "loot": {PICK: 1}}),
				], 2),
				_choice("Search the shelf above", [
					_outcome("A few lumps of coal the miners never burned. The merchant will pay a little for them.", {"loot": {COAL: 2}}),
				], 1, {"investigation": true}),
			], Vector2i(1, 2), RACK_PROP, 2)

	# The coal seam: by hand a lump or two; a pick works it properly.
	_event("chest_coal_seam", "A coal seam",
			"A band of black coal runs through the rock here, crumbling at the edges where the miners stopped.",
			[
				_choice("Work it with the pick", [
					_outcome("The pick bites and the coal comes away in good lumps. Now and then, a green fleck of copper.", {"loot": {COAL: 4, ORE: 1}}),
				], 3, {"requires": PICK}),
				_choice("Prise some loose by hand", [
					_outcome("Black-handed and sore, you pull a couple of lumps free.", {"loot": {COAL: 2}}),
					_outcome("It comes away in dust and splinters. One lump is worth keeping.", {"loot": {COAL: 1}}),
				], 3),
			], Vector2i(1, 2), SEAM_PROP, 2)
	quit()
