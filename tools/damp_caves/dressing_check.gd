extends SceneTree
## Native Mobile art inspection. No Main, saves, live placements or game RNG.
const DIR="res://art/dressing/damp-dressing-v1/"
var out: String
var checks:=0
var failures: Array[String]=[]
var captures: Array[String]=[]
var counts: Dictionary={}
var world: Node3D
var stage: Node3D
var camera: Camera3D
var lamp: OmniLight3D
var key_light: DirectionalLight3D
var environment: Environment
var caption: Label

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	out=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://build/damp-dressing-review"
	DirAccess.make_dir_recursive_absolute(out);call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 4:await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await settle();await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	check(image!=null and image.save_png(out.path_join(name+".png"))==OK,"native image "+name)
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

func signature(node: Node3D) -> String:
	var parts: Array=[]
	for mesh in meshes(node):parts.append([mesh.name,mesh.global_transform,mesh.mesh.get_rid()])
	return str(parts)

func fit(prop: Node3D,mount: String,neutral: bool) -> void:
	environment.ambient_light_energy=.55 if neutral else .26
	key_light.light_energy=.8 if neutral else 0.0
	lamp.light_energy=0.0 if neutral else 1.7
	prop.position=Vector3(0,2.2,0) if mount=="ceiling" else (Vector3(0,1.1,0) if mount=="wall" else Vector3.ZERO)
	var box:=bounds(prop);var centre:=prop.to_global(box.get_center())
	var size:=maxf(maxf(box.size.x,box.size.y),box.size.z)
	var distance:=maxf(1.15,size*1.8)
	var offset:=Vector3(.65,.42,1).normalized()*distance
	if mount in ["floor","edge"]:offset=Vector3(.5,.90,1).normalized()*distance
	if mount=="ceiling":offset=Vector3(.4,-.35,1).normalized()*distance
	camera.position=centre+offset;camera.look_at(centre);camera.fov=58
	lamp.position=centre+Vector3(.25,.6,1.4)

func plane(at: Vector3,size: Vector2,wall:=false) -> MeshInstance3D:
	var node:=MeshInstance3D.new();var mesh:=PlaneMesh.new();mesh.size=size;node.mesh=mesh;node.position=at
	if wall:node.rotation.x=PI/2
	node.material_override=load("res://art/textures/damp-caves-v1/limestone-wall.tres" if wall else "res://art/textures/damp-caves-v1/silt-floor.tres")
	stage.add_child(node);return node

