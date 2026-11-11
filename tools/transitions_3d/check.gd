extends SceneTree
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func settle() -> void:
	for i in 4: await process_frame
func capture(app,name: String,full := false) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image() if full else app.viewport.get_texture().get_image()
	check(image.save_png("res://captures/"+name)==OK,"Capture "+name)
	captures.append(name)
func bounds(node: Node3D) -> AABB:
	var result:=AABB()
	var first:=true
	for item: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		var piece: AABB=(node.global_transform.affine_inverse()*item.global_transform)*item.get_aabb()
		result=piece if first else result.merge(piece)
		first=false
	return result
func intersections(node: Node3D,a: Vector3,b: Vector3) -> Array[Vector3]:
	var hits: Array[Vector3]=[]
	for item: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		if item.is_in_group("ceiling"): continue
		for surface in item.mesh.get_surface_count():
			var data: Array=item.mesh.surface_get_arrays(surface)
			for i in range(0,data[Mesh.ARRAY_INDEX].size(),3):
				var v:=[]
				for j in 3: v.append(item.global_transform*data[Mesh.ARRAY_VERTEX][data[Mesh.ARRAY_INDEX][i+j]])
				var hit=Geometry3D.segment_intersects_triangle(a,b,v[0],v[1],v[2])
				if hit!=null: hits.append(hit)
	return hits
func height(node: Node3D,z: float) -> float:
	var result:=-100.0
	for hit in intersections(node,Vector3(0,2.5,z),Vector3(0,-1.1,z)): result=maxf(result,hit.y)
	return result
