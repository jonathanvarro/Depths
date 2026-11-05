class_name ConversationPage
extends Resource
## One page of a conversation: what the speaker says, and the replies.
## A page with no replies ends with a plain "Go on" button.

## Who says it: the first or second person on the right, the player's
## hero (lit in the lower left), or nobody (narration).
@export_enum("npc", "npc2", "hero", "narrator") var speaker := "npc"
@export_multiline var text := ""
## The text for a particular starting hero, keyed by name ("Mara", "Corin",
## "Sister Alwen"); others get `text`. Mostly for the hero's own lines.
@export var text_by: Dictionary = {}
## The first speaker's animated face for this page (#166): a PortraitSet
## expression rig, which blinks and talks while the page shows. Empty keeps
## the conversation's own picture (a static pose stays still).
@export var expression: PortraitSet
@export var replies: Array[ConversationReply] = []
