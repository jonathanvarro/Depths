extends Node3D
## Art state only, compatible with Main._empty_prop(). Event rules own outcomes.
@export_enum("closed", "empty") var state := "closed":
	set(value):
		state = value
		if is_node_ready(): _apply()
@export var closed_texture: Texture2D
@export var empty_texture: Texture2D
@export var offerings_texture: Texture2D
@export var spent_offerings_texture: Texture2D
@export var candle_glow_enabled := true:
	set(value):
		candle_glow_enabled = value
		if is_node_ready(): _apply()

func _ready() -> void:
	_apply()

func _apply() -> void:
	var spent := state == "empty"
	$Sprite.texture = empty_texture if spent else closed_texture
	$Offerings.texture = spent_offerings_texture if spent else offerings_texture
	$Glow.visible = not spent and candle_glow_enabled
	if $Glow.visible: $Glow.play(&"glow")
	else: $Glow.stop()
