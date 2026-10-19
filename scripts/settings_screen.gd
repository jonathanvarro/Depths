extends Control
## The Settings screen (#52), from the title or in game (Pack, camp):
## volumes, fullscreen (computers), screen flashes and text size. Changes
## apply and save at once.

signal closed

const Settings := preload("res://scripts/settings.gd")
const COLOR_TEXT := Color("e8d9b0")
const COLOR_DIM := Color(0.85, 0.8, 0.7, 0.7)

var content: MarginContainer
var _column: VBoxContainer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.03, 0.03, 1.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 32)
	add_child(content)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_column = VBoxContainer.new()
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_theme_constant_override("separation", 14)
	scroll.add_child(_column)
	visible = false


func open() -> void:
	for child in _column.get_children():
		child.queue_free()
	var header := HBoxContainer.new()
	_column.add_child(header)
	var title := _label("Settings", 30, COLOR_TEXT)
	title.theme_type_variation = "PageTitle"  # Cinzel heading (#51)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := _button("Close")
	close.pressed.connect(func():
		visible = false
		closed.emit())
	header.add_child(close)

	_column.add_child(_label("Sound", 22, COLOR_TEXT))
	for bus in Settings.BUSES:
		_slider({"Master": "Master volume", "Music": "Music and ambience", "Effects": "Effects"}[bus], bus)

	_column.add_child(_label("Display", 22, COLOR_TEXT))
	if not OS.has_feature("mobile"):
		_toggle("Fullscreen", "fullscreen")
	_toggle("Screen flashes (the red flash when bleeding)", "flashes")
	var sizes := HBoxContainer.new()
	sizes.add_theme_constant_override("separation", 10)
	var size_label := _label("Text size", 20, COLOR_TEXT)
	size_label.custom_minimum_size = Vector2(240, 0)
	sizes.add_child(size_label)
	for size_name in Settings.TEXT_SIZES:
		var choice := _button(size_name)
		choice.toggle_mode = true
		choice.button_pressed = Settings.get_value("text_size") == size_name
		choice.pressed.connect(func():
			Settings.set_value("text_size", size_name, get_tree())
			open())
		sizes.add_child(choice)
	_column.add_child(sizes)
	_column.add_child(_label("Changes are saved straight away.", 16, COLOR_DIM))
	visible = true
	close.grab_focus.call_deferred()


func _slider(text: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label := _label(text, 20, COLOR_TEXT)
	label.custom_minimum_size = Vector2(240, 0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = Settings.get_value(key)
	slider.custom_minimum_size = Vector2(320, 44)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var amount := _label("%d%%" % roundi(slider.value * 100), 18, COLOR_DIM)
	amount.custom_minimum_size = Vector2(60, 0)
	slider.value_changed.connect(func(v):
		amount.text = "%d%%" % roundi(v * 100)
		Settings.set_value(key, v, get_tree()))
	row.add_child(slider)
	row.add_child(amount)
	_column.add_child(row)


func _toggle(text: String, key: String) -> void:
	var check := CheckButton.new()
	check.text = text
	check.button_pressed = Settings.get_value(key)
	check.custom_minimum_size = Vector2(0, 48)
	check.add_theme_font_size_override("font_size", 20)
	check.toggled.connect(func(on): Settings.set_value(key, on, get_tree()))
	_column.add_child(check)


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 52)
	button.add_theme_font_size_override("font_size", 20)
	return button


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
