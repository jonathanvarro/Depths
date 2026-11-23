extends RefCounted
## Owner-selected #269 frames, adapted to native nine-slice styles (#271).
enum Edge { LEFT, CENTRE, RIGHT }
const FRAMES := [preload("res://art/ui/reliquary-brass-v1/left.svg"), preload("res://art/ui/reliquary-brass-v1/centre.svg"), preload("res://art/ui/reliquary-brass-v1/right.svg")]
const PANEL := preload("res://art/ui/reliquary-brass-v1/panel.svg")
const STATES := ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]
const TINTS := {"normal": Color(1,1,1), "hover": Color(1.3,1.2,1.02), "pressed": Color(1.2,1.1,.88), "hover_pressed": Color(1.35,1.23,.96), "disabled": Color(.58,.60,.53,.8), "focus": Color(1.65,1.5,1.15)}

static func frame(state := "normal", edge := Edge.CENTRE, padding := 10.0) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = FRAMES[edge]
	box.set_texture_margin(SIDE_LEFT, 12)
	box.set_texture_margin(SIDE_RIGHT, 12)
	box.set_texture_margin(SIDE_TOP, 9)
	box.set_texture_margin(SIDE_BOTTOM, 9)
	box.set_content_margin_all(padding)
	box.modulate_color = TINTS.get(state, Color.WHITE)
	box.draw_center = state != "focus"
	return box

static func apply(button: Button, edge := Edge.CENTRE, padding := 10.0) -> void:
	for state in STATES:
		button.add_theme_stylebox_override(state, frame(state, edge, padding))
	button.set_meta("reliquary_edge", edge)

static func panel(padding := 14.0) -> StyleBoxTexture:
	var box := frame("normal", Edge.CENTRE, padding)
	box.texture = PANEL
	box.modulate_color = Color(.94,.96,.91,.96)
	return box
