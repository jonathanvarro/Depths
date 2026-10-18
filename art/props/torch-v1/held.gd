extends Node2D
## Presentation only. The real Supplies model owns duration and source changes.
const Supplies := preload("res://scripts/supplies.gd")
@export var burning := true
@export var dim := false

func _ready() -> void:
	set_burning(burning, dim)

func set_burning(value: bool, low := false) -> void:
	burning = value
	dim = low
	var flame := get_node("FlameAnchor/Flames") as AnimatedSprite2D
	get_node("FlameAnchor").scale = Vector2.ONE * (0.6 if dim else 1.0)
	flame.visible = burning
	if burning:
		flame.play("burn")
	else:
		flame.pause()

func apply_supplies(supplies) -> void:
	visible = supplies.source == Supplies.Source.TORCH and supplies.torch_left > 0.0
	set_burning(visible, supplies.light_band() == Supplies.Light.DIM)
