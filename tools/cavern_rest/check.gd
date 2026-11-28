extends SceneTree
## Native imported geometry and presentation checks. No Main or player saves.
const DIR="res://art/props/cavern-rest-v1/"
const Materials=preload("res://art/materials/worked-props-v2/materials.gd")
var output: String
var checks:=0
var failures: Array[String]=[]
var captures: Array[String]=[]
var scene_costs: Dictionary={}
var world: Node3D
var stage: Node3D
var camera: Camera3D
var env: Environment
var lamp: OmniLight3D
var key: DirectionalLight3D
var caption: Label
var ground: MeshInstance3D

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func meshes(node: Node3D) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D]=[]
	for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		if mesh.is_visible_in_tree():result.append(mesh)
	return result

func points(node: Node3D) -> PackedVector3Array:
	var result:=PackedVector3Array()
	for mesh in meshes(node):
		for surface in mesh.mesh.get_surface_count():
			var vertices: PackedVector3Array=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for v in vertices:result.append(mesh.global_transform*v)
	return result

func bounds(node: Node3D) -> AABB:
	var vertices:=points(node);var box:=AABB(vertices[0],Vector3.ZERO)
	for v in vertices:box=box.expand(v)
	return box

func costs(node: Node3D) -> Vector2i:
	var count:=Vector2i.ZERO
	for mesh in meshes(node):
		for surface in mesh.mesh.get_surface_count():
			var arrays:=mesh.mesh.surface_get_arrays(surface)
			count.x+=arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX]!=null else arrays[Mesh.ARRAY_VERTEX].size()/3
			count.y+=1
	return count

func settle() -> void:
	for i in 5:await process_frame

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await settle();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"));captures.append(name+".png")

func fit(node: Node3D,neutral:=true,overview:=false) -> void:
	var box:=bounds(node);var target:=box.get_center()
	var extent:=maxf(box.size.x,maxf(box.size.y,box.size.z))
	var direction:=Vector3(.75,.85,1) if overview else Vector3(.6,.60,1)
	camera.fov=58;camera.position=target+direction.normalized()*maxf(1.3,extent*1.8);camera.look_at(target)
	for attempt in 6:
		if complete_frame(node):break
		camera.position=target+(camera.position-target)*1.12;camera.look_at(target)
	env.ambient_light_energy=.62 if neutral else .15;key.light_energy=.9 if neutral else 0
	lamp.light_energy=0 if neutral else 2.1;lamp.position=camera.position+Vector3(.3,.2,-.1);lamp.omni_range=maxf(8,extent*2)
	ground.visible=node.get_meta("asset_id","")!="cavern-rift-identity"
	ground.position.y=-.015 if node.get_meta("asset_id","")=="rest-area-approach" else minf(-.015,box.position.y-.015)
	var ground_mesh:=ground.mesh as PlaneMesh
	var ground_material:=ground.material_override as StandardMaterial3D
	var span:=8.0 if node.get_meta("asset_id","")=="rest-area-approach" else 80.0
	ground_mesh.size=Vector2(span,span);ground_material.uv1_scale=Vector3(span*.5,span*.5,1)

func complete_frame(node: Node3D) -> bool:
	for p in points(node):
		if camera.is_position_behind(p):return false
		if not Rect2(Vector2(5,34),Vector2(root.size)-Vector2(10,39)).has_point(camera.unproject_position(p)):return false
	return true

func ray_hits(node: Node3D,from: Vector3,to: Vector3) -> bool:
	for mesh in meshes(node):
		var faces:=mesh.mesh.get_faces()
		for i in range(0,faces.size(),3):
			if Geometry3D.segment_intersects_triangle(from,to,mesh.global_transform*faces[i],mesh.global_transform*faces[i+1],mesh.global_transform*faces[i+2])!=null:return true
	return false

