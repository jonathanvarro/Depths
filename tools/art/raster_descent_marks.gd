extends SceneTree
## Rasterize original native ornamental drawings; no game state is loaded.
func _initialize() -> void:
	for id: String in ["stranger-mark","inscription-band","seal-ornament","stranger-mark-ink"]:
		var image:=Image.new()
		var path: String="res://art/source/cave-dressing-v2/native/"+id
		assert(image.load_svg_from_string(FileAccess.get_file_as_string(path+".svg"))==OK)
		assert(image.save_png(path+".png")==OK)
	print("DESCENT_MARKS: three 128px world drawings and matching 32px ink form")
	quit()
