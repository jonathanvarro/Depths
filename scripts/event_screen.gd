extends CenterContainer
## Shows a room event (#16): its clue, its choices and "Leave it". Each
## choice spends time and shows what happened; investigations add to the
## clue and keep the event open. Emits `finished` when the player is done.

## {"left": bool, "ambush": Array[EnemyType]}
signal finished(result: Dictionary)

const COLOR_TEXT := Color("e8d9b0")
const COLOR_DIM_TEXT := Color(0.85, 0.8, 0.7, 0.85)

var _rules  # room_events.gd
var _party  # party_state.gd
var _event: RoomEvent
var _title: Label
var _body: Label
var _buttons: VBoxContainer
var _used := {}  # investigations already tried


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.045, 0.04, 0.94)
	style.border_color = Color(0.35, 0.27, 0.18, 0.9)
	style.set_border_width_all(1)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	_title = _label(26, COLOR_TEXT)
	column.add_child(_title)
	_body = _label(19, COLOR_DIM_TEXT)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(520, 0)
	column.add_child(_body)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 8)
	column.add_child(_buttons)
	visible = false


func show_event(event: RoomEvent, party_state, rules) -> void:
	_event = event
	_party = party_state
	_rules = rules
	_used.clear()
	_title.text = event.title
	_body.text = event.clue
	_show_choices()
	visible = true


func _show_choices() -> void:
	_clear_buttons()
	for choice in _event.choices:
		if _used.has(choice):
			continue
		var label := choice.label
		if choice.time_cost > 0 and not label.contains("time"):
			label += "  (%d time)" % choice.time_cost
		_add_button(label, _choose.bind(choice))
	_add_button("Leave it", func(): _finish({"left": true, "ambush": [] as Array[EnemyType]}))


func _choose(choice: EventChoice) -> void:
	var result: Dictionary = _rules.resolve(_party, choice)
	if choice.investigation and result["ambush"].is_empty():
		_used[choice] = true
		_body.text += "\n\n" + result["text"]
		_show_choices()
		return
	_body.text = result["text"]
	_clear_buttons()
	_add_button("Continue", func(): _finish({"left": false, "ambush": result["ambush"]}))


func _finish(result: Dictionary) -> void:
	visible = false
	finished.emit(result)


func _clear_buttons() -> void:
	for child in _buttons.get_children():
		child.queue_free()


func _add_button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 52)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(action)
	_buttons.add_child(button)


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
