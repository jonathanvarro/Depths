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
enum Intent { ATTACK, LUNGE, DART, WEB, BITE, SWING, HEAVY, SHIELD, KILLING_BLOW, SHOOT, BASH, BRACE, CALL, SCREECH, CLEAVER, RUSH, RECOVER, BEAT, SWOOP, SWELL, GRAB, CURL, SNARE, DRAIN, RALLY, BROOD }
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
	Intent.SWOOP: "circling to swoop",
	Intent.SWELL: "swelling, about to burst",
	Intent.GRAB: "reaching to grab",
	Intent.CURL: "curling up",
	Intent.SNARE: "laying a snare",
	Intent.DRAIN: "drawn to your light",
	Intent.RALLY: "raising its horn to rally",
	Intent.BROOD: "calling her brood",
}
## The rest of #140's monsters. A curled beetle takes at most this much
## from a blow. A snared hero acts last next round. A lamp-eater drinks
## this much oil, or this much of a torch's life. Hounds hit harder while
## another hound stands. The Broodmother calls this many hatchlings, once,
## and rages below half health. A gate captain's rally braces an ally.
const CURLED_DAMAGE := 1
const SNARE_INITIATIVE := 10
const DRAIN_OIL := 12.0
const DRAIN_TORCH := 12.0
const PACK_DAMAGE := 1
const BROOD_HATCHLINGS := 2
## New monsters (#140). A brute recovering from its heavy blow is wide open:
## blows land this much harder. A gas-bloat's burst: damage to the front
## and back rows and strain for all; killed from the back row, the gas
## mostly misses; set alight by a thrown torch, it flashes instead,
## burning the other foes more than the party.
const BRUTE_OPENING := 2
const GAS_DAMAGE := {"front": 2, "back": 1}
const GAS_STRAIN := 6.0
const FLASH_FOE_DAMAGE := 3
const FLASH_HERO_DAMAGE := 1
## Elites (#140, owner 2026-10-21): from floor 2, some foes carry one
## modifier and a coloured nameplate. They're worth a little more XP and
## hold most of the drop chance (trinkets.gd, gear_gen.gd). At most this
## many per fight.
const ELITE_CHANCE := {2: 0.12, 3: 0.18, 4: 0.22}  # nudged up 2026-10-25, after the free torches
const MAX_ELITES := {2: 1, 3: 2, 4: 2}
const ELITES := ["Hardened", "Savage", "Swift", "Venomous"]
const HARDENED_HEALTH := 1.5
const SAVAGE_DAMAGE := 1
const SWIFT_INITIATIVE := 3
## Deeper floors bite harder (owner, 2026-10-21): foes' health and damage
## scale by floor, the queen and her guards included.
const DEPTH_SCALE := {2: 1.05, 3: 1.15, 4: 1.25}  # was 3: 1.1, 4: 1.2 (retuned 2026-10-25 to ~24/30)
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
	var elite := ""  # "Hardened", "Savage", "Swift" or "Venomous" (#140)
	var curled := false  # rock beetle: blows barely scratch it until its next turn

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
## Who moves first in round one (#73): "party" after striking first, "foes"
## when they heard you coming; "" goes by initiative as usual.
var opening := ""
var _turn := 0
var _defending := {}  # Companion -> true until their next turn
var _webbed := {}  # Companion -> true until their next action
var _venom := {}  # Companion -> turns left
var _venom_damage := {}  # Companion -> damage per tick (a venom spider's is worse)
var _opened := {}  # Companion -> true after their first attack (opening shot, #47)
var _dazzled := {}  # Foe -> true: a flare costs it its next action (#74)
var _squinting := {}  # Foe -> true: worse aim on its next action (#74)
var _drummed := {}  # Foe -> true: their next hit is stronger (goblin drummer)
var _grabbed := {}  # Companion -> Foe holding them (hollow miner, #140)
var depth_scale := 1.0  # see prepare()
var _snared := {}  # Companion -> true: acts last next round (goblin trapper)
var _snared_this_round := {}  # who's acting last now, for the card's mark
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
		if foe.type.tactic == EnemyType.Tactic.SWOOPER:
			foe.row_override = "back"  # a bat starts in the air
		plan(foe)
	_build_order()


