extends Node3D
## Visual state only. The game decides whether a search has resolved.
@export_enum("closed","empty") var state := "closed":
	set(value):
		state=value
		if is_node_ready():_apply()
@export var closed_texture: Texture2D
@export var empty_texture: Texture2D

func _ready() -> void:
	_apply()

func _apply() -> void:
	if has_node("Pack"):
		get_node("Pack").set_searched(state == "empty")
	elif has_node("Sprite"):
		get_node("Sprite").texture=empty_texture if state == "empty" and empty_texture else closed_texture
