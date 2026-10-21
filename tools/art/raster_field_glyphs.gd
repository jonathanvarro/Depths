extends SceneTree
## Native vector glyph export; no game state or saves are loaded.
func _initialize() -> void:
	var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/items/field-kit-v1/catalog.json"))
	for entry: Dictionary in catalogue.symbols:
		var drawing:=Image.new()
		var error:=drawing.load_svg_from_string(FileAccess.get_file_as_string(entry.source))
		assert(error==OK and drawing.get_size()==Vector2i(32,32),entry.id)
		assert(drawing.save_png(entry.icon)==OK,entry.id)
	print("FIELD_GLYPHS: eleven native 32px symbols exported")
	quit()
