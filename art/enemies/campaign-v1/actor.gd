extends Node3D
## Presentation only: retain the combat model's phase and shield state.
@export var enraged_frames: SpriteFrames
var _normal_frames: SpriteFrames
var _enraged := false

func _ready() -> void:
	_normal_frames=$Sprite.sprite_frames

func set_combat_state(enraged: bool, braced: bool) -> void:
	var sprite: AnimatedSprite3D=$Sprite
	if enraged_frames and _enraged!=enraged:
		_enraged=enraged
		var pose: StringName=sprite.animation
		sprite.sprite_frames=enraged_frames if enraged else _normal_frames
		sprite.play(pose if sprite.sprite_frames.has_animation(pose) else &"idle")
	if sprite.animation in [&"idle",&"brace"] and sprite.sprite_frames.has_animation(&"brace"):
		var pose: StringName=&"brace" if braced else &"idle"
		if sprite.animation!=pose:sprite.play(pose)
