extends Control
## Nine-face artwork review; no generated-recruit, camp or inventory logic.
const VIEW := preload("res://art/portraits/recruit-kit-v1/lit_portrait_view.gd")
const FONT := preload("res://art/fonts/source-sans-3/SourceSans3-Variable.ttf")
var canvas: Control
var profiles: Array = []
var views: Array = []
var controls: Dictionary = {}
var lighting := "neutral"
var expression := "neutral"
var condition := ""
var outfit_on := true
var light_index := 0
var expression_index := 0
var condition_index := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 16
	var background := ColorRect.new()
	background.color = Color("17201c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	canvas = Control.new()
	canvas.size = Vector2(800,560)
	add_child(canvas)
	# This fixed three-column historical scene covers the original nine faces;
	# later role packs have their own native/phone inspectors (Fixer: #163).
	profiles = JSON.parse_string(FileAccess.get_file_as_string("res://art/portraits/recruit-roster-v1/catalog.json")).portraits.filter(func(p): return p.role in ["Warden", "Scout", "Brawler"])
	for col in 3:
		canvas.add_child(_label(["Warden","Scout","Brawler"][col],Vector2(col*256+16,5),20))
	for i in profiles.size():
		var profile: Dictionary = profiles[i]
		var x := (i%3)*256+8
		var y := floori(i/3.0)*146+34
		var group: Array = []
		for small in [false,true]:
			var view = VIEW.new()
			view.position = Vector2(x+136,y+16) if small else Vector2(x,y)
			view.size = Vector2(96,96) if small else Vector2(128,128)
			canvas.add_child(view)
			view.configure(profile.id,"neutral",profile)
			group.append(view)
		views.append(group)
		canvas.add_child(_label(profile.id,Vector2(x+8,y+128),16))
	for i in 6:
		var button := Button.new()
		button.position = Vector2(14+i*129,504)
		button.size = Vector2(120,44)
		var id: String = ["Light","Emotion","Condition","Outfit","Blink","Talk"][i]
		button.text = id
		canvas.add_child(button)
		controls[id] = button
		match id:
			"Light": button.pressed.connect(_cycle_light)
			"Emotion": button.pressed.connect(_cycle_expression)
			"Condition": button.pressed.connect(_cycle_condition)
			"Outfit": button.pressed.connect(func():set_outfit(not outfit_on))
			"Blink": button.pressed.connect(blink_all)
			"Talk": button.pressed.connect(talk_all)
	resized.connect(_fit)
	_fit()

func _label(text: String, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("e6dac1"))
	return label

func _fit() -> void:
	var margin := Vector2(48,12) if size.x/size.y>1.95 else Vector2(20,12)
	var room := size-margin*2
	var ratio := minf(room.x/800,room.y/560)
	canvas.scale = Vector2.ONE*ratio
	canvas.position = (size-Vector2(800,560)*ratio)/2

func set_light(preset: String) -> void:
	lighting = preset
	for group in views:
		for view in group:view.set_illumination(preset)

func set_expression(emotion: String) -> void:
	expression = emotion
	for i in views.size():
		for view in views[i]:
			view.configure(profiles[i].id,emotion,profiles[i])
			view.set_condition(condition,true)
	controls.Blink.disabled = emotion != "neutral"
	controls.Talk.disabled = emotion != "neutral"

func set_condition(name: String) -> void:
	condition = name
	for group in views:
		for view in group:
			for old in ["blood","dirt","bandage","pallor"]:view.set_condition(old,false)
			view.set_condition(name,true)

func set_outfit(shown: bool) -> void:
	outfit_on = shown
	for group in views:
		for view in group:view.set_outfit(shown)

func blink_all() -> void:
	for group in views:
		for view in group:view.blink()

func talk_all() -> void:
	for group in views:
		for view in group:view.talk(0.9)

func _cycle_light() -> void:
	light_index = (light_index+1)%3
	set_light(["neutral","warm","dim"][light_index])

func _cycle_expression() -> void:
	expression_index = (expression_index+1)%3
	set_expression(["neutral","worried","exhausted"][expression_index])

func _cycle_condition() -> void:
	condition_index = (condition_index+1)%5
	set_condition(["","blood","dirt","bandage","pallor"][condition_index])
