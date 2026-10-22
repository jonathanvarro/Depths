class_name Injury
extends Resource
## A lasting injury (#11). It stays until treated at camp; in the field a
## dressing only suppresses its effect until then.
##
## Definitions live in `data/injuries/*.tres`. A hero holds references to
## them; the files themselves never change.

@export var display_name := "Injury"
@export_multiline var description := ""
## Maximum health lost while the injury is untreated (and not dressed).
@export var max_health_penalty := 0
## Extra time each step costs while untreated (and not dressed).
@export var extra_step_time := 0
## Pack slots that hero's share loses while untreated (and not dressed):
## a limping hero carries less (#104).
@export var carry_penalty := 0
## Portrait overlays (see PortraitSet.conditions), if the art exists.
@export var portrait_condition := ""
@export var dressed_portrait_condition := "bandage"
## Card icon: "wound" or "limp" (drawn placeholders for now).
@export var icon_kind := "wound"
## Days a hero spends in the nurse's tent after treatment (#40).
@export var recovery_days := 1
