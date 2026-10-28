extends RefCounted
## Levels, experience and talents (#47; owner decisions from ChatGPT's
## research, docs/stats-monsters-xp-research.md).
##
## Levels 1-4 in the cave: a talent choice at levels 2 and 4, +1 attribute
## at level 3, +2 maximum health each level. Level-ups are chosen at camp.
## Everyone active gets the full XP of a fight; each floor only teaches so
## much fight XP over the whole campaign (the cave regenerates daily), with
## one-off awards for the gate, the queen and clearing the cave.

## Total XP needed to reach level 2, 3 and 4 (index = current level).
const THRESHOLDS := [0, 0, 80, 220, 440]
const MAX_LEVEL := 4
const XP_PER_THREAT := 4
## Fight XP each floor can give over the whole campaign.
## Level 4 is reachable before the queen (owner, 2026-10-19, #49): the
## floors and the gate offer 490 of the 440 needed; she can be a quest.
const FLOOR_XP_LIMIT := {1: 60, 2: 90, 3: 150, 4: 150, 5: 160, 6: 170}
const GATE_XP := 40
const QUEEN_XP := 80
const CLEARED_XP := 40
## Attributes a level-3 point can raise, and the cave's ceiling.
const ATTRIBUTES := {"stat_str": "Strength", "stat_dex": "Dexterity", "stat_vit": "Vitality", "stat_res": "Resolve"}
const ATTRIBUTE_CAP := 4

## Two talents to choose from at levels 2 and 4, by role: [id, name, effect].
const TALENTS := {
	"Warden": {
		2: [["bulwark", "Bulwark", "Defending takes only 15% of a blow"], ["stalwart", "Stalwart", "+4 maximum health"]],
		4: [["iron_hide", "Iron hide", "Every blow does 1 less"], ["steel_nerves", "Steel nerves", "Strain builds 20% slower"]],
	},
	"Scout": {
		# A Scout's own (owner, 2026-10-25): Sharp ears in place of Deadeye
		# (#73; hearing fights first is a skill to unlock, not for everyone),
		# then Slip past (which needs it) or Trap sense (#94).
		2: [["sharp_ears", "Sharp ears", "Hears some fights before they notice the party"], ["quick_hands", "Quick hands", "Acts sooner (+2 speed)"]],
		4: [["slip_past", "Slip past", "Leads the party quietly past a fight Sharp ears heard"], ["trap_sense", "Trap sense", "Always spots traps"]],
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
const DEFAULT_ROLE := "Brawler"


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


static func talent_name(id: String) -> String:
	for role in TALENTS:
		for level in TALENTS[role]:
			for t in TALENTS[role][level]:
				if t[0] == id:
					return t[1]
	return id
