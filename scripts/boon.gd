class_name Boon
extends Resource
## A blessing or a curse (#133; owner 2026-10-21): what a shrine, an idol
## or a bargain leaves on a hero for a while. Definitions live in
## `data/boons/*.tres`; an event outcome grants one.
##
## Strong ones last a number of fights and stay through camp until they run
## out (the nurse can lift a bane for a price); mild ones (`fights` 0) last
## until the end of the trip. Shown as an icon on the hero's card.

@export var display_name := "A blessing"
## What it does, in a line: the card's tooltip.
@export_multiline var description := ""
@export var icon: Texture2D
@export var bane := false
## Fights it lasts; 0: until the party is back at camp.
@export var fights := 0

@export_group("Effects")
@export var damage := 0
## Added to the chance to hit (0.08 = +8%).
@export var accuracy := 0.0
@export var max_health := 0
## Multiplies strain gained (0.5: nerves fray half as fast).
@export var strain_rate := 1.0
## Multiplies all healing received (food, draughts, rest effects).
@export var healing := 1.0
## Multiplies the oil the lantern burns while this hero is with the party.
@export var oil_rate := 1.0
## The party sees traps, as with Mara's keen eyes (#95).
@export var reveals_traps := false
## Events that can end in an ambush do so twice as often.
@export var draws_ambush := false


## "3 fights" or "until camp", for tooltips.
func duration_text(fights_left: int) -> String:
	if fights == 0:
		return "until camp"
	return "%d fight%s left" % [fights_left, "" if fights_left == 1 else "s"]
