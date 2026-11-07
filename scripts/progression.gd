extends RefCounted
## Levels, experience and talents (#47; owner decisions from ChatGPT's
## research, docs/stats-monsters-xp-research.md).
##
## Levels 1-4 in the cave: a talent choice at levels 2 and 4, +1 attribute
## at level 3, +2 maximum health each level. Everyone active gets the full
## XP of a fight, with one-off awards for the gate, the queen and clearing
## the cave.
##
## Levels and skills split (#233, owner 2026-11-06): a level is a small
## automatic gain (+2 maximum health, +2% to hit), with no choices. Skills
## are their own thing and kept for good: earned by deeds (a hero who braces
## often learns Bulwark), read from manuals found below, taught at camp, or
## given for quests. `talents` holds them; old talent picks became skills.
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


## Skills (#233): id -> name, what it does, and the deed that teaches it:
## a counter in Companion.deeds and how many times. A count of 0: not
## learned by deeds (a manual, a trainer or a quest).
const SKILLS := {
	"bulwark": {"name": "Bulwark", "text": "Defending takes only 15% of a blow", "deed": "braced", "count": 6, "how": "Brace in fights"},
	"heavy_hands": {"name": "Heavy hands", "text": "+1 damage", "deed": "felled", "count": 12, "how": "Fell foes"},
	"iron_hide": {"name": "Iron hide", "text": "Every blow does 1 less", "deed": "struck", "count": 40, "how": "Take blows and stand"},
	"berserker": {"name": "Berserker", "text": "+2 damage while below half health", "deed": "fought_hurt", "count": 10, "how": "Land blows while badly hurt"},
	"deadeye": {"name": "Deadeye", "text": "+5% to hit", "deed": "hits", "count": 30, "how": "Land blows"},
	"quick_hands": {"name": "Quick hands", "text": "Acts sooner (+2 speed)", "deed": "opened", "count": 8, "how": "Strike first in fights"},
	"opening_shot": {"name": "Opening shot", "text": "First attack each fight +2 damage", "deed": "opened", "count": 20, "how": "Strike first in fights"},
	"steady_hands": {"name": "Steady hands", "text": "Dressings also heal 4", "deed": "dressed", "count": 6, "how": "Dress wounds"},
	"herbalist": {"name": "Herbalist", "text": "Healing items heal another 25%", "deed": "healed", "count": 60, "how": "Heal with draughts and herbs"},
	"steel_nerves": {"name": "Steel nerves", "text": "Strain builds 20% slower", "deed": "shocks", "count": 12, "how": "Endure frights and shocks"},
	"slip_web": {"name": "Slip the web", "text": "Webs never stick", "deed": "webs", "count": 5, "how": "Force through webs"},
	"stalwart": {"name": "Stalwart", "text": "+4 maximum health", "deed": "struck", "count": 20, "how": "Take blows and stand"},
	"unbreakable": {"name": "Unbreakable", "text": "+6 maximum health", "deed": "", "count": 0, "how": "A quest's reward"},
	"triage": {"name": "Triage", "text": "Two dressing-free bindings a trip", "deed": "", "count": 0, "how": "A manual"},
	"thick_skull": {"name": "Thick skull", "text": "No longer takes extra damage", "deed": "", "count": 0, "how": "A manual"},
	"slip_past": {"name": "Slip past", "text": "Leads the party quietly past a fight Sharp ears heard", "deed": "", "count": 0, "how": "A manual"},
}


## Learns skill `id` for good (#233). False if already known.
static func learn(hero: Companion, id: String) -> bool:
	if hero == null or id == "" or id in hero.talents or not SKILLS.has(id):
		return false
	hero.talents.append(id)
	hero.refresh_stats()
	hero.emit_changed()
	hero.learned_skill.emit(id)
	return true


