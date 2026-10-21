extends RefCounted
## Room-event rules (#16): picks events for a floor and applies choices.
## No visuals; event_screen.gd shows them and main.gd wires them in.

const EVENTS_DIR := "res://data/events"
const Glyphs := preload("res://art/ui/backlog96-v1/glyphs.gd")
const Quests := preload("res://scripts/quests.gd")
## Result chips (#105): what changed, as an icon and a number.
const CHIP_ICONS := {
	"health": preload("res://art/ui/visual105-v1/heart.png"),
	"strain": preload("res://art/ui/visual105-v1/nerves.png"),
	"rest": preload("res://art/ui/visual105-v1/rest.png"),
	"gold": preload("res://art/ui/coin-v1/heads.png"),
	"oil": preload("res://data/items/oil_flask.tres"),
}
## Boon (false) and bane (true) marks when a Boon has no icon of its own (#133).
const BOON_ICONS := {false: preload("res://art/ui/boons-v1/boon.png"), true: preload("res://art/ui/boons-v1/bane.png")}

## Supplies found by any choice, for the expedition record (#17).
signal loot_found(loot: Dictionary)
signal gold_found(amount: int)

## Valuables a room can hold (#42): [item, deepest-from depth, weight].
## Cheap finds near the top, richer ones deeper. Art: ChatGPT's treasure
## sets (#90, #91); values are game data in each item.
const TREASURE := [
	[preload("res://data/items/amethyst.tres"), 1, 3],
	[preload("res://data/items/fine_cloth.tres"), 1, 3],
	[preload("res://data/items/silver_trinket.tres"), 1, 3],
	[preload("res://data/items/military_medal.tres"), 1, 2],
	[preload("res://data/items/silver_locket.tres"), 1, 2],
	[preload("res://data/items/garnet.tres"), 1, 2],
	[preload("res://data/items/amber_pendant.tres"), 2, 2],
	[preload("res://data/items/spice_pouch.tres"), 2, 2],
	[preload("res://data/items/silver_goblet.tres"), 2, 2],
	[preload("res://data/items/old_coin_purse.tres"), 2, 2],
	[preload("res://data/items/gold_signet_ring.tres"), 2, 1],
	[preload("res://data/items/gold_nuggets.tres"), 2, 1],
	[preload("res://data/items/silver_ingot.tres"), 3, 1],
	[preload("res://data/items/emerald.tres"), 3, 1],
	[preload("res://data/items/small_reliquary.tres"), 3, 1],
	[preload("res://data/items/pearl_necklace.tres"), 3, 1],
]

