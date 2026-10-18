extends Control
## Isolated art review. No campaign, inventory, spending or service actions.
const DIR := "res://art/camp/cave-camp-v1/"
const BODY_FONT := preload("res://art/fonts/source-sans-3/SourceSans3-Variable.ttf")
const HEADING_FONT := preload("res://art/fonts/cinzel/Cinzel-Variable.ttf")
var canvas: Control
var destinations: Array[Dictionary] = []
var buttons: Dictionary = {}
var activity: Panel
var back: Button
var current_id := ""
var selected_id := ""
var activity_portrait: TextureRect
var activity_title: Label
var activity_art: TextureRect
var art_nodes: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = Theme.new()
	theme.default_font = BODY_FONT
	theme.default_font_size = 14
	var backdrop := ColorRect.new()
	backdrop.color = Color("101715")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	canvas = Control.new()
	canvas.size = Vector2(640,360)
	add_child(canvas)
	var scenery := TextureRect.new()
	scenery.texture = load(DIR + "clearing.png")
	scenery.size = Vector2(640,360)
	scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(scenery)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "layout.json"))
	for item in data.sites:
		destinations.append(item)
		var r: Array = item.rect
		var rect := Rect2(r[0],r[1],r[2],r[3])
		var area = load(DIR + item.id + ".tscn").instantiate()
		area.position = Vector2(rect.get_center().x, rect.end.y-24)
		area.scale = Vector2.ONE*float(item.scale)
		canvas.add_child(area)
		art_nodes[item.id] = area
		var button := Button.new()
		button.position = rect.position
		button.size = rect.size
		button.text = item.label
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_font_size_override("font_size",14)
		button.add_theme_color_override("font_color",Color("eee2c9"))
		button.add_theme_color_override("font_shadow_color",Color.BLACK)
		button.add_theme_constant_override("shadow_offset_x",1)
		button.add_theme_constant_override("shadow_offset_y",1)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0,0,0,0)
		normal.content_margin_top = rect.size.y-22
		normal.content_margin_bottom = 0
		normal.content_margin_left = 0
		normal.content_margin_right = 0
		button.add_theme_stylebox_override("normal",normal)
		for state in ["hover","pressed","focus"]:
			var highlight := normal.duplicate() as StyleBoxFlat
			highlight.bg_color = Color(0.7,0.49,0.22,0.08)
			highlight.border_color = Color("bc9b60")
			highlight.set_border_width_all(1)
			button.add_theme_stylebox_override(state,highlight)
		button.pressed.connect(open_area.bind(String(item.id)))
		canvas.add_child(button)
		# A readable label strip, independent of the scene's dark pixels.
		var strip := ColorRect.new()
		strip.color = Color(0.04,0.06,0.05,0.86)
		strip.position = Vector2(4,rect.size.y-21)
		strip.size = Vector2(rect.size.x-8,20)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.show_behind_parent = true
		button.add_child(strip)
		buttons[item.id] = button
	var title := Label.new()
	title.text = "Relief camp"
	title.position = Vector2(20,8)
	title.add_theme_font_size_override("font_size",18)
	title.add_theme_font_override("font",_heading_font())
	title.add_theme_color_override("font_color",Color("e5d9bf"))
	title.add_theme_color_override("font_shadow_color",Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x",1)
	title.add_theme_constant_override("shadow_offset_y",1)
	canvas.add_child(title)
	_build_activity()
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	if canvas == null:
		return
	# Simulated landscape-phone safe margins; live integration uses SafeArea.
	var safe := Vector2(48,12) if size.x/size.y > 1.95 else Vector2(20,12)
	var room := size-safe*2
	var ratio: float = minf(room.x/640.0,room.y/360.0)
	canvas.scale = Vector2.ONE*ratio
	canvas.position = (size-Vector2(640,360)*ratio)/2

func _heading_font() -> FontVariation:
	var font := FontVariation.new()
	font.base_font = HEADING_FONT
	font.variation_opentype = {"wght":600}
	return font

func _build_activity() -> void:
	activity = Panel.new()
	activity.position = Vector2(42,28)
	activity.size = Vector2(556,304)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("1b2421")
	panel_style.border_color = Color("938263")
	panel_style.set_border_width_all(1)
	activity.add_theme_stylebox_override("panel",panel_style)
	canvas.add_child(activity)
	activity_title = Label.new()
	activity_title.position = Vector2(24,13)
	activity_title.add_theme_font_size_override("font_size",22)
	activity_title.add_theme_font_override("font",_heading_font())
	activity.add_child(activity_title)
	activity_portrait = TextureRect.new()
	activity_portrait.position = Vector2(12,62)
	activity_portrait.size = Vector2(216,216)
	activity_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	activity_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	activity.add_child(activity_portrait)
	activity_art = TextureRect.new()
	activity_art.position = Vector2(254,64)
	activity_art.size = Vector2(280,210)
	activity_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	activity_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	activity.add_child(activity_art)
	back = Button.new()
	back.text = "Back to camp"
	back.position = Vector2(394,14)
	back.size = Vector2(142,32)
	back.add_theme_font_size_override("font_size",16)
	back.pressed.connect(close_area)
	activity.add_child(back)
	activity.hide()

func open_area(id: String) -> void:
	for item in destinations:
		if item.id != id:
			continue
		current_id = id
		selected_id = id
		for button in buttons.values():
			button.hide()
		activity_title.text = item.label
		activity_portrait.texture = load(DIR + item.npc + ".png") if not item.npc.is_empty() else null
		activity_art.position.x = 138 if item.npc.is_empty() else 254
		activity_art.texture = load(DIR + id + ".png")
		activity.show()
		back.grab_focus()
		return

func close_area() -> void:
	activity.hide()
	current_id = ""
	for button in buttons.values():
		button.show()
	if buttons.has(selected_id):
		buttons[selected_id].grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and activity.visible:
		close_area()
		get_viewport().set_input_as_handled()
