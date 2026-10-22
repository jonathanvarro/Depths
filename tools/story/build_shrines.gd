extends SceneTree
## Writes the boons and banes (data/boons) and the events that give them or
## ask for the right item (#133, owner 2026-10-21): a miners' shrine, a
## defiled shrine, a fouled well and a buried cache. Rerun to rebuild:
##   Godot --headless --path . --script tools/story/build_shrines.gd
##
## Every one is a tradeoff: an offering for a favour, a gamble you can
## study first, power with a sting, or a curse with a way out. Carrying a
## pick, spade, holy water or antidote opens a better choice.

const RATION := preload("res://data/items/ration.tres")
const HOLY_WATER := preload("res://data/items/holy_water.tres")
const ANTIDOTE := preload("res://data/items/antidote.tres")
const SPADE := preload("res://data/items/spade.tres")
const PICK := preload("res://data/items/pick.tres")
const ORE := preload("res://data/items/copper_ore.tres")
const OIL := preload("res://data/items/oil_flask.tres")
const SHRINE := "res://art/dressing/landmarks-v1/miners-shrine-event.tscn"  # #132's shrine, set in a wall
const DEFILED_SHRINE := "res://art/props/shrine-events-v1/defiled-shrine.tscn"
const POOL := "res://art/props/shrine-events-v1/fouled-well.tscn"
const WORKINGS := "res://art/props/shrine-events-v1/buried-cache.tscn"
const OBJECT := 4  # DungeonMap.Content.STRANGE_OBJECT
const CHEST := 2


func _boon(id: String, name: String, about: String, bane: bool, fights: int, effects: Dictionary) -> Boon:
	var b := Boon.new()
	b.display_name = name
	b.icon = load("res://art/ui/boons-v2/%s.png" % id.replace("_", "-"))
	b.description = about
	b.bane = bane
	b.fights = fights
	for key in effects:
		b.set(key, effects[key])
	var path := "res://data/boons/%s.tres" % id
	print(path, " ", "ok" if ResourceSaver.save(b, path) == OK else "FAILED")
	return load(path)


func _outcome(text: String, extra := {}) -> EventOutcome:
	var o := EventOutcome.new()
	o.text = text
	for key in extra:
		if key == "loot":
			o.loot.assign(extra[key])  # a typed dictionary: set() would drop it silently (#137)
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


