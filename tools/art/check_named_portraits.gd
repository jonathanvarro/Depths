extends SceneTree

const PortraitView := preload("res://scripts/portrait_view.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(passed: bool, label: String) -> void:
	print("PASS " if passed else "FAIL ", label)
	if not passed:
		failures += 1

func run() -> void:
	var canvas := Control.new()
	root.add_child(canvas)
	var preview := OS.get_cmdline_user_args()
	for index in 3:
		var id: String = ["branna", "nessa", "maelin"][index]
		var set: PortraitSet = load("res://data/portraits/named-cast-v1/%s.tres" % id)
		check(set != null and set.face_id == StringName(id), id + " unique resource")
		var textures: Array = [set.body, set.head, set.eyes, set.mouth, set.light_shadow, set.light_highlight]
		textures.append_array(set.blink_frames)
		textures.append_array(set.talk_frames)
		textures.append_array(set.conditions.values())
		check(textures.size() == 14 and textures.all(func(t): return t.get_size() == Vector2(192,192)), id + " 14 aligned textures")
		var view = PortraitView.new()
		canvas.add_child(view)
		view.position = Vector2(95 + index * 352, 108)
		view.size = Vector2(192,192)
		view.show_portrait(set)
		view.blink()
		await view._eye_tween.finished
		check(view._eyes.texture == set.eyes, id + " blink reopens")
		view.talk(.25)
		await view._talk_tween.finished
		check(view._mouth.texture == set.mouth, id + " speech returns to neutral")
		view.set_condition("bandage",true)
		view.set_illumination("torch")
		check(view._overlays["bandage"].visible, id + " independent bandage")
		var card = PortraitView.new()
		canvas.add_child(card)
		card.position = view.position + Vector2(48, 215)
		card.size = Vector2(96,96)
		card.show_portrait(set)
		card.set_animated(false)
		card._eyes.texture = set.blink_frames[-1]
		card._mouth.texture = set.talk_frames[-1]
	if not preview.is_empty():
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(preview[0]) == OK, "save native and card capture")
	print("fails=", failures)
	quit(failures)
