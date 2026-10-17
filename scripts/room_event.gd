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
