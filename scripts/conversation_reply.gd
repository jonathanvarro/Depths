class_name ConversationReply
extends Resource
## A reply button. It can move a quest on and mark a flag (quests.gd).

@export var label := "Go on"
## The page it leads to; -1 ends the conversation.
@export var next := -1
## A quest to move on (an ID in quests.gd INFO) and the stage to move it to.
@export var quest := ""
@export var stage := -1
## A flag to mark on that quest (e.g. "told_ambush").
@export var flag := ""
## What the hero actually says (#228): the button shows `label`, a short
## summary, and the line spoken goes in the party's speech bubble. `said_by`
## gives a line per starting hero, keyed by name ("Mara", "Corin", "Sister
## Alwen"); `said` is for anyone else. Empty both, and a label in quotes is
## spoken as it is.
@export_multiline var said := ""
@export var said_by: Dictionary = {}
## Marks the button as taking on `quest` ("Accept: Those Left Behind").
@export var accepts := false


## The line `hero` speaks for this reply, or "" if it isn't spoken.
func spoken_by(hero: Companion) -> String:
	if hero and said_by.has(hero.display_name):
		return said_by[hero.display_name]
	if said != "":
		return said
	return label if label.begins_with("\"") else ""
