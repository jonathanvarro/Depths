extends SceneTree
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var scene_triangles := {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:
		failures.append(text)
		push_error(text)

func settle() -> void:
	for frame in 4: await process_frame

func capture(app, name: String, full := false) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image() if full else app.viewport.get_texture().get_image()
	check(image.save_png("res://captures/"+name)==OK,"Native capture "+name)
	captures.append(name)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	root.size=Vector2i(1278,590)
	var app=load("res://review.tscn").instantiate()
	root.add_child(app)
	await settle()
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(app.ART+"catalog.json"))
	for entry in catalog.assets:
		var node: Node3D=load(app.ART+entry.id+".glb").instantiate()
		root.add_child(node)
		var triangles:=0
		var bounds:=AABB()
		var first:=true
		for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
			var piece:=mesh.transform*mesh.get_aabb()
			bounds=piece if first else bounds.merge(piece)
			first=false
			check(mesh.mesh.get_surface_count()==1,"One palette surface "+str(entry.id))
			var arrays: Array=mesh.mesh.surface_get_arrays(0)
			triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
			check(arrays[Mesh.ARRAY_TEX_UV].size()==arrays[Mesh.ARRAY_VERTEX].size(),"Retained UVs "+str(entry.id))
		var low:=Vector3(entry.min[0],entry.min[2],-entry.max[1])
		var high:=Vector3(entry.max[0],entry.max[2],-entry.min[1])
		check(bounds.position.distance_to(low)<.0001 and bounds.end.distance_to(high)<.0001,"Metric bounds "+str(entry.id))
		check(triangles==int(entry.triangles),"Triangle count "+str(entry.id))
		node.queue_free()
	app.motion=false
	for index in app.IDS.size():
		app.selected=index
		app.state="empty" if index<6 else "closed"
		app.load_prop()
		await settle()
		check(app.prop.find_children("*","CollisionObject3D",true,false).is_empty(),"No collision")
		check(app.prop.find_children("*","Light3D",true,false).is_empty(),"No world light")
		var original: Transform3D=app.prop.transform
		var states: Array=["closed","open","empty"] if index<2 else ["closed","empty"]
		if index>=6: states=["closed"]
		for cave in [true,false]:
			app.cave=cave
			for angle in 3:
				app.angle=angle
				var camera_size: float=-1
				for state in states:
					app.state=state
					app.apply_state()
					check(app.prop.transform==original,"Root registration across states")
					if index<2:
						var target:=0.0 if state=="closed" else deg_to_rad(-102)
						check(is_equal_approx(app.prop.get_node("LidPivot").rotation.x,target),"Restored lid state")
						check(app.prop.get_node("Contents").visible==(state=="open"),"Contents visibility")
					if index>=2 and index<6:
						check(app.prop.get_node("Fresh").visible==(state!="empty"),"Fresh group")
						check(app.prop.get_node("Spent").visible==(state=="empty"),"Spent group")
					if camera_size<0: camera_size=app.camera.size
					check(is_equal_approx(camera_size,app.camera.size),"Consistent review scale "+str(index))
					var triangles:=0
					for mesh: MeshInstance3D in app.prop.find_children("*","MeshInstance3D",true,false):
						if mesh.is_visible_in_tree(): triangles+=mesh.mesh.get_faces().size()/3
					scene_triangles[app.IDS[index]+"-"+state]=triangles
					var name: String="%s-%s-%d-%s.png" % [app.IDS[index],"cave" if cave else "neutral",angle,state]
					await capture(app,name)
		if index<2:
			app.prop.state="closed"
			app.prop.animate_motion=true
			app.prop.state="open"
			await create_timer(.10).timeout
			var middle: float=app.prop.get_node("LidPivot").rotation.x
			check(middle<-.01 and middle>deg_to_rad(-102),"Intermediate lid motion")
			app.prop.state="closed"
			app.prop.state="empty"
			await create_timer(.36).timeout
			check(is_equal_approx(app.prop.get_node("LidPivot").rotation.x,deg_to_rad(-102)),"Interrupted motion finishes latest state")
			app.prop.state="closed"
			app.prop.set_motion(false)
			check(is_zero_approx(app.prop.get_node("LidPivot").rotation.x),"Still mode finishes immediately")
		app.prop.set_searched(true)
		check(app.prop.state=="empty","Searched API")
	app.selected=0
	app.state="open"
	app.cave=true
	app.angle=0
	app.load_prop()
	for size in [Vector2i(1278,590),Vector2i(852,393),Vector2i(667,375)]:
		root.size=size
		await settle()
		app.frame_prop()
		for control: Control in app.controls:
			var rect:=control.get_global_rect()
			check(rect.size.y>=44 and rect.end.x<=size.x-43,"Phone-safe controls "+str(size))
		check(app.viewport.size.y>=190,"Phone viewport height")
		await capture(app,"screen-%d.png" % size.x,true)
	root.size=Vector2i(1278,590)
	await settle()
	var batches: Array=[
		[["chest",Vector3(-.65,0,0),"open"],["strongbox",Vector3(.65,0,0),"empty"]],
		[["abandoned-pack",Vector3(-1.3,0,0),"empty"],["dry-alcove",Vector3(0,0,0),"closed"],["cold-camp",Vector3(1.3,0,0),"empty"]],
		[["old-workings",Vector3(-.75,0,0),"closed"],["rails-broken",Vector3(.75,0,0),"closed"]],
	]
	for batch in batches.size():
		app.stage.remove_child(app.prop)
		app.prop.queue_free()
		var group:=Node3D.new()
		app.stage.add_child(group)
		app.prop=group
		app.selected=2
		for entry in batches[batch]:
			var item=load(app.ART+entry[0]+".tscn").instantiate()
			item.animate_motion=false
			item.state=entry[2]
			item.position=entry[1]
			group.add_child(item)
		app.frame_prop()
		await capture(app,"batch-%d.png" % batch)
	var report:={"checks":checks,"failures":failures,"captures":captures,
		"scene_triangles":scene_triangles,"renderer":RenderingServer.get_current_rendering_method(),"physical_iphone":false}
	var file:=FileAccess.open("res://validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ")+"\n")
	print("EXPEDITION_CHECKS ",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
