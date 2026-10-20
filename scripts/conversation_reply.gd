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
