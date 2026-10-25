extends Node2D
## The held torch or lantern, low in the view while exploring (owner,
## 2026-10-20): small 3D models (held_light_3d.gd) rendered into their own
## low-resolution view and drawn with hard pixels, so they match the cave's
## pixel look and can't clip into walls. They sway as the party turns, bob
## as it walks, and follow the real supplies; they never spend fuel.
## (Replaces the flat art in art/props/torch-v1 and lantern-v1, kept as is.)

const HeldLight3D := preload("res://scripts/held_light_3d.gd")
const Supplies := preload("res://scripts/supplies.gd")
const DRAW_SIZE := Vector2(128, 256)  # the space the flat art used
const RENDER_SIZE := Vector2i(96, 192)  # fewer pixels: chunkier, like the world
const SUNK := 0.22  # how much of the drawing sits below the screen's edge

var _main: WeakRef
var _viewport: SubViewport
var _sprite: Sprite2D
var _pivot: Node3D  # moved for bob and sway
var _torch: Node3D
var _lantern: Node3D
var _last_position := Vector3.ZERO
var _last_yaw := 0.0
var _walk_phase := 0.0
var _sway := 0.0
var _bob := 0.0


func setup(main: Node) -> void:
	_main = weakref(main)
	_viewport = SubViewport.new()
	_viewport.size = RENDER_SIZE
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	add_child(_viewport)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_CLEAR_COLOR
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.32, 0.24, 0.17)
	world.environment.ambient_light_energy = 0.55
	_viewport.add_child(world)
	var camera := Camera3D.new()
	camera.fov = 28.0
	camera.position = Vector3(0, 0, 1.0)
	_viewport.add_child(camera)
	# A soft fill from the party's other light, behind the viewer's shoulder.
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(1.0, 0.75, 0.5)
	fill.light_energy = 0.45
	fill.rotation = Vector3(-0.5, -0.6, 0)
	_viewport.add_child(fill)
	_pivot = Node3D.new()
	_viewport.add_child(_pivot)
	_torch = HeldLight3D.new()
	_torch.build("torch")
	# Held low and to the right, the head leaning in and away from the eye.
	_torch.position = Vector3(0.025, -0.16, 0)
	_torch.rotation = Vector3(-0.28, 0.25, 0.14)
	_torch.scale = Vector3.ONE * 1.35
	_pivot.add_child(_torch)
	_lantern = HeldLight3D.new()
	_lantern.build("lantern")
	_lantern.position = Vector3(0.005, 0.0, 0.05)
	_lantern.rotation = Vector3(0.12, 0.45, 0.05)
	_lantern.scale = Vector3.ONE * 1.15
	_pivot.add_child(_lantern)
	_sprite = Sprite2D.new()
	_sprite.texture = _viewport.get_texture()
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = DRAW_SIZE / Vector2(RENDER_SIZE)
	add_child(_sprite)


func _process(delta: float) -> void:
	var main = _main.get_ref() if _main else null
	if main == null or not is_instance_valid(main._party):
		return
	visible = not (main._ending or main._in_combat or main._pack.visible or main._chest.visible or main._full_map.visible or main._event_screen.visible or main._camp.visible or main._preparation.visible)
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE if visible else SubViewport.UPDATE_DISABLED
	if not visible:
		return
	_apply_supplies(main._party_state.supplies)
	_animate(main._party, delta)
	# Larger, and held lower so the handle runs off the bottom of the
	# screen (owner, 2026-10-25): no one needs to see the end of it.
	var amount := clampf(main._safe_area.size.y * 0.54 / DRAW_SIZE.y, 0.85, 1.35)
	scale = Vector2.ONE * amount
	position = Vector2(main._touch_pad.position.x - DRAW_SIZE.x * amount - 8, main._safe_area.size.y - DRAW_SIZE.y * amount * (1.0 - SUNK))


func _apply_supplies(supplies) -> void:
	var torch_on: bool = supplies.source == Supplies.Source.TORCH and supplies.torch_left > 0.0
	_torch.visible = torch_on
	if torch_on:
		_torch.set_strength(0.6 if supplies.light_band() == Supplies.Light.DIM else 1.0)
	var lantern_on: bool = supplies.has_lantern and supplies.source == Supplies.Source.LANTERN
	_lantern.visible = lantern_on
	if lantern_on:
		if supplies.oil <= 0.0:
			_lantern.set_strength(0.0)
		elif supplies.oil <= Supplies.LANTERN_CAPACITY * 0.10:
			_lantern.set_strength(0.35)
		elif supplies.light_band() == Supplies.Light.DIM:
			_lantern.set_strength(0.6)
		else:
			_lantern.set_strength(1.0)


## Walking bobs the light; turning swings it the other way, and the flame
## leans against the motion.
func _animate(party: Node3D, delta: float) -> void:
	var moved := party.global_position.distance_to(_last_position)
	var yaw_change := wrapf(party.rotation.y - _last_yaw, -PI, PI)
	_last_position = party.global_position
	_last_yaw = party.rotation.y
	var speed := moved / maxf(delta, 0.001)
	if speed > 0.05 and speed < 50.0:  # not when placed on a new floor
		_walk_phase += delta * 9.0
	_bob = lerpf(_bob, 1.0 if speed > 0.05 and speed < 50.0 else 0.0, minf(1.0, delta * 6.0))
	var turn_rate := yaw_change / maxf(delta, 0.001)
	_sway = lerpf(_sway, clampf(turn_rate * 0.05, -0.25, 0.25), minf(1.0, delta * 8.0))
	var idle := Time.get_ticks_msec() / 1000.0
	_pivot.position = Vector3(
			sin(_walk_phase) * 0.008 * _bob - _sway * 0.05,
			-absf(cos(_walk_phase)) * 0.012 * _bob + sin(idle * 1.3) * 0.002,
			0)
	_pivot.rotation = Vector3(0, -_sway * 0.6, _sway + sin(_walk_phase) * 0.03 * _bob + sin(idle * 0.9) * 0.01)
	for light in [_torch, _lantern]:
		light.set_lean(clampf(-_sway * 1.5 + sin(_walk_phase) * 0.05 * _bob, -0.35, 0.35))