func run() -> void:
	AudioServer.set_bus_mute(0,true)
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"catalog.json"))
	world=Node3D.new();root.add_child(world);stage=Node3D.new();world.add_child(stage)
	env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("0b151c")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("aebfc4")
	var we:=WorldEnvironment.new();we.environment=env;world.add_child(we)
	camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.near=.025;camera.far=100
	key=DirectionalLight3D.new();world.add_child(key);key.rotation_degrees=Vector3(-40,-25,0)
	lamp=OmniLight3D.new();world.add_child(lamp);lamp.light_color=Color(1,.72,.42)
	ground=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(80,80);ground.mesh=plane
	var ground_material: StandardMaterial3D=load(DIR+"cavern-floor.tres").duplicate()
	ground_material.uv1_scale=Vector3(40,40,1);ground.material_override=ground_material;world.add_child(ground)
	var layer:=CanvasLayer.new();root.add_child(layer);caption=Label.new();layer.add_child(caption);caption.position=Vector2(14,9);caption.add_theme_font_size_override("font_size",18)
	for row: Dictionary in catalog.assets:
		var node: Node3D=load(DIR+row.id+".glb").instantiate();stage.add_child(node);Materials.apply(node,Materials.make());await settle()
		var box:=bounds(node);var low:=Vector3(row.min[0],row.min[1],row.min[2]);var high:=Vector3(row.max[0],row.max[1],row.max[2])
		check(box.position.distance_to(low)<.004 and box.end.distance_to(high)<.004,"actual export bounds "+row.id)
		check(FileAccess.get_sha256(DIR+row.id+".glb")==row.sha256,"source hash "+row.id)
		var cost:=costs(node);check(cost.x==int(row.triangles) and cost.y<=4 and cost.x<5000,"imported triangle/draw budget "+row.id)
		for mesh in meshes(node):
			check(mesh.material_override!=null and mesh.cast_shadow==0,"physical materials and no shadow draw "+row.id)
			for surface in mesh.mesh.get_surface_count():
				var a:=mesh.mesh.surface_get_arrays(surface)
				check(a[Mesh.ARRAY_COLOR]!=null and a[Mesh.ARRAY_TEX_UV]!=null,"physical UV/vertex colour "+row.id)
		root.size=Vector2i(960,640);fit(node);caption.text=row.id+" · native physical export · "+str(cost.x)+" triangles"
		await shot("raw-"+row.id);node.queue_free();await settle()
	for row: Dictionary in catalog.scenes:
		var id: String=row.id;var node: Node3D=load(row.scene).instantiate()
		check(node.set_state(row.states[-1]),"pre-ready restored state "+id);node.set_motion(false);stage.add_child(node);await settle()
		check(not node.set_state("invalid"),"invalid state guarded "+id)
		check(node.find_children("*","CollisionObject3D",true,false).is_empty(),"no art-owned collision "+id)
		check(node.find_children("*","SpriteBase3D",true,false).is_empty(),"all true 3D "+id)
		for state: String in row.states:
			node.set_state(state);await settle();var cost:=costs(node);scene_costs[id+"-"+state]={"triangles":cost.x,"draws":cost.y}
			check(cost.x>0 and cost.x<120000 and cost.y<100,"whole scene budget "+id+state)
			check(node.find_children("*","Light3D",true,false).size()<=1,"at most one retained mood light "+id)
			for child: Node3D in node.find_children("*","Node3D",true,false):
				if child.has_meta("appearance_state"):check(child.visible==(child.get_meta("appearance_state")==state),"registered direct state "+id+state)
			for mesh in meshes(node):
				check(mesh.cast_shadow==0,"no extra mesh shadow draw "+id)
				var material:=mesh.material_override
				if material is ShaderMaterial:
					check(not material.shader.code.contains("ALPHA") or mesh.name.begins_with("Flame"),"only retained fire uses alpha "+id)
			root.size=Vector2i(1280,720);await settle();fit(node);caption.text=id+" · "+state+" · native neutral"
			check(complete_frame(node),"complete desktop frame "+id+state);await shot(id+"-"+state+"-neutral")
			for size in [Vector2i(1278,590),Vector2i(844,390)]:
				root.size=size;await settle();fit(node,false);caption.text=id+" · "+state+" · "+str(size.x)+"×"+str(size.y)+" / torch"
				check(complete_frame(node),"complete phone frame "+id+state+str(size.x));await shot(id+"-"+state+"-"+str(size.x))
		if row.states.size()==2:
			check(node.set_state("closed") and node.state==row.states[0],"legacy closed "+id)
			check(node.set_state("empty") and node.state==row.states[1],"legacy empty "+id)
			node.state=row.states[0];check(node.state==row.states[0],"direct state restoration "+id)
		if id in ["hide-curtain","goblin-barricade"]:
			node.set_state(row.states[0]);check(ray_hits(node,Vector3(0,1.0,1),Vector3(0,1.0,-1)),"closed visual barrier "+id)
			node.set_state(row.states[-1]);check(not ray_hits(node,Vector3(0,1.2,1),Vector3(0,1.2,-1)),"opened central clearance "+id)
		if id in ["on-to-rest","rest-to-fortress"]:
			check(ray_hits(node,Vector3(0,.2,0),Vector3(0,-.2,0)),"descent owns omitted tile landing "+id)
		if id in ["back-to-damp","rest-return"]:
			check(not ray_hits(node,Vector3(0,.2,0),Vector3(0,-.2,0)),"return retains caller floor "+id)
		if id in ["refuge-marker","rest-area-approach"]:
			for state: String in row.states:
				node.set_state(state);node.set_motion(false);await settle()
				var fire: Node3D=node.get_node("fresh/Fire")
				check(not fire.is_processing(),"fire exact still stops processing "+id+state)
				check(fire.is_visible_in_tree()==(state=="fresh"),"banked fire visibility "+id+state)
				var lamp_node: Light3D=fire.get_node("Light");var energy:=lamp_node.light_energy;await create_timer(.07).timeout
				check(is_equal_approx(energy,lamp_node.light_energy),"stable fire light "+id+state)
			if id=="refuge-marker":
				var box:=bounds(node);check(box.position.x>=-1 and box.end.x<=1 and box.position.z>=-1 and box.end.z<=1,"compact refuge fits one actual cell")
			else:
				check(not ray_hits(node,Vector3(0,.10,3),Vector3(0,.10,.6)),"rest arrival path clear of furniture")
		if id in ["cavern-rift-identity","rest-area-approach"]:
			if id=="cavern-rift-identity":
				var supports:=0
				for mesh in meshes(node):
					var faces:=mesh.mesh.get_faces();var hit_floor:=false
					for i in range(0,faces.size(),3):
						var hit=Geometry3D.segment_intersects_triangle(Vector3(-2.43,.1,.37),Vector3(-2.43,-.1,.37),mesh.global_transform*faces[i],mesh.global_transform*faces[i+1],mesh.global_transform*faces[i+2])
						if hit!=null and absf(hit.y)<.004:hit_floor=true;break
					if hit_floor:supports+=1
				check(supports==1,"rift walkway has one support surface, no coplanar floor fighting")
			node.set_state(row.states[0]);root.size=Vector2i(1278,590);ground.position.y=-.015;ground.visible=id!="cavern-rift-identity"
			env.ambient_light_energy=.32;key.light_energy=.25;lamp.light_energy=1.9;lamp.omni_range=6
			camera.fov=72
			camera.position=Vector3(-2.5,1.2,6.3) if id=="cavern-rift-identity" else Vector3(0,1.2,3.8)
			camera.look_at(Vector3(0,1.3,-4) if id=="cavern-rift-identity" else Vector3(0,.9,-1.7));lamp.position=camera.position
			caption.text=id+" · first-person art composition / no player controller";await shot(id+"-eye-height")
			root.size=Vector2i(844,390);await shot(id+"-eye-height-phone")
		node.queue_free();await settle()
	for row: Dictionary in catalog.retained_inputs:check(FileAccess.get_sha256(row.path)==row.sha256,"unchanged retained input "+row.path)
	# Exercise the actual Main prop adapter without starting its save/game loop.
	var caller=load("res://scripts/main.gd").new()
	caller._map=load("res://scripts/dungeon_map.gd").new(PackedStringArray(["#####","#S.R#","#####"]),3)
	caller._level=Node3D.new();world.add_child(caller._level)
	var rest_event=load("res://data/events/refuge_scouts.tres")
	check(rest_event.prop.resource_path==DIR+"refuge-marker.tscn","live Refuge event binds compact 3D marker")
	var actual: Node3D=caller._create_room_prop(Vector2i(3,1),rest_event);await settle()
	check(actual.position==Vector3(6,0,2) and actual.state=="fresh","actual Main factory floor registration")
	caller._empty_prop(Vector2i(3,1));await settle();check(actual.state=="used","actual saved empty state banks refuge")
	actual.set_motion(false);root.size=Vector2i(844,390);await settle();fit(actual,false)
	caption.text="Actual Main refuge prop · restored banked state / 844×390";await shot("live-refuge-restored")
	caller._level.queue_free();caller.free();await settle()
	var theme: EnvironmentTheme=load(DIR+"theme.tres")
	check(theme!=null and theme.display_name=="Cavern" and theme.wall_face_uv,"candidate theme full-face UV")
	check(theme.closed_scene.resource_path==DIR+"hide-curtain.tscn" and theme.opened_scene.resource_path==DIR+"hide-curtain-opened.tscn","candidate correct passage defaults")
	var sources: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/textures/cavern-v1/generation.json"))
	for row: Dictionary in sources.assets:
		var path: String="res://art/textures/cavern-v1/"+row.file
		var texture: Texture2D=load(path)
		check(FileAccess.get_sha256(path)==row.sha256,"unchanged generated albedo "+row.id)
		check(texture.get_width()<=512 and texture.get_height()<=512 and texture.get_image().has_mipmaps(),"bounded mipmapped texture "+row.id)
	var report:={"checks":checks,"failures":failures,"captures":captures,"scene_costs":scene_costs,"renderer":RenderingServer.get_current_rendering_method(),"live_binding":"refuge_scouts.prop URI only","elevation_prototype":false,"physical_iPhone":false}
	FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("CAVERN_REST_CHECKS=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
