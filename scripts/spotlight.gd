extends Control
## Dims the whole screen except one control, and lets clicks reach only that
## control (owner, 2026-11-22: the opening's "drop the broken knife" step).
## `finder` returns the control to leave lit (or null to hide), asked every
## frame like hint_ring.gd, as the Pack lays itself out.

var finder := Callable()
var _hole := Rect2()


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _process(_delta: float) -> void:
	var target: Control = finder.call() if finder.is_valid() else null
	var show := target != null and is_instance_valid(target) and target.is_visible_in_tree()
	if show != visible:
		visible = show
	if not show:
		return
	var hole := target.get_global_rect().grow(8.0)
	if hole != _hole:
		_hole = hole
		queue_redraw()


## Clicks inside the hole go through to the lit control.
func _has_point(point: Vector2) -> bool:
	return not _hole.has_point(point)


func _draw() -> void:
	var shade := Color(0, 0, 0, 0.62)
	var full := Rect2(Vector2.ZERO, size)
	var h := _hole.intersection(full)
	draw_rect(Rect2(0, 0, size.x, h.position.y), shade)
	draw_rect(Rect2(0, h.end.y, size.x, size.y - h.end.y), shade)
	draw_rect(Rect2(0, h.position.y, h.position.x, h.size.y), shade)
	draw_rect(Rect2(h.end.x, h.position.y, size.x - h.end.x, h.size.y), shade)
