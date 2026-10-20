class_name Companion
extends Resource

const StrainRules := preload("res://scripts/strain.gd")
## One hero in the party: who they are, and their current condition.
##
## Companion definitions live in `data/companions/*.tres`. The game plays with
## a copy (see PartyState.add_member), so the definition files never change.
##
## Effects over time: something like a slow-acting remedy is added with
## add_effect_over_time() and applied a little each time unit (one step = one
## unit). Changing floors completes every effect at once.
##
## Injuries (#11) lower maximum health or slow each step until treated at
## camp. A dressing suppresses an injury's effect in the meantime.
##
## Strain (#12) builds from time, darkness, lost health, injury and hunger;
## see strain.gd for the rules and states.

@export var display_name := "Unnamed"
@export var role := ""
## Why they came into the dungeon (and why they might stay or leave).
@export_multiline var motive := ""
@export_multiline var personality := ""
## What pressure gets to them first.
@export_multiline var vulnerability := ""
## Layered, animated portrait (preferred). See PortraitSet.
@export var portrait_set: PortraitSet
## Single flat image, used if there's no portrait_set.
@export var portrait: Texture2D
## What they say, by situation (#57).
@export var dialogue: DialogueLines
@export var max_health := 20
@export var health := 20
@export_group("Fighting")
## Damage range of a basic attack (a plain knife for now; weapons later).
@export var attack_min := 2
@export var attack_max := 4
@export_range(0.0, 1.0) var accuracy := 0.75
## What they fight with; without one they use attack_min/max (#58).
@export var weapon: Equipment
## What this hero takes from the fallen companion in the opening (balance
## report, owner 2026-10-19): a weapon that suits their arm. Empty means
## the companion's iron sword.
@export var companion_weapon: Equipment
## Higher acts earlier in a combat round.
@export var initiative := 10
## Share of a blow taken while defending (a Warden takes less, #41).
@export_range(0.0, 1.0) var guard_factor := 0.5
## Taken off every blow they suffer (negative: hurt more, e.g. a Brawler).
@export var toughness := 0
## Body armour (#93): takes `armour` off every blow, slows by its penalty.
@export var body: Equipment
@export_group("Stats")
## Attributes (#47): Strength, Dexterity, Vitality, Resolve, about 1-4.
## When `uses_stats` is on, maximum health, accuracy and initiative are
## derived from them (refresh_stats); off, those fields are used as set.
@export var uses_stats := false
@export var stat_str := 2
@export var stat_dex := 2
@export var stat_vit := 2
@export var stat_res := 2
## Role and personal offsets the derived numbers start from.
@export var aim_base := 0.75
@export var speed_base := 10
@export var hp_bonus := 0
## A personal strength/weakness on the top of their damage (Strong arm).
@export var damage_max_mod := 0
## Level 1-4 and total XP (#47); talents chosen at levels 2 and 4.
@export var level := 1
@export var xp := 0
@export var talents: Array[String] = []
@export_group("")
## A recruit's strength and weakness, as shown at the fire (#41).
@export var strength := ""
@export var weakness := ""
## The campaign's first hero (Mara): can't be dismissed at camp.
@export var founder := false
## A main hero (#83): falling leaves them unconscious, not dead - carried
## by the party until a draught or a rest revives them.
@export var main_hero := false
## A main hero's special trait (#95), one recruits never get:
## "keen_eyes" (traps show), "grudge" (+1 damage against goblins),
## "field_medic" (healing works better; a dressing-free binding per trip).
@export var trait_id := ""
@export var trait_name := ""
@export var trait_text := ""
## One line shown when choosing a starting hero.
@export_multiline var backstory := ""
## Subject, object, possessive - for text written about them.
@export var pronouns := PackedStringArray(["they", "them", "their"])
## Combat row (#72): "front" takes melee and shields the back; "back" is
## safe from melee but attacks only with reach. Kept between fights.
@export_enum("front", "back") var row := "front"
## Attacks from the back row without a reach weapon (a Scout's sling).
@export var reach := false
## Added to the odds of heads when the coin is flipped (#77).
@export_range(0.0, 0.5) var luck := 0.0


## Can attack from the back row / into the enemy's back row.
func has_reach() -> bool:
	return weapon.reach if weapon else reach

## 0 (calm) to 100 (panicking). See strain.gd.
@export_range(0.0, 100.0) var strain := 0.0
## Time units since the hero last ate.
@export var hunger := 0
## Injuries carried (a definition can list some to start with).
@export var injuries: Array[Injury] = []
## Injuries currently bound by a dressing: present, but not hindering.
var dressed: Array[Injury] = []
## Damage can't take health below this (the opening escape can't be lost, #30).
var min_health := 0
## While true, strain doesn't change (the opening holds panic back, #56).
var strain_locked := false
## Cosmetic portrait overlays (names in PortraitSet.conditions), e.g. the
## blood and dirt of the opening.
var appearance: Array[String] = []
## Losing health as they walk (the opening, #69): shown on their card.
var bleeding := false

## Effects still playing out: [{"stat": "health", "per_unit": float,
## "units_left": int}]. Health is the only stat for now.
var pending_effects: Array[Dictionary] = []

var _health_fraction := 0.0  # partial healing carried between time units


