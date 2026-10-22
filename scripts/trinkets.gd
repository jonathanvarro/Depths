extends RefCounted
## Trinkets (#135; owner 2026-10-21): where they're defined and how they
## turn up. Definitions are Equipment with slot "trinket" in data/trinkets;
## jewellery found as treasure links to the trinket it's worn as.
##
## Chests and events give magic ones (the jewellery in the
## treasure tables); tougher foes sometimes drop magic or rare ones, or a
## cursed one; uniques come only from quests, the fortress and later layers.

const DIR := "res://data/trinkets"
## Tougher foes: a kill has this chance of leaving a trinket.
const DROP_CHANCE := 0.12
const TOUGH_HEALTH := 10  # foes with at least this much health count as tougher
## Elites carry most of the drop chance (#140).
const ELITE_TIMES := 3.0
const ORDINARY_TIMES := 0.5
## Of those drops, the chance it's a cursed one (floors 2+).
const CURSED_SHARE := 0.25


## Every trinket definition (works in exported builds too).
static func all() -> Array[Equipment]:
	var found: Array[Equipment] = []
	for file in DirAccess.get_files_at(DIR):
		file = file.trim_suffix(".remap")
		if file.ends_with(".tres"):
			var trinket := load(DIR.path_join(file)) as Equipment
			if trinket and trinket.slot == "trinket":
				found.append(trinket)
	return found


## The trinket a piece of treasure is worn as, or null.
static func for_treasure(item: SupplyItem) -> Equipment:
	for trinket in all():
		if trinket.treasure == item:
			return trinket
	return null


## Uniques for a reward, e.g. the queen's hoard: one not already owned.
static func unique_reward(rng: RandomNumberGenerator, owned: Array) -> Equipment:
	var options := all().filter(func(t: Equipment): return t.tier == "unique" and t not in owned)
	return options[rng.randi_range(0, options.size() - 1)] if not options.is_empty() else null


## What a tougher foe leaves, if anything: magic or rare jewellery (as
## treasure, to wear or sell), or on floors 2+ sometimes a cursed trinket.
## Returns a SupplyItem, an Equipment, or null.
## Elites (#140) count as tougher whatever their health, and carry most of
## the chance; ordinary tougher foes carry less.
static func drop(rng: RandomNumberGenerator, depth: int, foe_health: int, elite := false):
	if foe_health < TOUGH_HEALTH and not elite:
		return null
	if rng.randf() >= DROP_CHANCE * (ELITE_TIMES if elite else ORDINARY_TIMES):
		return null
	if depth >= 2 and rng.randf() < CURSED_SHARE:
		var cursed := all().filter(func(t: Equipment): return t.curse != null)
		if not cursed.is_empty():
			return cursed[rng.randi_range(0, cursed.size() - 1)]
	var tiers := ["magic"] if depth <= 2 else ["magic", "rare"]
	var jewels := all().filter(func(t: Equipment): return t.treasure != null and t.tier in tiers)
	return jewels[rng.randi_range(0, jewels.size() - 1)].treasure if not jewels.is_empty() else null
