extends SceneTree
## Native import and phone-size presentation for #216's item and prayer icons.
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func icon(parent: Control, path: String, pixels: int) -> void:
	var texture = load(path) as Texture2D
	check(texture != null, "Load " + path)
	if texture == null:
		return
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(pixels, pixels)
	parent.add_child(rect)
	check(texture.get_image().get_used_rect().has_area(), "Nonblank " + path)

func run() -> void:
	root.size = Vector2i(1278, 590)
	var canvas := ColorRect.new()
	canvas.color = Color("#172021")
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	canvas.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	var title := Label.new()
	title.text = "PRAYERS / FIELD ITEMS"
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	var items := HBoxContainer.new()
	items.add_theme_constant_override("separation", 36)
	column.add_child(items)
	for name in ["tome_light", "tome_bind", "tome_watch", "votive_candle"]:
		var group := VBoxContainer.new()
		items.add_child(group)
		for size in [128, 64]:
			var suffix := "" if size == 128 else "-64"
			var path: String = "res://art/items/prayers-v1/" + name + suffix + ".png"
			icon(group, path, size)
			var texture = load(path) as Texture2D
			if texture:
				check(texture.get_width() == size and texture.get_height() == size, "Native dimensions " + path)
		var label := Label.new()
		label.text = name.replace("_", " ")
		group.add_child(label)
	var marks := HBoxContainer.new()
	marks.add_theme_constant_override("separation", 40)
	column.add_child(marks)
	for name in ["mend", "holy-light", "bind", "watchful-eye", "bound"]:
		var group := VBoxContainer.new()
		marks.add_child(group)
		for size in [32, 24, 16]:
			icon(group, "res://art/ui/prayers-v1/" + name + ".svg", size)
		var label := Label.new()
		label.text = name
		group.add_child(label)
	if DisplayServer.get_name() != "headless":
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://native-prayers.png") == OK, "Native capture")
	var report := {"checks": checks, "failures": failures, "renderer": RenderingServer.get_current_rendering_method()}
	var file := FileAccess.open("res://native-prayers.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	print("PRAYER_CHECKS ", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
