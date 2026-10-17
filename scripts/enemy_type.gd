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
