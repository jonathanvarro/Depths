class_name Conversation
extends Resource
## A talk with someone (#122, #123): a speaker, a portrait and pages of
## lines with replies. Write them in data/conversations/*.tres. Text can use
## {hero}, {they}, {them}, {their} and {They} for the player's main hero.

@export var speaker := ""
@export var portrait: Texture2D
## A second person in the scene (optional): both stand on the right, and
## whoever speaks is lit while the other dims.
@export var second_speaker := ""
@export var second_portrait: Texture2D
## A vision of the past or a dream (owner, 2026-10-20): the whole scene
## plays in the cold blue vision tint (vision_filter.gd).
@export var vision := false
## Optional scene art; absent conversations retain the live camp behind them.
@export var backdrop: Texture2D
## Page 0 is shown first; replies say which page comes next.
@export var pages: Array[ConversationPage] = []
