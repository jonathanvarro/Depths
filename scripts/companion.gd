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
## Higher acts earlier in a combat round.
@export var initiative := 10
@export_group("")

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

## Effects still playing out: [{"stat": "health", "per_unit": float,
## "units_left": int}]. Health is the only stat for now.
var pending_effects: Array[Dictionary] = []

var _health_fraction := 0.0  # partial healing carried between time units


## Damage range of a basic attack: the weapon's, or their own bare-handed.
func attack_range() -> Vector2i:
	if weapon:
		return Vector2i(weapon.attack_min, weapon.attack_max)
	return Vector2i(attack_min, attack_max)


func hit_accuracy() -> float:
	return accuracy + (weapon.accuracy_bonus if weapon else 0.0)


func is_alive() -> bool:
	return health > 0


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