## A deed done (#233): counts it, and teaches any skill it completes.
## Returns the ids learned (usually none).
static func note_deed(hero: Companion, deed: String, amount := 1) -> Array:
	if hero == null or not hero.uses_stats or amount <= 0:
		return []
	var before: int = hero.deeds.get(deed, 0)
	hero.deeds[deed] = before + amount
	var learned := []
	for id in SKILLS:
		var s: Dictionary = SKILLS[id]
		if s["deed"] == deed and s["count"] > 0 and before < s["count"] and before + amount >= s["count"] and learn(hero, id):
			learned.append(id)
	return learned


## "Mara learns Bulwark: defending takes only 15% of a blow."
static func learned_text(hero: Companion, id: String) -> String:
	return "%s learns %s: %s." % [hero.display_name, SKILLS[id]["name"], SKILLS[id]["text"].to_lower()]


## Skills deeds can still teach `hero`, with progress: [[id, done, needed]].
static func skill_progress(hero: Companion) -> Array:
	var out := []
	for id in SKILLS:
		var s: Dictionary = SKILLS[id]
		if s["count"] > 0 and not hero.has_talent(id):
			out.append([id, mini(hero.deeds.get(s["deed"], 0), s["count"]), s["count"]])
	return out


static func xp_for_next(hero: Companion) -> int:
	return THRESHOLDS[hero.level + 1] if hero.level < MAX_LEVEL else -1


static func ready_to_advance(hero: Companion) -> bool:
	return hero.level < MAX_LEVEL and hero.xp >= THRESHOLDS[hero.level + 1]


## What the next level offers. Since #233 levels are automatic: nothing.
## (The talent tables above stay for reference and old saves.)
static func choices(_hero: Companion) -> Array:
	return []


static func _old_choices(hero: Companion) -> Array:
	var next := hero.level + 1
	if next == 3:
		var raise := []
		for key in ATTRIBUTES:
			if hero.get(key) < ATTRIBUTE_CAP:
				raise.append([key, ATTRIBUTES[key], "+1 (now %d)" % hero.get(key)])
		return raise
	var table: Dictionary = TALENTS.get(hero.role, TALENTS[DEFAULT_ROLE])
	return table.get(next, []).filter(func(t): return t[0] not in hero.talents)


## Takes the next level: +2 maximum health and +2% to hit, automatically
## (#233). `_choice` is ignored; kept for older callers.
static func advance(hero: Companion, _choice := "") -> bool:
	if not ready_to_advance(hero):
		return false
	hero.level += 1
	var before := hero.max_health
	hero.refresh_stats()
	hero.health = mini(hero.max_health, hero.health + maxi(0, hero.max_health - before))  # the new health comes filled
	hero.emit_changed()
	return true


## Every level owed, at once (levels are automatic, #233).
static func auto_advance(hero: Companion) -> void:
	while ready_to_advance(hero):
		if not advance(hero):
			break


## A fresh expedition (#172): back to level 1, any attribute points of the
## last one undone (old saves). Skills stay (#233), as does everything else.
static func reset(hero: Companion) -> void:
	if not hero.uses_stats:
		return
	for key in hero.raised:
		hero.set(key, hero.get(key) - 1)
	hero.raised.clear()
	hero.level = 1
	hero.xp = 0
	load("res://scripts/spells.gd").refill(hero)  # casts come back each trip (#170)
	hero.refresh_stats()
	hero.health = mini(hero.health, hero.max_health)
	hero.emit_changed()


## A scouts' route start (tuning 2026-11-01): the party arrives with the
## experience the skipped floors would have given - level 2 on floor 2,
## level 3 on floor 3, and so on. The choices are offered on arrival.
static func route_xp(start_depth: int) -> int:
	return THRESHOLDS[clampi(start_depth, 1, MAX_LEVEL)]


static func talent_name(id: String) -> String:
	if SKILLS.has(id):
		return SKILLS[id]["name"]
	for role in TALENTS:
		for level in TALENTS[role]:
			for t in TALENTS[role][level]:
				if t[0] == id:
					return t[1]
	return id
