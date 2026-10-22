extends SceneTree
## Native 32px glyph rasterization only; no gameplay loaded.
func _initialize() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/ui/monsters-v1/catalog.json"))
	var count := 0
	for group: String in catalog.groups:
		for id: String in catalog.groups[group]:
			if id == "wind-up":
				continue
			var image := Image.new()
			var source: String = "res://art/source/monsters-v1/glyphs/" + group + "/" + id + ".svg"
			assert(image.load_svg_from_string(FileAccess.get_file_as_string(source)) == OK)
			assert(image.save_png(catalog.groups[group][id]) == OK)
			count += 1
	print("MONSTER_GLYPHS: %d original native 32px icons" % count)
	quit()