## Damage range of a basic attack: the weapon's, or their own bare-handed.
func attack_range() -> Vector2i:
	var span := Vector2i(weapon.attack_min, weapon.attack_max) if weapon else Vector2i(attack_min, attack_max)
	if not uses_stats:
		return span
	# Strength adds to force weapons (and their own fists); a light knife
	# ignores a weak arm; a sling ignores Strength (#47).
	var str_bonus := stat_str - 2
	if weapon and weapon.light:
		str_bonus = maxi(0, str_bonus)
	elif (weapon and not weapon.force) or (not weapon and reach):
		str_bonus = 0
	span += Vector2i(str_bonus, str_bonus)
	if has_talent("heavy_hands"):
		span += Vector2i.ONE
	span.y += damage_max_mod
	span.x = maxi(1, span.x)
	span.y = maxi(span.x, span.y)
	return span


func hit_accuracy() -> float:
	return accuracy + (weapon.accuracy_bonus if weapon else 0.0)


func has_talent(id: String) -> bool:
	return id in talents


## Recomputes the derived numbers from attributes, level and talents (#47).
## Raising maximum health doesn't refill current health.
func refresh_stats() -> void:
	if not uses_stats:
		return
	max_health = 12 + 4 * stat_vit + hp_bonus + 2 * (level - 1)
	if has_talent("stalwart"):
		max_health += 4
	if has_talent("unbreakable"):
		max_health += 6
	accuracy = aim_base + 0.04 * (stat_dex - 2) + (0.05 if has_talent("deadeye") else 0.0)
	initiative = speed_base + 2 * (stat_dex - 2) + (2 if has_talent("quick_hands") else 0)
	if has_talent("bulwark"):
		guard_factor = minf(guard_factor, 0.15)
	health = mini(health, max_health)


## Acting order in a fight: armour slows (#93).
func effective_initiative() -> int:
	return initiative - (body.initiative_penalty if body else 0)


## Taken off every blow: toughness, talents and body armour (#47, #93).
func damage_reduction() -> int:
	var reduction := toughness + (body.armour if body else 0)
	if has_talent("iron_hide"):
		reduction += 1
	if has_talent("thick_skull") and toughness < 0:
		reduction -= toughness
	return reduction


func is_alive() -> bool:
	return health > 0


## Fallen but not dead (#83). The one place the "can't die" rule lives, so a
## permanent-loss rule can replace it later.
func is_unconscious() -> bool:
	return main_hero and health <= 0


## Still with the party: conscious, or a main hero being carried.
func is_with_party() -> bool:
	return is_alive() or is_unconscious()


func change_health(amount: int) -> void:
	var before := health
	var lowest := mini(min_health, health)
	health = clampi(health + amount, lowest, effective_max_health())
	if health < before:
		change_strain((before - health) * StrainRules.DAMAGE_PER_HEALTH)
	if health != before:
		emit_changed()


func change_strain(amount: float) -> void:
	if strain_locked:
		return
	if amount > 0.0 and uses_stats:
		# Resolve steadies (#47): only gains are scaled, never relief.
		amount *= clampf(1.0 - 0.08 * (stat_res - 2), 0.75, 1.15) * (0.8 if has_talent("steel_nerves") else 1.0)
	var before := strain
	strain = clampf(strain + amount, 0.0, StrainRules.MAX)
	if not is_equal_approx(strain, before):
		emit_changed()


func strain_state() -> StrainRules.State:
	return StrainRules.state_for(strain)


func effectiveness() -> float:
	return StrainRules.EFFECTIVENESS[strain_state()]


func is_hungry() -> bool:
	return hunger >= StrainRules.HUNGRY_AFTER


## Eating resets hunger and eases strain a little.
func eat() -> void:
	hunger = 0
	change_strain(StrainRules.EATING)
	emit_changed()

## Maximum health after untreated, undressed injuries.
func effective_max_health() -> int:
	var penalty := 0
	for injury in hindering_injuries():
		penalty += injury.max_health_penalty
	return maxi(1, max_health - penalty)


## Time one step costs this hero.
func step_time() -> int:
	var cost := 1
	for injury in hindering_injuries():
		cost += injury.extra_step_time
	return cost


func hindering_injuries() -> Array[Injury]:
	return injuries.filter(func(i: Injury): return i not in dressed)


## Adds an injury (once per kind). Returns false if they already have it.
func add_injury(injury: Injury) -> bool:
	if injury in injuries:
		return false
	injuries.append(injury)
	health = mini(health, effective_max_health())
	change_strain(StrainRules.NEW_INJURY)
	emit_changed()
	return true


## Field treatment: binds the first undressed injury until camp.
func dress_injury() -> Injury:
	var hindering := hindering_injuries()
	if hindering.is_empty():
		return null
	dressed.append(hindering[0])
	emit_changed()
	return hindering[0]


## Proper treatment at camp: every injury is gone (health isn't restored).
func treat_injuries() -> void:
	injuries.clear()
	dressed.clear()
	emit_changed()


## Spreads `total` evenly over `units` of time.
func add_effect_over_time(stat: String, total: int, units: int) -> void:
	pending_effects.append({"stat": stat, "per_unit": float(total) / maxi(units, 1), "units_left": maxi(units, 1)})
	emit_changed()


func advance_time(units: int) -> void:
	for i in units:
		for effect in pending_effects:
			_apply(effect["stat"], effect["per_unit"])
			effect["units_left"] -= 1
		pending_effects = pending_effects.filter(func(e): return e["units_left"] > 0)


## Applies whatever remains of every effect immediately.
func complete_pending_effects() -> void:
	for effect in pending_effects:
		_apply(effect["stat"], effect["per_unit"] * effect["units_left"])
	pending_effects.clear()
	_health_fraction = 0.0


func _apply(stat: String, amount: float) -> void:
	if stat != "health":
		push_warning("Unknown effect stat: %s" % stat)
		return
	_health_fraction += amount
	var whole := int(_health_fraction)
	_health_fraction -= whole
	change_health(whole)
