extends RefCounted
## The four classes (#179, owner 2026-10-31; DESIGN.md "The party as one
## unit"). Duplicates are allowed, so any party of three has a gap.
##
## - Melee: armour and health, the front row. Takes the Warden's and the
##   Brawler's place.
## - Scout: awareness. Hears some fights first and always spots traps; the
##   back row, light or medium armour.
## - Mage: prayers (#170, spells.gd); light armour only.
## - Fixer: weaker in a fight, but better prices, more treasure, and clears
##   blockages such as rubble (taken over from the Brawler).
##
## Every hero has their class's standard skills plus one personal trait.

const NAMES := ["Melee", "Scout", "Mage", "Fixer"]
## What players see (owner, 2026-11-25): the ids above stay the game's
## (saves, data, rules); only these names are shown.
const LABELS := {"Melee": "Soldier", "Scout": "Scout", "Mage": "Acolyte", "Fixer": "Sapper"}
## Older roles, for saves and old recruits.
const OLD := {"Warden": "Melee", "Brawler": "Melee", "Rogue": "Scout", "Healer": "Mage"}
## Skills a class always has (Companion.has_talent counts them).
const SKILLS := {
	"Melee": [],
	"Scout": ["sharp_ears", "trap_sense"],
	"Mage": [],
	"Fixer": [],
}
## What each class may wear (data/equipment/bases.json "classes").
const MELEE_HEALTH := 4  # armour and health
const FIXER_AIM := -0.05  # weaker in a fight
const FIXER_TREASURE := 0  # no longer: the Sapper's perks are traps and rubble (2026-11-26)
const ABOUT := {
	"Melee": "Front row. Armour and health; little awareness, no magic.",
	"Scout": "Back row. Hears some fights before they notice the party and always spots traps. Heavy armour slows them more.",
	"Mage": "Prays: a few casts each trip, more prayers from tomes. Armour past light slows them more; no awareness.",
	"Fixer": "Weaker in a fight, but spots every trap, jams set ones as the party passes, and clears rubble without a tool.",
}


static func of(role: String) -> String:
	if role in NAMES:
		return role
	return OLD.get(role, "Melee")


## Updates an older hero's role to its class.
static func migrate(hero: Companion) -> void:
	hero.role = of(hero.role)


static func skills(role: String) -> Array:
	return SKILLS.get(of(role), [])


## Armour heavier than a class is used to slows it more; Melee carry heavy
## armour better (owner, 2026-11-17, #192: anyone may wear any weight).
## Class -> weight -> extra initiative lost (negative: less).
const ARMOUR_DRAG := {
	"Melee": {"heavy": -1},
	"Scout": {"heavy": 1},
	"Fixer": {"heavy": 1},
	"Mage": {"medium": 1, "heavy": 2},
}


static func armour_drag(hero: Companion, item: Equipment) -> int:
	if hero == null or item == null or item.slot != "body" or item.base_id == "":
		return 0
	var weight: String = load("res://scripts/gear_model.gd").base(item.base_id).get("weight", "")
	return int(ARMOUR_DRAG.get(of(hero.role), {}).get(weight, 0))


## Why `hero` can't wear `item`, or "". Any body armour fits anyone now
## (it slows them instead: armour_drag); the back slot keeps its rules.
static func refuses(hero: Companion, item: Equipment) -> String:
	if item != null and item.named_for != "" and item.named_for != hero.named_id:  # their own gear (#180)
		return "Only %s can use %s" % [item.named_for.capitalize(), item.display_name]
	if item == null or item.base_id == "" or item.slot != "back":
		return ""
	var gear = load("res://scripts/gear_model.gd")
	var allowed: Dictionary = gear.tables()["bases"].get("classes", {}).get(of(hero.role).to_lower(), {})
	if allowed.is_empty():
		return ""
	var b: Dictionary = gear.base(item.base_id)
	var kind: String = b.get("weight", "") if item.slot == "body" else b.get("kind", "")
	if kind != "" and kind not in allowed.get(item.slot, [kind]):
		return "A %s can't wear %s %s" % [of(hero.role).to_lower(), kind, "armour" if item.slot == "body" else ("a " + kind)]
	return ""


## The name players see for `role` (an old role reads as its class).
static func label(role: String) -> String:
	return LABELS.get(of(role), role)
