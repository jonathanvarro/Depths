class_name Conversation
extends Resource
## A talk with someone (#122, #123): a speaker, a portrait and pages of
## lines with replies. Write them in data/conversations/*.tres. Text can use
## {hero}, {they}, {them}, {their} and {They} for the player's main hero.

@export var speaker := ""
@export var portrait: Texture2D
## Page 0 is shown first; replies say which page comes next.
@export var pages: Array[ConversationPage] = []
