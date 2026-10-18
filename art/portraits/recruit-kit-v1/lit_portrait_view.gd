extends "res://scripts/portrait_view.gd"
## Optional presentation adapter for this kit; the existing neutral PortraitSet
## also works in PortraitView without this adapter. Does not migrate Mara.
const DIR := "res://art/portraits/recruit-kit-v1/"
var character_id := "warden-a"
var expression := "neutral"
var illumination := "neutral"
var outfit_visible := true
var _shadow: TextureRect
var _highlight: TextureRect
var _blink_tween: Tween

func configure(id: String, emotion: String = "neutral", profile: Dictionary = {}) -> void:
	# A frame callback from the previous expression must never restore old eyes.
	for tween in [_blink_tween,_talk_tween,_hurt_tween]:
		if tween and tween.is_valid():
			tween.kill()
	character_id = id
	expression = emotion
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var suffix := "" if emotion == "neutral" else "-" + emotion
	var neutral_path: String = profile.get("portrait_set","res://data/portraits/recruits-v1/" + id + ".tres")
	show_portrait(load(neutral_path.trim_suffix(".tres") + suffix + ".tres"))
	_shadow = _add_layer(load(profile.get("shadow",DIR + id + "/shadow-left.png")))
	_highlight = _add_layer(load(profile.get("highlight",DIR + id + "/highlight-left.png")))
	set_illumination(illumination)
	set_outfit(outfit_visible)

func blink() -> void:
	if portrait_set == null or portrait_set.blink_frames.is_empty() or _eyes == null:
		return
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	var frames := portrait_set.blink_frames.duplicate()
	var reverse := portrait_set.blink_frames.duplicate()
	reverse.reverse()
	frames.append_array(reverse.slice(1))
	_blink_tween = create_tween()
	for frame in frames:
		_blink_tween.tween_callback(func(): _eyes.texture = frame)
		_blink_tween.tween_interval(BLINK_FRAME_SECONDS)
	_blink_tween.tween_callback(func(): _eyes.texture = portrait_set.eyes)

func set_illumination(preset: String) -> void:
	illumination = preset
	if _shadow == null:
		return
	match preset:
		"warm":
			_rig.modulate = Color.WHITE
			_shadow.modulate = Color(1,1,1,0.26)
			_highlight.modulate = Color(1,0.70,0.36,0.24)
		"dim":
			_rig.modulate = Color(0.60,0.64,0.68)
			_shadow.modulate = Color(1,1,1,0.43)
			_highlight.modulate = Color(0.65,0.76,0.90,0.05)
		_:
			_rig.modulate = Color.WHITE
			_shadow.modulate.a = 0.0
			_highlight.modulate.a = 0.0

func set_outfit(shown: bool) -> void:
	outfit_visible = shown
	if _rig == null:
		return
	for layer in _rig.get_children():
		if layer is TextureRect and layer.texture != null and layer.texture.resource_path.ends_with("/shared/jerkin.png"):
			layer.visible = shown
