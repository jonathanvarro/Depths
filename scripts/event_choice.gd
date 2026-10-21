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
## Something the party must carry to choose this (#133): a spade to clear
## rubble, holy water for an evil shrine, a ration to offer. Without it the
## choice shows greyed, "needs a spade", so players learn what to bring.
## Used up by choosing, unless it's a tool (pick, spade).
@export var requires: SupplyItem
## Gold handed over (an offering).
@export var gold_cost := 0


## Why the party can't choose this now, or "".
func missing(party) -> String:
	if requires and party.supplies.count(requires) <= 0:
		return "needs %s" % requires.with_article()
	if gold_cost > 0 and party.supplies.gold < gold_cost:
		return "needs %d gold" % gold_cost
	return ""
