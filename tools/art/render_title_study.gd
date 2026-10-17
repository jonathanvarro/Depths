extends SceneTree
## Capture the optional title/type study; leave project.godot unchanged.
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	assert(ok,message)
	checks += 1

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for font_path in ["title-cinzel", "heading-cinzel", "body-source-sans", "action-source-sans"]:
		var font: FontVariation = load("res://art/fonts/"+font_path+".tres")
		check(font != null and font.base_font != null,"Bundled font loads")
		for ch in "DEPTHS Pack 0123456789 Il1 O0 — × %":
			check(font.has_char(ch.unicode_at(0)),"Glyph coverage: "+ch)
	for mode in ["desktop", "phone", "specimen"]:
		root.size = Vector2i(1278,590) if mode == "phone" else Vector2i(1280,720)
		var node = load("res://art/title/title-v1/preview.tscn").instantiate()
		node.phone_preview = mode == "phone"
		node.specimen = mode == "specimen"
		root.add_child(node)
		await create_timer(0.25).timeout
		for control: Control in node.text_controls:
			var rect := control.get_global_rect()
			check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= root.size.x and rect.end.y <= root.size.y,"Text/control within viewport")
			if control is Button:
				check(rect.size.y >= 56,"Menu target height")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art/title/title-v1/title-"+mode+".png")
		node.queue_free()
		await process_frame
	print("TITLE_TYPE_CHECKS_PASSED: ",checks)
	quit()
