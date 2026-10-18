extends Panel
## A pulsing gold ring around the button a tutorial card wants pressed
## (#105), so the card can say less. `finder` returns that button (or null)
## and is asked every frame, as menus open and close.

var finder := Callable()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = Color("f2c94c")
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", style)
	visible = false


func _process(_delta: float) -> void:
	var target: Control = finder.call() if finder.is_valid() else null
	visible = target != null and is_instance_valid(target) and target.is_visible_in_tree()
	if not visible:
		return
	var rect := target.get_global_rect().grow(6.0)
	position = rect.position
	size = rect.size
	modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 160.0)
