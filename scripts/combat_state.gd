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
## Rats may dart off once below half health; goblins may raise a shield.
const RAT_FLEE_CHANCE := 0.5
const GOBLIN_SHIELD_CHANCE := 0.4

## Enemy intentions (#60): every enemy shows what it will do on its next
## turn - the action, never the target - so Defend, targeting and items are
## real choices. Each is planned after the enemy acts (and at the start).
enum Intent { ATTACK, LUNGE, DART, WEB, BITE, SWING, HEAVY, SHIELD, KILLING_BLOW, SHOOT, BASH, BRACE, CALL, SCREECH, CLEAVER, RUSH, RECOVER, BEAT }
const INTENT_TEXT := {
	Intent.ATTACK: "attacking",
	Intent.LUNGE: "lunging",
	Intent.DART: "darting back",
	Intent.WEB: "spinning a web",
	Intent.BITE: "poised to bite",
	Intent.SWING: "swinging",
	Intent.HEAVY: "winding up a heavy blow",
	Intent.SHIELD: "raising a shield",
	Intent.KILLING_BLOW: "lining up a killing blow",
	Intent.SHOOT: "nocking an arrow",
	Intent.BASH: "readying a shield bash",
	Intent.BRACE: "bracing behind its shield",
	Intent.CALL: "calling her guards",
	Intent.SCREECH: "drawing breath to screech",
	Intent.CLEAVER: "raising her cleaver",
	Intent.RUSH: "bunching to rush",
	Intent.RECOVER: "catching its breath",
	Intent.BEAT: "beating a war drum",
}
## New monsters (#47): a great rat's rush hits harder; a drummer's beat
## makes each other goblin's next hit stronger.
const RUSH_DAMAGE := 2
const DRUM_DAMAGE := 1
## The fortress (#44). Guards brace now and then; the queen calls up to
## QUEEN_CALLS guards, screeches (strain for everyone) and swings a cleaver
## the coin decides. Below half health she's enraged: she steps forward,
## hits harder and swings the cleaver more often.
const GUARD_BRACE_CHANCE := 0.3
const GUARD_WALL_FACTOR := 0.5
const QUEEN_CALLS := 1
const QUEEN_CALL_CHANCE := 0.4
const QUEEN_CLEAVER_CHANCE := 0.25
const QUEEN_ENRAGED_CLEAVER_CHANCE := 0.45
const QUEEN_SCREECH_CHANCE := 0.15  # was 0.2 (balance report, owner 2026-10-19)
const SCREECH_STRAIN := 8.0  # was 15
const ENRAGED_DAMAGE := 2

## A foe joined mid-fight (the queen's guards): the screen adds its tag.
signal foe_joined(foe)
## Goblin: now and then a killing blow, decided by the coin (#77). Heads it
## misses; tails it hits double, past any guard, and leaves an injury.
## Defending the target, and luck, bend the odds.
const GOBLIN_KILLING_CHANCE := 0.1
const KILLING_DEFEND_BONUS := 0.2
const MAX_HEADS_CHANCE := 0.85
## Goblin: a telegraphed heavy blow hits this many times harder; a hero
## who Defends turns it aside completely.
const HEAVY_MULTIPLIER := 2
const GOBLIN_HEAVY_CHANCE := 0.3
## Spider: chance to spin another web after a bite.
const SPIDER_REWEB_CHANCE := 0.25


## One enemy in this fight.
class Foe:
	var type: EnemyType
	var name: String
	var health: int
	var node: Node3D  # set by the combat screen
	var fled := false
	var shielded := false  # goblin: halves damage until its next turn
	var has_webbed := false  # spider: opens with a web once
	var intent := Intent.ATTACK  # what it does next turn (#60)
	## Blows glance off: 0-1 damage and it never falls (the opening's
	## spider, which only fire drives off, #69). Its health isn't shown.
	var glancing := false
	var marked: Companion  # a killing blow's target, chosen before the coin
	var row_override := ""  # "front" once the enraged queen steps forward
	var enraged := false
	var calls := 0

	func in_back() -> bool:
		return (row_override if row_override != "" else type.row) == "back"

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
var _opened := {}  # Companion -> true after their first attack (opening shot, #47)
var _drummed := {}  # Foe -> true: their next hit is stronger (goblin drummer)
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
	for foe in foes:
		plan(foe)
	_build_order()


