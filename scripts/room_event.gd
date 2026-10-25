class_name RoomEvent
extends Resource
## A room encounter that isn't a fight (#16): a chest, a trap, a strange
## object or a rest spot. Shows a clue on arrival and offers choices.
## Definitions live in `data/events/*.tres`; main.gd picks one per cell by
## kind and floor depth.

## Which map content it belongs to (dungeon_map.gd Content: 2 chest,
## 3 trap, 4 strange object, 5 rest spot).
@export var kind := 2
@export var title := "Something"
## Shown on arrival. Hint at the risk; don't give it away.
@export_multiline var clue := ""
@export var choices: Array[EventChoice] = []
## Floors it can appear on, and how often relative to others of its kind.
@export var min_depth := 1
@export var max_depth := 99
@export var weight := 1
## What stands in the room (#46): a scene with a floor origin. If it has a
## `state` property ("closed"/"empty"), it shows its used art once resolved.
## Missing art falls back to a plain placeholder. Unresolved traps require
## Keen eyes; their sprung/collapsed remains are visible after resolving.
@export var prop: PackedScene
## The prop stands against a wall (a miners' shrine, #132/#133): set back
## to the nearest wall of its cell, facing into the room.
@export var prop_on_wall := false
## A trap no one spotted (#94): this happens as the party walks in - with a
## fall - instead of the choices.
@export var sprung: EventOutcome
