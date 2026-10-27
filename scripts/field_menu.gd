extends Control
## Shared Field kit modal frame. Callers supply safe-area insets.
signal closed

const Kit := preload("res://art/ui/field-kit-v1/style.gd")
const CLOSE := preload("res://art/ui/controls-v1/close.svg")

var content: MarginContainer
var _panel: PanelContainer
var _header: HBoxContainer
var _heading: Label
var _symbol: TextureRect
var _close: Button
var _body: Control
var _return_focus: WeakRef

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.03, 0.025, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)
	# Manual inner layout keeps the header outside all scrolling regions.
	var canvas := Control.new()
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(canvas)
	canvas.resized.connect(_fit.call_deferred)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", Kit.plate(Color("20231c"), Kit.EDGE, 14))
	canvas.add_child(_panel)
	_panel.resized.connect(_fit.call_deferred)
	_panel.minimum_size_changed.connect(_fit.call_deferred)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_panel.add_child(column)
	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 12)
	column.add_child(_header)
	_symbol = TextureRect.new()
	_symbol.custom_minimum_size = Vector2(30, 30)
	_symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_symbol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_symbol.modulate = Kit.AMBER
	_header.add_child(_symbol)
	_heading = text_label("", 28, Kit.TEXT)
	_heading.add_theme_font_override("font", Kit.HEADING)
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_child(_heading)
	_close = Button.new()
	_close.icon = CLOSE
	_close.expand_icon = true
	_close.add_theme_constant_override("icon_max_width", 20)
	_close.custom_minimum_size = Vector2(48, 48)
	_close.tooltip_text = "Close"
	_close.accessibility_name = "Close"
	_close.pressed.connect(finish)
	_header.add_child(_close)
	_body = Control.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_body)
	content.resized.connect(_fit.call_deferred)
	_body.resized.connect(_layout_body.call_deferred)
	visible = false

func _ready() -> void:
	_fit()

func set_safe_area(insets: Vector4) -> void:
	content.offset_left = insets.x
	content.offset_top = insets.y
	content.offset_right = -insets.z
	content.offset_bottom = -insets.w
	_fit.call_deferred()

func _fit() -> void:
	if not is_inside_tree(): return
	var canvas: Control = _panel.get_parent()
	var available := canvas.size
	var desired := Vector2(minf(1100, maxf(0, available.x - 24)), minf(660, maxf(0, available.y - 24)))
	_panel.position = (available - desired) / 2
	_panel.size = desired
	_layout_body.call_deferred()

func _layout_body() -> void:
	pass

func begin_open() -> void:
	if not visible:
		var previous := get_viewport().gui_get_focus_owner()
		_return_focus = weakref(previous) if previous and not is_ancestor_of(previous) else null
	visible = true
	_fit()
	_close.grab_focus.call_deferred()

func finish() -> void:
	if not visible: return
	visible = false
	closed.emit()
	_restore_focus.call_deferred()

func _restore_focus() -> void:
	var previous = _return_focus.get_ref() if _return_focus else null
	if is_instance_valid(previous) and previous.is_visible_in_tree():
		previous.grab_focus()
	_return_focus = null

func cancel() -> void:
	finish()

func _input(event: InputEvent) -> void:
	# Consume Escape before the Pack beneath can also react to that key.
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		cancel()
		get_viewport().set_input_as_handled()
	elif is_visible_in_tree() and (event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev")):
		var controls: Array[Control] = []
		for node in find_children("*", "Control", true, false):
			if node.is_visible_in_tree() and node.focus_mode == Control.FOCUS_ALL and not (node is BaseButton and node.disabled):
				controls.append(node)
		if not controls.is_empty():
			var index := controls.find(get_viewport().gui_get_focus_owner())
			var direction := -1 if event.is_action_pressed("ui_focus_prev") else 1
			controls[posmod(index + direction, controls.size())].grab_focus()
		get_viewport().set_input_as_handled()
	elif is_visible_in_tree():
		# These actions are installed by Main, so they need not exist on the title.
		for action in ["toggle_pack", "toggle_map"]:
			if InputMap.has_action(action) and event.is_action_pressed(action):
				get_viewport().set_input_as_handled()
				break

func text_label(value: String, font_size: int, color := Kit.TEXT) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func action_button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 19)
	return button
