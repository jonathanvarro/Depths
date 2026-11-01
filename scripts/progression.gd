extends RefCounted
## Levels, experience and talents (#47; owner decisions from ChatGPT's
## research, docs/stats-monsters-xp-research.md).
##
## Levels 1-4 in the cave: a talent choice at levels 2 and 4, +1 attribute
## at level 3, +2 maximum health each level. Everyone active gets the full
## XP of a fight, with one-off awards for the gate, the queen and clearing
## the cave.
##
## Levels last one expedition (#172, owner 2026-10-30/31): every departure
## from the surface starts at level 1, levels come quickly, and the choices
## are made underground after a fight. Personality, role, scars, memories
## and gear mastery stay. An underground camp keeps the expedition going.

## Total XP needed to reach level 2, 3 and 4 (index = current level).
## Tuned 2026-11-01 (was 25/70/140): a party leaves floor 1 at about
## level 3 and reaches floor 4 at level 4.
const THRESHOLDS := [0, 0, 10, 28, 56]
const MAX_LEVEL := 4
const XP_PER_THREAT := 4
## Retired by #172 (levels reset each expedition); kept so old saves load.
const FLOOR_XP_LIMIT := {1: 60, 2: 90, 3: 150, 4: 150, 5: 160, 6: 170}
const GATE_XP := 40
const QUEEN_XP := 80
const CLEARED_XP := 40
## Attributes a level-3 point can raise, and the cave's ceiling.
const ATTRIBUTES := {"stat_str": "Strength", "stat_dex": "Dexterity", "stat_vit": "Vitality", "stat_res": "Resolve"}
const ATTRIBUTE_CAP := 4

## Two talents to choose from at levels 2 and 4, by class (#179): [id, name,
## effect]. A Scout's Sharp ears and Trap sense are now standard skills.
## Older role keys stay below for old saves' recruits.
const TALENTS := {
	"Melee": {
		2: [["bulwark", "Bulwark", "Defending takes only 15% of a blow"], ["heavy_hands", "Heavy hands", "+1 damage"]],
		4: [["iron_hide", "Iron hide", "Every blow does 1 less"], ["berserker", "Berserker", "+2 damage while below half health"]],
	},
	"Mage": {
		2: [["steady_hands", "Steady hands", "Dressings also heal 4"], ["steel_nerves", "Steel nerves", "Strain builds 20% slower"]],
		4: [["triage", "Triage", "Two dressing-free bindings a trip"], ["herbalist", "Herbalist", "Healing items heal another 25%"]],
	},
	"Warden": {
		2: [["bulwark", "Bulwark", "Defending takes only 15% of a blow"], ["stalwart", "Stalwart", "+4 maximum health"]],
		4: [["iron_hide", "Iron hide", "Every blow does 1 less"], ["steel_nerves", "Steel nerves", "Strain builds 20% slower"]],
	},
	"Scout": {
		# Sharp ears and Trap sense come with the class (#179); Slip past
		# builds on hearing fights first.
		2: [["deadeye", "Deadeye", "+5% to hit"], ["quick_hands", "Quick hands", "Acts sooner (+2 speed)"]],
		4: [["slip_past", "Slip past", "Leads the party quietly past a fight Sharp ears heard"], ["slip_web", "Slip the web", "Webs never stick"]],
	},
	"Fixer": {  # #101: modest in a fight
		2: [["deadeye", "Deadeye", "+5% to hit"], ["quick_hands", "Quick hands", "Acts sooner (+2 speed)"]],
		4: [["steel_nerves", "Steel nerves", "Strain builds 20% slower"], ["opening_shot", "Opening shot", "First attack each fight +2 damage"]],
	},
	"Rogue": {
		2: [["deadeye", "Deadeye", "+5% to hit"], ["quick_hands", "Quick hands", "Acts sooner (+2 speed)"]],
		4: [["slip_web", "Slip the web", "Webs never stick"], ["opening_shot", "Opening shot", "First attack each fight +2 damage"]],
	},
	"Brawler": {
		2: [["heavy_hands", "Heavy hands", "+1 damage"], ["thick_skull", "Thick skull", "No longer takes extra damage"]],
		4: [["berserker", "Berserker", "+2 damage while below half health"], ["unbreakable", "Unbreakable", "+6 maximum health"]],
	},
	"Healer": {
		2: [["steady_hands", "Steady hands", "Dressings also heal 4"], ["steel_nerves", "Steel nerves", "Strain builds 20% slower"]],
		4: [["triage", "Triage", "Two dressing-free bindings a trip"], ["herbalist", "Herbalist", "Healing items heal another 25%"]],
	},
}
const DEFAULT_ROLE := "Melee"


