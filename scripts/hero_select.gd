extends Control
## Choosing a starting hero (#95): three main heroes side by side, each with
## a portrait, role, one-line backstory and their special trait. The one
## chosen wakes in the cave; the others don't exist in that game.

signal chosen(path: String)
signal cancelled

const HEROES := [
	"res://data/companions/mara.tres",
	"res://data/companions/corin.tres",
	"res://data/companions/alwen.tres",
]
const TEXT := Color("e6dac1")
const MUTED := Color("b3a78f")
const AMBER := Color("dbb477")
const HEADING := preload("res://art/fonts/heading-cinzel.tres")
const BODY := preload("res://art/fonts/body-source-sans.tres")

var content: MarginContainer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.045, 0.04, 1.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 24)
	add_child(content)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	content.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label("Who wakes in the dark?", HEADING, 30, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := _button("Back")
	back.pressed.connect(func():
		visible = false
		cancelled.emit())
	header.add_child(back)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	for path in HEROES:
		row.add_child(_card(path))
	visible = false


func open() -> void:
	visible = true


func _card(path: String) -> Control:
	var hero: Companion = load(path)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.08, 0.06)
	style.border_color = Color(0.45, 0.36, 0.22)
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var face := TextureRect.new()
	face.texture = hero.portrait
	face.custom_minimum_size = Vector2(0, 150)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	column.add_child(face)
	column.add_child(_label(hero.display_name, HEADING, 24, TEXT))
	column.add_child(_label(hero.role, BODY, 18, AMBER))
	var story := _label(hero.backstory, BODY, 16, MUTED)
	story.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(story)
	column.add_child(_label("%s: %s" % [hero.trait_name, hero.trait_text], BODY, 16, AMBER))
	var choose := _button("Wake as %s" % hero.display_name.split(" ")[-1])
	choose.pressed.connect(func():
		visible = false
		chosen.emit(path))
	column.add_child(choose)
	return panel


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 52)
	button.add_theme_font_size_override("font_size", 20)
	return button


func _label(text: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
