class_name Equipment
extends Resource
## A piece of gear a hero can wield (#58, a first slice of #48). Carried
## gear sits in the pack until equipped; equipping swaps out what the hero
## held before. Definitions live in `data/gear/*.tres`.

@export var display_name := "Gear"
@export_multiline var description := ""
@export var icon: Texture2D
## Damage range when attacking with it.
@export var attack_min := 1
@export var attack_max := 2
## Added to the hero's hit chance (negative for a poor weapon).
@export_range(-0.5, 0.5) var accuracy_bonus := 0.0
## Gold at the smith; the merchant buys it back for 30% (#42).
@export var price := 0
## Reaches past the front row: usable from the back, hits enemies' back row (#72).
@export var reach := false
