extends Control
## The spoils of a won fight (owner, 2026-10-20): gold, each hero's
## experience filling a bar, a mark for anyone ready to level up, and the
## contract's progress. Shown on the dark battle stage before the fog sinks
## back. It arrives the way the last enemy fell: a slash, a smash, a thrust
## or a burn (plain fade with screen flashes off). Closes on a tap or key,
## or by itself after a moment.

signal _done

const CombatFx := preload("res://scripts/combat_fx.gd")
const Progression := preload("res://scripts/progression.gd")
const COIN := preload("res://art/ui/results-v1/coin-pouch.png")
const XP_MARK := preload("res://art/ui/results-v1/experience.png")
const LEVEL_MARK := preload("res://art/ui/results-v1/level-up.png")
const ARRIVALS := {
	"slash": preload("res://art/ui/results-v1/slash-frames.tres"),
	"smash": preload("res://art/ui/results-v1/smash-frames.tres"),
	"pierce": preload("res://art/ui/results-v1/pierce-frames.tres"),
	"fire": preload("res://art/ui/results-v1/fire-frames.tres"),
}
const TEXT := Color("e8d9b0")
const MUTED := Color(0.85, 0.8, 0.7, 0.7)
const AMBER := Color("f2c94c")
const HOLD := 2.6  # seconds before it closes by itself
const BURN_SHADER := """
shader_type canvas_item;
uniform float progress = 0.0;  // 0 covered, 1 burned away
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec2 uv = floor(UV * vec2(120.0, 60.0)) / vec2(120.0, 60.0);
	float n = noise(uv * 6.0) * 0.6 + noise(uv * 14.0) * 0.4;
	// It burns from the bottom up, ragged.
	float burn = (1.0 - uv.y) * 0.55 + n * 0.45;
	float edge = progress * 1.3 - 0.15;
	if (burn < edge) { discard; }
	float glow = 1.0 - smoothstep(0.0, 0.08, burn - edge);
	COLOR = mix(vec4(0.03, 0.025, 0.02, 1.0), vec4(1.0, 0.55, 0.15, 1.0), glow);
}
"""

var _panel: PanelContainer
var _rows: VBoxContainer
var _fx: Control
var _skip := false


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_fx = CombatFx.new()
	add_child(_fx)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(520, 0)
	add_child(_panel)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	_panel.add_child(_rows)


## Plays the spoils, arriving as `blow` ("slash", "smash", "pierce",
## "fire"); returns when the player moves on. `spoils`: {"gold": int,
## "heroes": [{"hero", "from", "to"}], "contract": String, "note": String}.
func play(spoils: Dictionary, blow: String, motion := true) -> void:
	_build(spoils)
	visible = true
	_skip = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.reset_size()
	var view := get_viewport_rect().size
	var home := (view - _panel.size) / 2.0 - Vector2(0, 40)
	_panel.position = home
	_panel.pivot_offset = _panel.size / 2.0
	if not motion:
		blow = "fade"
	await _arrive(blow, home)
	_count_up(spoils)
	var timer := get_tree().create_timer(HOLD)
	while not _skip and timer.time_left > 0.0:
		await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
	await tween.finished
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed or event is InputEventScreenTouch and event.pressed:
		_skip = true


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_pressed() and not event.is_echo() and (event is InputEventKey or event is InputEventJoypadButton):
		_skip = true
		get_viewport().set_input_as_handled()


# --- Arrivals ---------------------------------------------------------

