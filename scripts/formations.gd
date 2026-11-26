extends RefCounted
## Party formations (#305, owner 2026-11-26). The party's classes play off
## each other: what it is good at, and its blind spots, are named at the
## campfire before setting out.
##
## - Pure (three of a kind): a big ability that changes how the party moves
##   through a floor.
## - Pair (two of a kind): a smaller version of that ability.
## - Mixed (three different classes): a steady all-round bonus.
##
## Set when the party leaves camp (Companion.set_out). Underground, a hero
## knocked out or killed steps it down to what the others still make; getting
## back up restores it, a death doesn't (a dead hero never stands again).
## Static helpers only (no static variables: see #100). Numbers are first
## guesses, to tune in playtests.

## Role ids (classes.gd NAMES): Melee = Soldier, Scout, Mage = Acolyte, Fixer = Sapper.
const PURE := {
	"Melee": {"name": "Shield Wall", "bonus": "Every blow against the party lands 1 lighter."},
	"Scout": {"name": "Pathfinders", "bonus": "Every fight is heard before it notices you, rooms map in full as you enter, and wandering packs show on the map."},
	"Fixer": {"name": "Tunnel Crew", "bonus": "Locked doors and chained gates give way without key or lever, and treasure rooms yield an extra find."},
	"Mage": {"name": "Vigil", "bonus": "Each Acolyte sets out with an extra prayer, and nerves fray a quarter slower."},
}
const PAIR := {
	"Melee": {"name": "Spearhead", "bonus": "Blows against the front row land 1 lighter."},
	"Scout": {"name": "Lookouts", "bonus": "Rooms map in full as you enter."},
	"Fixer": {"name": "Work Gang", "bonus": "Treasure rooms yield an extra find."},
	"Mage": {"name": "Chantry", "bonus": "Nerves fray a tenth slower."},
}
const MIXED := {"name": "Survey Party", "bonus": "Nerves fray a tenth slower, and lantern oil lasts a tenth longer."}

## What a missing class leaves the party without (the blind spots).
const WITHOUT := {
	"Melee": "No Soldier: a thin front row.",
	"Scout": "No Scout: traps go unseen and fights are rarely heard first.",
	"Fixer": "No Sapper: disarming is a gamble and rubble needs a tool.",
	"Mage": "No Acolyte: no prayers to mend or light the way.",
}

## Tiers from strongest down.
const TIERS := ["pure", "pair", "mixed"]

## Strain gains are scaled by this (Vigil, Chantry, Survey Party).
const CALM := {"pure:Mage": 0.75, "pair:Mage": 0.9, "mixed": 0.9}
## The light burns this much (Survey Party).
const LIGHT_RATE := {"mixed": 0.9}
## Time spent forcing a lock or a chained gate (Tunnel Crew).
const PICK_TIME := 6
const GATE_TIME := 10


## The formation `heroes` make, standing as they are: {} if none. Keys: id
## ("pure:Melee", "pair:Scout", "mixed"), tier, role, name, bonus.
static func of(heroes: Array) -> Dictionary:
	var counts := {}
	for hero: Companion in heroes:
		counts[hero.role] = counts.get(hero.role, 0) + 1
	for role in counts:
		if counts[role] >= 3:
			return {"id": "pure:" + role, "tier": "pure", "role": role, "name": PURE[role]["name"], "bonus": PURE[role]["bonus"]} if PURE.has(role) else {}
	for role in counts:
		if counts[role] == 2 and PAIR.has(role):
			return {"id": "pair:" + role, "tier": "pair", "role": role, "name": PAIR[role]["name"], "bonus": PAIR[role]["bonus"]}
	if heroes.size() >= 3 and counts.size() >= 3:
		return {"id": "mixed", "tier": "mixed", "role": "", "name": MIXED["name"], "bonus": MIXED["bonus"]}
	return {}


## The party's formation now: who set out with it and still stands.
static func current(party) -> Dictionary:
	return of(party.members.filter(func(h: Companion): return h.set_out and h.is_alive()))


## The blind spots of a party of `heroes`: one line per missing class.
static func blind_spots(heroes: Array) -> Array[String]:
	var roles := {}
	var keen := false
	for hero: Companion in heroes:
		roles[hero.role] = true
		keen = keen or hero.trait_id == "keen_eyes"
	var out: Array[String] = []
	for role in ["Melee", "Scout", "Fixer", "Mage"]:
		if not roles.has(role):
			out.append("No Scout: fights are rarely heard first." if role == "Scout" and keen else WITHOUT[role])
	return out


## For the campfire and the preparation screen: [name line, bonus, blind
## spots], or an empty array for a party of one.
static func describe(heroes: Array) -> Array:
	if heroes.size() < 2:
		return []
	var f := of(heroes)
	var head: String = f["name"] if not f.is_empty() else "No formation"
	var bonus: String = f["bonus"] if not f.is_empty() else "Two of a kind, or three different classes, make a formation."
	return [head, bonus, " ".join(blind_spots(heroes))]