## The floor being explored; main.gd sets it before an event (#42).
var depth := 1
## The camp, for events that move quests on (#123); set by main.gd.
var camp

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
## "ambush": Array[EnemyType], "ends": bool, "story": String, "changes":
## Array of {"icon": Texture2D, "text": String, "good": bool}} - the story
## line and what changed as chips (#105); "text" has both in words.
## `forced`: which outcome to use (the coin decided), or -1 to pick by weight.
## `flags`: the room's preparation so far (#114); outcomes it rules out
## aren't rolled, and this outcome's own flag is added to it.
func resolve(party, choice: EventChoice, forced := -1, flags: Array = []) -> Dictionary:
	party.advance_time(choice.time_cost)
	# What the choice asks for (#133): an item (tools are kept) and gold.
	if choice.requires and choice.requires.effect != SupplyItem.Effect.TOOL:
		party.supplies.take(choice.requires)
	if choice.gold_cost > 0:
		party.supplies.gold = maxi(0, party.supplies.gold - choice.gold_cost)
		party.supplies.changed.emit()
	var outcome: EventOutcome = choice.outcomes[forced] if forced >= 0 and forced < choice.outcomes.size() else _pick_outcome(choice, flags, party.draws_ambush())
	if outcome and outcome.sets_flag != "" and outcome.sets_flag not in flags:
		flags.append(outcome.sets_flag)
	if outcome and outcome.quest != "" and camp != null:
		if outcome.quest_stage >= 0:
			Quests.set_stage(camp, outcome.quest, outcome.quest_stage)
		if outcome.quest_flag != "":
			Quests.set_flag(camp, outcome.quest, outcome.quest_flag)
	# "no_room": finds that didn't fit in the pack (#133), for main.gd to offer.
	var result := {"text": "", "ambush": [] as Array[EnemyType], "ends": not choice.investigation, "story": "", "changes": [], "no_room": {}}
	if outcome == null:
		return result
	var changes: Array = result["changes"]
	var named: bool = outcome.target == EventOutcome.Target.EVERYONE and party.living_members().size() > 1
	var chip := func(icon: Texture2D, text: String, good: bool, hero) -> void:
		changes.append({"icon": icon, "text": ("%s %s" % [hero.display_name, text]) if hero and named else text, "good": good})
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
			chip.call(CHIP_ICONS["health"], "%+d" % outcome.health, outcome.health > 0, hero)
		if outcome.heal_over_time > 0:
			hero.add_effect_over_time("health", outcome.heal_over_time, 20)
			notes.append("%s will recover %d" % [hero.display_name, outcome.heal_over_time])
			chip.call(Glyphs.STATUS["healing"], "+%d" % outcome.heal_over_time, true, hero)
		if outcome.strain != 0.0:
			hero.change_strain(outcome.strain)
			notes.append("%s %s" % [hero.display_name, "steadies" if outcome.strain < 0 else "is shaken"])
			chip.call(CHIP_ICONS["strain"], "-" if outcome.strain < 0 else "+", outcome.strain < 0, hero)
		if outcome.boon:
			hero.add_boon(outcome.boon)
			notes.append("%s: %s" % [hero.display_name, outcome.boon.display_name.to_lower()])
			chip.call(outcome.boon.icon if outcome.boon.icon else BOON_ICONS[outcome.boon.bane], outcome.boon.display_name, not outcome.boon.bane, hero)
		if outcome.lift_bane:
			var lifted: Boon = hero.lift_bane()
			if lifted:
				notes.append("%s is free of %s" % [hero.display_name, lifted.display_name.to_lower()])
				chip.call(BOON_ICONS[false], "lifted: " + lifted.display_name, true, hero)
		if outcome.injury and hero.add_injury(outcome.injury):
			notes.append("%s suffers a %s" % [hero.display_name, outcome.injury.display_name.to_lower()])
			chip.call(Glyphs.STATUS["limp" if outcome.injury.icon_kind == "limp" else "deep-wound"], outcome.injury.display_name, false, hero)
	if outcome.oil != 0.0:
		party.supplies.oil = clampf(party.supplies.oil + outcome.oil, 0.0, party.supplies.LANTERN_CAPACITY)
		party.supplies.changed.emit()
		notes.append("lantern %s" % ("refilled" if outcome.oil > 0 else "spilled"))
		chip.call(CHIP_ICONS["oil"].icon, "+" if outcome.oil > 0 else "-", outcome.oil > 0, null)
	var loot: Dictionary = outcome.loot.duplicate()
	for i in outcome.treasure:
		var find: SupplyItem = random_treasure(depth)
		loot[find] = loot.get(find, 0) + 1
	if not loot.is_empty():
		loot_found.emit(loot)
	for item in loot:
		var fits: int = party.supplies.add_what_fits(item, loot[item])
		if fits < loot[item]:
			result["no_room"][item] = loot[item] - fits
		notes.append("found %s ×%d" % [item.display_name.to_lower(), loot[item]])
		chip.call(item.icon, "×%d" % loot[item] if item.icon else "%s ×%d" % [item.display_name, loot[item]], true, null)
	if outcome.gold > 0:
		party.supplies.gold += outcome.gold
		party.supplies.changed.emit()
		gold_found.emit(outcome.gold)
		notes.append("found %d gold" % outcome.gold)
		chip.call(CHIP_ICONS["gold"], "+%d" % outcome.gold, true, null)
	for item in outcome.gear:
		if not party.supplies.has_room_for_gear():
			notes.append("no room for %s" % item.display_name.to_lower())
			chip.call(item.icon, "no room", false, null)
			continue
		party.supplies.gear.append(item)
		party.supplies.changed.emit()
		notes.append("found %s" % item.display_name.to_lower())
		chip.call(item.icon, "" if item.icon else item.display_name, true, null)
	if outcome.rest:
		party.rest()
		notes.append("rested")
		chip.call(CHIP_ICONS["rest"], "", true, null)
	result["ambush"] = outcome.ambush.duplicate()
	result["story"] = outcome.text
	var text := outcome.text
	if not notes.is_empty():
		text += "\n(" + "; ".join(notes) + ")"
	result["text"] = text
	return result


## One valuable fit for `floor_depth`, picked by weight.
func random_treasure(floor_depth: int) -> SupplyItem:
	var pool := TREASURE.filter(func(t): return t[1] <= maxi(1, floor_depth))
	var total := 0
	for entry in pool:
		total += entry[2]
	var roll := randi_range(1, total)
	for entry in pool:
		roll -= entry[2]
		if roll <= 0:
			return entry[0]
	return pool[0][0]


## `hunted`: a bane draws ambushes - outcomes that end in one weigh double (#133).
func _pick_outcome(choice: EventChoice, flags: Array = [], hunted := false) -> EventOutcome:
	var possible: Array = choice.outcomes.filter(func(o: EventOutcome): return o.blocked_by == "" or o.blocked_by not in flags)
	if possible.is_empty():
		return null
	var weight := func(o: EventOutcome) -> int: return o.weight * (2 if hunted and not o.ambush.is_empty() else 1)
	var total := 0
	for outcome in possible:
		total += weight.call(outcome)
	var roll := rng.randi_range(1, total)
	for outcome in possible:
		roll -= weight.call(outcome)
		if roll <= 0:
			return outcome
	return possible[0]
