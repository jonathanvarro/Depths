extends SceneTree
## Rasterize original icon sources with Godot's native SVG renderer.
func _initialize() -> void:
	var count := 0
	var folder := "res://art/source/campaign-v1/glyphs/"
	for name in DirAccess.get_files_at(folder):
		if not name.ends_with(".svg"):continue
		var image := Image.new()
		if image.load_svg_from_string(FileAccess.get_file_as_string(folder+name))!=OK:
			push_error("Cannot rasterize "+name);quit(1);return
		if image.get_size()!=Vector2i(32,32) or image.save_png("res://art/ui/visual105-v1/"+name.trim_suffix(".svg")+".png")!=OK:
			push_error("Cannot export "+name);quit(1);return
		count+=1
	print("CAMPAIGN_GLYPHS: ",count)
	quit(0 if count==12 else 1)