func _arrive(blow: String, home: Vector2) -> void:
	var center := home + _panel.size / 2.0
	var view := get_viewport_rect().size
	_panel.modulate.a = 0.0
	var tween := create_tween()
	match blow:
		"slash":  # a blade's cut across the screen, the spoils slide in along it
			var dir := Vector2(1, 0.62).normalized()
			_arrival_art("slash", center)
			_panel.position = home - dir * 260.0
			tween.set_parallel()
			tween.tween_property(_panel, "position", home, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tween.tween_property(_panel, "modulate:a", 1.0, 0.12)
		"smash":  # a blunt impact: a flash, cracks, a shake, and it drops in
			_arrival_art("smash", center)
			_panel.scale = Vector2(1.5, 1.5)
			tween.set_parallel()
			tween.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(_panel, "modulate:a", 1.0, 0.08)
			_shake()
		"pierce":  # a quick thrust from the side
			_arrival_art("pierce", center)
			_panel.position = home - Vector2(view.x * 0.5, 0)
			tween.set_parallel()
			tween.tween_property(_panel, "position", home, 0.16).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			tween.tween_property(_panel, "modulate:a", 1.0, 0.1)
		"fire":  # it burns in: embers eat away a dark cover
			_arrival_art("fire", center)
			_panel.modulate.a = 1.0
			var cover := ColorRect.new()
			cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cover.position = _panel.position - Vector2(6, 6)
			cover.size = _panel.size + Vector2(12, 12)
			var material := ShaderMaterial.new()
			material.shader = Shader.new()
			material.shader.code = BURN_SHADER
			material.set_shader_parameter("progress", 0.0)
			cover.material = material
			add_child(cover)
			tween.tween_method(func(v: float): material.set_shader_parameter("progress", v), 0.0, 1.0, 0.7)
			tween.tween_callback(cover.queue_free)
		_:  # plain fade (screen flashes off)
			tween.tween_property(_panel, "modulate:a", 1.0, 0.2)
	await tween.finished


func _arrival_art(kind: String, at: Vector2) -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = ARRIVALS[kind]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = at
	sprite.scale = Vector2(5, 3)
	sprite.z_index = 1  # the brief arrival must remain visible over the panel
	_fx.add_child(sprite)
	sprite.animation_finished.connect(sprite.queue_free)
	sprite.play(&"arrival")


func _streak(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var streak := CombatFx.Streak.new()
	streak.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	streak.from = from
	streak.to = to
	streak.color = color
	streak.width = width
	_fx.add_child(streak)
	var tween := streak.create_tween()
	tween.tween_property(streak, "progress", 1.0, 0.12)
	tween.tween_property(streak, "modulate:a", 0.0, 0.35)
	tween.tween_callback(streak.queue_free)


## A pale flash and cracks radiating from the point of impact.
func _impact(at: Vector2) -> void:
	for i in 9:
		var angle := TAU * i / 9.0 + randf_range(-0.2, 0.2)
		var dir := Vector2.from_angle(angle)
		_streak(at + dir * 30.0, at + dir * randf_range(150.0, 260.0), Color("f6e7c8"), randf_range(4.0, 8.0))
	var flash := ColorRect.new()
	flash.color = Color(1, 0.95, 0.85, 0.14)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.15)
	tween.tween_callback(flash.queue_free)


func _shake() -> void:
	var tween := create_tween()
	for i in 6:
		var offset := Vector2(randf_range(-10, 10), randf_range(-8, 8)) * (1.0 - i / 6.0)
		tween.tween_property(self, "position", offset, 0.035)
	tween.tween_property(self, "position", Vector2.ZERO, 0.035)


# --- Contents ---------------------------------------------------------

var _gold_label: Label
var _bars: Array = []  # [ProgressBar, from, to, ready mark]


func _build(spoils: Dictionary) -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_bars.clear()
	_panel.modulate.a = 1.0
	_panel.scale = Vector2.ONE
	var title := Label.new()
	title.text = "Spoils"
	title.theme_type_variation = "PageTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rows.add_child(title)
	_gold_label = null
	if spoils.get("gold", 0) > 0:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		var coin := TextureRect.new()
		coin.texture = COIN
		coin.custom_minimum_size = Vector2(36, 36)
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(coin)
		_gold_label = _label("+0", AMBER, 30)
		row.add_child(_gold_label)
		_rows.add_child(row)
	for entry in spoils.get("heroes", []):
		var hero: Companion = entry["hero"]
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		var name := _label(hero.display_name, TEXT, 20)
		name.custom_minimum_size = Vector2(130, 0)
		line.add_child(name)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(220, 14)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var span := _span(hero, entry["from"])
		bar.min_value = span.x
		bar.max_value = span.y
		bar.value = entry["from"]
		line.add_child(bar)
		var gained := _label("+%d XP" % (entry["to"] - entry["from"]), TEXT, 18)
		line.add_child(_mark(XP_MARK, "Experience earned"))
		line.add_child(gained)
		var ready := _mark(LEVEL_MARK, "Level up at camp")
		ready.visible = false
		line.add_child(ready)
		_rows.add_child(line)
		_bars.append([bar, entry["from"], entry["to"], ready, hero])
	if spoils.get("note", "") != "":
		_rows.add_child(_label(spoils["note"], MUTED, 17))
	if spoils.get("contract", "") != "":
		_rows.add_child(_label(spoils["contract"], MUTED, 17))
	var hint := _label("Tap to continue", MUTED, 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rows.add_child(hint)


## The XP band a bar shows: from this level's threshold to the next.
func _span(hero: Companion, xp: int) -> Vector2:
	var level := 1
	for l in range(1, Progression.THRESHOLDS.size()):
		if xp >= Progression.THRESHOLDS[l]:
			level = l
	var low: int = Progression.THRESHOLDS[level]
	var high: int = Progression.THRESHOLDS[level + 1] if level + 1 < Progression.THRESHOLDS.size() else low + 1
	return Vector2(low, high)


## Gold counts up; bars fill; a level-up mark lights when one is earned.
func _count_up(spoils: Dictionary) -> void:
	var tween := create_tween().set_parallel()
	if _gold_label:
		var gold: int = spoils["gold"]
		tween.tween_method(func(v: float): _gold_label.text = "+%d" % roundi(v), 0.0, float(gold), 0.6)
	for b in _bars:
		var bar: ProgressBar = b[0]
		tween.tween_property(bar, "value", float(b[2]), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		var hero: Companion = b[4]
		if Progression.ready_to_advance(hero):
			var mark: TextureRect = b[3]
			tween.tween_callback(func(): mark.visible = true).set_delay(0.8)


func _mark(texture: Texture2D, description: String) -> TextureRect:
	var mark := TextureRect.new()
	mark.texture = texture
	mark.custom_minimum_size = Vector2(28, 28)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mark.tooltip_text = description
	mark.accessibility_name = description
	return mark


func _label(text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
