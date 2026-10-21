extends SceneTree
## Native SVG assets; canonical seal source remains unchanged.
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://art/source/landmarks-v1/native")
	var image := Image.new()
	assert(image.load_svg_from_string(FileAccess.get_file_as_string("res://art/source/landmarks-v1/landmark.svg")) == OK)
	assert(image.save_png("res://art/ui/backlog96-v1/map/landmark.png") == OK)
	var seal := FileAccess.get_file_as_string("res://art/symbols/crest-v1/forked-seal.svg").replace("#e8d9b0", "#b49452")
	assert(image.load_svg_from_string(seal, .34375) == OK)
	assert(image.get_size() == Vector2i(22,22))
	assert(image.save_png("res://art/source/landmarks-v1/native/banner-seal.png") == OK)
	print("LANDMARK_NATIVE: 32px cairn and exact 22px shared seal")
	quit()
