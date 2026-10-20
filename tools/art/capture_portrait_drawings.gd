extends SceneTree
## #124: actual PortraitView drawings at native192 and party-card96, no filters.
const VIEW=preload("res://scripts/portrait_view.gd")
const OUT="res://art/concepts/portrait-drawings-v4/godot/"
var checks:=0
var failures:Array[String]=[]

func _initialize()->void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(OUT)
	call_deferred("_run")

func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func _run()->void:
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/portraits/catalog.json"))
	var entries:Array=[]
	for entry:Dictionary in catalog.portraits:
		if entry.id==entry.face_id:entries.append(entry)
	for pixels:int in [192,96]:
		var row_height:=pixels+24
		root.size=Vector2i(pixels*6,row_height*3)
		for group in 4:
			var controls:Array[Control]=[]
			for row in 3:
				var entry:Dictionary=entries[group*3+row]
				var layers:PortraitSet=load(entry.resource)
				check(layers.talk_frames.size()==(3 if entry.kind=="Unique" else 2),entry.id+" exact authored talk count")
				for col in 6:
					var label:=Label.new();root.add_child(label);controls.append(label)
					label.position=Vector2(col*pixels,row*row_height);label.add_theme_font_size_override("font_size",12)
					var state:String=["rest","half","closed","small","open","round"][col]
					label.text=entry.id+" "+state if pixels==192 else (entry.id if col==0 else state)
					if col==5 and layers.talk_frames.size()==2:
						label.text="2 talk shapes";continue
					var view=VIEW.new();root.add_child(view);controls.append(view)
					view.position=Vector2(col*pixels,row*row_height+24);view.size=Vector2(pixels,pixels)
					view.show_portrait(layers);view.set_animated(false)
					if col in [1,2]:view._eyes.texture=layers.blink_frames[col-1]
					if col>=3:view._mouth.texture=layers.talk_frames[col-3]
			await process_frame;await RenderingServer.frame_post_draw
			var image:=root.get_texture().get_image()
			check(image.get_size()==Vector2i(pixels*6,row_height*3),"Exact viewport dimensions")
			check(image.save_png(OUT+"native%d-group%d.png"%[pixels,group])==OK,"Saved actual held frame capture")
			for control in controls:control.queue_free()
			await process_frame
	var report:={"checks":checks,"failures":failures,"sizes":[192,96],"groups":4,"recruit_round":"blank labelled 2 talk shapes; never neutral fallback"}
	var file:=FileAccess.open(OUT+"card-validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("PORTRAIT_DRAWINGS checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