## Sets the fight up for its floor (#140): deeper foes are tougher, and
## some become elites. `kind`: "", "gate" or "queen" (set fights have no
## elites). The game and the playtest bot both call this, so they match.
func prepare(depth: int, kind := "") -> void:
	depth_scale = DEPTH_SCALE.get(depth, 1.0)
	for foe in foes:
		_scale(foe)
	if kind == "":
		var chance: float = ELITE_CHANCE.get(depth, 0.0)
		var made := 0
		for foe in foes:
			if made < MAX_ELITES.get(depth, 0) and rng.randf() < chance:
				make_elite(foe, ELITES[rng.randi_range(0, ELITES.size() - 1)])
				made += 1
	# Their first moves were planned when the fight was set up; planning
	# again here skipped each pattern's opening (the Broodmother bit before
	# calling her brood, the captain swung before rallying, #145). The order
	# is rebuilt for a Swift elite.
	_build_order()


## Deeper, tougher: health and damage times the floor's scale.
func _scale(foe: Foe) -> void:
	if is_equal_approx(depth_scale, 1.0):
		return
	var type: EnemyType = foe.type.duplicate()
	type.max_health = roundi(type.max_health * depth_scale)
	type.damage_min = roundi(type.damage_min * depth_scale)
	type.damage_max = roundi(type.damage_max * depth_scale)
	foe.type = type
	foe.health = type.max_health


## Makes `foe` an elite of `kind`. Its kind keeps its own name for contracts
## and the expedition record; the fight shows "Hardened goblin".
func make_elite(foe: Foe, kind: String) -> void:
	var type: EnemyType = foe.type.duplicate()
	match kind:
		"Hardened":
			type.max_health = roundi(type.max_health * HARDENED_HEALTH)
		"Savage":
			type.damage_min += SAVAGE_DAMAGE
			type.damage_max += SAVAGE_DAMAGE
		"Swift":
			type.initiative += SWIFT_INITIATIVE
	type.threat += 1  # a little more to learn from
	foe.type = type
	foe.health = type.max_health
	foe.elite = kind
	foe.name = "%s %s" % [kind, foe.name.substr(0, 1).to_lower() + foe.name.substr(1)]


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
		EnemyType.Tactic.SWOOPER:
			foe.intent = Intent.SWOOP if foe.in_back() else Intent.BITE
		EnemyType.Tactic.BRUTE:
			match foe.intent:
				Intent.SWING: foe.intent = Intent.HEAVY
				Intent.HEAVY: foe.intent = Intent.RECOVER
				_: foe.intent = Intent.SWING
		EnemyType.Tactic.BLOAT:
			foe.intent = Intent.SWELL if hurt else Intent.ATTACK
		EnemyType.Tactic.GRABBER:
			var holding := _grabbed.values().has(foe)
			foe.intent = Intent.SWING if holding or foe.intent == Intent.GRAB else Intent.GRAB
		EnemyType.Tactic.CURLER:
			foe.intent = Intent.CURL if foe.intent == Intent.BITE else Intent.BITE
		EnemyType.Tactic.TRAPPER:
			foe.intent = Intent.SHOOT if foe.intent == Intent.SNARE else Intent.SNARE
		EnemyType.Tactic.DRAINER:
			foe.intent = Intent.DRAIN if party.supplies.light_band() != Supplies.Light.OUT else Intent.BITE
		EnemyType.Tactic.PACK:
			foe.intent = Intent.LUNGE
		EnemyType.Tactic.BROOD:
			if not foe.enraged and hurt:
				foe.enraged = true
				events.append("The %s shrieks and lunges, enraged!" % foe.name.to_lower())
			foe.intent = Intent.BROOD if foe.calls == 0 and foe.intent != Intent.BROOD and not foe.enraged else Intent.BITE
		EnemyType.Tactic.CAPTAIN:
			match foe.intent:
				Intent.RALLY: foe.intent = Intent.HEAVY
				Intent.HEAVY: foe.intent = Intent.SWING
				_: foe.intent = Intent.RALLY if living_foes().size() > 1 else Intent.HEAVY
		_:
			foe.intent = Intent.ATTACK


