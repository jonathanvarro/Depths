class_name ConversationPage
extends Resource
## One page of a conversation: what the speaker says, and the replies.
## A page with no replies ends with a plain "Go on" button.

@export_multiline var text := ""
@export var replies: Array[ConversationReply] = []
