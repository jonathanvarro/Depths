extends Control
## Draws a PortraitSet as stacked, aligned layers and animates it:
## blinking on its own every few seconds, talk(), hurt(), and condition
## overlays. With no PortraitSet it shows a single flat image instead.

const BLINK_FRAME_SECONDS := 0.045
const BLINK_INTERVAL := Vector2(2.5, 6.0)  # seconds between blinks, random
const TALK_FRAME_SECONDS := 0.09
const HURT_COLOR := Color(0.8, 0.05, 0.05, 0.55)

var portrait_set: PortraitSet

var _rig: Control  # holds the layers; moved to shake
var _character: Control  # excludes the background and card UI
var _light_shadow: TextureRect
var _light_highlight: TextureRect
var _illumination := "neutral"
var _eye_tween: Tween
var _eyes: TextureRect
var _mouth: TextureRect
var _overlays := {}  # condition name -> TextureRect
var _flash: ColorRect
var _blink_timer: Timer
var _talk_tween: Tween
var _hurt_tween: Tween
var _trembling := false
var _tremble_clock := 0.0


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Builds the layer stack. `fallback` is used when there's no set.
func show_portrait(layers: PortraitSet, fallback: Texture2D = null) -> void:
	for tween in [_eye_tween, _talk_tween, _hurt_tween]:
		if tween and tween.is_valid():
			tween.kill()  # its layers are about to be replaced
	portrait_set = layers
	for child in get_children():
		child.queue_free()
	_overlays.clear()
	_character = null
	_eyes = null
	_mouth = null
	_light_shadow = null
	_light_highlight = null
	_rig = Control.new()
	_rig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rig)
	if layers != null:
		_add_layer(layers.background)
	_character = Control.new()
	_character.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_character.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rig.add_child(_character)

	if layers == null:
		_add_layer(fallback)
	else:
		for texture in layers.back:
			_add_layer(texture)
		_add_layer(layers.body)
		_add_layer(layers.head)
		_eyes = _add_layer(layers.eyes)
		_mouth = _add_layer(layers.mouth)
		for texture in layers.clothing:
			_add_layer(texture)
		for texture in layers.front:
			_add_layer(texture)
		for condition in layers.conditions:
			var overlay := _add_layer(layers.conditions[condition])
			overlay.visible = false
			_overlays[condition] = overlay
		if layers.light_shadow:
			_light_shadow = _add_layer(layers.light_shadow)
		if layers.light_highlight:
			_light_highlight = _add_layer(layers.light_highlight)
	_apply_illumination()

	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(HURT_COLOR, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_blink_timer = Timer.new()
	_blink_timer.one_shot = true
	_blink_timer.timeout.connect(_on_blink_timer)
	add_child(_blink_timer)
	_schedule_blink()


func set_condition(condition: String, shown: bool) -> void:
	if _overlays.has(condition):
		_overlays[condition].visible = shown


func blink() -> void:
	if portrait_set == null or portrait_set.blink_frames.is_empty() or _eyes == null:
		return
	var frames := portrait_set.blink_frames.duplicate()
	var reverse := portrait_set.blink_frames.duplicate()
	reverse.reverse()
	frames.append_array(reverse.slice(1))
	if _eye_tween and _eye_tween.is_valid():
		_eye_tween.kill()
	_eye_tween = create_tween()
	for frame in frames:
		_eye_tween.tween_callback(func(): if is_instance_valid(_eyes): _eyes.texture = frame)
		_eye_tween.tween_interval(BLINK_FRAME_SECONDS)
	_eye_tween.tween_callback(func(): if is_instance_valid(_eyes) and portrait_set: _eyes.texture = portrait_set.eyes)


## Explicit presentation choice. Fuel and world-light rules remain with the caller.
func set_illumination(preset: String) -> void:
	_illumination = preset
	_apply_illumination()


func _apply_illumination() -> void:
	if _character == null:
		return
	_character.modulate = Color(0.60, 0.64, 0.68) if _illumination == "dim" else Color.WHITE
	if _light_shadow:
		_light_shadow.modulate = Color(1, 1, 1, 0.43 if _illumination == "dim" else (0.26 if _illumination == "warm" else 0.0))
	if _light_highlight:
		match _illumination:
			"warm": _light_highlight.modulate = Color(1, 0.70, 0.36, 0.24)
			"dim": _light_highlight.modulate = Color(0.65, 0.76, 0.90, 0.05)
			_: _light_highlight.modulate = Color(1, 1, 1, 0)


## Cycles mouth shapes for `seconds`, then returns to the resting mouth.
func talk(seconds: float) -> void:
	if portrait_set == null or portrait_set.talk_frames.is_empty() or _mouth == null:
		return
	if _talk_tween:
		_talk_tween.kill()
	_talk_tween = create_tween()
	for i in int(seconds / TALK_FRAME_SECONDS):
		var frame: Texture2D = portrait_set.talk_frames.pick_random()
		_talk_tween.tween_callback(func(): if is_instance_valid(_mouth): _mouth.texture = frame)
		_talk_tween.tween_interval(TALK_FRAME_SECONDS)
	_talk_tween.tween_callback(func(): if is_instance_valid(_mouth) and portrait_set: _mouth.texture = portrait_set.mouth)


## A constant small tremor (used while panicking). Needs no extra art.
func set_tremble(on: bool) -> void:
	_trembling = on
	if not on and _rig and not (_hurt_tween and _hurt_tween.is_running()):
		_rig.position = Vector2.ZERO


func _process(delta: float) -> void:
	if not _trembling or _rig == null or (_hurt_tween and _hurt_tween.is_running()):
		return
	_tremble_clock -= delta
	if _tremble_clock <= 0.0:
		_tremble_clock = 0.05
		_rig.position = Vector2(randf_range(-1.5, 1.5), randf_range(-1.0, 1.0))


## Red flash and a short shake. Needs no extra art.
func hurt() -> void:
	if _hurt_tween:
		_hurt_tween.kill()
	_rig.position = Vector2.ZERO
	_hurt_tween = create_tween()
	_hurt_tween.tween_property(_flash, "color:a", HURT_COLOR.a, 0.04)
	_hurt_tween.parallel().tween_property(_rig, "position", Vector2(-4, 1), 0.04)
	_hurt_tween.tween_property(_rig, "position", Vector2(3, -1), 0.05)
	_hurt_tween.tween_property(_rig, "position", Vector2(-2, 0), 0.05)
	_hurt_tween.tween_property(_rig, "position", Vector2.ZERO, 0.05)
	_hurt_tween.parallel().tween_property(_flash, "color:a", 0.0, 0.35)


func _add_layer(texture: Texture2D) -> TextureRect:
	var layer := TextureRect.new()
	layer.texture = texture
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _character:
		_character.add_child(layer)
	else:
		_rig.add_child(layer)
	return layer


func _schedule_blink() -> void:
	_blink_timer.start(randf_range(BLINK_INTERVAL.x, BLINK_INTERVAL.y))


func _on_blink_timer() -> void:
	blink()
	_schedule_blink()
