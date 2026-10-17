class_name Companion
extends Resource
## One hero in the party: who they are, and their current condition.
##
## Companion definitions live in `data/companions/*.tres`. The game plays with
## a copy (see PartyState.add_member), so the definition files never change.
##
## Effects over time: something like a slow-acting remedy is added with
## add_effect_over_time() and applied a little each time unit (one step = one
## unit). Changing floors completes every effect at once.

@export var display_name := "Unnamed"
@export var role := ""
## Why they came into the dungeon (and why they might stay or leave).
@export_multiline var motive := ""
@export_multiline var personality := ""
## What pressure gets to them first.
@export_multiline var vulnerability := ""
@export var portrait: Texture2D
@export var max_health := 20
@export var health := 20

## Effects still playing out: [{"stat": "health", "per_unit": float,
## "units_left": int}]. Health is the only stat for now.
var pending_effects: Array[Dictionary] = []

var _health_fraction := 0.0  # partial healing carried between time units


func is_alive() -> bool:
	return health > 0


func change_health(amount: int) -> void:
	health = clampi(health + amount, 0, max_health)


## Spreads `total` evenly over `units` of time.
func add_effect_over_time(stat: String, total: int, units: int) -> void:
	pending_effects.append({"stat": stat, "per_unit": float(total) / maxi(units, 1), "units_left": maxi(units, 1)})


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