func _event(name: String, title: String, clue: String, choices: Array, kind: int, depths: Vector2i, prop: String, weight := 1, on_wall := false) -> void:
	var e := RoomEvent.new()
	e.title = title
	e.clue = clue
	e.kind = kind
	e.min_depth = depths.x
	e.max_depth = depths.y
	e.weight = weight
	e.choices.assign(choices)
	e.prop = load(prop)
	e.prop_on_wall = on_wall
	var path := "res://data/events/%s.tres" % name
	print(path, " ", "ok" if ResourceSaver.save(e, path) == OK else "FAILED")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/boons")
	# Boons: strong ones last fights, mild ones until camp.
	var luck := _boon("miners_luck", "Miners' luck", "+8% to hit.", false, 3, {"accuracy": 0.08})
	var quiet := _boon("quiet_heart", "Quiet heart", "Nerves fray half as fast.", false, 0, {"strain_rate": 0.5})
	var lamp := _boon("lamp_blessing", "Lamp blessing", "The lantern burns a quarter slower.", false, 0, {"oil_rate": 0.75})
	var eyes := _boon("deep_eyes", "Deep eyes", "Traps show before you step on them.", false, 0, {"reveals_traps": true})
	var blessed := _boon("blessed", "Blessed", "+1 damage.", false, 3, {"damage": 1})
	var hearty := _boon("hearty", "Hearty", "Healing does half again as much.", false, 0, {"healing": 1.5})
	var blood := _boon("blood_of_the_deep", "Blood of the deep", "+2 damage, but healing does only half.", false, 3, {"damage": 2, "healing": 0.5})
	# Banes.
	var withering := _boon("withering", "Withering", "4 less maximum health.", true, 3, {"max_health": -4})
	var marked := _boon("marked", "Marked", "Something follows: ambushes come twice as often.", true, 0, {"draws_ambush": true})
	var sick := _boon("sickness", "Sickness", "Healing does only half, and nerves fray faster.", true, 0, {"healing": 0.5, "strain_rate": 1.5})
	var clumsy := _boon("shaking_hands", "Shaking hands", "8% less to hit, 1 less damage.", true, 3, {"accuracy": -0.08, "damage": -1})

	# A miners' shrine: an offering for a favour.
	_event("object_miners_shrine", "A miners' shrine",
		"A niche cut neatly into the rock: candle stubs, a tin cup, a coin worn smooth. Someone kept this, once.",
		[
			_choice("Leave a ration", [_outcome("You set the food in the cup. The candle stubs seem to lean toward you.", {"boon": luck})], 1, {"requires": RATION}),
			_choice("Leave 10 gold", [_outcome("The coins ring in the tin. A calm settles on you, like a hand on the shoulder.", {"boon": quiet})], 1, {"gold_cost": 10}),
			_choice("Pour a flask of oil into the cup", [_outcome("The oil pools, dark and still. Your light steadies.", {"boon": lamp})], 1, {"requires": OIL}),
			_choice("Pray", [
				_outcome("You stay a while. Your breathing slows.", {"strain": -10.0, "weight": 2}),
				_outcome("As you rise you notice what you hadn't: the loose stones, the thin places in the floor.", {"boon": eyes}),
				_outcome("Nothing answers. The cold gets into your knees.", {"weight": 2}),
			], 2),
		], OBJECT, Vector2i(1, 3), SHRINE, 2, true)

	# A defiled shrine: bless it, break it, or gamble on it - and you can
	# study it first.
	_event("object_defiled_shrine", "A defiled shrine",
		"The same miners' niche, but goblin hands have smeared it with something dark, and a black stone sits where the candles were. It feels warm.",
		[
			_choice("Study it", [_outcome("Scratches around the niche: tally marks in two columns. Under one, a fist. Under the other, a skull. About as many of each.")], 2, {"investigation": true}),
			_choice("Bless it with holy water", [_outcome("The stone hisses and cracks. Clean candlelight, from nowhere, for a breath. Everyone stands straighter.", {"target": EventOutcome.Target.EVERYONE, "boon": blessed})], 1, {"requires": HOLY_WATER}),
			_choice("Smash the stone", [
				_outcome("It splits with a sound like a sigh. The air lightens.", {"target": EventOutcome.Target.EVERYONE, "strain": -6.0, "weight": 2}),
				_outcome("It breaks - and somewhere far off, something notices.", {"boon": marked}),
			], 2, {"requires": PICK}),
			_choice("Touch the dark stone", [
				_outcome("Heat runs up your arm and into your fists. It doesn't feel like yours.", {"boon": blood}),
				_outcome("The warmth drains out of you instead.", {"boon": withering}),
			], 1),
		], OBJECT, Vector2i(2, 4), DEFILED_SHRINE, 2, true)

	# A fouled well: safe with an antidote, a gamble without.
	_event("object_fouled_well", "A fouled well",
		"A miners' well, rope long rotted. The water smells wrong, but it's water.",
		[
			_choice("Stir in an antidote and drink", [_outcome("Bitter, then clean. Cold all the way down.", {"target": EventOutcome.Target.EVERYONE, "heal_over_time": 8, "boon": hearty})], 1, {"requires": ANTIDOTE}),
			_choice("Drink anyway", [
				_outcome("You keep it down. It helps, a little.", {"heal_over_time": 4}),
				_outcome("Your stomach clenches. You'll pay for that.", {"health": -2, "boon": sick, "weight": 2}),
			], 1),
		], OBJECT, Vector2i(1, 3), POOL, 2)

	# A buried cache: tools dig it out cleanly, hands may not.
	_event("chest_buried_cache", "A buried cache",
		"A slump of fallen rock, and under it the corner of a crate stamped with the king's mark.",
		[
			_choice("Dig it out with the spade", [_outcome("The crate comes free, lid intact.", {"treasure": 2, "gold": 8})], 3, {"requires": SPADE}),
			_choice("Break the rock with the pick", [_outcome("The rock gives in chunks. The crate is crushed, but some of it is still good - and there's ore in the rock.", {"treasure": 1, "loot": {ORE: 1}})], 2, {"requires": PICK}),
			_choice("Dig with your hands", [
				_outcome("Fingers raw, you prise out what you can.", {"treasure": 1}),
				_outcome("A rock shifts and drops on your hand.", {"health": -3, "boon": clumsy}),
			], 4),
		], CHEST, Vector2i(1, 3), WORKINGS, 2)
	print("done")
	quit()