## Picks what `foe` will do on its next turn (shown to the player).
## Call again after changing a foe's state from outside (e.g. has_webbed).
func plan(foe: Foe) -> void:
	var hurt := foe.health * 2 < foe.type.max_health
	match foe.type.tactic:
		EnemyType.Tactic.DARTING:
			foe.intent = Intent.DART if hurt and not foe.glancing and rng.randf() < RAT_FLEE_CHANCE else Intent.LUNGE
		EnemyType.Tactic.WEB_AND_VENOM:
			var reweb := foe.intent == Intent.BITE and rng.randf() < foe.type.web_chance
			foe.intent = Intent.WEB if not foe.has_webbed or reweb else Intent.BITE
		EnemyType.Tactic.CUNNING:
			if not foe.shielded and foe.health * 2 <= foe.type.max_health and rng.randf() < GOBLIN_SHIELD_CHANCE:
				foe.intent = Intent.SHIELD
			elif foe.intent not in [Intent.HEAVY, Intent.KILLING_BLOW] and rng.randf() < GOBLIN_KILLING_CHANCE:
				foe.intent = Intent.KILLING_BLOW
			elif foe.intent not in [Intent.HEAVY, Intent.KILLING_BLOW] and rng.randf() < GOBLIN_HEAVY_CHANCE:
				foe.intent = Intent.HEAVY
			else:
				foe.intent = Intent.SWING
		EnemyType.Tactic.ARCHER:
			foe.intent = Intent.SHOOT
		EnemyType.Tactic.RUSHER:
			foe.intent = Intent.RECOVER if foe.intent == Intent.RUSH else Intent.RUSH
		EnemyType.Tactic.DRUMMER:
			foe.intent = Intent.SWING if foe.intent == Intent.BEAT else Intent.BEAT
		EnemyType.Tactic.GUARD:
			foe.intent = Intent.BRACE if not foe.shielded and foe.intent != Intent.BRACE and rng.randf() < GUARD_BRACE_CHANCE else Intent.BASH
		EnemyType.Tactic.QUEEN:
			if not foe.enraged and foe.health * 2 <= foe.type.max_health:
				foe.enraged = true
				foe.row_override = "front"
				events.append("The goblin queen roars and storms forward, enraged!")
			var guards := living_foes().filter(func(f: Foe): return f.type.tactic == EnemyType.Tactic.GUARD).size()
			var cleaver := QUEEN_ENRAGED_CLEAVER_CHANCE if foe.enraged else QUEEN_CLEAVER_CHANCE
			var roll := rng.randf()
			if foe.type.summons and foe.calls < QUEEN_CALLS and guards < 2 and foe.intent != Intent.CALL and roll < QUEEN_CALL_CHANCE:
				foe.intent = Intent.CALL
			elif foe.intent != Intent.CLEAVER and rng.randf() < cleaver:
				foe.intent = Intent.CLEAVER
			elif foe.intent != Intent.SCREECH and rng.randf() < QUEEN_SCREECH_CHANCE:
				foe.intent = Intent.SCREECH
			else:
				foe.intent = Intent.SWING
		_:
			foe.intent = Intent.ATTACK


## The queen's call: another guard joins the fight.
func _call_guard(queen: Foe) -> Dictionary:
	queen.calls += 1
	var count := foes.filter(func(f: Foe): return f.type == queen.type.summons).size() + 1
	var guard := Foe.new(queen.type.summons, "%s %d" % [queen.type.summons.display_name, count])
	foes.append(guard)
	plan(guard)
	foe_joined.emit(guard)
	return {"target": null, "hit": false, "damage": 0, "injury": null,
			"text": "The queen shrieks - %s rushes in to guard her!" % guard.name.to_lower()}


func _screech(queen: Foe) -> Dictionary:
	for hero: Companion in party.living_members():
		hero.change_strain(SCREECH_STRAIN)
	return {"target": null, "hit": false, "damage": 0, "injury": null,
			"text": "The queen's screech rattles everyone's nerves."}


## The coin's result for the next killing blow: 1 heads, 0 tails, -1 not
## flipped (then it's rolled here, e.g. in simulations).
var coin := -1


## Picks who a killing blow is aimed at, so the coin's odds can show.
func prepare_killing_blow(foe: Foe) -> Companion:
	foe.marked = _choose_target(foe)
	return foe.marked


func killing_blow_odds(target: Companion) -> float:
	var chance: float = 0.5 + party.luck()[0]
	if target and is_defending(target):
		chance += KILLING_DEFEND_BONUS
	return minf(chance, MAX_HEADS_CHANCE)


