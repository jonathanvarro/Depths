extends SceneTree
## Writes the traps (#94, owner 2026-10-25) into data/events: the bell wire,
## the snare and the dart plate, and gives the older tripwire and hollow
## floor what happens when no one spots them (`sprung`). A spotted trap
## offers its choices; an unspotted one springs as the party walks in.
## Rerun to rebuild:
## Godot --headless --path . --script tools/story/build_traps.gd

const LIMP := preload("res://data/injuries/limp.tres")
const BELL_WIRE := preload("res://art/props/traps-lamps-v1/bell.tscn")
const SNARE := preload("res://art/props/traps-lamps-v1/snare.tscn")
const DART := preload("res://art/props/traps-lamps-v1/dart.tscn")


func _outcome(fields: Dictionary) -> EventOutcome:
	var o := EventOutcome.new()
	for key in fields:
		o.set(key, fields[key])
	return o


func _choice(label: String, time: int, outcomes: Array) -> EventChoice:
	var c := EventChoice.new()
	c.label = label
	c.time_cost = time
	c.outcomes.assign(outcomes)
	return c


func _trap(id: String, title: String, clue: String, prop: PackedScene, min_depth: int, choices: Array, sprung: EventOutcome) -> void:
	var e := RoomEvent.new()
	e.kind = 3
	e.title = title
	e.clue = clue
	e.prop = prop
	e.min_depth = min_depth
	e.max_depth = 99
	e.weight = 2
	e.choices.assign(choices)
	e.sprung = sprung
	var path := "res://data/events/%s.tres" % id
	print(path, " ", "ok" if ResourceSaver.save(e, path) == OK else "FAILED")


func _initialize() -> void:
	_trap("trap_bell_wire", "A bell wire",
			"A thin wire across the way, strung with a tiny goblin bell. Ring it and everything down here will know.", BELL_WIRE, 2, [
		_choice("Step over carefully", 2, [
			_outcome({"weight": 3, "text": "You ease over without a sound."}),
			_outcome({"weight": 1, "alarm": true, "text": "The bell tinkles. Somewhere ahead, something goes very quiet."})]),
		_choice("Hold the bell and cut it", 3, [
			_outcome({"weight": 4, "text": "You still the bell in your fist and cut the wire."}),
			_outcome({"weight": 1, "alarm": true, "text": "The clapper slips your fingers - one clear note rings out."})]),
	], _outcome({"alarm": true, "strain": 3.0,
		"text": "Your foot snags a wire you never saw. A little bell rings out, bright and terrible. Whatever is down here knows you're coming."}))

	_trap("trap_snare", "A snare",
			"A loop of cord lies half-buried in the grit, staked to the rock.", SNARE, 1, [
		_choice("Step around it", 1, [
			_outcome({"weight": 4, "text": "You give it a wide berth."}),
			_outcome({"weight": 1, "injury": LIMP, "text": "Your boot clips the loop - it snaps tight around your ankle."})]),
		_choice("Spring it with a stick", 2, [
			_outcome({"text": "The loop whips shut on the stick. Harmless now."})]),
	], _outcome({"injury": LIMP, "text": "A noose snaps tight around your ankle and yanks you off your feet."}))

	_trap("trap_dart", "A dart plate",
			"Tiny holes pock the wall at knee height, and one floor stone sits a shade too proud.", DART, 2, [
		_choice("Edge along the far wall", 2, [
			_outcome({"weight": 3, "text": "You keep clear of the plate."}),
			_outcome({"weight": 1, "health": -3, "text": "The stone shifts anyway. A dart hisses out and bites your calf."})]),
		_choice("Jam the plate with a stone", 2, [
			_outcome({"weight": 3, "text": "The plate clicks against the stone and holds."}),
			_outcome({"weight": 1, "health": -3, "text": "It slips - click - and a dart bites deep."})]),
	], _outcome({"health": -3, "text": "Click. Darts hiss from the wall, and one bites deep."}))

	# The older traps, sprung unseen.
	for spec in [
		["trap_tripwire", _outcome({"health": -3, "strain": 5.0, "text": "Your heel catches a wire you never saw. Stones crash down from above!"})],
		["trap_hollow_floor", _outcome({"health": -4, "text": "The floor gives way under you and you drop hard onto broken stone."})],
	]:
		var path := "res://data/events/%s.tres" % spec[0]
		var e: RoomEvent = load(path)
		e.sprung = spec[1]
		print(path, " ", "ok" if ResourceSaver.save(e, path) == OK else "FAILED")
	quit()