## The queen's call: another guard joins the fight.
func _call_guard(queen: Foe) -> Dictionary:
	queen.calls += 1
	# By name: depth scaling gives each foe its own copy of its kind (#140).
	var count := foes.filter(func(f: Foe): return f.type.display_name == queen.type.summons.display_name).size() + 1
	var guard := Foe.new(queen.type.summons, "%s %d" % [queen.type.summons.display_name, count])
	_scale(guard)
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
				if actor.is_alive() and is_grabbed(actor):
					# Held fast (#140): the turn goes on struggling, and
					# they wrench free at the end of it (#143).
					events.append("%s struggles in the %s's grip and wrenches free." % [actor.display_name, _grabbed[actor].name.to_lower()])
					_grabbed.erase(actor)
				elif actor.is_alive():
					return
			else:
				actor.shielded = false  # a shield lasts until its next turn
				actor.curled = false  # and a beetle unfolds
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


## Whether `foe` can strike `hero` (melee reaches only the front; a bat's
## swoop reaches anyone).
func foe_can_reach(foe: Foe, hero: Companion) -> bool:
	return foe.type.reach_back or foe.intent == Intent.SWOOP or hero_in_front(hero)


## Held by a hollow miner (#140): loses their next turn struggling free,
## unless someone hits the miner first (#143).
func is_grabbed(hero: Companion) -> bool:
	if not _grabbed.has(hero):
		return false
	if not _grabbed[hero].is_alive():
		_grabbed.erase(hero)
		return false
	return true


