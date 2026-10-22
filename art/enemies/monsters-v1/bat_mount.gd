extends "res://art/enemies/monsters-v1/pose_bounds.gd"
## Presentation only: the floor-rooted bat hangs from a 2.4m roof in idle,
## swoops in mid-air, and reaches the floor in landed. No timers or combat rules.
@export var ceiling_height := 2.4
@export var hanging_top_pixel := 8
var _ground_y := 0.0

func _ready() -> void:
	_ground_y = $Sprite.position.y
	super._ready()
	$Sprite.animation_changed.connect(_mount)
	_mount()

func _mount() -> void:
	var sprite: AnimatedSprite3D = $Sprite
	var extra := 0.0
	match sprite.animation:
		&"idle":
			extra = ceiling_height - (120 - hanging_top_pixel) * sprite.pixel_size
		&"attack", &"swoop":
			extra = 0.65
		&"hurt":
			extra = 0.35
	sprite.position.y = _ground_y + extra
	_update_bounds()
