extends Node3D
## Visual state only. The room/chest model owns contents and interactions.
@export_enum("closed", "open", "empty") var state: String = "closed":
	set(value):
		if value not in ["closed", "open", "empty"]:
			push_warning("Unknown chest art state: " + value)
			return
		state = value
		if is_node_ready():
			_apply_state()

func _ready() -> void:
	_apply_state()

func set_state(value: StringName) -> void:
	state = String(value)

func _apply_state() -> void:
	var sprite := get_node("Sprite") as AnimatedSprite3D
	sprite.animation = StringName(state)
	sprite.stop()