func signature(item: MeshInstance3D) -> String:
	var data: Array=item.mesh.surface_get_arrays(0)
	return var_to_bytes([data[Mesh.ARRAY_VERTEX],data[Mesh.ARRAY_INDEX],data[Mesh.ARRAY_TEX_UV]]).hex_encode().sha256_text()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	root.size=Vector2i(1278,590)
	var app=load("res://review.tscn").instantiate()
	root.add_child(app)
	await settle()
	for index in app.catalog.assets.size():
		app.selected=index
		app.load_prop()
		await settle()
		var entry: Dictionary=app.catalog.assets[index]
		var actual:=bounds(app.prop)
		var low:=Vector3(entry.min[0],entry.min[2],-entry.max[1])
		var high:=Vector3(entry.max[0],entry.max[2],-entry.min[1])
		check(actual.position.distance_to(low)<.0001 and actual.end.distance_to(high)<.0001,"Actual imported envelope "+entry.id)
		check(actual.size.x<=2.03 and actual.size.z<=2.03,"Fits cell/feature width and depth "+entry.id)
		check(actual.end.y<=2.41 and actual.position.y>=-.96,"Height/depth envelope "+entry.id)
		check(app.prop.find_children("*","CollisionObject3D",true,false).is_empty(),"No art collision")
		check(app.prop.find_children("*","Light3D",true,false).is_empty(),"No extra world light")
		check(not app.prop.is_processing(),"Static feature has no idle processing")
		var triangles:=0
		for item: MeshInstance3D in app.prop.find_children("*","MeshInstance3D",true,false):
			check(item.mesh.get_surface_count()==1,"One surface per component")
			var arrays: Array=item.mesh.surface_get_arrays(0)
			triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
			check(arrays[Mesh.ARRAY_VERTEX].size()==arrays[Mesh.ARRAY_TEX_UV].size(),"Palette UVs retained")
			check(item.material_override!=null and item.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"Shared material / no shadow casting")
		check(triangles==int(entry.triangles) and triangles<=2600,"Modest triangle budget "+entry.id)
		if entry.id in ["stone-up","fortress-up","stone-down","fortress-down"]:
			var front:=height(app.prop,.64)
			var back:=height(app.prop,-.64)
			check(front> -1 and back> -1,"Actual stair treads "+entry.id)
			var correct: bool=back-front>.3 if entry.direction=="up" else back-front<-.3
			check(correct,"Flight travels the expected way along -Z "+entry.id)
		if entry.floor_aperture:
			check(height(app.prop,0)<-.10,"Real recessed centre "+entry.id)
		if entry.id in ["web-intact","web-torn"]:
			var blocked:=not intersections(app.prop,Vector3(-.15,1.28,2),Vector3(-.15,1.28,-2)).is_empty()
			check(blocked==(entry.id=="web-intact"),"Torn web clears the former silk centre")
		for neutral in [false,true]:
			app.neutral=neutral
			for angle in 3:
				app.angle=angle
				app.frame_prop()
				await capture(app,"%s-%s-%d.png" % [entry.id,"neutral" if neutral else "cave",angle])
				if entry.id=="root-climb-up":
					for item: MeshInstance3D in app.prop.find_children("*","MeshInstance3D",true,false):
						if item.is_in_group("ceiling"): check(item.visible==(angle!=2),"Upward cap hides and restores for overhead")
	var geometry_reference: Array[String]=[]
	for region_index in 4:
		app.selected=app.catalog.assets.size()+region_index
		app.load_prop()
		await settle()
		var signatures: Array[String]=[]
		var shared: Material
		for item: MeshInstance3D in app.prop.find_children("*","MeshInstance3D",true,false):
			signatures.append(signature(item))
			if shared==null: shared=item.material_override
			check(item.material_override==shared,"One shared material for regional props")
			check(not item.material_override.emission_enabled,"No loot-like emission")
		if region_index==0: geometry_reference=signatures
		else: check(signatures==geometry_reference,"Same imported geometry and UVs across skins")
		check(shared.roughness>=.8 and shared.detail_uv_layer==BaseMaterial3D.DETAIL_UV_2,"Restrained regional surface")
		for neutral in [false,true]:
			app.neutral=neutral
			for angle in 3:
				app.angle=angle
				app.frame_prop()
				await capture(app,"props-%s-%s-%d.png" % [app.REGIONS[region_index],"neutral" if neutral else "cave",angle])
	for selected in [1,9,12]:
		app.selected=selected
		app.neutral=false
		app.angle=0
		app.load_prop()
		for size in [Vector2i(1278,590),Vector2i(852,393),Vector2i(667,375)]:
			root.size=size
			await settle()
			app.frame_prop()
			for control: Control in app.controls:
				var rect:=control.get_global_rect()
				check(rect.size.y>=44 and rect.end.x<=size.x-43,"Safe 44px controls "+str(size))
			check(app.viewport.size.y>=210,"Phone display height")
			await capture(app,"screen-%d-%d.png" % [selected,size.x],true)
	root.size=Vector2i(1278,590)
	await settle()
	app.floor_root.visible=false
	app.wall.visible=false
	app.stage.remove_child(app.prop)
	app.prop.queue_free()
	var cases: Array=[["stone-up","<",false],["stone-down",">",false],["fortress-down",">",true],
		["web-intact","D",false],["web-torn","D",false],["root-barrier","B",false]]
	for index in cases.size():
		var entry: Array=cases[index]
		for feature_index in app.catalog.assets.size():
			if app.catalog.assets[feature_index].id==entry[0]:
				app.selected=feature_index
				break
		var layout: PackedStringArray=["#####","##.##","##"+entry[1]+"##","##S##","#####"]
		if entry[2]: layout=["#####","#####","#S"+entry[1]+".#","#####","#####"]
		var map=load("res://scripts/dungeon_map.gd").new(layout)
		if entry[0]=="web-torn": map.doors[Vector2i(2,2)]=map.Door.OPEN
		var theme=load("res://scripts/environment_theme.gd").new()
		theme.floor_material=app.surface("floor")
		theme.wall_material=app.surface("wall")
		theme.ceiling_material=app.surface("ceiling")
		theme.ascent_scene=load(app.ART+"stone-up.tscn")
		theme.descent_scene=load(app.ART+entry[0]+".tscn") if entry[1]==">" else load(app.ART+"stone-down.tscn")
		theme.closed_scene=load(app.ART+"web-intact.tscn")
		theme.opened_scene=load(app.ART+"web-torn.tscn")
		theme.blocked_scene=load(app.ART+"root-barrier.tscn")
		var level=load("res://scripts/level_builder.gd").new()
		app.stage.add_child(level)
		level.position=Vector3(-4,0,-4)
		level.build(map,theme,2,2.4)
		await settle()
		var feature: Node3D
		for child in level.get_children():
			if child.has_meta("asset_id"): feature=child
		check(feature!=null and feature.get_meta("asset_id")==entry[0],"Actual LevelBuilder uses feature "+entry[0])
		check(is_equal_approx(feature.rotation.y,PI/2 if entry[2] else 0),"Corridor rotation preserved")
		if entry[1]==">":
			var hits:=intersections(level,Vector3(0,2.3,0),Vector3(0,-1,0))
			var maximum:=-100.0
			for hit in hits: maximum=maxf(maximum,hit.y)
			check(maximum<-.1,"Builder leaves actual stair cell floor open")
		for angle in [1,2]:
			for node: MeshInstance3D in level.find_children("*","MeshInstance3D",true,false):
				if node.is_in_group("ceiling"): node.visible=angle!=2
			app.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
			app.camera.fov=65 if angle==1 else 45
			app.camera.position=(Vector3(2.6,1.55,0) if entry[2] else Vector3(0,1.55,2.6)) if angle==1 else Vector3(.1,5,3.4)
			app.camera.look_at(Vector3(0,.55 if angle==1 else 0,0))
			await capture(app,"level-%d-%d.png" % [index,angle])
		level.free()
	var report:={"checks":checks,"failures":failures,"captures":captures,"renderer":RenderingServer.get_current_rendering_method(),
		"physical_iphone":false,"catalog_sha256":FileAccess.get_sha256(app.ART+"catalog.json"),"runtime_sha256":{}}
	for path in [app.ART+"appearance.gd",app.ART+"daylight.gdshader","res://art/materials/regional-props-v1/skins.gd","res://art/materials/regional-props-v1/catalog.json"]:
		report.runtime_sha256[path]=FileAccess.get_sha256(path)
	var file:=FileAccess.open("res://validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ")+"\n")
	print("TRANSITIONS_CHECKS ",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
