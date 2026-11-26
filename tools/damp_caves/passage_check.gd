extends SceneTree
## #302: registered static passage geometry and real LevelBuilder fixtures.
const DIR="res://art/features/damp-passages-v1/"
const MAP=preload("res://scripts/dungeon_map.gd")
const BUILDER=preload("res://scripts/level_builder.gd")
var out: String
var checks:=0
var failures: Array[String]=[]
var captures: Array[String]=[]
var scene_counts: Dictionary={}
var world: Node3D
var stage: Node3D
var camera: Camera3D
var lamp: OmniLight3D
var environment: Environment
var caption: Label

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	out=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://build/damp-passages-review"
	DirAccess.make_dir_recursive_absolute(out);call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 5:await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await settle();await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	check(image!=null and image.save_png(out.path_join(name+".png"))==OK,"native capture "+name)
	captures.append(name+".png")

func meshes(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D]=[]
	for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		if mesh.is_visible_in_tree():found.append(mesh)
	return found

func bounds(node: Node3D) -> AABB:
	var result:=AABB();var first:=true
	for mesh in meshes(node):
		var part: AABB=(node.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		result=part if first else result.merge(part);first=false
	return result

func hits(node: Node3D,a: Vector3,b: Vector3) -> Array[Vector3]:
	var result: Array[Vector3]=[]
	for mesh in meshes(node):
		if mesh.is_in_group("ceiling") or mesh.name=="RouteLettering":continue
		for i in mesh.mesh.get_surface_count():
			var active:=mesh.get_active_material(i)
			if active is StandardMaterial3D and active.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:continue
			var data:=mesh.mesh.surface_get_arrays(i);var indices: PackedInt32Array=data[Mesh.ARRAY_INDEX];var points: PackedVector3Array=data[Mesh.ARRAY_VERTEX]
			for index in range(0,indices.size(),3):
				var hit=Geometry3D.segment_intersects_triangle(a,b,mesh.global_transform*points[indices[index]],mesh.global_transform*points[indices[index+1]],mesh.global_transform*points[indices[index+2]])
				if hit!=null:result.append(hit)
	return result

func floor_height(node: Node3D,x: float,z: float,top:=.10) -> float:
	var result:=-10.0
	for hit in hits(node,Vector3(x,top,z),Vector3(x,-1.0,z)):result=maxf(result,hit.y)
	return result

func central_obstruction(node: Node3D) -> int:
	var count:=0
	for y in [.2,.45,.7,.95,1.2,1.5,1.75,1.85]:
		for x in [-.6,-.4,-.2,0.0,.2,.4,.6]:
			if not hits(node,Vector3(x,y,1.5),Vector3(x,y,-1.5)).is_empty():count+=1
	return count

func floor_panels(provides_ground: bool) -> Node3D:
	var result:=Node3D.new();stage.add_child(result)
	for rect: Vector4 in [Vector4(-2,0,2,6),Vector4(2,0,2,6),Vector4(0,2,2,2),Vector4(0,-2,2,2)]:
		var mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(rect.z,rect.w);mesh.mesh=plane
		mesh.material_override=load("res://art/textures/damp-caves-v1/silt-floor.tres");mesh.position=Vector3(rect.x,-.01,rect.y);result.add_child(mesh)
	if not provides_ground:
		var mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(2,2);mesh.mesh=plane;mesh.position.y=-.012
		mesh.material_override=load("res://art/textures/damp-caves-v1/silt-floor.tres");result.add_child(mesh)
	return result

func view(angle: String,neutral: bool) -> void:
	environment.ambient_light_energy=.8 if neutral else .23;lamp.light_energy=0 if neutral else 1.8
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=65
	camera.position=Vector3(2.6,2.1,3.5) if angle=="three-quarter" else Vector3(0,1.2,2.8)
	camera.look_at(Vector3(0,.7,0) if angle=="three-quarter" else Vector3(0,1.0,0))

func run() -> void:
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"catalog.json"))
	world=Node3D.new();root.add_child(world);stage=Node3D.new();world.add_child(stage)
	environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("101a1e")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("b0c2c7")
	var env:=WorldEnvironment.new();env.environment=environment;world.add_child(env)
	camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.near=.05
	lamp=OmniLight3D.new();world.add_child(lamp);lamp.position=Vector3(.5,1.6,2);lamp.omni_range=7;lamp.light_color=Color(1,.77,.49);lamp.shadow_enabled=false
	var ui:=CanvasLayer.new();root.add_child(ui);caption=Label.new();ui.add_child(caption);caption.position=Vector2(14,10)
	caption.add_theme_font_size_override("font_size",20);caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_offset_x",2);caption.add_theme_constant_override("shadow_offset_y",2)
	for row: Dictionary in catalog.assets:
		var prop: Node3D=load(row.scene).instantiate()
		if row.states.size()>1:check(prop.set_state(row.id.get_slice("-",1)),"state can be restored before ready "+row.id)
		stage.add_child(prop);await settle()
		var actual:=bounds(prop);var low:=Vector3(row.min[0],row.min[1],row.min[2]);var high:=Vector3(row.max[0],row.max[1],row.max[2])
		check(actual.position.distance_to(low)<.002 and actual.end.distance_to(high)<.002,"actual visible engine envelope "+row.id)
		check(actual.size.x<=2.02 and actual.size.z<=2.02 and actual.end.y<=2.20 and actual.position.y>=-.94,"fits 2m / 2.2m feature cell "+row.id)
		check(FileAccess.get_sha256(row.model)==row.sha256,"export hash "+row.id)
		check(prop.find_children("*","CollisionObject3D",true,false).is_empty(),"no art collision "+row.id)
		check(prop.find_children("*","Light3D",true,false).is_empty(),"no art-owned lights "+row.id)
		check(not prop.is_processing(),"no idle processing "+row.id)
		var triangles:=0;var lettering_triangles:=0;var draws:=0
		for mesh in meshes(prop):
			check(mesh.material_override!=null and mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"material and no extra shadow draw "+row.id)
			for index in mesh.mesh.get_surface_count():
				draws+=1
				var arrays:=mesh.mesh.surface_get_arrays(index)
				var count: int=arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX]!=null else arrays[Mesh.ARRAY_VERTEX].size()/3
				if mesh.name=="RouteLettering":lettering_triangles+=count
				else:
					triangles+=count
					check(arrays[Mesh.ARRAY_COLOR]!=null and arrays[Mesh.ARRAY_TEX_UV2]!=null,"physical material/color data "+row.id)
					check(mesh.material_override is StandardMaterial3D or not mesh.material_override.shader.code.contains("ALPHA="),"opaque default material "+row.id)
		check(triangles==int(row.triangles),"actual GLB triangle count "+row.id)
		check(draws<=4 and triangles+lettering_triangles<=3200,"complete scene draw/triangle budget "+row.id)
		scene_counts[row.id]={"model_triangles":triangles,"lettering_triangles":lettering_triangles,"visible_draws":draws}
		var old_bounds:=bounds(prop);prop.set_motion(false);await settle();check(bounds(prop)==old_bounds,"exact still pose "+row.id)
		prop.set_motion(true);await settle();check(bounds(prop)==old_bounds,"static enabled pose "+row.id)
		if row.sign:
			check(prop.get_meta("destination_hint")==row.destination_hint and prop.get_meta("paired_asset")==row.paired_asset,"paired destination art metadata "+row.id)
			check(prop.sign_label==row.sign_label,"route marker label hint "+row.id)
		if row.id=="cavern-onward":
			check(floor_height(prop,0,0)<-.80,"true recessed centre, not a black floor card")
			check(absf(floor_height(prop,.92,.8))<.03,"complete shaft floor apron")
		if row.id.begins_with("hollows"):
			check((absf(floor_height(prop,0,0))<.03 if row.provides_ground else floor_height(prop,0,0)<-1.0),"crawl supplies a floor when builder omits its tile "+row.id)
			check(not hits(prop,Vector3(0,.7,.4),Vector3(0,.7,-.95)).is_empty(),"opaque recessed crawl end "+row.id)
		if row.id=="cavern-return":
			check(floor_height(prop,0,-.40,2.19)-floor_height(prop,0,.46,2.19)>.8,"rope rungs climb away toward -Z")
			var canopy: Array=prop.find_children("*","MeshInstance3D",true,false).filter(func(mesh):return mesh.is_in_group("ceiling"))
			check(not canopy.is_empty(),"upper throat tagged for overhead hide/restore")
			for mesh: MeshInstance3D in canopy:mesh.visible=false
			check(canopy.all(func(mesh):return not mesh.is_visible_in_tree()),"canopy hides in overhead view")
			for mesh: MeshInstance3D in canopy:mesh.visible=true
			check(canopy.all(func(mesh):return mesh.is_visible_in_tree()),"canopy restores for first person")
		if row.id.begins_with("curtain"):
			check(prop.set_state("intact"),"curtain accepts intact");var intact:=central_obstruction(prop)
			check(prop.set_state("opened"),"curtain accepts opened")
			check(intact>0 and central_obstruction(prop)==0,"torn curtain clears real central volume")
			check(not prop.set_state("burned") and prop.state=="opened","invalid state cannot invent an art outcome")
			prop.set_state(row.id.get_slice("-",1))
		if row.id.begins_with("siltfall"):
			prop.set_state("blocked");var blocked:=central_obstruction(prop);prop.set_state("cleared")
			check(blocked>0 and central_obstruction(prop)==0,"cleared siltfall leaves a real central opening")
			prop.set_state(row.id.get_slice("-",1))
		var floor:=floor_panels(row.provides_ground)
		for neutral in [true,false]:
			for angle: String in ["front","three-quarter"]:
				root.size=Vector2i(1280,720);view(angle,neutral);caption.text=row.id+" · "+angle+" · "+("neutral" if neutral else "torch")
				await capture(row.id+"-"+angle+"-"+("neutral" if neutral else "torch"))
		for size in [Vector2i(1278,590),Vector2i(844,390)]:
			root.size=size;view("front",false);caption.text=row.id+" · phone eye-height review";await capture(row.id+"-phone-"+str(size.x))
		floor.queue_free();prop.queue_free();await settle()
	# Actual caller placement for both corridor orientations and each feature role.
	for id: String in ["cavern-onward","cavern-return","hollows-onward","hollows-return","curtain-intact","curtain-opened","siltfall-blocked","siltfall-cleared"]:
		for east_west in [false,true]:
			var symbol: String="<" if id in ["cavern-return","hollows-return"] else ("D" if id.begins_with("curtain") else ("B" if id.begins_with("siltfall") else ">"))
			var rows: PackedStringArray=["#####","##.##","##"+symbol+"##","##S##","#####"]
			if east_west:rows=["#####","#####","#."+symbol+"S#","#####","#####"]
			var map=MAP.new(rows)
			if id=="curtain-opened":map.doors[Vector2i(2,2)]=MAP.Door.OPEN
			var theme:=EnvironmentTheme.new();theme.wall_face_uv=true
			theme.wall_material=load("res://art/textures/damp-caves-v1/limestone-wall.tres");theme.floor_material=load("res://art/textures/damp-caves-v1/silt-floor.tres");theme.ceiling_material=load("res://art/textures/damp-caves-v1/seeping-ceiling.tres")
			theme.descent_scene=load(DIR+id+".tscn");theme.ascent_scene=load(DIR+id+".tscn")
			theme.closed_scene=load(DIR+"curtain-intact.tscn");theme.opened_scene=load(DIR+"curtain-opened.tscn");theme.blocked_scene=load(DIR+id+".tscn")
			var level=BUILDER.new();stage.add_child(level);level.position=Vector3(-4,0,-4);level.build(map,theme,2,2.2);await settle()
			var feature: Node3D
			for child in level.get_children():
				if child.has_meta("asset_id"):feature=child
			check(feature!=null and feature.get_meta("asset_id")==id,"actual LevelBuilder feature "+id+str(east_west))
			check(is_equal_approx(feature.rotation.y,PI/2 if east_west else 0),"complete feature corridor rotation "+id+str(east_west))
			if id=="cavern-onward":check(floor_height(level,0,0)<-.80,"builder leaves the shaft floor open "+str(east_west))
			if id.begins_with("hollows"):check(absf(floor_height(level,0,0))<.03,"crawl apron covers omitted builder floor "+str(east_west))
			if id=="curtain-intact":
				map.doors[Vector2i(2,2)]=MAP.Door.OPEN;level.refresh_door(Vector2i(2,2));await settle()
				check(level._door_nodes[Vector2i(2,2)].get_meta("asset_id")=="curtain-opened","caller changes passage artwork")
				map.doors[Vector2i(2,2)]=MAP.Door.CLOSED;level.refresh_door(Vector2i(2,2));await settle()
			view("front",false);camera.position=Vector3(2.8,1.2,0) if east_west else Vector3(0,1.2,2.8);camera.look_at(Vector3(0,1.0,0));root.size=Vector2i(844,390);caption.text=id+" · real corridor / "+("E–W" if east_west else "N–S")
			await capture("corridor-"+id+("-ew" if east_west else "-ns"));level.queue_free();await settle()
	# Actual map glyph imports, including phone-scale rendering.
	var icons: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/ui/area-routes-v1/catalog.json"))
	var card:=ColorRect.new();card.color=Color("10181b");card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(card)
	var list:=VBoxContainer.new();list.position=Vector2(40,60);card.add_child(list)
	for row: Dictionary in icons.assets:
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",30);list.add_child(line)
		var label:=Label.new();label.text=row.id;label.custom_minimum_size=Vector2(260,40);line.add_child(label)
		var texture: Texture2D=load(row.path);check(texture.get_size()==Vector2(32,32),"native vector glyph size "+row.id)
		for size in [16,24,32]:
			var icon:=TextureRect.new();icon.texture=texture;icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(size,size);line.add_child(icon)
			var image:=texture.get_image();image.resize(size,size);var pixels:=0
			for y in size:
				for x in size:
					if image.get_pixel(x,y).a>.2:pixels+=1
			check(pixels>=size and pixels<size*size*.8,"visible transparent glyph at "+str(size)+" "+row.id)
	root.size=Vector2i(844,390);await capture("map-glyphs")
	var report:={"checks":checks,"failures":failures,"captures":captures,"scene_counts":scene_counts,"renderer":RenderingServer.get_current_rendering_method(),"physical_iPhone":false,"live_bindings_changed":false}
	FileAccess.open(out.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	world.queue_free();ui.queue_free();await settle();print("DAMP_PASSAGE_CHECKS=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
