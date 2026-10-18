extends Control
## Combat feedback drawn over the fight (#105): slashes and claw marks, big
## damage numbers that pop and rise, and icons for what happened (a miss, a
## block, venom, a web). Replaces the old sentence log.

const COLOR_DAMAGE := Color("f2d27a")
const COLOR_HURT := Color("ff5a44")
const COLOR_HEAL := Color("7fd36a")
const COLOR_DULL := Color(0.8, 0.78, 0.72)
const NUMBER_SIZE := 52
const ICON_SIZE := 44.0


## One streak: a tapered stroke from `from` to `to` that sweeps in, then fades.
class Streak:
	extends Control
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var width := 7.0
	var color := Color.WHITE
	var progress := 0.0:
		set(value):
			progress = value
			queue_redraw()

	func _draw() -> void:
		if progress <= 0.0:
			return
		# One tapered blade shape: thin at the ends, thickest in the middle.
		var end := from.lerp(to, progress)
		var normal := (to - from).normalized().orthogonal()
		var steps := 12
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in steps + 1:
			var t := float(i) / steps
			var half := width * 0.5 * sin(t * PI) + 0.5
			var point := from.lerp(end, t)
			left.append(point + normal * half)
			right.append(point - normal * half)
		right.reverse()
		left.append_array(right)
		draw_colored_polygon(left, color)


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A hero's blow landing at `at`: one bright diagonal slash.
func slash(at: Vector2, heavy := false) -> void:
	var reach := 95.0 if heavy else 75.0
	_streak(at + Vector2(-reach, -reach * 0.8), at + Vector2(reach, reach * 0.8), Color("fff3d6"), 12.0 if heavy else 9.0, 0.0)


## An enemy's blow landing at `at` (over a hero's card): three claw marks.
func claw(at: Vector2) -> void:
	for i in 3:
		var shift := Vector2((i - 1) * 16.0, 0)
		# Pale, so they read over the card's red hurt flash.
		_streak(at + shift + Vector2(-24, -44), at + shift + Vector2(18, 40), Color("ffe6da"), 8.0, i * 0.04)


## A big number that pops at `at`, rises and fades; `delay` lets a slash
## land first.
func number(at: Vector2, text: String, color := COLOR_DAMAGE, size := NUMBER_SIZE, delay := 0.0) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.03))
	label.add_theme_constant_override("outline_size", 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	label.reset_size()
	label.pivot_offset = label.size / 2.0
	label.position = at - label.size / 2.0
	label.scale = Vector2(1.7, 1.7)
	var tween := label.create_tween()
	if delay > 0.0:
		label.modulate.a = 0.0
		tween.tween_interval(delay)
		tween.tween_property(label, "modulate:a", 1.0, 0.01)
	tween.tween_property(label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 46.0, 0.8).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.45)
	tween.tween_callback(label.queue_free)


## An icon that pops at `at` and fades: a miss, a block, venom, a web...
func icon(at: Vector2, texture: Texture2D, size := ICON_SIZE) -> void:
	if texture == null:
		return
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = Vector2(size, size)
	rect.pivot_offset = rect.size / 2.0
	rect.position = at - rect.size / 2.0
	rect.scale = Vector2(0.4, 0.4)
	add_child(rect)
	var tween := rect.create_tween()
	tween.tween_property(rect, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(rect, "position:y", rect.position.y - 24.0, 0.7)
	tween.parallel().tween_property(rect, "modulate:a", 0.0, 0.3).set_delay(0.4)
	tween.tween_callback(rect.queue_free)


func _streak(from: Vector2, to: Vector2, color: Color, width: float, delay: float) -> void:
	var streak := Streak.new()
	streak.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	streak.from = from
	streak.to = to
	streak.color = color
	streak.width = width
	add_child(streak)
	var tween := streak.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(streak, "progress", 1.0, 0.12)
	tween.tween_property(streak, "modulate:a", 0.0, 0.3)
	tween.tween_callback(streak.queue_free)