func run() -> void:
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"catalog.json"))
	world=Node3D.new();root.add_child(world);stage=Node3D.new();world.add_child(stage)
	environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("111c21")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("bac7ca")
	var env:=WorldEnvironment.new();env.environment=environment;world.add_child(env)
	camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.near=.025
	lamp=OmniLight3D.new();world.add_child(lamp);lamp.omni_range=6;lamp.light_color=Color(1,.77,.49)
	key_light=DirectionalLight3D.new();world.add_child(key_light);key_light.rotation_degrees=Vector3(-35,-25,0);key_light.shadow_enabled=false
	var ui:=CanvasLayer.new();root.add_child(ui);caption=Label.new();ui.add_child(caption);caption.position=Vector2(14,10)
	caption.add_theme_font_size_override("font_size",18);caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",2);caption.add_theme_constant_override("shadow_offset_y",2)
	var material: ShaderMaterial=load(DIR+"wet.tres")
	check(not material.shader.code.contains("ALPHA=") and not material.shader.code.contains("ALPHA ="),"all solid normal surfaces use opaque depth")
	check(not material.shader.code.contains("TIME") or material.shader.code.contains("No ALPHA, TIME"),"material has no independent animation clock")
	for row: Dictionary in catalog.assets:
		var prop: Node3D=load(row.scene).instantiate()
		check(prop.set_state(row.appearance_state),"restore before ready "+row.id)
		stage.add_child(prop);await settle()
		var box:=bounds(prop);var low:=Vector3(row.min[0],row.min[1],row.min[2]);var high:=Vector3(row.max[0],row.max[1],row.max[2])
		check(box.position.distance_to(low)<.002 and box.end.distance_to(high)<.002,"actual imported metric envelope "+row.id)
		check(FileAccess.get_sha256(row.model)==row.sha256,"GLB hash "+row.id)
		check(prop.find_children("*","SpriteBase3D",true,false).is_empty(),"no billboard replacement "+row.id)
		check(prop.find_children("*","CollisionObject3D",true,false).is_empty(),"caller collision authority "+row.id)
		check(prop.find_children("*","Light3D",true,false).is_empty(),"no art light "+row.id)
		var triangles:=0;var draws:=0
		for mesh in meshes(prop):
			check(mesh.material_override==material,"shared physical surface "+row.id)
			check(mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"no extra shadow pass "+row.id)
			for surface in mesh.mesh.get_surface_count():
				var arrays:=mesh.mesh.surface_get_arrays(surface);draws+=1
				triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
				check(arrays[Mesh.ARRAY_COLOR]!=null and arrays[Mesh.ARRAY_TEX_UV2]!=null,"material family/vertex colour "+row.id)
		check(triangles==int(row.triangles) and draws==int(row.draws),"actual triangle and draw accounting "+row.id)
		check(draws==1 and triangles<=3200,"per-model mobile budget "+row.id)
		counts[row.id]={"triangles":triangles,"draws":draws}
		if row.mount=="ceiling":
			check(box.end.y<=.02 and box.position.y>=-.66,"roof envelope/head clearance "+row.id)
			check(prop.get_child(0).is_in_group("ceiling"),"ceiling hide contract "+row.id)
		if row.mount=="wall":check(box.position.z>=-.005 and box.end.z<=.30,"+Z wall mount within 30cm perimeter envelope "+row.id)
		if row.mount in ["floor","edge"]:check(box.position.y>=-.07 and box.end.y<=1.5,"floor origin/edge envelope "+row.id)
		var before:=signature(prop);prop.set_motion(true);await settle();check(signature(prop)==before,"static enabled geometry "+row.id)
		prop.set_motion(false);await settle();check(signature(prop)==before and not prop.is_processing(),"exact still pose/process off "+row.id)
		check(not prop.set_state("not-a-state") and prop.state==row.appearance_state,"reject invalid state "+row.id)
		root.size=Vector2i(960,640);fit(prop,row.mount,true);caption.text=row.id+" · neutral / "+str(triangles)+" triangles / 1 draw"
		await capture(row.id+"-neutral")
		root.size=Vector2i(844,390);fit(prop,row.mount,false);caption.text=row.id+" · phone / torch"
		await settle()
		var framing:=true
		for corner in 8:
			var point:=prop.to_global(box.get_endpoint(corner));var screen:=camera.unproject_position(point)
			framing=framing and not camera.is_position_behind(point) and Rect2(4,4,836,382).has_point(screen)
		check(framing,"complete phone framing "+row.id)
		await capture(row.id+"-phone")
		prop.queue_free();await settle()
	# Direct property assignment and interrupted restores match existing event prop use.
	for id: String in ["goblin-stash","lamp-store","three-knocks"]:
		var prop: Node3D=load(DIR+id+".tscn").instantiate();prop.state="empty";stage.add_child(prop);await settle()
		var used:=signature(prop);check(prop.state in ["empty","used"],"legacy empty setter "+id)
		prop.state="closed";await settle();check(prop.state=="fresh","legacy closed setter "+id)
		check(signature(prop)!=used,"different registered resolved geometry "+id)
		prop.set_state("empty",true);prop.set_state("closed",true);check(prop.state=="fresh","interrupted state restore "+id)
		prop.set_searched(true);check(prop.state in ["empty","used"],"searched adapter "+id)
		prop.queue_free();await settle()
	for row: Dictionary in catalog.dispositions:
		check(ResourceLoader.exists(row.damp_scene),"every leftover has a native disposition "+row.old_id)
		if row.mine_scene:
			var prop: Node3D=load(row.mine_scene).instantiate();stage.add_child(prop);await settle()
			check(meshes(prop)[0].material_override==load(DIR+"mine.tres"),"shared warmer dry material "+row.old_id)
			check(not prop.is_processing(),"dry variants idle "+row.old_id);prop.queue_free();await settle()
	# Effects: actual landing and phase reset. Defaults are motionless.
	for id: String in ["moss-curtain-lit","fungus-pulse","drip","drip-stalactite-effect"]:
		var prop: Node3D=load(DIR+id+".tscn").instantiate();stage.add_child(prop);prop.position.y=2.2 if "drip" in id or "curtain" in id else 0
		await settle();check(not prop.is_processing(),"optional effect default still "+id)
		if id in ["drip","drip-stalactite-effect"]:
			var drip=prop if id=="drip" else prop.get_node("Drip")
			prop.set_motion(true);check(drip.is_processing(),"parent effects preference reaches drip "+id);prop.set_motion(false)
			var effect_triangles:=0
			for mesh: MeshInstance3D in drip.find_children("*","MeshInstance3D",true,false):
				check(mesh.material_override is StandardMaterial3D and mesh.material_override.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,"opaque drop/ripple material "+id)
				effect_triangles+=mesh.mesh.get_faces().size()/3
			check(effect_triangles<=400,"procedural effect triangle budget "+id)
			counts[id+"-effect"]={"triangles":effect_triangles,"max_draws":2}
			drip.sample(.78);check(drip.get_node("Ripple").visible,"impact ripple "+id)
			check(absf(drip.get_node("Ripple").global_position.y-.01)<.012,"real floor landing "+id)
			drip.sample(.34);check(drip.get_node("WaterBead").visible,"falling opaque drop "+id)
			drip.set_motion(false);var initial:=signature(drip);drip.set_motion(true);await settle();drip.set_motion(false);await settle()
			check(initial==signature(drip) and not drip.is_processing(),"exact drip still reset "+id)
			camera.position=Vector3(.55,1.4,2.0);camera.look_at(Vector3(0,1.1,0));caption.text=id+" · falling bead and ripple (paused samples)"
			drip.sample(.78);await capture(id+"-impact");drip.sample(.34);await capture(id+"-fall")
		else:
			var mat: ShaderMaterial=meshes(prop)[0].material_override
			prop.set_motion(true);await settle();prop.set_motion(false);check(is_equal_approx(mat.get_shader_parameter("glow_strength"),.08),"fixed glow restored "+id)
			check(material.get_shader_parameter("glow_strength")==0.0,"optional glow cannot mutate shared wet material "+id)
		prop.queue_free();await settle()
	# Real metric room examples. Decorations stay outside the central walking strip.
	for mode: String in ["wet-room","fungal-exit-room","lost-cache","mine-conversions"]:
		var items: Array
		if mode=="wet-room":items=[["wet-flowstone",Vector3(-.54,1.12,-.98)],["mineral-seep",Vector3(.60,1.2,-.98)],
			["soda-straws",Vector3(0,2.19,-.55)],["rimstone-edge",Vector3(-.65,0,-.58)],
			["drowned-debris",Vector3(.47,0,-.68)],["puddle-wide",Vector3(0,0,.26)],["mud-bootprints",Vector3(0,0,.72)]]
		elif mode=="fungal-exit-room":items=[["exit-wall-mold",Vector3(-.54,.85,-.98)],["exit-wall-mold",Vector3(.60,1.10,-.98)],
			["exit-mushrooms",Vector3(-.57,0,-.62)],["exit-mushrooms",Vector3(.59,0,-.57)],
			["exit-floor-mold",Vector3(-.56,0,-.27)],["exit-floor-mold",Vector3(.58,0,-.22)]]
		elif mode=="lost-cache":items=[["collapsed-crates",Vector3(-.58,0,-.50)],["split-barrel",Vector3(.64,0,-.6)],
			["fallen-banner",Vector3(-.21,0,.10)],["cache-spilled-grain",Vector3(.28,0,.47)],["hanging-wet-roots",Vector3(0,2.19,-.45)]]
		else:items=[["mine-collapsed-crates",Vector3(-.58,0,-.5)],["mine-split-barrel",Vector3(.64,0,-.6)],
			["mine-chalk-arrow",Vector3(-.48,1.15,-.98)],["mine-chalk-tally",Vector3(.45,1.1,-.98)],["mine-rat-nest",Vector3(.5,0,.24)]]
		var room: Array[Node3D]=[]
		room.append(plane(Vector3(0,-.008,0),Vector2(4,5)));room.append(plane(Vector3(0,1.1,-1.0),Vector2(4,2.2),true))
		var left:=plane(Vector3(-2,1.1,.5),Vector2(5,2.2),true);left.rotation.y=PI/2;room.append(left)
		var right:=plane(Vector3(2,1.1,.5),Vector2(5,2.2),true);right.rotation.y=-PI/2;room.append(right)
		var roof:=plane(Vector3(0,2.2,0),Vector2(4,5));roof.rotation.z=PI
		roof.material_override=load("res://art/textures/damp-caves-v1/seeping-ceiling.tres");room.append(roof)
		for item: Array in items:
			var prop: Node3D=load(DIR+item[0]+".tscn").instantiate();stage.add_child(prop);prop.position=item[1];room.append(prop)
		camera.position=Vector3(.02,1.20,1.60);camera.look_at(Vector3(0,1.03,-.9));camera.fov=68;lamp.position=Vector3(.4,1.6,1.2)
		for size in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(844,390)]:
			root.size=size;caption.text=mode+" · 2m cave cell · "+str(size.x)+"×"+str(size.y)
			await capture(mode+"-"+str(size.x))
		for node in room:node.queue_free()
		await settle()
	var report:={"checks":checks,"failures":failures,"captures":captures,"scene_counts":counts,
		"renderer":RenderingServer.get_current_rendering_method(),"physical_iPhone":false,"live_bindings_changed":false}
	FileAccess.open(out.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	world.queue_free();ui.queue_free();await settle();print("DAMP_DRESSING_CHECKS=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