func _killing_blow(foe: Foe) -> Dictionary:
	var target: Companion = foe.marked if foe.marked and foe.marked.is_alive() else _choose_target(foe)
	foe.marked = null
	var outcome := {"target": target, "hit": false, "damage": 0, "injury": null}
	if target == null:
		return outcome
	var heads: bool = coin == 1 if coin != -1 else rng.randf() < killing_blow_odds(target)
	coin = -1
	if heads:
		outcome["text"] = "The %s's %s whistles past %s!" % [foe.name.to_lower(), "cleaver" if foe.intent == Intent.CLEAVER else "killing blow", target.display_name]
		return outcome
	var damage: int = maxi(1, foe.type.damage_max * HEAVY_MULTIPLIER - target.damage_reduction())
	target.change_health(-damage)
	outcome["hit"] = true
	outcome["damage"] = damage
	outcome["text"] = "The %s's %s lands on %s for %d!" % [foe.name.to_lower(), "cleaver" if foe.intent == Intent.CLEAVER else "killing blow", target.display_name, damage]
	if target.is_alive() and not foe.type.injuries.is_empty():
		var injury: Injury = foe.type.injuries[rng.randi_range(0, foe.type.injuries.size() - 1)]
		if target.add_injury(injury):
			outcome["injury"] = injury
			outcome["text"] += " %s suffers a %s!" % [target.display_name, injury.display_name.to_lower()]
	if not target.is_alive():
		outcome["text"] += _fall_text(target)
	_check_end()
	return outcome


## How the intent reads on screen, e.g. "winding up a heavy blow".
static func intent_text(foe) -> String:
	return INTENT_TEXT[foe.intent]


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


## A goblin guard stands in front: those behind it take half damage (#44).
func guard_wall_up() -> bool:
	return living_foes().any(func(f: Foe): return f.type.tactic == EnemyType.Tactic.GUARD and not f.in_back())


# --- Rows (#72) -------------------------------------------------------
# The front row takes melee and shields the back. A row stands alone (no
# one left in front of it) counts as the front.

func hero_in_front(hero: Companion) -> bool:
	return hero.row == "front" or not party.living_members().any(func(h: Companion): return h.row == "front")


func foe_in_front(foe: Foe) -> bool:
	return not foe.in_back() or not living_foes().any(func(f: Foe): return not f.in_back())


## Whether `hero` can attack `foe` from where they stand.
func can_hit(hero: Companion, foe: Foe) -> bool:
	if not foe.is_alive():
		return false
	if not hero_in_front(hero) and not hero.has_reach():
		return false  # back row without reach: defend or use items
	return foe_in_front(foe) or hero.has_reach()


func targets_for(hero: Companion) -> Array[Foe]:
	return living_foes().filter(func(f: Foe): return can_hit(hero, f))


## Whether `foe` can strike `hero` (melee reaches only the front).
func foe_can_reach(foe: Foe, hero: Companion) -> bool:
	return foe.type.reach_back or hero_in_front(hero)


## Steps to the other row; takes the hero's turn.
func hero_move(hero: Companion) -> String:
	hero.row = "back" if hero.row == "front" else "front"
	_webbed.erase(hero)
	hero.emit_changed()
	return "%s steps to the %s." % [hero.display_name, hero.row]


func hero_hit_chance(hero: Companion) -> float:
	var chance: float = hero.hit_accuracy() * hero.effectiveness() + LIGHT_ACCURACY[party.supplies.light_band()]
	# A trinket or boon that favours bright light, and pays for the dark (#135).
	match party.supplies.light_band():
		Supplies.Light.BRIGHT:
			chance += hero.boon_total("light_accuracy")
		Supplies.Light.DIM, Supplies.Light.OUT:
			chance -= hero.boon_total("light_accuracy")
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
	if not can_hit(hero, target):
		outcome["text"] = "%s can't reach the %s from there." % [hero.display_name, target.name.to_lower()]
		return outcome
	var hit := rng.randf() < hero_hit_chance(hero)
	_webbed.erase(hero)  # the web only spoils one action
	if hit and target.glancing:
		var scratch := rng.randi_range(0, 1)
		target.health = maxi(1, target.health - scratch)
		outcome = {"hit": true, "damage": scratch, "killed": false, "glanced": true}
		outcome["text"] = "%s's blow glances off the %s's hard legs." % [hero.display_name, target.name.to_lower()]
	elif hit:
		var reach := hero.attack_range()
		var damage := maxi(1, roundi(rng.randi_range(reach.x, reach.y) * hero.effectiveness()))
		if hero.trait_id == "grudge" and target.type.display_name.begins_with("Goblin"):
			damage += 1  # Corin's grudge (#95)
		if hero.has_talent("berserker") and hero.health * 2 < hero.effective_max_health():
			damage += 2
		if hero.health * 2 < hero.effective_max_health():
			damage += int(hero.boon_total("low_health_damage"))  # a bloodstone (#135)
		if hero.row == "back":
			damage += int(hero.boon_total("back_row_damage"))  # a slinger's ring
		if hero.has_talent("opening_shot") and not _opened.has(hero):
			damage += 2
		_opened[hero] = true
		if target.shielded:
			damage = maxi(1, damage / 2)
		if target.in_back() and guard_wall_up():
			damage = maxi(1, floori(damage * GUARD_WALL_FACTOR))
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
	var steadies: float = hero.boon_total("defend_steadies")  # a shield-bearer's token (#135)
	if steadies > 0.0:
		for member in party.living_members():
			member.change_strain(-steadies)
	return "%s braces, guarding the party." % hero.display_name


