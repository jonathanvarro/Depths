extends RefCounted
## Turn-based combat rules (#14), with no visuals: the combat screen drives
## it and animates the results, and tests can run it directly.
##
## Owner decisions: a hero's turn is attack, defend or use an item (magic
## later). Retreat is a trial of the owner's idea: flee to a random nearby
## spot at a cost of time and light. All numbers are first guesses to tune.

const Supplies := preload("res://scripts/supplies.gd")

enum Result { ONGOING, VICTORY, DEFEAT, RETREAT }

## Hero hit chance adjusted by the lantern: light is an advantage (#10).
## Enemies see in the dark, so it doesn't affect them.
const LIGHT_ACCURACY := {Supplies.Light.BRIGHT: 0.1, Supplies.Light.STEADY: 0.0, Supplies.Light.DIM: -0.1, Supplies.Light.OUT: -0.25}
const MIN_HIT_CHANCE := 0.1
const MAX_HIT_CHANCE := 0.95
## Time each round costs (the lantern burns and strain builds meanwhile).
const ROUND_TIME := 1
## Time lost fleeing.
const RETREAT_TIME := 6


## One enemy in this fight.
class Foe:
	var type: EnemyType
	var name: String
	var health: int
	var node: Node3D  # set by the combat screen

	func _init(enemy_type: EnemyType, label: String) -> void:
		type = enemy_type
		name = label
		health = enemy_type.max_health

	func is_alive() -> bool:
		return health > 0


var party  # party_state.gd
var foes: Array[Foe] = []
var round := 1
var result := Result.ONGOING
var rng := RandomNumberGenerator.new()

var _order: Array = []  # Companion or Foe, this round's acting order
var _turn := 0
var _defending := {}  # Companion -> true until their next turn


func _init(party_state, enemy_types: Array[EnemyType]) -> void:
	party = party_state
	rng.randomize()
	var seen := {}
	for type in enemy_types:
		seen[type] = seen.get(type, 0) + 1
	var numbered := {}
	for type in enemy_types:
		numbered[type] = numbered.get(type, 0) + 1
		var label := type.display_name if seen[type] == 1 else "%s %d" % [type.display_name, numbered[type]]
		foes.append(Foe.new(type, label))
	_build_order()


## Whoever acts now: a Companion or a Foe.
func current_actor():
	return _order[_turn] if _turn < _order.size() else null


func living_foes() -> Array[Foe]:
	return foes.filter(func(f: Foe): return f.is_alive())


func is_defending(hero: Companion) -> bool:
	return _defending.has(hero)


## Moves to the next living actor, starting a new round (and spending its
## time) when everyone has acted.
func advance() -> void:
	_check_end()
	if result != Result.ONGOING:
		return
	_turn += 1
	while true:
		if _turn >= _order.size():
			round += 1
			party.advance_time(ROUND_TIME)
			_check_end()
			if result != Result.ONGOING:
				return
			_build_order()
			_turn = 0
		var actor = _order[_turn]
		if actor.is_alive():
			if actor is Companion:
				_defending.erase(actor)  # a defence lasts until their next turn
			return
		_turn += 1


func hero_hit_chance(hero: Companion) -> float:
	var chance: float = hero.accuracy * hero.effectiveness() + LIGHT_ACCURACY[party.supplies.light_band()]
	return clampf(chance, MIN_HIT_CHANCE, MAX_HIT_CHANCE)


## Returns {"hit": bool, "damage": int, "killed": bool, "text": String}.
func hero_attack(hero: Companion, target: Foe) -> Dictionary:
	var outcome := {"hit": false, "damage": 0, "killed": false}
	if rng.randf() < hero_hit_chance(hero):
		var damage := maxi(1, roundi(rng.randi_range(hero.attack_min, hero.attack_max) * hero.effectiveness()))
		target.health = maxi(0, target.health - damage)
		outcome = {"hit": true, "damage": damage, "killed": not target.is_alive()}
		outcome["text"] = "%s strikes the %s for %d.%s" % [hero.display_name, target.name.to_lower(), damage, " It falls." if outcome["killed"] else ""]
	else:
		outcome["text"] = "%s misses the %s." % [hero.display_name, target.name.to_lower()]
	_check_end()
	return outcome


## Halves damage until the hero's next turn and draws enemy attacks.
func hero_defend(hero: Companion) -> String:
	_defending[hero] = true
	return "%s braces, guarding the party." % hero.display_name


func hero_use_item(item: SupplyItem) -> String:
	return party.use_item(item, true)


## Returns {"target": Companion, "hit": bool, "damage": int,
## "injury": Injury or null, "text": String}.
func enemy_act(foe: Foe) -> Dictionary:
	var target := _choose_target()
	var outcome := {"target": target, "hit": false, "damage": 0, "injury": null}
	if target == null:
		return outcome
	if rng.randf() < foe.type.accuracy:
		var damage := rng.randi_range(foe.type.damage_min, foe.type.damage_max)
		if is_defending(target):
			damage = maxi(1, damage / 2)
		target.change_health(-damage)
		outcome["hit"] = true
		outcome["damage"] = damage
		outcome["text"] = "The %s %s %s for %d." % [foe.name.to_lower(), foe.type.attack_verb, target.display_name, damage]
		if target.is_alive() and not foe.type.injuries.is_empty() and rng.randf() < foe.type.injury_chance:
			var injury: Injury = foe.type.injuries[rng.randi_range(0, foe.type.injuries.size() - 1)]
			if target.add_injury(injury):
				outcome["injury"] = injury
				outcome["text"] += " %s suffers a %s!" % [target.display_name, injury.display_name.to_lower()]
		if not target.is_alive():
			outcome["text"] += " %s falls." % target.display_name
	else:
		outcome["text"] = "The %s lunges at %s and misses." % [foe.name.to_lower(), target.display_name]
	_check_end()
	return outcome


## The owner's retreat idea (trial): the fight ends, the party flees.
## Where they end up and the time cost are handled by the caller.
func retreat() -> String:
	result = Result.RETREAT
	return "You flee blindly into the dark."


## Enemies go after whoever is defending; otherwise anyone standing.
func _choose_target() -> Companion:
	var living: Array[Companion] = party.living_members()
	if living.is_empty():
		return null
	var guards := living.filter(func(h: Companion): return is_defending(h))
	var pool: Array = guards if not guards.is_empty() else living
	return pool[rng.randi_range(0, pool.size() - 1)]


func _build_order() -> void:
	_order.clear()
	for hero in party.living_members():
		_order.append(hero)
	for foe in living_foes():
		_order.append(foe)
	# Higher initiative first; ties go to the party.
	_order.sort_custom(func(a, b):
		var ia: int = a.initiative if a is Companion else a.type.initiative
		var ib: int = b.initiative if b is Companion else b.type.initiative
		if ia != ib:
			return ia > ib
		return a is Companion and not b is Companion)


func _check_end() -> void:
	if result != Result.ONGOING:
		return
	if party.living_members().is_empty():
		result = Result.DEFEAT
	elif living_foes().is_empty():
		result = Result.VICTORY