## A grabber took a blow: everyone it held is free.
func _release(foe: Foe) -> void:
	for hero in _grabbed.keys():
		if _grabbed[hero] == foe:
			_grabbed.erase(hero)


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
		if target.type.tactic == EnemyType.Tactic.BRUTE and target.intent == Intent.RECOVER:
			damage += BRUTE_OPENING  # a brute catching its breath is wide open (#140)
		if target.curled:
			damage = mini(damage, CURLED_DAMAGE)  # a curled beetle: a scratch at most
		if target.shielded:
			damage = maxi(1, damage / 2)
		if target.in_back() and guard_wall_up():
			damage = maxi(1, floori(damage * GUARD_WALL_FACTOR))
		target.health = maxi(0, target.health - damage)
		_release(target)
		outcome = {"hit": true, "damage": damage, "killed": not target.is_alive()}
		outcome["text"] = "%s strikes the %s for %d.%s" % [hero.display_name, target.name.to_lower(), damage, " It falls." if outcome["killed"] else ""]
		if outcome["killed"] and target.type.tactic == EnemyType.Tactic.BLOAT:
			outcome["text"] += " " + _burst(target, "back" if not hero_in_front(hero) else "near")
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
	if _dazzled.has(foe):  # blinded by a flare: this turn is lost (#74)
		_dazzled.erase(foe)
		return {"target": null, "hit": false, "damage": 0, "injury": null,
				"text": "The %s reels from the glare, eyes screwed shut." % foe.name.to_lower()}
	var acted := foe.intent
	var outcome := _carry_out(foe)
	_squinting.erase(foe)  # its eyes have cleared
	if foe.type.tactic == EnemyType.Tactic.SWOOPER and foe.is_alive():
		# A bat lands after its swoop, then rises again after biting (#140).
		foe.row_override = "front" if acted == Intent.SWOOP else "back"
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
		Intent.SWELL:
			foe.health = 0
			var swollen := "The %s swells and tears open! %s" % [foe.name.to_lower(), _burst(foe, "near")]
			_check_end()
			return {"target": null, "hit": false, "damage": 0, "injury": null, "text": swollen}
		Intent.CURL:
			foe.curled = true
			return {"target": null, "hit": false, "damage": 0, "injury": null,
					"text": "The %s curls into a stony ball." % foe.name.to_lower()}
		Intent.SNARE:
			var caught := _choose_target(foe)
			if caught == null:
				return {"target": null, "hit": false, "damage": 0, "injury": null, "text": ""}
			_snared[caught] = true
			return {"target": caught, "hit": true, "damage": 0, "injury": null,
					"text": "The %s's snare catches %s's ankle. They'll be last to act next round." % [foe.name.to_lower(), caught.display_name]}
		Intent.DRAIN:
			return _drain(foe)
		Intent.RALLY:
			var allies := living_foes().filter(func(f: Foe): return f != foe)
			if not allies.is_empty():
				var ally: Foe = allies[rng.randi_range(0, allies.size() - 1)]
				ally.shielded = true
				return {"target": null, "hit": false, "damage": 0, "injury": null,
						"text": "The %s blasts its horn - the %s braces behind its guard." % [foe.name.to_lower(), ally.name.to_lower()]}
			return {"target": null, "hit": false, "damage": 0, "injury": null, "text": ""}
		Intent.BROOD:
			return _call_brood(foe)
		Intent.GRAB:
			var held := _choose_target(foe)
			if held == null:
				return {"target": null, "hit": false, "damage": 0, "injury": null, "text": ""}
			if is_defending(held) or rng.randf() >= _foe_accuracy(foe):
				return {"target": held, "hit": false, "damage": 0, "injury": null,
						"text": "The %s grabs at %s, who twists free." % [foe.name.to_lower(), held.display_name]}
			_grabbed[held] = foe
			return {"target": held, "hit": true, "damage": 0, "injury": null,
					"text": "The %s seizes %s! Hit it to break the hold, or they lose their next turn struggling free." % [foe.name.to_lower(), held.display_name]}
	var heavy := foe.intent == Intent.HEAVY
	var target := _choose_target(foe)
	var outcome := {"target": target, "hit": false, "damage": 0, "injury": null}
	if target == null:
		return outcome
	if rng.randf() < _foe_accuracy(foe):
		var damage := rng.randi_range(foe.type.damage_min, foe.type.damage_max)
		if foe.enraged:
			damage += ENRAGED_DAMAGE
		if foe.intent == Intent.RUSH:
			damage += RUSH_DAMAGE
		if foe.type.tactic == EnemyType.Tactic.PACK and living_foes().any(func(f: Foe): return f != foe and f.type.tactic == EnemyType.Tactic.PACK):
			damage += PACK_DAMAGE  # hounds hunt together (#140)
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
		if ((foe.type.tactic in [EnemyType.Tactic.WEB_AND_VENOM, EnemyType.Tactic.BROOD] and foe.type.venomous) or foe.elite == "Venomous") and target.is_alive():
			_venom[target] = VENOM_TURNS
			_venom_damage[target] = maxi(foe.type.venom_damage, 1)
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


## A flare (#74, owner 2026-10-25): goblins and miners squint this much
## worse on their next action.
const SQUINT := 0.2

## What a flare does to `foe`: "dazzle" (a beast that fears fire loses its
## next action), "squint" (worse aim), "drink" (a lamp-eater feeds on it)
## or "" (a gas-bloat: only a thrown torch sets one off).
static func flare_effect(foe: Foe) -> String:
	match foe.type.tactic:
		EnemyType.Tactic.DRAINER:
			return "drink"
		EnemyType.Tactic.BLOAT:
			return ""
	return "dazzle" if foe.type.fears_fire else "squint"


