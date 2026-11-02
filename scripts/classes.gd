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
const FIXER_TREASURE := 1  # one more find in a treasure room
const ABOUT := {
	"Melee": "Front row. Armour and health; little awareness, no magic.",
	"Scout": "Back row. Hears some fights before they notice the party and always spots traps. Light or medium armour.",
	"Mage": "Prays: a few casts each trip, more prayers from tomes. Light armour only; no awareness.",
	"Fixer": "Weaker in a fight, but better prices, more treasure, and clears rubble without a tool.",
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


## Why `hero` can't wear `item`, or "".
static func refuses(hero: Companion, item: Equipment) -> String:
	if item == null or item.base_id == "" or item.slot not in ["body", "back"]:
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
