extends Control
## The quest log (#123): what you've been asked to do, and what you've
## found. Hidden quests appear only once discovered. Opened from the Pack.

signal closed

const Quests := preload("res://scripts/quests.gd")
const TEXT := Color("e8d9b0")
const MUTED := Color(0.85, 0.8, 0.7, 0.7)
const AMBER := Color("d7b174")

var _list: VBoxContainer
var _close: Button


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Quests"
	title.theme_type_variation = "PageTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_close = Button.new()
	_close.text = "Close"
	_close.custom_minimum_size = Vector2(110, 52)
	_close.pressed.connect(func():
		visible = false
		closed.emit())
	header.add_child(_close)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	column.add_child(_list)


func open(camp) -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var ids: Array = Quests.in_log(camp)
	if ids.is_empty():
		_list.add_child(_label("No quests yet.", MUTED, 18))
	# Unfinished first, then done.
	ids.sort_custom(func(a, b): return (Quests.stage(camp, a) == Quests.Stage.RESOLVED) < (Quests.stage(camp, b) == Quests.Stage.RESOLVED))
	for id in ids:
		var info: Dictionary = Quests.INFO[id]
		var done: bool = Quests.stage(camp, id) == Quests.Stage.RESOLVED
		var from := " · from %s" % info["giver"] if info["giver"] != "" else " · found in the mine"
		_list.add_child(_label("%s  (floor %d%s)" % [info["title"], info["floor"], from], MUTED if done else AMBER, 20))
		_list.add_child(_label(Quests.next_step(camp, id), MUTED if done else TEXT, 18))
	visible = true
	_close.grab_focus.call_deferred()


func _label(text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(600, 0)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	return label


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
		closed.emit()
		get_viewport().set_input_as_handled()
