extends PanelContainer
## A hero's spoken line, shown beside the portrait cards while the portrait
## talks (#57). Lines fade after a time that suits their length.

const SECONDS_PER_CHARACTER := 0.06
const MIN_SECONDS := 2.5
const COLOR_NAME := Color("dbb477")
const COLOR_TEXT := Color("e8d9b0")

var _name: Label
var _text: Label
var _tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.045, 0.04, 0.85)
	style.border_color = Color(0.35, 0.27, 0.18, 0.9)
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 16)
	_name.add_theme_color_override("font_color", COLOR_NAME)
	column.add_child(_name)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 19)
	_text.add_theme_color_override("font_color", COLOR_TEXT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(300, 0)
	column.add_child(_text)
	modulate.a = 0.0


## Shows `line` from `speaker`; returns how long it stays up (seconds).
func say(speaker: String, line: String) -> float:
	var seconds := maxf(MIN_SECONDS, line.length() * SECONDS_PER_CHARACTER)
	_name.text = speaker
	_text.text = "“%s”" % line
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	_tween.tween_interval(seconds)
	_tween.tween_property(self, "modulate:a", 0.0, 0.6)
	return seconds