static func xp_for_next(hero: Companion) -> int:
	return THRESHOLDS[hero.level + 1] if hero.level < MAX_LEVEL else -1


static func ready_to_advance(hero: Companion) -> bool:
	return hero.level < MAX_LEVEL and hero.xp >= THRESHOLDS[hero.level + 1]


## What the next level offers: talents [[id, name, text]...] or attributes
## [["stat_str", "Strength", "+1"]...].
static func choices(hero: Companion) -> Array:
	var next := hero.level + 1
	if next == 3:
		var raise := []
		for key in ATTRIBUTES:
			if hero.get(key) < ATTRIBUTE_CAP:
				raise.append([key, ATTRIBUTES[key], "+1 (now %d)" % hero.get(key)])
		return raise
	var table: Dictionary = TALENTS.get(hero.role, TALENTS[DEFAULT_ROLE])
	return table.get(next, []).filter(func(t): return t[0] not in hero.talents)


## Takes the next level with `choice` (a talent or attribute id).
static func advance(hero: Companion, choice: String) -> bool:
	if not ready_to_advance(hero):
		return false
	var valid := choices(hero).map(func(c): return c[0])
	if choice not in valid and not valid.is_empty():
		return false
	hero.level += 1
	if choice in ATTRIBUTES:
		hero.set(choice, hero.get(choice) + 1)
		hero.raised.append(choice)  # undone when the expedition ends (#172)
	elif choice != "":
		hero.talents.append(choice)
	hero.refresh_stats()
	hero.emit_changed()
	return true


## A recruit joining part-way up takes sensible choices (first talent, their
## best attribute).
static func auto_advance(hero: Companion) -> void:
	while ready_to_advance(hero):
		var options := choices(hero)
		var pick := ""
		if not options.is_empty():
			pick = options[0][0]
			if hero.level + 1 == 3:
				var best := ""
				for key in ATTRIBUTES:
					if hero.get(key) < ATTRIBUTE_CAP and (best == "" or hero.get(key) > hero.get(best)):
						best = key
				pick = best
		if not advance(hero, pick):
			break


## A fresh expedition (#172): back to level 1, the talents and attribute
## points of the last one undone. Everything else about the hero stays.
static func reset(hero: Companion) -> void:
	if not hero.uses_stats:
		return
	for key in hero.raised:
		hero.set(key, hero.get(key) - 1)
	hero.raised.clear()
	hero.talents.clear()
	hero.level = 1
	hero.xp = 0
	hero.refresh_stats()
	hero.health = mini(hero.health, hero.max_health)
	hero.emit_changed()


## A scouts' route start (tuning 2026-11-01): the party arrives with the
## experience the skipped floors would have given - level 2 on floor 2,
## level 3 on floor 3, and so on. The choices are offered on arrival.
static func route_xp(start_depth: int) -> int:
	return THRESHOLDS[clampi(start_depth, 1, MAX_LEVEL)]


static func talent_name(id: String) -> String:
	for role in TALENTS:
		for level in TALENTS[role]:
			for t in TALENTS[role][level]:
				if t[0] == id:
					return t[1]
	return id