func hero_use_item(item: SupplyItem) -> String:
	if current_actor() is Companion:
		_webbed.erase(current_actor())
	if item.effect == SupplyItem.Effect.CURE_VENOM:
		return _cure_venom(item)
	return party.use_item(item, true)


func any_venom() -> bool:
	return _venom.values().any(func(turns): return turns > 0)


## An antidote (#133): the acting hero first if poisoned, else whoever is.
func _cure_venom(item: SupplyItem) -> String:
	var patient = current_actor() if venom_turns(current_actor()) > 0 else null
	if patient == null:
		for hero in _venom:
			if _venom[hero] > 0:
				patient = hero
				break
	if patient == null or not party.supplies.take(item):
		return ""
	_venom.erase(patient)
	return "%s: %s" % [patient.display_name, item.use_message]


## Carries out the foe's shown intent, then plans its next one.
## Returns {"target": Companion, "hit": bool, "damage": int,
## "injury": Injury or null, "text": String}.
func enemy_act(foe: Foe) -> Dictionary:
	var outcome := _carry_out(foe)
	if foe.is_alive():
		plan(foe)
	return outcome


func _carry_out(foe: Foe) -> Dictionary:
	match foe.intent:
		Intent.DART:
			foe.fled = true
			_check_end()
			return {"target": null, "hit": false, "damage": 0, "injury": null, "fled": true,
					"text": "The %s squeals and scurries away." % foe.name.to_lower()}
		Intent.WEB:
			foe.has_webbed = true
			var victim := _choose_target(foe)
			if victim and victim.has_talent("slip_web"):
				return {"target": victim, "hit": false, "damage": 0, "injury": null,
						"text": "The %s spits a web at %s, who slips free." % [foe.name.to_lower(), victim.display_name]}
			if victim:
				_webbed[victim] = true
				return {"target": victim, "hit": false, "damage": 0, "injury": null,
						"text": "The %s spits a web over %s. Their next move will be clumsy." % [foe.name.to_lower(), victim.display_name]}
		Intent.SHIELD:
			foe.shielded = true
			return {"target": null, "hit": false, "damage": 0, "injury": null,
					"text": "The %s raises a battered shield." % foe.name.to_lower()}
		Intent.KILLING_BLOW, Intent.CLEAVER:
			return _killing_blow(foe)
		Intent.BRACE:
			foe.shielded = true
			return {"target": null, "hit": false, "damage": 0, "injury": null,
					"text": "The %s braces behind its shield." % foe.name.to_lower()}
		Intent.CALL:
			return _call_guard(foe)
		Intent.RECOVER:
			return {"target": null, "hit": false, "damage": 0, "injury": null,
					"text": "The %s pants, catching its breath." % foe.name.to_lower()}
		Intent.BEAT:
			for other in living_foes():
				if other != foe:
					_drummed[other] = true
			return {"target": null, "hit": false, "damage": 0, "injury": null,
					"text": "The %s pounds its drum - the others snarl and surge." % foe.name.to_lower()}
		Intent.SCREECH:
			return _screech(foe)
	var heavy := foe.intent == Intent.HEAVY
	var target := _choose_target(foe)
	var outcome := {"target": target, "hit": false, "damage": 0, "injury": null}
	if target == null:
		return outcome
	if rng.randf() < foe.type.accuracy:
		var damage := rng.randi_range(foe.type.damage_min, foe.type.damage_max)
		if foe.enraged:
			damage += ENRAGED_DAMAGE
		if foe.intent == Intent.RUSH:
			damage += RUSH_DAMAGE
		if _drummed.has(foe):
			damage += DRUM_DAMAGE
			_drummed.erase(foe)
		if heavy:
			damage *= HEAVY_MULTIPLIER
		if heavy and is_defending(target):
			damage = 0  # braced for it: the heavy blow is turned aside
		elif is_defending(target):
			damage = maxi(1, floori(damage * target.guard_factor))
		if damage > 0:
			damage = maxi(1, damage - target.damage_reduction())  # toughness, talents, armour (#93)
		if heavy and damage == 0:
			outcome["text"] = "%s braces and turns aside the %s's heavy blow!" % [target.display_name, foe.name.to_lower()]
			_check_end()
			return outcome
		target.change_health(-damage)
		outcome["hit"] = true
		outcome["damage"] = damage
		var verb: String = "brings down a heavy blow on" if heavy else foe.type.attack_verb
		outcome["text"] = "The %s %s %s for %d." % [foe.name.to_lower(), verb, target.display_name, damage]
		if foe.type.tactic == EnemyType.Tactic.WEB_AND_VENOM and foe.type.venomous and target.is_alive():
			_venom[target] = VENOM_TURNS
			outcome["text"] += " Venom burns in the wound."
		if target.is_alive() and not foe.type.injuries.is_empty() and rng.randf() < foe.type.injury_chance:
			var injury: Injury = foe.type.injuries[rng.randi_range(0, foe.type.injuries.size() - 1)]
			if target.add_injury(injury):
				outcome["injury"] = injury
				outcome["text"] += " %s suffers a %s!" % [target.display_name, injury.display_name.to_lower()]
		if not target.is_alive():
			outcome["text"] += _fall_text(target)
	else:
		outcome["text"] = "The %s lunges at %s and misses." % [foe.name.to_lower(), target.display_name]
	_check_end()
	return outcome


