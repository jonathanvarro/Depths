extends Control
## End-of-expedition results (#17): how it ended, what was gained and what
## was lost, and a button to go again.

signal continue_pressed

const Expedition := preload("res://scripts/expedition.gd")
const COLOR_TEXT := Color("e8d9b0")
const COLOR_DIM_TEXT := Color(0.85, 0.8, 0.7, 0.85)
const COLOR_LOSS := Color("d98a7a")

var content: MarginContainer  # main.gd keeps this inside the safe area

var _title: Label
var _subtitle: Label
var _gained: VBoxContainer
var _lost: VBoxContainer
var _button: Button
var _illustration: TextureRect
var _tallies: HBoxContainer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.02, 0.97)
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
	_title = _label(34, COLOR_TEXT)
	_title.theme_type_variation = "PageTitle"  # Cinzel heading (#51)
	column.add_child(_title)
	_subtitle = _label(20, COLOR_DIM_TEXT)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_subtitle)
	_illustration=TextureRect.new()
	_illustration.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	_illustration.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_illustration.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_illustration.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_illustration.custom_minimum_size=Vector2(0,120)
	_illustration.visible=false
	column.add_child(_illustration)
	var columns := HBoxContainer.new()
	_tallies=columns
	columns.add_theme_constant_override("separation", 40)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(columns)
	_gained = _section(columns, "Gained")
	_lost = _section(columns, "Lost")
	_button = Button.new()
	_button.custom_minimum_size = Vector2(260, 60)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_button.focus_mode = Control.FOCUS_NONE
	_button.add_theme_font_size_override("font_size", 22)
	_button.pressed.connect(func(): continue_pressed.emit())
	column.add_child(_button)
	visible = false


func show_results(ending: int, expedition, party, note: String) -> void:
	_illustration.visible=false
	_tallies.visible=true
	_title.text = Expedition.TITLES[ending]
	var where := "Expedition %d" % expedition.number
	_subtitle.text = where + ". " + note
	_gained.get_parent().visible = true
	_lost.get_parent().visible = true
	_fill(_gained, expedition.gained(party), COLOR_DIM_TEXT)
	_fill(_lost, expedition.lost(party), COLOR_LOSS)
	_button.text = "Begin again" if ending == Expedition.Ending.WIPED else "New expedition"
	visible = true


## A short ending with no tallies (the opening: "Barely survived", #56).
## Later this is where gold retrieved and enemies slain will show.
func show_brief(title: String, note: String, button: String, illustration: Texture2D=null) -> void:
	_illustration.texture=illustration
	_illustration.visible=illustration!=null
	_tallies.visible=false
	_title.text = title
	_subtitle.text = note
	_gained.get_parent().visible = false
	_lost.get_parent().visible = false
	_button.text = button
	visible = true


func _section(parent: Control, heading: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	box.add_child(_label(24, COLOR_TEXT, heading))
	var lines := VBoxContainer.new()
	box.add_child(lines)
	parent.add_child(box)
	return lines


func _fill(box: VBoxContainer, lines: PackedStringArray, color: Color) -> void:
	for child in box.get_children():
		child.queue_free()
	for line in lines:
		var label := _label(18, color, line)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(label)


func _label(size: int, color: Color, text := "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
