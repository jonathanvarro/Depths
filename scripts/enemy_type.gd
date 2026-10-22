class_name EnemyType
extends Resource
## A kind of enemy (#14, #15): its look and fighting numbers.
## Definitions live in `data/enemies/*.tres`; a fight creates instances.
## Numbers are first guesses to tune.

@export var display_name := "Enemy"
## A Node3D scene with an AnimatedSprite3D named "Sprite" that has
## "idle", "attack" and "hurt" animations (see art/enemies/).
@export var scene: PackedScene
@export var max_health := 6
@export var damage_min := 1
@export var damage_max := 3
## Chance to hit before a defending target halves the damage.
@export_range(0.0, 1.0) var accuracy := 0.7
## Higher acts earlier in the round.
@export var initiative := 10
## Chance that a hit also leaves a lasting injury.
@export_range(0.0, 1.0) var injury_chance := 0.1
@export var injuries: Array[Injury] = []
## Verb used in the combat log ("The rat bites Mara").
@export var attack_verb := "attacks"

## How it fights (#15). See combat_state.gd for what each does.
enum Tactic {
	BASIC,  ## attacks anyone; respects a defender
	DARTING,  ## goes for the weakest; may flee when badly hurt (rats)
	WEB_AND_VENOM,  ## opens with a web, bites poison; ignores defenders (spiders)
	CUNNING,  ## flanks whoever isn't defending; shields up when hurt (goblins)
	ARCHER,  ## shoots from the back row, reaching anyone (goblin archer, #44)
	GUARD,  ## shield wall: goblins behind it take half damage (goblin guard)
	QUEEN,  ## calls guards, screeches, and her cleaver is decided by the coin
	RUSHER,  ## rushes, then catches its breath (great rat, #47)
	DRUMMER,  ## beats a war drum: the others hit harder next (goblin drummer)
	SWOOPER,  ## in the air (only reach hits it), swoops at anyone, lands, rises (cave bat, #140)
	BRUTE,  ## swings, winds up a heavy blow, then recovers - wide open (goblin brute)
	BLOAT,  ## drifts and puffs; swells when hurt; bursts gas over the party when it dies (gas-bloat)
	GRABBER,  ## grabs a hero, who can't act until it's hit; swings its pick (hollow miner)
	CURLER,  ## bites, then curls up: blows barely scratch it until it unfolds (rock beetle)
	TRAPPER,  ## sets a snare (the hero acts last next round), then throws (goblin trapper)
	DRAINER,  ## drinks the party's light - lantern oil or a torch's life (lamp-eater)
	PACK,  ## lunges at the weakest; hits harder while another of its pack stands (breach hound)
	BROOD,  ## calls hatchlings once, bites with venom, rages below half health (Broodmother)
	CAPTAIN,  ## rallies an ally behind a raised guard, winds up, strikes (gate captain)
}
@export var tactic := Tactic.BASIC
## Shown when the fight starts: a hint at how it fights.
@export var intro := ""
## Gold dropped when beaten, min-max (goblins carry purses, #42).
@export var purse := Vector2i.ZERO
## A thrown torch (#115, owner 2026-10-19): beasts that fear fire flee from
## it; goblins stand their ground and are burned instead.
@export var fears_fire := true
## Threat points (#47): an encounter's cost; XP is 4 per point. 0 for the
## opening's scripted enemies.
@export var threat := 1
## Where it stands in a fight (#72): back-row enemies can only be hit with
## reach until the front row is down.
@export_enum("front", "back") var row := "front"
## Attacks reach the heroes' back row (a spider drops from above).
@export var reach_back := false
## Spiders: chance to web again after a bite, and whether bites poison.
@export_range(0.0, 1.0) var web_chance := 0.25
@export var venomous := true
## Venom per tick for a bite that poisons (a venom spider's is worse, #140).
@export var venom_damage := 1
## Who it calls into the fight (the queen's guards, #44).
@export var summons: EnemyType
## Placeholder look until its own art exists: a tint and a size for the
## shared sprite (#99).
@export var tint := Color.WHITE
@export var sprite_scale := 1.0
## Something it may leave behind when beaten (a hollow miner's pick, #140).
@export var drop: SupplyItem
@export_range(0.0, 1.0) var drop_chance := 0.0
