extends Node2D
## Pure presentation. Supplies remains the owner of oil, time and light rules.
const Supplies := preload("res://scripts/supplies.gd")
@export_enum("steady","dim","nearly-out","unlit") var state := "steady"

func _ready() -> void:
	set_state(state)

func set_state(value: String) -> void:
	state = value
	var flame := get_node("FlameAnchor/Flames") as AnimatedSprite2D
	var anchor := get_node("FlameAnchor") as Node2D
	anchor.scale = Vector2.ONE * (0.45 if state == "nearly-out" else (0.70 if state == "dim" else 1.0))
	flame.visible = state != "unlit"
	if flame.visible:flame.play("burn")
	else:flame.pause()

func apply_supplies(supplies) -> void:
	visible = supplies.has_lantern and supplies.source == Supplies.Source.LANTERN
	if supplies.oil <= 0.0:
		set_state("unlit")
	elif supplies.oil <= Supplies.LANTERN_CAPACITY * 0.10:
		set_state("nearly-out")
	elif supplies.light_band() == Supplies.Light.DIM:
		set_state("dim")
	else:
		set_state("steady")
