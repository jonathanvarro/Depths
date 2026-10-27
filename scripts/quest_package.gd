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
## ...and that quest has none of these flags (e.g. the thing is done)...
@export var unless_flags: PackedStringArray = []
## ...and all of these (e.g. the gate was seen: its stair is open).
@export var needs_flags: PackedStringArray = []
@export var rows: PackedStringArray = []
@export var events: Array[RoomEvent] = []
## Who waits at its 'E'.
@export var fight: Array[EnemyType] = []
## A mini-boss lair (#145, owner 2026-10-25): placed by chance on about
## half of its floors rather than by a quest; "brood" or "captain".
@export var lair := ""
## Said at the threshold, with Go in or Back away.
@export_multiline var warning := ""
## A creature's territory (#149): placed by chance on its floors, this
## often (0 = only when a quest wants it).
@export_range(0.0, 1.0) var chance := 0.0
## Joins the fight only when the whole party is there. The scaling is kept
## light on purpose: adventuring solo should be high risk (owner).
@export var full_party_extra: Array[EnemyType] = []
