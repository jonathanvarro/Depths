extends Node3D
## Presentation only. Precomputed native pixel tops keep existing enemy tags
## above raised weapons/wings, without image reads, timers or combat state.
@export var pose_tops: Dictionary = {}

func _ready() -> void:
	$Sprite.animation_changed.connect(_update_bounds)
	$Sprite.frame_changed.connect(_update_bounds)
	_update_bounds()

func _update_bounds() -> void:
	var sprite: AnimatedSprite3D = $Sprite
	var tops: Array = pose_tops.get(String(sprite.animation), [8])
	var frame: int = mini(sprite.frame, sprite.sprite_frames.get_frame_count(sprite.animation) - 1)
	var top: float = float(tops[mini(frame, tops.size() - 1)])
	var height: float = sprite.sprite_frames.get_frame_texture(sprite.animation, frame).get_height()
	set_meta("visual_height", sprite.position.y + (height / 2.0 - top) * sprite.pixel_size)
