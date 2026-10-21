extends SceneTree
## Render editable SVG source through Godot's own lossless importer.
func _initialize() -> void:
	for id in ["experience", "level-up", "danger-light", "object-light", "down-light"]:
		var image := Image.new()
		assert(image.load_svg_from_string(FileAccess.get_file_as_string("res://art/source/results-v1/" + id + ".svg")) == OK)
		assert(image.get_size() == Vector2i(32,32))
		assert(image.save_png("res://art/ui/results-v1/" + id + ".png") == OK)
	print("RESULTS_GLYPHS: five 32px transparent glyphs")
	quit()
