extends "res://art/camp/organic-v3/site.gd"
## Keep authored scene contacts independent of texture import size limits.
@export var canvas_width := 181.0

func _ready() -> void:
	$Base.scale=Vector2.ONE*canvas_width/$Base.texture.get_width()
	super()
