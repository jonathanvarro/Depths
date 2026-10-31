extends "res://scripts/field_menu.gd"
## Same settings model and immediate persistence; presentation only.
const Settings := preload("res://scripts/settings.gd")
const MUSIC_CREDITS := "Music: \"The Rising Tide\" by HitCtrl (CC-BY 3.0); \"For the Black Lord\" by Ronhul Maggot (CC-BY 4.0); Paul Wortmann, William Hector and RandomMind (CC0). All via OpenGameArt."

var _workspace: Control
var _sound_scroll: ScrollContainer
var _display_scroll: ScrollContainer
var _credits_scroll: ScrollContainer
var _display_panel: PanelContainer
var _credits: Button
var _sliders: Dictionary = {}
var _amounts: Dictionary = {}
var _toggles: Dictionary = {}
var _sizes: Dictionary = {}
var _credits_open := false

func _init() -> void:
	super()
	_heading.text = "Settings"
	_symbol.texture = preload("res://art/ui/controls-v1/settings.svg")
	_workspace = Control.new()
	_body.add_child(_workspace)
	var sound := _section("Sound")
	_sound_scroll = sound.scroll
	_workspace.add_child(_sound_scroll)
	for bus: String in Settings.BUSES:
		_slider(sound.column, {"Master": "Master volume", "Music": "Music and ambience", "Effects": "Effects"}[bus], bus)
	var display := _section("Display")
	_display_scroll = display.scroll
	_display_panel = _display_scroll.get_child(0)
	_workspace.add_child(_display_scroll)
	if not OS.has_feature("mobile"): _toggle(display.column, "Fullscreen", "fullscreen")
	_toggle(display.column, "Screen flashes", "flashes")
	_toggle(display.column, "Fights on the map (trial)", "map_fights")  # off: the battle stage (#171)
	display.column.add_child(text_label("Text size", 20))
	var sizes := HBoxContainer.new()
	sizes.add_theme_constant_override("separation", 6)
	display.column.add_child(sizes)
	var group := ButtonGroup.new()
	for size_name: String in Settings.TEXT_SIZES:
		var choice := action_button(size_name)
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.toggle_mode = true
		choice.button_group = group
		choice.accessibility_name = "Text size: " + size_name
		choice.pressed.connect(_choose_text_size.bind(size_name))
		sizes.add_child(choice)
		_sizes[size_name] = choice
	_credits_scroll = ScrollContainer.new()
	_credits_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_credits_scroll.follow_focus = true
	_credits_scroll.focus_mode = Control.FOCUS_ALL
	_body.add_child(_credits_scroll)
	var credits_column := VBoxContainer.new()
	credits_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credits_column.add_theme_constant_override("separation", 14)
	_credits_scroll.add_child(credits_column)
	credits_column.add_child(text_label("Music credits", 24, Kit.AMBER))
	credits_column.add_child(text_label(MUSIC_CREDITS, 20, Kit.MUTED))
	_credits = action_button("Music credits")
	_credits.pressed.connect(_toggle_credits)
	_header.add_child(_credits)
	_header.move_child(_credits, _header.get_child_count() - 2)

func _section(title: String) -> Dictionary:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", Kit.plate(Color("282b22"), Kit.EDGE, 12))
	scroll.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var heading := text_label(title, 22, Kit.AMBER)
	heading.add_theme_font_override("font", Kit.HEADING)
	column.add_child(heading)
	return {"scroll": scroll, "column": column}

func _slider(column: VBoxContainer, title: String, key: String) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)
	var label := text_label(title, 20)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var amount := text_label("", 18, Kit.MUTED)
	amount.custom_minimum_size.x = 48
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(amount)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(0, 44)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.tooltip_text = title
	slider.accessibility_name = title
	column.add_child(slider)
	slider.value_changed.connect(func(value: float):
		amount.text = "%d%%" % roundi(value * 100)
		Settings.set_value(key, value, get_tree()))
	_sliders[key] = slider
	_amounts[key] = amount

func _toggle(column: VBoxContainer, title: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	var label := text_label(title, 20)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	var toggle := action_button("")
	toggle.custom_minimum_size.x = 76
	toggle.toggle_mode = true
	toggle.tooltip_text = title
	toggle.accessibility_name = title
	toggle.toggled.connect(func(on: bool):
		toggle.text = "On" if on else "Off"
		Settings.set_value(key, on, get_tree()))
	row.add_child(toggle)
	_toggles[key] = toggle

func _choose_text_size(size_name: String) -> void:
	Settings.set_value("text_size", size_name, get_tree())
	# Keep the focused button alive while the viewport changes scale.
	_sync()
	_layout_body.call_deferred()

func _sync() -> void:
	for key in _sliders:
		var value: float = Settings.get_value(key)
		_sliders[key].set_value_no_signal(value)
		_amounts[key].text = "%d%%" % roundi(value * 100)
	for key in _toggles:
		var on: bool = Settings.get_value(key)
		_toggles[key].set_pressed_no_signal(on)
		_toggles[key].text = "On" if on else "Off"
	for key in _sizes: _sizes[key].set_pressed_no_signal(Settings.get_value("text_size") == key)

func open() -> void:
	_sync()
	_credits_open = false
	_sound_scroll.scroll_vertical = 0
	_display_scroll.scroll_vertical = 0
	_layout_body()
	begin_open()

func _toggle_credits() -> void:
	_credits_open = not _credits_open
	_layout_body()
	_credits.grab_focus.call_deferred()

func cancel() -> void:
	if _credits_open: _toggle_credits()
	else: super.cancel()

func _layout_body() -> void:
	if not _workspace: return
	var area := _body.size
	_workspace.position = Vector2.ZERO
	_workspace.size = area
	_workspace.visible = not _credits_open
	_credits_scroll.position = Vector2.ZERO
	_credits_scroll.size = area
	_credits_scroll.visible = _credits_open
	_credits.text = "Back" if _credits_open else "Music credits"
	# Narrow viewports use a single scrollable column, with both sections in it.
	# Normal landscape phones keep two independently scrollable sections.
	var compact := area.x < 650
	var focused := get_viewport().gui_get_focus_owner()
	var restore_focus := focused != null and _display_panel.is_ancestor_of(focused)
	if compact:
		# One scroll, with Display's panel below Sound; no nested touch scrolling.
		var sound_column: VBoxContainer = _sound_scroll.get_child(0).get_child(0)
		if _display_panel.get_parent() != sound_column:
			_display_panel.reparent(sound_column)
			if restore_focus: focused.grab_focus.call_deferred()
		_display_scroll.hide()
		_sound_scroll.position = Vector2.ZERO
		_sound_scroll.size = area
	else:
		if _display_panel.get_parent() != _display_scroll:
			_display_panel.reparent(_display_scroll)
			if restore_focus: focused.grab_focus.call_deferred()
		_display_scroll.show()
		var width := (area.x - 14) / 2
		_sound_scroll.position = Vector2.ZERO
		_sound_scroll.size = Vector2(width, area.y)
		_display_scroll.position = Vector2(width + 14, 0)
		_display_scroll.size = Vector2(width, area.y)