## Flares the party's light at every foe: it takes the hero's turn and
## burns 10 oil, or 15 of a torch. Returns {"text", "dazzled", "squinting"}.
func hero_flare(hero: Companion) -> Dictionary:
	var outcome := {"text": "", "dazzled": [], "squinting": []}
	if not party.supplies.can_flare():
		return outcome
	party.supplies.spend_flare()
	var drank := false
	for foe in living_foes():
		match flare_effect(foe):
			"dazzle":
				_dazzled[foe] = true
				outcome["dazzled"].append(foe)
				if foe.type.tactic == EnemyType.Tactic.SWOOPER and foe.in_back():
					foe.row_override = "front"  # the glare knocks a bat out of the air
					plan(foe)
			"squint":
				_squinting[foe] = true
				outcome["squinting"].append(foe)
			"drink":
				drank = true
	var parts := PackedStringArray()
	if not outcome["dazzled"].is_empty():
		parts.append("the beasts reel back, blinded")
	if not outcome["squinting"].is_empty():
		parts.append("the others squint and curse")
	if drank:
		parts.append("the lamp-eater drinks it in")
	outcome["text"] = "%s flares the light%s" % [hero.display_name, (" - " + ", ".join(parts) + ".") if not parts.is_empty() else "."]
	return outcome


func is_dazzled(foe: Foe) -> bool:
	return _dazzled.has(foe)


func is_squinting(foe: Foe) -> bool:
	return _squinting.has(foe)


func _foe_accuracy(foe: Foe) -> float:
	return foe.type.accuracy - (SQUINT if _squinting.has(foe) else 0.0)


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
	elif target.type.tactic == EnemyType.Tactic.BLOAT:
		# Fire and gas (#140): it goes up in a flash, burning its friends.
		outcome["damage"] = target.health
		target.health = 0
		outcome["killed"] = true
		outcome["text"] = "%s hurls the burning torch - %s" % [hero.display_name, _burst(target, "fire")]
	else:
		var burn := rng.randi_range(TORCH_BURN.x, TORCH_BURN.y) + int(hero.boon_total("torch_burn"))
		target.health = maxi(0, target.health - burn)
		_release(target)
		outcome["damage"] = burn
		outcome["killed"] = not target.is_alive()
		outcome["text"] = "%s hurls the burning torch - the %s is burned for %d, but stands its ground." % [hero.display_name, target.name.to_lower(), burn]
	_check_end()
	return outcome


## Snared: acting last this round (#140), for the card's mark.
func is_snared(hero: Companion) -> bool:
	return _snared_this_round.has(hero) or _snared.has(hero)


## A lamp-eater drinks the light (#140): oil from the lantern, or a held
## torch's remaining life. Out of light, it bites instead (planned so).
func _drain(foe: Foe) -> Dictionary:
	var supplies = party.supplies
	var text := ""
	if supplies.torch_lit():
		supplies.torch_left = maxf(0.0, supplies.torch_left - DRAIN_TORCH)
		if supplies.torch_left <= 0.0:
			supplies.burn(1)  # it gutters out
		text = "The %s settles on the torch and drinks its flame low." % foe.name.to_lower()
	elif supplies.has_lantern and supplies.oil > 0.0:
		supplies.oil = maxf(0.0, supplies.oil - DRAIN_OIL)
		text = "The %s clings to the lantern and drinks - the light gutters." % foe.name.to_lower()
	supplies.changed.emit()
	return {"target": null, "hit": false, "damage": 0, "injury": null, "drained": true, "text": text}


## The Broodmother calls her hatchlings (#140), once.
func _call_brood(mother: Foe) -> Dictionary:
	mother.calls += 1
	var hatchling: EnemyType = mother.type.summons
	if hatchling == null:
		return {"target": null, "hit": false, "damage": 0, "injury": null, "text": ""}
	for i in BROOD_HATCHLINGS:
		var count := foes.filter(func(f: Foe): return f.type.display_name == hatchling.display_name).size() + 1
		var young := Foe.new(hatchling, "%s %d" % [hatchling.display_name, count])
		_scale(young)
		foes.append(young)
		plan(young)
		foe_joined.emit(young)
	return {"target": null, "hit": false, "damage": 0, "injury": null,
			"text": "The %s's sac splits - hatchlings swarm out!" % mother.name.to_lower()}


