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
}
@export var tactic := Tactic.BASIC
## Shown when the fight starts: a hint at how it fights.
@export var intro := ""
## Gold dropped when beaten, min-max (goblins carry purses, #42).
@export var purse := Vector2i.ZERO
## Where it stands in a fight (#72): back-row enemies can only be hit with
## reach until the front row is down.
@export_enum("front", "back") var row := "front"
## Attacks reach the heroes' back row (a spider drops from above).
@export var reach_back := false
## Who it calls into the fight (the queen's guards, #44).
@export var summons: EnemyType
## Placeholder look until its own art exists: a tint and a size for the
## shared sprite (#99).
@export var tint := Color.WHITE
@export var sprite_scale := 1.0
