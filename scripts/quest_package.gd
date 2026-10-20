class_name QuestPackage
extends Resource
## A quest package (#123, docs/first-slice-plan.md): a small hand-drawn
## piece of maze that's stamped into a generated floor while its quest
## wants it. Write them in data/packages/*.tres.
##
## `rows` uses the floor's own symbols ('#' rock, ',' room floor, '.'
## passage, 'E' its fight, 'D' a closed passage...) plus digits: '1' is
## events[0], '2' events[1], and so on. A '.' on the edge is where a short
## dug corridor joins it to the rest of the floor.

@export var id := ""
@export var min_depth := 1
@export var max_depth := 1
## Placed while this quest is at one of these stages (quests.gd Stage)...
@export var quest := ""
@export var stages: Array[int] = [2]
## ...and that quest has none of these flags (e.g. the thing is done).
@export var unless_flags: PackedStringArray = []
@export var rows: PackedStringArray = []
@export var events: Array[RoomEvent] = []
## Who waits at its 'E'.
@export var fight: Array[EnemyType] = []
