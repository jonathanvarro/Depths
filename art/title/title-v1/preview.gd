extends Control
## Visual study only (#38): not the entry scene or #18's title/preparation flow.
const DISPLAY := preload("res://art/fonts/title-cinzel.tres")
const HEADING := preload("res://art/fonts/heading-cinzel.tres")
const BODY := preload("res://art/fonts/body-source-sans.tres")
const ACTION := preload("res://art/fonts/action-source-sans.tres")
const TEXT := Color("e6dac1")
const MUTED := Color("b3a78f")
const AMBER := Color("dbb477")
var phone_preview := false
var specimen := false
var text_controls: Array[Control] = []

func _ready() -> void:
	build()

func label(parent: Node, text: String, font: Font, size: int, color: Color = TEXT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", font)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	text_controls.append(node)
	return node

func build() -> void:
	for child in get_children():
		child.queue_free()
	text_controls.clear()
	if specimen:
		build_specimen()
		return
	var backdrop := TextureRect.new()
	backdrop.texture = preload("res://art/title/title-v1/background.png")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 100 if phone_preview else 88)
	margin.add_theme_constant_override("margin_right", 100 if phone_preview else 64)
	margin.add_theme_constant_override("margin_top", 56 if phone_preview else 128)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_theme_constant_override("separation", 12 if phone_preview else 18)
	margin.add_child(column)
	label(column, "DEPTHS", DISPLAY, 78 if phone_preview else 96)
	var line := ColorRect.new()
	line.color = Color("806a48")
	line.custom_minimum_size = Vector2(300,1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(line)
	var gap := Control.new()
	gap.custom_minimum_size.y = 18 if phone_preview else 26
	column.add_child(gap)
	for title in (["Begin expedition", "Settings"] if phone_preview else ["Begin expedition", "Settings", "Quit"]):
		var button := Button.new()
		button.text = title
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(310,72 if phone_preview else 56)
		button.add_theme_font_override("font", ACTION)
		button.add_theme_font_size_override("font_size", 26)
		button.add_theme_color_override("font_color", AMBER if title == "Begin expedition" else TEXT)
		button.add_theme_color_override("font_hover_color", AMBER)
		button.add_theme_color_override("font_focus_color", AMBER)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.06,0.07,0.06,0.65)
		normal.border_color = Color("493f2d")
		normal.set_border_width(SIDE_BOTTOM,1)
		normal.content_margin_left = 14
		button.add_theme_stylebox_override("normal", normal)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("29291e")
		hover.border_color = AMBER
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color(0,0,0,0)
		focus.border_color = AMBER
		focus.set_border_width_all(2)
		button.add_theme_stylebox_override("focus", focus)
		button.pressed.connect(func(): pass) # Deliberately no navigation/game actions.
		column.add_child(button)
		text_controls.append(button)
	var footer := Label.new()
	footer.text = "Title & type study · Working title"
	footer.add_theme_font_override("font", BODY)
	footer.add_theme_font_size_override("font_size", 18)
	footer.add_theme_color_override("font_color", MUTED)
	footer.position = Vector2(100 if phone_preview else 88, size.y - 42)
	add_child(footer)
	text_controls.append(footer)

func build_specimen() -> void:
	var background := ColorRect.new()
	background.color = Color("171a17")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column := VBoxContainer.new()
	column.position = Vector2(64,42)
	column.size = Vector2(size.x - 128,size.y - 84)
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	label(column,"DEPTHS",DISPLAY,78)
	label(column,"Cinzel 600 · Title and major headings",BODY,20,MUTED)
	label(column,"Pack     Party     Expedition",HEADING,30)
	label(column,"Source Sans 3 · Actions and body text",BODY,20,MUTED)
	label(column,"Begin expedition     Defend     Leave it",ACTION,26,AMBER)
	label(column,"The passage bends into darkness. A draft rises from below.",BODY,22)
	label(column,"Health 14/20    Oil 100/100    Shaken    ×3",ACTION,22)
	label(column,"0123456789   Il1 O0   Aa Bb Cc   —  –  ×  /  %",BODY,22)
	var paper := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("c9b58e")
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	paper.add_theme_stylebox_override("panel",style)
	column.add_child(paper)
	var notes := VBoxContainer.new()
	paper.add_child(notes)
	label(notes,"Known routes",HEADING,26,Color("29281f"))
	label(notes,"Dark ink on parchment. Clear type for names, costs and warnings.",BODY,22,Color("29281f"))