## A gas-bloat bursts (#140). `how`: "near" (killed up close, or it
## swelled until it tore), "back" (killed from the back row: the gas mostly
## misses) or "fire" (a thrown torch: a flash that burns the other foes).
## Returns what happened, and adds it to the events.
func _burst(bloat: Foe, how: String) -> String:
	var text := ""
	if how == "fire":
		for foe in living_foes():
			foe.health = maxi(0, foe.health - FLASH_FOE_DAMAGE)
			_release(foe)
		for hero: Companion in party.living_members():
			hero.change_health(-FLASH_HERO_DAMAGE)
		text = "the gas catches in a roaring flash! Everything nearby is scorched."
	else:
		var softer := how == "back"
		for hero: Companion in party.living_members():
			var hurt: int = GAS_DAMAGE["front" if hero_in_front(hero) else "back"] - (1 if softer else 0)
			if hurt > 0:
				hero.change_health(-hurt)
			hero.change_strain(GAS_STRAIN * (0.5 if softer else 1.0))
		text = "Gas billows out of the %s%s" % [bloat.name.to_lower(), " - most of it rolls past." if softer else " over everyone. Eyes stream, lungs burn."]
	events.append(text)
	_check_end()
	return text


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
		EnemyType.Tactic.PACK:
			pool = [_weakest(living)]  # hounds go for the weakest, braced or not
		EnemyType.Tactic.GRABBER:
			# It swings at whoever it holds; it grabs whoever isn't braced.
			var held: Array = living.filter(func(h: Companion): return _grabbed.get(h) == foe)
			pool = held if not held.is_empty() else (exposed if not exposed.is_empty() else living)
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
	var burn: int = _venom_damage.get(hero, VENOM_DAMAGE)
	hero.change_health(-burn)
	turns -= 1
	if turns > 0:
		_venom[hero] = turns
	else:
		_venom.erase(hero)
	var text := "Venom burns %s (%d)." % [hero.display_name, burn]
	if not hero.is_alive():
		text += _fall_text(hero)
	events.append(text)


func _fall_text(hero: Companion) -> String:
	if hero.is_unconscious():
		return " %s collapses, unconscious." % hero.display_name
	return " %s falls." % hero.display_name


## Sets who goes first in round one (#73) and reorders it.
func set_opening(side: String) -> void:
	opening = side
	_build_order()


func _build_order() -> void:
	_order.clear()
	var snared := _snared.duplicate()  # a snare lasts one round (#140)
	for hero in party.living_members():
		_order.append(hero)
	for foe in living_foes():
		_order.append(foe)
	# Higher initiative first; ties go to the party. In round one, a side
	# that struck first (or was caught out) goes before the other (#73).
	_order.sort_custom(func(a, b):
		if round == 1 and opening != "" and (a is Companion) != (b is Companion):
			return (a is Companion) == (opening == "party")
		var ia: int = (a.effective_initiative() - (SNARE_INITIATIVE if _snared.has(a) else 0)) if a is Companion else a.type.initiative
		var ib: int = (b.effective_initiative() - (SNARE_INITIATIVE if _snared.has(b) else 0)) if b is Companion else b.type.initiative
		if ia != ib:
			return ia > ib
		return a is Companion and not b is Companion)
	_snared = {}
	_snared_this_round = {}
	for hero in snared:
		_snared_this_round[hero] = true


func _check_end() -> void:
	if result != Result.ONGOING:
		return
	if party.living_members().is_empty():
		result = Result.DEFEAT
	elif living_foes().is_empty():
		result = Result.VICTORY
