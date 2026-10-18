class_name EventChoice
extends Resource
## A choice offered by a room event (#16): investigate, use, open...
## "Leave it" is always added automatically.

@export var label := "Choose"
## Time spent (the lantern burns and strain builds meanwhile).
@export var time_cost := 1
## Investigations: offered once, and the event stays open afterwards.
@export var investigation := false
@export var outcomes: Array[EventOutcome] = []
## Decided by the coin (#77): the first outcome is heads, the second tails.
@export var coin_flip := false
@export var heads_text := ""
@export var tails_text := ""
