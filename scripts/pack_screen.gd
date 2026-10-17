extends Control
## Backpack screen (#10): lantern oil, time spent, and supplies with Use
## buttons. Supplies live here rather than on the HUD, to keep the view
## quiet. Opening and browsing spend nothing; using an item spends its time.

signal closed
## An item was used; `message` describes what happened.
signal used(message: String)

const Supplies := preload("res://scripts/supplies.gd")
const COLOR_TEXT := Color("e8d9b0")
const COLOR_DIM_TEXT := Color(0.85, 0.8, 0.7, 0.65)
const COLOR_OIL := Color("e8a84a")

var content: MarginContainer  # main.gd keeps this inside the safe area

var _party  # party_state.gd
var _time_label: Label
var _lantern_bar: ProgressBar
var _lantern_label: Label
var _list: VBoxContainer
var _injuries: VBoxContainer


func setup(party_state) -> void:
	_party = party_state
	_build()
	party_state.changed.connect(refresh)
	party_state.supplies.changed.connect(refresh)
	refresh()


func refresh() -> void:
	if not visible or _party == null:
		return
	var supplies = _party.supplies
	_time_label.text = "Time spent: %d" % _party.time_elapsed
	_lantern_bar.value = supplies.oil
	var flask_note := "  ·  part-used flask: %d" % roundi(supplies.open_flask) if supplies.open_flask > 0.0 else ""
	_lantern_label.text = "%s  ·  %d/%d oil  ·  burns %.1f per step%s" % [
		Supplies.LIGHT_NAMES[supplies.light_band()], roundi(supplies.oil), int(Supplies.LANTERN_CAPACITY),
		supplies.burn_rate(), flask_note]

	for child in _injuries.get_children():
		child.queue_free()
	var any_injury := false
	for member: Companion in _party.members:
		for injury in member.injuries:
			any_injury = true
			var state := "dressed until camp" if injury in member.dressed else "untreated"
			var line := _label("%s: %s (%s). %s" % [member.display_name, injury.display_name, state, injury.description], 17, COLOR_DIM_TEXT)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_injuries.add_child(line)
	if not any_injury:
		_injuries.add_child(_label("No injuries.", 17, COLOR_DIM_TEXT))

	for child in _list.get_children():
		child.queue_free()
	for item: SupplyItem in supplies.items:
		_list.add_child(_item_row(item))


func _item_row(item: SupplyItem) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var title := _label("%s  ×%d" % [item.display_name, _party.supplies.count(item)], 22, COLOR_TEXT)
	text.add_child(title)
	var about := _label(item.description, 17, COLOR_DIM_TEXT)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(about)

	var reason: String = _party.cannot_use_reason(item)
	var button := Button.new()
	button.text = "Use" if reason == "" else reason
	button.disabled = reason != ""
	button.custom_minimum_size = Vector2(170, 56)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func():
		var message: String = _party.use_item(item)
		if message != "":
			used.emit(message)
		refresh())
	row.add_child(button)
	return row


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.03, 0.03, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 32)
	add_child(content)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	content.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label("Pack", 30, COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_time_label = _label("", 20, COLOR_DIM_TEXT)
	_time_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_time_label)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(120, 52)
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(func(): closed.emit())
	header.add_child(close)

	column.add_child(_label("Lantern", 22, COLOR_TEXT))
	_lantern_bar = ProgressBar.new()
	_lantern_bar.max_value = Supplies.LANTERN_CAPACITY
	_lantern_bar.show_percentage = false
	_lantern_bar.custom_minimum_size = Vector2(0, 18)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.12, 0.09, 0.05)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COLOR_OIL
	_lantern_bar.add_theme_stylebox_override("background", back)
	_lantern_bar.add_theme_stylebox_override("fill", fill)
	column.add_child(_lantern_bar)
	_lantern_label = _label("", 17, COLOR_DIM_TEXT)
	column.add_child(_lantern_label)
	column.add_child(_label("A fuller lantern lights farther but burns faster.", 17, COLOR_DIM_TEXT))

	column.add_child(_label("Injuries", 22, COLOR_TEXT))
	_injuries = VBoxContainer.new()
	column.add_child(_injuries)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 14)
	scroll.add_child(_list)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
