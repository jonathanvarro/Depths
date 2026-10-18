extends RefCounted
## Room-event rules (#16): picks events for a floor and applies choices.
## No visuals; event_screen.gd shows them and main.gd wires them in.

const EVENTS_DIR := "res://data/events"

## Supplies found by any choice, for the expedition record (#17).
signal loot_found(loot: Dictionary)
signal gold_found(amount: int)

var library: Array[RoomEvent] = []
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()
	library = load_library()
	if library.is_empty():
		push_error("No room events found in %s" % EVENTS_DIR)


## Every RoomEvent in data/events (works in exported builds too, where
## resources are listed with a ".remap" suffix).
static func load_library() -> Array[RoomEvent]:
	var found: Array[RoomEvent] = []
	for file in DirAccess.get_files_at(EVENTS_DIR):
		file = file.trim_suffix(".remap")
		if file.ends_with(".tres") or file.ends_with(".res"):
			var event := load(EVENTS_DIR.path_join(file)) as RoomEvent
			if event:
				found.append(event)
	return found


## A weighted random event of this kind that suits the floor, or null.
func pick(kind: int, depth: int) -> RoomEvent:
	var options := library.filter(func(e: RoomEvent): return e.kind == kind and depth >= e.min_depth and depth <= e.max_depth)
	if options.is_empty():
		return null
	var total := 0
	for event in options:
		total += event.weight
	var roll := rng.randi_range(1, total)
	for event in options:
		roll -= event.weight
		if roll <= 0:
			return event
	return options[0]


## Applies `choice` for the party. Returns {"text": String,
## "ambush": Array[EnemyType], "ends": bool}.
func resolve(party, choice: EventChoice) -> Dictionary:
	party.advance_time(choice.time_cost)
	var outcome := _pick_outcome(choice)
	var result := {"text": "", "ambush": [] as Array[EnemyType], "ends": not choice.investigation}
	if outcome == null:
		return result
	var living: Array[Companion] = party.living_members()
	var targets: Array[Companion] = []
	if outcome.target == EventOutcome.Target.EVERYONE:
		targets = living
	elif not living.is_empty():
		targets.append(living[0])  # whoever acted: the party's lead for now
	var notes := PackedStringArray()
	for hero in targets:
		if outcome.health != 0:
			hero.change_health(outcome.health)
			notes.append("%s %+d health" % [hero.display_name, outcome.health])
		if outcome.heal_over_time > 0:
			hero.add_effect_over_time("health", outcome.heal_over_time, 20)
			notes.append("%s will recover %d" % [hero.display_name, outcome.heal_over_time])
		if outcome.strain != 0.0:
			hero.change_strain(outcome.strain)
			notes.append("%s %s" % [hero.display_name, "steadies" if outcome.strain < 0 else "is shaken"])
		if outcome.injury and hero.add_injury(outcome.injury):
			notes.append("%s suffers a %s" % [hero.display_name, outcome.injury.display_name.to_lower()])
	if outcome.oil != 0.0:
		party.supplies.oil = clampf(party.supplies.oil + outcome.oil, 0.0, party.supplies.LANTERN_CAPACITY)
		party.supplies.changed.emit()
		notes.append("lantern %s" % ("refilled" if outcome.oil > 0 else "spilled"))
	if not outcome.loot.is_empty():
		loot_found.emit(outcome.loot)
	for item in outcome.loot:
		party.supplies.add(item, outcome.loot[item])
		notes.append("found %s ×%d" % [item.display_name.to_lower(), outcome.loot[item]])
	if outcome.gold > 0:
		party.supplies.gold += outcome.gold
		party.supplies.changed.emit()
		gold_found.emit(outcome.gold)
		notes.append("found %d gold" % outcome.gold)
	for item in outcome.gear:
		party.supplies.gear.append(item)
		party.supplies.changed.emit()
		notes.append("found %s" % item.display_name.to_lower())
	if outcome.rest:
		party.rest()
		notes.append("rested")
	result["ambush"] = outcome.ambush.duplicate()
	var text := outcome.text
	if not notes.is_empty():
		text += "\n(" + "; ".join(notes) + ")"
	result["text"] = text
	return result


func _pick_outcome(choice: EventChoice) -> EventOutcome:
	if choice.outcomes.is_empty():
		return null
	var total := 0
	for outcome in choice.outcomes:
		total += outcome.weight
	var roll := rng.randi_range(1, total)
	for outcome in choice.outcomes:
		roll -= outcome.weight
		if roll <= 0:
			return outcome
	return choice.outcomes[0]
