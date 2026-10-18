extends SceneTree
## Native Godot SVG renderer; no external rasterizer dependency.
func _initialize() -> void:
	var count := 0
	for group in ["status","intent","map"]:
		var folder: String = "res://art/source/backlog96-v1/glyphs/"+group+"/"
		var output: String = "res://art/ui/backlog96-v1/"+group+"/"
		for name in DirAccess.get_files_at(folder):
			if not name.ends_with(".svg"):continue
			var im := Image.new()
			if im.load_svg_from_string(FileAccess.get_file_as_string(folder+name)) != OK:
				push_error("SVG failed: "+name);quit(1);return
			if im.get_size()!=Vector2i(32,32) or im.save_png(output+name.trim_suffix(".svg")+".png")!=OK:
				push_error("Export failed: "+name);quit(1);return
			count+=1
	print("GLYPH_EXPORTS: ",count)
	quit(0 if count==34 else 1)