## Burn damage when a thrown torch hits something that doesn't fear fire.
const TORCH_BURN := Vector2i(3, 5)

## Throws the burning torch at `target` (#59, #115): beasts that fear fire
## flee; goblins (the queen too) are burned but stand their ground.
## The torch is gone; without a lantern, the party is in the dark.
## Returns {"fled", "damage", "killed", "text"}.
func hero_throw_torch(hero: Companion, target: Foe) -> Dictionary:
	var outcome := {"fled": false, "damage": 0, "killed": false, "text": ""}
	if not party.supplies.torch_lit():
		return outcome
	_webbed.erase(hero)
	party.supplies.lose_torch()
	if target.type.fears_fire:
		target.fled = true
		outcome["fled"] = true
		outcome["text"] = "%s hurls the burning torch - the %s flees from the flames!" % [hero.display_name, target.name.to_lower()]
	else:
		var burn := rng.randi_range(TORCH_BURN.x, TORCH_BURN.y) + int(hero.boon_total("torch_burn"))
		target.health = maxi(0, target.health - burn)
		outcome["damage"] = burn
		outcome["killed"] = not target.is_alive()
		outcome["text"] = "%s hurls the burning torch - the %s is burned for %d, but stands its ground." % [hero.display_name, target.name.to_lower(), burn]
	_check_end()
	return outcome


## The owner's retreat idea (trial): the fight ends, the party flees.
## Where they end up and the time cost are handled by the caller.
func retreat() -> String:
	result = Result.RETREAT
	return "You flee blindly into the dark."


## Who an enemy goes after, by tactic. Normally a defender draws attacks.
func _choose_target(foe: Foe = null) -> Companion:
	var living: Array[Companion] = party.living_members()
	if foe:
		living = living.filter(func(h: Companion): return foe_can_reach(foe, h))
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
		text += _fall_text(hero)
	events.append(text)


func _fall_text(hero: Companion) -> String:
	if hero.is_unconscious():
		return " %s collapses, unconscious." % hero.display_name
	return " %s falls." % hero.display_name


func _build_order() -> void:
	_order.clear()
	for hero in party.living_members():
		_order.append(hero)
	for foe in living_foes():
		_order.append(foe)
	# Higher initiative first; ties go to the party.
	_order.sort_custom(func(a, b):
		var ia: int = a.effective_initiative() if a is Companion else a.type.initiative
		var ib: int = b.effective_initiative() if b is Companion else b.type.initiative
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
