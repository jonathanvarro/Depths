extends SceneTree
## Every title button stays on screen (owner, 2026-11-21: Quit fell off the
## bottom). Run at several --resolution sizes. Args: tag, screenshot dir.

const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var shots: String = args[1] if args.size() > 1 else ""
	# A save, so Continue shows too (the tallest menu).
	FileAccess.open(SaveGame.path(), FileAccess.WRITE).store_string("x")
	var title = load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	for i in 4:
		await process_frame
	var height: float = root.get_visible_rect().size.y
	var buttons: Array = title._column.find_children("*", "Button", true, false)
	var lowest: float = buttons.map(func(b): return b.get_global_rect().end.y).max()
	check("all %d buttons on screen at %s" % [buttons.size(), str(root.get_visible_rect().size)], buttons.size() >= 5 and lowest <= height, "%.0f vs %.0f" % [lowest, height])
	if shots != "":
		var image := root.get_texture().get_image()
		if image:
			image.save_png(shots + "/title_%dx%d.png" % [int(root.get_visible_rect().size.x), int(height)])
	SaveGame.delete()
	print("fails=", fails)
	quit()
