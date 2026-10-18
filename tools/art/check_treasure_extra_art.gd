extends SceneTree
## Check the additional valuables and combined catalog without loading gameplay.
const OUT := "res://art/concepts/treasure-extra-v1/"
const FONT := preload("res://art/fonts/source-sans-3/SourceSans3-Variable.ttf")
var checks := 0
var failures: Array[String] = []
var captures := 0

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/items/treasure-extra-v1/catalog.json"))
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/items/treasure-v1/catalog.json"))
	check(catalog.assets.size() == 22 and catalog.new_ids.size() == 8,"Combined 22 entries with eight additions")
	check(catalog.assets.slice(0,14) == original.assets,"All original catalog entries preserved")
	var ids: Array[String] = []
	var additions: Array = []
	for entry in catalog.assets:
		check(not ids.has(entry.id),"Unique ID "+entry.id)
		ids.append(entry.id)
		check(ResourceLoader.exists(entry.icon) and ResourceLoader.exists(entry.illustration),"Existing paths "+entry.id)
		if not catalog.new_ids.has(entry.id):continue
		additions.append(entry)
		for field in ["icon","illustration"]:
			var texture: Texture2D = load(entry[field])
			var size := Vector2(64,64) if field == "icon" else Vector2(128,128)
			check(texture.get_size() == size,entry.id+" exact "+field+" canvas")
			var image := texture.get_image()
			check(not image.is_invisible(),entry.id+" nonempty "+field)
			check(image.get_pixel(0,0).a == 0 and image.get_pixel(int(size.x)-1,int(size.y)-1).a == 0,entry.id+" transparent margins "+field)
	check(additions.size() == 8,"All eight new IDs resolve")
	if "--capture" in OS.get_cmdline_user_args():await _inventory(additions)
	var report := {"godot":"4.7.2","checks":checks,"failures":failures,"captures":captures,
		"viewports":[[1280,720],[1278,590]],"icon_review_sizes":[64,40],"physical_phone_test":false,
		"scope":"Eight additional valuables and combined catalog; no price, effect, currency or room integration."}
	FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("TREASURE_EXTRA_CHECKS: ",checks," failures: ",failures.size()," captures: ",captures)
	quit(0 if failures.is_empty() else 1)

func _inventory(entries: Array) -> void:
	var canvas := Control.new()
	root.add_child(canvas)
	var background := ColorRect.new()
	canvas.add_child(background)
	var board := Control.new()
	canvas.add_child(board)
	var boxes: Array[Control] = []
	for i in entries.size():
		var x := (i%4)*180
		var y := floori(i/4.0)*176
		for small in [false,true]:
			var box := TextureRect.new()
			box.texture = load(entries[i].icon)
			box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			box.position = Vector2(x+48,y+4) if not small else Vector2(x+60,y+80)
			box.size = Vector2(64,64) if not small else Vector2(40,40)
			board.add_child(box)
			boxes.append(box)
		var label := Label.new()
		label.text = entries[i].label
		label.position = Vector2(x,y+128)
		label.size = Vector2(160,32)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font",FONT)
		label.add_theme_font_size_override("font_size",17)
		board.add_child(label)
	for phone in [false,true]:
		root.size = Vector2i(1278,590) if phone else Vector2i(1280,720)
		background.size = Vector2(root.size)
		board.position = (Vector2(root.size)-Vector2(720,352))/2
		await process_frame
		var suffix := "phone" if phone else "desktop"
		for box in boxes:
			check(Rect2(Vector2(48,12),Vector2(root.size)-Vector2(96,24)).encloses(box.get_global_rect()),"Icon safe bounds "+suffix)
		for light in [false,true]:
			background.color = Color("d6cbb4") if light else Color("1b2420")
			for child in board.get_children():
				if child is Label:child.modulate = Color("262b27") if light else Color("e6dac1")
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(OUT+"inventory-"+("light-" if light else "dark-")+suffix+".png") == OK,"Capture "+suffix)
			captures += 1
	canvas.queue_free()
	await process_frame
