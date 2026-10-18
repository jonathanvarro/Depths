extends Control
## Isolated source-art review, with no recruit/campaign/stat changes.
const VIEW := preload("res://art/portraits/recruit-kit-v1/lit_portrait_view.gd")
const FONT := preload("res://art/fonts/source-sans-3/SourceSans3-Variable.ttf")
var canvas: Control
var views: Array = []
var light_index := 0
var expression_index := 0
var condition_index := 0
var outfit_on := true
var lighting := "neutral"
var expression := "neutral"
var condition := ""
var status: Label
var blink_button: Button
var talk_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 14
	var backdrop := ColorRect.new()
	backdrop.color = Color("131b19")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	canvas = Control.new()
	canvas.size = Vector2(640,360)
	add_child(canvas)
	var title := _label("Recruit portrait kit",Vector2(18,4),20)
	canvas.add_child(title)
	for i in range(2):
		var id := "warden-a" if i == 0 else "scout-a"
		var x := 14 + i*318
		canvas.add_child(_label("Warden" if i == 0 else "Scout",Vector2(x,34),18))
		for small in [false,true]:
			var view = VIEW.new()
			view.position = Vector2(x+208,106) if small else Vector2(x,60)
			view.size = Vector2(96,96) if small else Vector2(192,192)
			canvas.add_child(view)
			view.configure(id)
			views.append(view)
	var names := ["Light","Expression","Condition","Outfit","Blink","Talk"]
	for i in names.size():
		var button := Button.new()
		button.text = names[i]
		button.position = Vector2(12+i*104,282)
		button.size = Vector2(96,34)
		canvas.add_child(button)
		match names[i]:
			"Light": button.pressed.connect(_cycle_light)
			"Expression": button.pressed.connect(_cycle_expression)
			"Condition": button.pressed.connect(_cycle_condition)
			"Outfit": button.pressed.connect(func(): set_outfit(not outfit_on))
			"Blink":
				blink_button = button
				button.pressed.connect(blink_all)
			"Talk":
				talk_button = button
				button.pressed.connect(talk_all)
	status = _label("",Vector2(18,326),14)
	canvas.add_child(status)
	_update_status()
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
	var ratio := minf(room.x/640,room.y/360)
	canvas.scale = Vector2.ONE*ratio
	canvas.position = (size-Vector2(640,360)*ratio)/2

func set_light(preset: String) -> void:
	lighting = preset
	for view in views:
		view.set_illumination(preset)
	_update_status()

func set_expression(emotion: String) -> void:
	expression = emotion
	for view in views:
		view.configure(view.character_id,emotion)
		view.set_condition(condition,true)
	blink_button.disabled = emotion != "neutral"
	talk_button.disabled = emotion != "neutral"
	_update_status()

func set_condition(name: String) -> void:
	for view in views:
		for old in ["blood","dirt","bandage","pallor"]:
			view.set_condition(old,false)
		view.set_condition(name,true)
	condition = name
	_update_status()

func set_outfit(shown: bool) -> void:
	outfit_on = shown
	for view in views:
		view.set_outfit(shown)
	_update_status()

func blink_all() -> void:
	for view in views:
		view.blink()

func talk_all() -> void:
	for view in views:
		view.talk(0.9)

func _cycle_light() -> void:
	light_index = (light_index+1)%3
	set_light(["neutral","warm","dim"][light_index])

func _cycle_expression() -> void:
	expression_index = (expression_index+1)%3
	set_expression(["neutral","worried","exhausted"][expression_index])

func _cycle_condition() -> void:
	condition_index = (condition_index+1)%5
	set_condition(["","blood","dirt","bandage","pallor"][condition_index])

func _update_status() -> void:
	if status:
		status.text = lighting.capitalize() + " light  ·  " + expression + "  ·  " + ("unmarked" if condition.is_empty() else condition) + "  ·  192px and 96px"
