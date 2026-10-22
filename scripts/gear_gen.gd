extends RefCounted
## Finer weapons and armour (owner, 2026-10-21): found gear is a smith's
## common piece made better. Each one is generated when it drops.
##   fine   - slightly better base: a weapon +1 damage or +5% to hit,
##            armour +2 maximum health ("Sharpened", "Balanced", "Reinforced")
##   magic  - fine, plus one modifier (its name: "Keen iron sword")
##   rare   - fine, plus a prefix and a suffix modifier ("Keen iron sword
##            of steady nerves")
## No drawbacks: those belong to trinkets (and, later, cursed gear). Better
## pieces sell for more. Uniques are named one-offs for the story, later.

const CampState := preload("res://scripts/camp_state.gd")

## Modifiers: name, whether it goes before or after the item's name, and
## its effect (Boon fields). "rare_only" and "reach_only" limit where they
## can roll.
const WEAPON_MODS := [
	{"name": "Keen", "prefix": true, "effects": {"accuracy": 0.05}},
	{"name": "Heavy", "prefix": true, "effects": {"damage": 1}},
	{"name": "of steady nerves", "prefix": false, "effects": {"strain_rate": 0.85}},
	{"name": "of the lamplighter", "prefix": false, "effects": {"light_accuracy": 0.05}},
	{"name": "of the back rank", "prefix": false, "effects": {"back_row_damage": 1}, "reach_only": true},
]
const ARMOUR_MODS := [
	{"name": "Warded", "prefix": true, "effects": {"max_health": 2}},
	{"name": "Lamp-hooked", "prefix": true, "effects": {"oil_rate": 0.9}},
	{"name": "of calm", "prefix": false, "effects": {"strain_rate": 0.85}},
	{"name": "of mending", "prefix": false, "effects": {"healing": 1.2}},
	{"name": "of the mole", "prefix": false, "effects": {"reveals_traps": true}, "rare_only": true},
]
const PRICE_TIMES := {"fine": 1.5, "magic": 2.5, "rare": 4.0}
## How likely a drop is, and how good, by floor (owner, 2026-10-21).
const CHEST_CHANCE := {1: 0.10, 2: 0.10, 3: 0.15, 4: 0.15}
const FOE_CHANCE := {1: 0.06, 2: 0.06, 3: 0.08, 4: 0.08}
const TIER_ODDS := {
	1: {"fine": 1.0},
	2: {"fine": 0.7, "magic": 0.3},
	3: {"magic": 0.75, "rare": 0.25},
	4: {"magic": 0.6, "rare": 0.4},
}
const TOUGH_HEALTH := 10  # as for trinkets: foes with this much health or more
const ELITE_TIMES := 3.0
const ORDINARY_TIMES := 0.5


## The smith's common weapons and armour: what finer gear is made from.
static func bases() -> Array[Equipment]:
	var found: Array[Equipment] = []
	for item: Equipment in CampState.SMITH_STOCK:
		if item.slot in ["weapon", "body"]:
			found.append(item)
	return found


## A chest's or a tougher foe's find, if any: a generated piece, or null.
## `source`: "chest" or "foe".
## Elites (#140) count as tougher whatever their health and carry most of
## the chance; ordinary tougher foes carry less.
static func drop(rng: RandomNumberGenerator, depth: int, source: String, foe_health := 0, elite := false) -> Equipment:
	var floor := clampi(depth, 1, 4)
	if source == "foe" and foe_health < TOUGH_HEALTH and not elite:
		return null
	var chance: float = (CHEST_CHANCE if source == "chest" else FOE_CHANCE)[floor]
	if source == "foe":
		chance *= ELITE_TIMES if elite else ORDINARY_TIMES
	if rng.randf() >= chance:
		return null
	var tier := _roll_tier(rng, TIER_ODDS[floor])
	var pool := bases()
	return make(pool[rng.randi_range(0, pool.size() - 1)], tier, rng)


static func _roll_tier(rng: RandomNumberGenerator, odds: Dictionary) -> String:
	var roll := rng.randf()
	for tier in odds:
		roll -= odds[tier]
		if roll < 0.0:
			return tier
	return odds.keys()[-1]


## `base` made into a `tier` piece ("fine", "magic" or "rare").
static func make(base: Equipment, tier: String, rng: RandomNumberGenerator) -> Equipment:
	var item: Equipment = base.duplicate()
	item.tier = tier
	item.price = roundi(base.price * PRICE_TIMES.get(tier, 1.0))
	var effects := {}
	var noun := _noun(base.display_name)
	var name := noun
	# Fine: the base itself, slightly better.
	if base.slot == "weapon":
		if rng.randi() % 2 == 0:
			item.attack_max += 1
			name = "Sharpened " + _lower_first(noun)
		else:
			item.accuracy_bonus += 0.05
			name = "Balanced " + _lower_first(noun)
	else:
		effects["max_health"] = 2
		name = "Reinforced " + _lower_first(noun)
	# Magic and rare: modifiers, which name the piece instead.
	var pool: Array = (WEAPON_MODS if base.slot == "weapon" else ARMOUR_MODS).filter(func(m):
		return (not m.get("reach_only", false) or base.reach) and (tier == "rare" or not m.get("rare_only", false)))
	var chosen: Array = []
	if tier == "magic":
		chosen.append(pool[rng.randi_range(0, pool.size() - 1)])
	elif tier == "rare":
		var prefixes: Array = pool.filter(func(m): return m["prefix"])
		var suffixes: Array = pool.filter(func(m): return not m["prefix"])
		chosen.append(prefixes[rng.randi_range(0, prefixes.size() - 1)])
		chosen.append(suffixes[rng.randi_range(0, suffixes.size() - 1)])
	if not chosen.is_empty():
		name = noun
		for mod in chosen:
			name = "%s %s" % [mod["name"], _lower_first(name)] if mod["prefix"] else "%s %s" % [name, mod["name"]]
			for key in mod["effects"]:
				var value = mod["effects"][key]
				if key in ["strain_rate", "healing", "oil_rate"]:
					effects[key] = effects.get(key, 1.0) * value
				elif value is bool:
					effects[key] = value
				else:
					effects[key] = effects.get(key, 0) + value
	item.display_name = name.substr(0, 1).to_upper() + name.substr(1)
	if not effects.is_empty():
		var boon := Boon.new()
		boon.display_name = item.display_name
		for key in effects:
			boon.set(key, effects[key])
		boon.description = boon.effects_text()
		item.effect = boon
	return item


static func _lower_first(text: String) -> String:
	return text.substr(0, 1).to_lower() + text.substr(1)


## "Companion's iron sword" -> "Iron sword": the plain thing itself.
static func _noun(base_name: String) -> String:
	return base_name.trim_prefix("Companion's ").substr(0, 1).to_upper() + base_name.trim_prefix("Companion's ").substr(1)
