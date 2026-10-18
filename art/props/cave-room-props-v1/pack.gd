extends Node3D
## Visual only: RoomEvents owns whether searching actually resolved.
@export var searched: bool = false:
	set(value):
		searched = value
		if is_node_ready():
			_apply_state()

func _ready() -> void:
	_apply_state()

func set_searched(value: bool) -> void:
	searched = value

func _apply_state() -> void:
	var sprite := get_node("Sprite") as AnimatedSprite3D
	sprite.animation = &"searched" if searched else &"unsearched"
	sprite.stop()
