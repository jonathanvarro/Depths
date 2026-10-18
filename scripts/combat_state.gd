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

## Enemy tactics (#15).
## Spider web: the victim's next action is this much less accurate.
const WEB_PENALTY := 0.25
## Spider venom: damage at the start of the victim's turns, for this many
## turns. A new bite refreshes it rather than stacking.
const VENOM_DAMAGE := 1
const VENOM_TURNS := 2
## Rats may flee once below half health; goblins may raise a shield.
const RAT_FLEE_CHANCE := 0.4
const GOBLIN_SHIELD_CHANCE := 0.4


## One enemy in this fight.
class Foe:
	var type: EnemyType
	var name: String
	var health: int
	var node: Node3D  # set by the combat screen
	var fled := false
	var shielded := false  # goblin: halves damage until its next turn
	var has_webbed := false  # spider: opens with a web once

	func _init(enemy_type: EnemyType, label: String) -> void:
		type = enemy_type
		name = label
		health = enemy_type.max_health

	## Still in the fight (not dead and not fled).
	func is_alive() -> bool:
		return health > 0 and not fled


var party  # party_state.gd
var foes: Array[Foe] = []
var round := 1
var result := Result.ONGOING
var rng := RandomNumberGenerator.new()

var _order: Array = []  # Companion or Foe, this round's acting order
var _turn := 0
var _defending := {}  # Companion -> true until their next turn
var _webbed := {}  # Companion -> true until their next action
var _venom := {}  # Companion -> turns left
## Things that happened between actions (venom ticking...). The combat
## screen shows and clears these after each advance().
var events: PackedStringArray = []


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
				_tick_venom(actor)
				_check_end()
				if result != Result.ONGOING:
					return
				if actor.is_alive():
					return
			else:
				actor.shielded = false  # a shield lasts until its next turn
				return
		_turn += 1


func hero_hit_chance(hero: Companion) -> float:
	var chance: float = hero.hit_accuracy() * hero.effectiveness() + LIGHT_ACCURACY[party.supplies.light_band()]
	if is_webbed(hero):
		chance -= WEB_PENALTY
	return clampf(chance, MIN_HIT_CHANCE, MAX_HIT_CHANCE)


func is_webbed(hero: Companion) -> bool:
	return _webbed.has(hero)


func venom_turns(hero: Companion) -> int:
	return _venom.get(hero, 0)


## Returns {"hit": bool, "damage": int, "killed": bool, "text": String}.
func hero_attack(hero: Companion, target: Foe) -> Dictionary:
	var outcome := {"hit": false, "damage": 0, "killed": false}
	var hit := rng.randf() < hero_hit_chance(hero)
	_webbed.erase(hero)  # the web only spoils one action
	if hit:
		var reach := hero.attack_range()
		var damage := maxi(1, roundi(rng.randi_range(reach.x, reach.y) * hero.effectiveness()))
		if target.shielded:
			damage = maxi(1, damage / 2)
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
	_webbed.erase(hero)
	return "%s braces, guarding the party." % hero.display_name


func hero_use_item(item: SupplyItem) -> String:
	if current_actor() is Companion:
		_webbed.erase(current_actor())
	return party.use_item(item, true)


## Returns {"target": Companion, "hit": bool, "damage": int,
## "injury": Injury or null, "text": String}.
func enemy_act(foe: Foe) -> Dictionary:
	match foe.type.tactic:
		EnemyType.Tactic.DARTING:
			if foe.health * 2 < foe.type.max_health and rng.randf() < RAT_FLEE_CHANCE:
				foe.fled = true
				_check_end()
				return {"target": null, "hit": false, "damage": 0, "injury": null, "fled": true,
						"text": "The %s squeals and scurries away." % foe.name.to_lower()}
		EnemyType.Tactic.WEB_AND_VENOM:
			if not foe.has_webbed:
				foe.has_webbed = true
				var victim := _choose_target(foe)
				if victim:
					_webbed[victim] = true
					return {"target": victim, "hit": false, "damage": 0, "injury": null,
							"text": "The %s spits a web over %s. Their next move will be clumsy." % [foe.name.to_lower(), victim.display_name]}
		EnemyType.Tactic.CUNNING:
			if not foe.shielded and foe.health * 2 <= foe.type.max_health and rng.randf() < GOBLIN_SHIELD_CHANCE:
				foe.shielded = true
				return {"target": null, "hit": false, "damage": 0, "injury": null,
						"text": "The %s raises a battered shield." % foe.name.to_lower()}
	var target := _choose_target(foe)
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
		if foe.type.tactic == EnemyType.Tactic.WEB_AND_VENOM and target.is_alive():
			_venom[target] = VENOM_TURNS
			outcome["text"] += " Venom burns in the wound."
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


## Throws the burning torch at `target`, which flees the flames (#59).
## The torch is gone; without a lantern, the party is in the dark.
func hero_throw_torch(hero: Companion, target: Foe) -> String:
	if not party.supplies.torch_lit():
		return ""
	_webbed.erase(hero)
	party.supplies.lose_torch()
	target.fled = true
	_check_end()
	return "%s hurls the burning torch - the %s flees from the flames!" % [hero.display_name, target.name.to_lower()]


## The owner's retreat idea (trial): the fight ends, the party flees.
## Where they end up and the time cost are handled by the caller.
func retreat() -> String:
	result = Result.RETREAT
	return "You flee blindly into the dark."


## Who an enemy goes after, by tactic. Normally a defender draws attacks.
func _choose_target(foe: Foe = null) -> Companion:
	var living: Array[Companion] = party.living_members()
	if living.is_empty():
		return null
	var guards := living.filter(func(h: Companion): return is_defending(h))
	var exposed := living.filter(func(h: Companion): return not is_defending(h))
	var tactic: int = foe.type.tactic if foe else EnemyType.Tactic.BASIC
	var pool: Array = living
	match tactic:
		EnemyType.Tactic.WEB_AND_VENOM:
			pool = living  # it drops from above; a defender covers no one
		EnemyType.Tactic.CUNNING:
			pool = exposed if not exposed.is_empty() else living  # flanks
		EnemyType.Tactic.DARTING:
			pool = guards if not guards.is_empty() else [_weakest(living)]
		_:
			pool = guards if not guards.is_empty() else living
	return pool[rng.randi_range(0, pool.size() - 1)]


func _weakest(heroes: Array[Companion]) -> Companion:
	var weakest := heroes[0]
	for hero in heroes:
		if hero.health < weakest.health:
			weakest = hero
	return weakest


func _tick_venom(hero: Companion) -> void:
	var turns: int = _venom.get(hero, 0)
	if turns <= 0:
		return
	hero.change_health(-VENOM_DAMAGE)
	turns -= 1
	if turns > 0:
		_venom[hero] = turns
	else:
		_venom.erase(hero)
	var text := "Venom burns %s (%d)." % [hero.display_name, VENOM_DAMAGE]
	if not hero.is_alive():
		text += " %s falls." % hero.display_name
	events.append(text)


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
