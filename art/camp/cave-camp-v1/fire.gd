extends Node2D
## Presentation only. Pause the reused flame loop when hidden or motion is off.
@export var animate_flames := true:
	set(value):
		animate_flames = value
		if is_node_ready():
			_sync_flames()

func _ready() -> void:
	visibility_changed.connect(_sync_flames)
	_sync_flames()

func _sync_flames() -> void:
	var flames := get_node("FlameAnchor/Flames") as AnimatedSprite2D
	if animate_flames and is_visible_in_tree():
		flames.play(&"burn")
	else:
		flames.pause()
		if not animate_flames:
			flames.frame = 0
