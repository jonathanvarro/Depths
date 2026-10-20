extends RefCounted
## One expedition's record (#17): a snapshot of the party at the start plus
## counters other systems add to, turned into "gained" and "lost" lines for
## the results screen.

enum Ending { RETURNED, WIPED, REACHED_BOTTOM }

const TITLES := {
	Ending.RETURNED: "Back in the daylight",
	Ending.WIPED: "The cave keeps them",
	Ending.REACHED_BOTTOM: "The bottom of the cave",
}

## Which expedition this is: 1 is the lone survivor's escape.
var number := 1
var deepest := 0  # deepest floor reached (higher = deeper)
var floors_seen := {}  # depth -> true
var enemies_defeated := {}  # display name -> count
var retreats := 0
var events_resolved := 0
var found := {}  # SupplyItem -> count
var gold_found := 0  # coins, purses and contracts (#42)

var _start_time := 0
var _start_oil := 0.0
var _start_supplies := {}  # SupplyItem -> count
var _start_heroes := {}  # Companion -> {"health", "strain", "injuries"}


func _init(party, expedition_number := 1) -> void:
	number = expedition_number
	_start_time = party.time_elapsed
	_start_oil = party.supplies.oil + party.supplies.open_flask
	for item in party.supplies.items:
		_start_supplies[item] = party.supplies.count(item)
	for hero: Companion in party.members:
		_start_heroes[hero] = {"health": hero.health, "strain": hero.strain, "injuries": hero.injuries.duplicate(), "xp": hero.xp}


func visit_floor(depth: int) -> void:
	floors_seen[depth] = true
	deepest = maxi(deepest, depth)


func add_defeated(name: String) -> void:
	enemies_defeated[name] = enemies_defeated.get(name, 0) + 1


func add_found(loot: Dictionary) -> void:
	for item in loot:
		found[item] = found.get(item, 0) + loot[item]


## The trip in numbers, for the results screen's chips: {"time",
## "deepest", "enemies", "events", "found": {item: n}, "gold", "used":
## {item: n}, "oil", "retreats"}.
func summary(party) -> Dictionary:
	var enemies := 0
	for name in enemies_defeated:
		enemies += enemies_defeated[name]
	var used := {}
	var flasks := 0
	for item: SupplyItem in _start_supplies.keys() + found.keys():
		if used.has(item):
			continue
		var spent: int = _start_supplies.get(item, 0) + found.get(item, 0) - party.supplies.count(item)
		if spent > 0:
			used[item] = spent
			if item.effect == SupplyItem.Effect.REFILL_LANTERN:
				flasks += spent
	var oil: float = _start_oil + flasks * 100.0 - (party.supplies.oil + party.supplies.open_flask)
	return {"time": party.time_elapsed - _start_time, "deepest": deepest, "enemies": enemies,
			"events": events_resolved, "found": found, "gold": gold_found, "used": used,
			"oil": roundi(maxf(oil, 0.0)), "retreats": retreats}


## One row per hero who set out: {"hero", "back" (came home), "health_from",
## "health", "xp_from", "xp", "strain_from", "strain", "new_injuries"}.
func hero_rows(party) -> Array:
	var rows := []
	for hero: Companion in _start_heroes:
		var before: Dictionary = _start_heroes[hero]
		rows.append({"hero": hero, "back": hero.is_with_party(), "health_from": before["health"], "health": hero.health,
				"xp_from": before.get("xp", hero.xp), "xp": hero.xp, "strain_from": before["strain"], "strain": hero.strain,
				"new_injuries": hero.injuries.filter(func(i): return i not in before["injuries"])})
	return rows


## Lines describing what the expedition brought.
func gained(party) -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("Time spent: %d" % (party.time_elapsed - _start_time))
	if deepest > 0:  # floor 0 is the opening escape
		lines.append("Deepest floor: %d   ·   floors seen: %d" % [deepest, floors_seen.size()])
	else:
		lines.append("Escaped the depths alive")
	var beaten := PackedStringArray()
	for name in enemies_defeated:
		beaten.append("%s ×%d" % [name.to_lower(), enemies_defeated[name]])
	lines.append("Enemies overcome: " + (", ".join(beaten) if not beaten.is_empty() else "none"))
	lines.append("Encounters resolved: %d" % events_resolved)
	var finds := PackedStringArray()
	for item: SupplyItem in found:
		finds.append("%s ×%d" % [item.display_name.to_lower(), found[item]])
	lines.append("Found: " + (", ".join(finds) if not finds.is_empty() else "nothing"))
	if gold_found > 0:
		lines.append("Gold found: %d" % gold_found)
	for hero: Companion in _start_heroes:
		if hero.is_alive() and hero.strain < _start_heroes[hero]["strain"] - 0.5:
			lines.append("%s is calmer (strain %d → %d)" % [hero.display_name, roundi(_start_heroes[hero]["strain"]), roundi(hero.strain)])
	return lines


## Lines describing what it cost.
func lost(party) -> PackedStringArray:
	var lines := PackedStringArray()
	var oil_now: float = party.supplies.oil + party.supplies.open_flask
	var flasks_used := 0
	var used := PackedStringArray()
	for item: SupplyItem in party.supplies.items:
		var spent: int = _start_supplies.get(item, 0) + found.get(item, 0) - party.supplies.count(item)
		if spent > 0:
			used.append("%s ×%d" % [item.display_name.to_lower(), spent])
			if item.effect == SupplyItem.Effect.REFILL_LANTERN:
				flasks_used += spent
	var burned := _start_oil + flasks_used * 100.0 - oil_now
	lines.append("Lamp oil burned: %d" % roundi(maxf(burned, 0.0)))
	lines.append("Supplies used: " + (", ".join(used) if not used.is_empty() else "none"))
	if retreats > 0:
		lines.append("Retreats: %d" % retreats)
	for hero: Companion in _start_heroes:
		var before: Dictionary = _start_heroes[hero]
		if not hero.is_alive():
			lines.append("%s did not come back." % hero.display_name)
			continue
		var health_change: int = hero.health - before["health"]
		if health_change < 0:
			lines.append("%s: health %d → %d" % [hero.display_name, before["health"], hero.health])
		if hero.strain > before["strain"] + 0.5:
			lines.append("%s: strain %d → %d" % [hero.display_name, roundi(before["strain"]), roundi(hero.strain)])
		for injury in hero.injuries:
			if injury not in before["injuries"]:
				lines.append("%s: new %s" % [hero.display_name, injury.display_name.to_lower()])
	return lines
