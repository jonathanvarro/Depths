extends SceneTree
## Native logo reuse: retain the exact existing forked-seal paths.
func _initialize() -> void:
	var source := "res://art/source/events-trinkets-v1/native/"
	DirAccess.make_dir_recursive_absolute(source)
	var svg := FileAccess.get_file_as_string("res://art/symbols/crest-v1/forked-seal.svg")
	var content := svg.substr(svg.find("<g fill="),svg.find("</svg>")-svg.find("<g fill="))
	var specs := {
		"token-seal": ["translate(40 36) rotate(-12 24 24) scale(0.75)", "#555047"],
		"cache-seal": ["translate(80.5 64.5) rotate(11 6 6) scale(0.20)", "#4d3323"],
		"cache-seal-used": ["translate(80.5 66.5) rotate(11 6 6) scale(0.20)", "#4d3323"],
	}
	for id: String in specs:
		var entry: Array=specs[id]
		var drawing := '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g transform="%s">%s</g></svg>' % [entry[0],content.replace("#e8d9b0",entry[1])]
		var file := FileAccess.open(source+id+".svg",FileAccess.WRITE)
		file.store_string(drawing);file.close()
		var image := Image.new()
		assert(image.load_svg_from_string(drawing)==OK)
		assert(image.save_png(source+id+".png")==OK)
	print("EVENT_TRINKET_SEALS: three native layers reuse the original seal paths")
	quit()
