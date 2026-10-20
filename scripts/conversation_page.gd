class_name ConversationPage
extends Resource
## One page of a conversation: what the speaker says, and the replies.
## A page with no replies ends with a plain "Go on" button.

## Who says it: the first or second person on the right, the player's
## hero (lit in the lower left), or nobody (narration).
@export_enum("npc", "npc2", "hero", "narrator") var speaker := "npc"
@export_multiline var text := ""
@export var replies: Array[ConversationReply] = []
