class_name Boon
extends Resource
## A blessing or a curse (#133; owner 2026-10-21): what a shrine, an idol
## or a bargain leaves on a hero for a while. A worn trinket (#135) carries
## one too, lasting as long as it's worn. Definitions live in
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

@export_group("Playstyle effects")
## Extra damage while below half health.
@export var low_health_damage := 0
## Added to the chance to hit in bright light, taken away in dim light or none.
@export var light_accuracy := 0.0
## Extra damage from the back row.
@export var back_row_damage := 0
## Extra burn from a thrown torch.
@export var torch_burn := 0
## Defending eases every hero's strain by this much.
@export var defend_steadies := 0.0
## Better odds when a coin is flipped (as the Lucky recruit strength).
@export var luck := 0.0


## What it does, in words, from its numbers: "+1 damage, 2 less maximum
## health". For trinkets, whose effects are shown, not described.
func effects_text() -> String:
	var parts := PackedStringArray()
	if damage != 0:
		parts.append("%+d damage" % damage)
	if not is_zero_approx(accuracy):
		parts.append("%+d%% to hit" % roundi(accuracy * 100))
	if max_health != 0:
		parts.append("%+d maximum health" % max_health)
	if not is_equal_approx(strain_rate, 1.0):
		parts.append("nerves fray %d%% %s" % [absi(roundi((strain_rate - 1.0) * 100)), "faster" if strain_rate > 1.0 else "slower"])
	if not is_equal_approx(healing, 1.0):
		parts.append("healing %+d%%" % roundi((healing - 1.0) * 100))
	if not is_equal_approx(oil_rate, 1.0):
		parts.append("the lantern burns %d%% %s" % [absi(roundi((oil_rate - 1.0) * 100)), "faster" if oil_rate > 1.0 else "slower"])
	if reveals_traps:
		parts.append("traps show")
	if draws_ambush:
		parts.append("ambushes come more often")
	if low_health_damage != 0:
		parts.append("%+d damage below half health" % low_health_damage)
	if not is_zero_approx(light_accuracy):
		parts.append("%+d%% to hit in bright light, %+d%% in dim light" % [roundi(light_accuracy * 100), -roundi(light_accuracy * 100)])
	if back_row_damage != 0:
		parts.append("%+d damage from the back row" % back_row_damage)
	if torch_burn != 0:
		parts.append("thrown torches burn %+d" % torch_burn)
	if defend_steadies > 0.0:
		parts.append("defending steadies everyone's nerves")
	if luck > 0.0:
		parts.append("coin flips favour you")
	return ", ".join(parts)


## "3 fights" or "until camp", for tooltips.
func duration_text(fights_left: int) -> String:
	if fights == 0:
		return "until camp"
	return "%d fight%s left" % [fights_left, "" if fights_left == 1 else "s"]
