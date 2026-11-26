extends Control
## #271: physical Rest/Store targets; CampState still owns all consequences.
signal rest_requested
signal store_requested
const ART := preload("res://art/camp/player-tent-v1/interior.png")
const HEADING := preload("res://art/fonts/heading-cinzel.tres")
const TARGETS := {
	"rest": {"rect":Rect2(.035,.385,.325,.58),"label":Vector2(.20,.78),"text":"Rest", "tip":"Sleep until morning: heals and calms. Injuries need the priest. The mine shifts overnight.", "outline":[Vector2(.04,.60),Vector2(.19,.40),Vector2(.35,.41),Vector2(.35,.65),Vector2(.28,.94),Vector2(.055,.94)]},
	"store": {"rect":Rect2(.477,.39,.217,.31),"label":Vector2(.58,.59),"text":"Store", "tip":"Store and take items and gold: they stay safe at camp.", "outline":[Vector2(.48,.45),Vector2(.51,.40),Vector2(.68,.41),Vector2(.69,.47),Vector2(.68,.68),Vector2(.485,.66)]},
}
var _picture := Rect2()
var _buttons := {}
var _activating := false
var _pressed_id := ""

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id: String in TARGETS:
		var button := Button.new()
		button.accessibility_name = "Rest until morning" if id=="rest" else "Store belongings"
		button.set_meta("tent_target",id)
		button.tooltip_text = TARGETS[id].tip
		button.custom_minimum_size = Vector2(44,44)
		for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		button.mouse_entered.connect(queue_redraw)
		button.mouse_exited.connect(queue_redraw)
		button.focus_entered.connect(queue_redraw)
		button.focus_exited.connect(queue_redraw)
		button.pressed.connect(_activate.bind(id))
		var label := Label.new()
		label.text = TARGETS[id].text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font",HEADING)
		label.add_theme_font_size_override("font_size",15)
		label.add_theme_color_override("font_color",Color("f0ddb4"))
		label.add_theme_color_override("font_outline_color",Color("15150f"))
		label.add_theme_constant_override("outline_size",6)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)
		_buttons[id] = button
		add_child(button)
	resized.connect(_fit)

func _ready() -> void:
	_fit()

## Resting once between trips (owner, 2026-11-24): the cot greys out, and
## says why, until the party has been down the mine again.
func set_rest_allowed(allowed: bool, reason := "") -> void:
	var button: Button = _buttons["rest"]
	button.disabled = not allowed
	button.tooltip_text = TARGETS["rest"].tip if allowed else reason
	button.modulate = Color.WHITE if allowed else Color(1, 1, 1, 0.45)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if allowed else Control.CURSOR_FORBIDDEN

func _activate(id: String) -> void:
	if _activating:return
	if id=="rest" and _buttons["rest"].disabled:return
	_activating=true
	_pressed_id=id
	queue_redraw()
	# A short static press highlight gives touch users the same object feedback.
	await get_tree().create_timer(.12).timeout
	if not is_visible_in_tree():
		_activating=false;_pressed_id="";queue_redraw()
		return
	if id=="rest":rest_requested.emit()
	else:store_requested.emit()

func _fit() -> void:
	var fitted := ART.get_size() * minf(size.x/ART.get_width(),size.y/ART.get_height())
	_picture = Rect2((size-fitted)/2,fitted)
	for id: String in _buttons:
		var button: Button = _buttons[id]
		var target: Rect2 = TARGETS[id].rect
		button.position = _picture.position + target.position * fitted
		button.size = target.size * fitted
		var label := button.get_child(0) as Label
		label.size = Vector2(84,24)
		label.position = _picture.position + TARGETS[id].label * fitted - button.position - Vector2(42,12)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("13150f"))
	if _picture.size.x<=0:return
	draw_texture_rect(ART,_picture,false)
	for id: String in _buttons:
		var button: Button = _buttons[id]
		if not button.is_hovered() and not button.has_focus() and _pressed_id!=id:continue
		var points := PackedVector2Array()
		for point: Vector2 in TARGETS[id].outline:
			points.append(_picture.position+point*_picture.size)
		draw_colored_polygon(points,Color(.85,.68,.40,.18 if _pressed_id==id else .10))
		points.append(points[0])
		draw_polyline(points,Color(.9,.74,.45,.85),2.0 if _pressed_id==id else 1.5,true)
