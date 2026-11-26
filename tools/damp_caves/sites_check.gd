extends "res://tools/damp_caves/dressing_check.gd"
## E/F isolated native review; inherited capture/geometry helpers only.
const SITES="res://art/props/damp-sites-v1/"
class FaceMap:
	extends RefCounted
	var side:=Vector2i.UP
	var missing:=false
	func is_wall(cell: Vector2i) -> bool:return not missing and cell==side

func costs(node: Node3D) -> Vector2i:
	var result:=Vector2i.ZERO
	for mesh in meshes(node):
		for surface in mesh.mesh.get_surface_count():
			var arrays:=mesh.mesh.surface_get_arrays(surface)
			result.x+=arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX]!=null else arrays[Mesh.ARRAY_VERTEX].size()/3
			result.y+=1
	return result

func floor_height(node: Node3D,x: float,z: float) -> float:
	var height:=-10.0
	for mesh in meshes(node):
		var faces:=mesh.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var hit=Geometry3D.segment_intersects_triangle(Vector3(x,.10,z),Vector3(x,-1,z),
			 mesh.global_transform*faces[i],mesh.global_transform*faces[i+1],mesh.global_transform*faces[i+2])
			if hit!=null:height=maxf(height,hit.y)
	return height

func solid_checks(node: Node3D,id: String) -> void:
	check(node.find_children("*","CollisionObject3D",true,false).is_empty(),"no art collision "+id)
	check(node.find_children("*","Light3D",true,false).is_empty(),"no art light "+id)
	check(node.find_children("*","SpriteBase3D",true,false).is_empty(),"solid models "+id)
	for mesh in meshes(node):
		check(mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"no extra shadow draw "+id)
		var mat:=mesh.material_override
		var ancestor: Node=mesh
		while ancestor!=node and ancestor!=null:
			if ancestor.get_meta("physical_surface",false):
				check(mat==load("res://art/dressing/damp-dressing-v1/wet.tres"),"authored physical material replaces importer default "+id);break
			ancestor=ancestor.get_parent()
		if mat is StandardMaterial3D and mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
			check(mesh.get_meta("clear_water_surface",false) and id.begins_with("blind-fish"),"alpha isolated to viewing water "+id)
		elif mat is ShaderMaterial:
			check(not mat.shader.code.contains("ALPHA=") and not mat.shader.code.contains("ALPHA ="),"opaque body shader "+id)

func run() -> void:
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SITES+"catalog.json"))
	world=Node3D.new();root.add_child(world);stage=Node3D.new();world.add_child(stage)
	environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("10191d")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("bac7ca")
	var env:=WorldEnvironment.new();env.environment=environment;world.add_child(env)
	camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.near=.025
	lamp=OmniLight3D.new();world.add_child(lamp);lamp.omni_range=8;lamp.light_color=Color(1,.77,.49)
	key_light=DirectionalLight3D.new();world.add_child(key_light);key_light.rotation_degrees=Vector3(-35,-25,0)
	var ui:=CanvasLayer.new();root.add_child(ui);caption=Label.new();ui.add_child(caption);caption.position=Vector2(14,10)
	caption.add_theme_font_size_override("font_size",18);caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",2);caption.add_theme_constant_override("shadow_offset_y",2)
	# Native raw exports: no estimated bounds or primitive-count claims.
	for row: Dictionary in catalog.assets:
		var prop: Node3D=load(row.model).instantiate();stage.add_child(prop);await settle()
		var actual:=bounds(prop);var low:=Vector3(row.min[0],row.min[1],row.min[2]);var high:=Vector3(row.max[0],row.max[1],row.max[2])
		check(actual.position.distance_to(low)<.003 and actual.end.distance_to(high)<.003,"imported metric envelope "+row.id)
		check(FileAccess.get_sha256(row.model)==row.sha256,"export hash "+row.id)
		var count:=costs(prop);check(count==Vector2i(int(row.triangles),1),"actual model budget "+row.id)
		for mesh in meshes(prop):mesh.material_override=load("res://art/dressing/damp-dressing-v1/wet.tres")
		root.size=Vector2i(960,640);fit(prop,"floor",true);caption.text=row.id+" · solid native export"
		await capture("raw-"+row.id+"-neutral")
		prop.queue_free();await settle()
	for row: Dictionary in catalog.events:
		var prop: Node3D=load(row.scene).instantiate()
		check(prop.set_state(row.states[-1]),"pre-ready resolved state "+row.id);stage.add_child(prop);await settle()
		check(prop.set_state("closed") and prop.state==row.states[0],"legacy fresh/ready alias "+row.id)
		check(not prop.set_state("bad-state"),"reject invalid state "+row.id)
		if row.id=="slick-ledge":check(not prop.set_state("empty"),"trap requires explicit actual outcome")
		else:check(prop.set_state("empty") and prop.state==row.states[1],"two-state legacy resolved alias "+row.id)
		var state_signatures: Array=[]
		for state: String in row.states:
			prop.state=state;await settle();check(prop.state==state,"direct state property "+row.id+state)
			state_signatures.append(signature(prop));solid_checks(prop,row.id+"-"+state)
			var count:=costs(prop);check(count.x<=8500 and count.y<=8,"whole event draw budget "+row.id+state)
			counts[row.id+"-"+state]={"triangles":count.x,"draws":count.y,"bounds":str(bounds(prop))}
			var b:=bounds(prop);prop.set_motion(true);await settle();prop.set_motion(false);await settle()
			check(bounds(prop)==b and not prop.is_processing(),"exact still restore "+row.id+state)
			root.size=Vector2i(960,640);fit(prop,"floor",true);caption.text=row.id+" · "+state+" · native neutral"
			await capture(row.id+"-"+state+"-neutral")
			root.size=Vector2i(844,390);fit(prop,"floor",false);caption.text=row.id+" · "+state+" · phone / torch"
			var framed:=true
			for corner in 8:
				var point:=prop.to_global(b.get_endpoint(corner));var screen:=camera.unproject_position(point)
				framed=framed and Rect2(4,4,836,382).has_point(screen) and not camera.is_position_behind(point)
			check(framed,"complete phone framing "+row.id+state);await capture(row.id+"-"+state+"-phone")
			if state==row.states[0]:root.size=Vector2i(1278,590);await capture(row.id+"-1278")
		check(state_signatures[0]!=state_signatures[1],"resolved visual changes "+row.id)
		prop.set_state(row.states[1],true);prop.set_state(row.states[0],true);check(prop.state==row.states[0],"interrupted restore "+row.id)
		if row.id=="blind-fish":
			for node: Node3D in prop.find_children("*","Node3D",true,false):
				if node.get_meta("swimming_fish",false):
					var fish_bounds:=bounds(node)
					check(node.to_global(fish_bounds.position).y>.01 and node.to_global(fish_bounds.end).y<.09,"opaque fish fits below water and above silt")
			prop.set_motion(false);var rest:=signature(prop);prop.sample(2.0);check(signature(prop)!=rest,"school actually moves")
			prop.set_motion(false);check(signature(prop)==rest,"fish exact rest")
			prop.set_motion(true);prop.set_state("fished");check(not prop.is_processing(),"no swimming work after fishing")
		if row.id=="slick-ledge":
			check(floor_height(prop,-.60,0)>.0,"safe ledge has real support")
			check(floor_height(prop,.60,0)<-.50,"actual recessed drop stays open")
		if row.id=="seep":
			var map:=FaceMap.new()
			for side: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
				map.side=side;check(prop.mount_in_cell(map,Vector2i.ZERO,2.0),"real wall found "+str(side))
				var mount: Node3D=prop.get_node("Mount")
				check(mount.position.distance_to(Vector3(side.x,0,side.y)*.988)<.001,"actual face anchor "+str(side))
				check(mount.basis.z.dot(Vector3(-side.x,0,-side.y))>.999,"+Z faces inward "+str(side))
			map.missing=true;check(not prop.mount_in_cell(map,Vector2i.ZERO,2) and not prop.visible,"no floating unmounted seep")
			map.missing=false;check(prop.mount_in_cell(map,Vector2i.ZERO,2) and prop.visible,"restore valid mount")
		prop.queue_free();await settle()
	# Full landmark compositions in metric rooms, plus a neutral overview.
	for row: Dictionary in catalog.landmarks:
		var prop: Node3D=load(row.scene).instantiate();stage.add_child(prop);await settle();solid_checks(prop,row.id)
		var count:=costs(prop);counts[row.id]={"triangles":count.x,"draws":count.y,"bounds":str(bounds(prop))}
		check(count.x<=22000 and count.y<=36,"whole landmark budget "+row.id)
		var b:=bounds(prop);check(b.position.y>=-.15 and b.end.y<=2.2,"floor/ceiling metric envelope "+row.id)
		var width: float=row.room_cells[0]*2.0;var depth: float=row.room_cells[1]*2.0
		check(b.position.x>=-width/2-.01 and b.end.x<=width/2+.01 and b.position.z>=-depth/2-.02 and b.end.z<=depth/2+.02,"fits advertised room "+row.id)
		var before:=signature(prop);prop.set_motion(true);await settle();prop.set_motion(false);await settle()
		check(signature(prop)==before and not prop.is_processing(),"landmark child effects reset "+row.id)
		check(prop.find_children("*","Marker3D",true,false).size()>=1,"separate caller interaction/approach anchors "+row.id)
		var room: Array[Node3D]=[];room.append(plane(Vector3(0,-.008,0),Vector2(width,depth)))
		var walls: Array[Node3D]=[]
		walls.append(plane(Vector3(0,1.1,-depth/2),Vector2(width,2.2),true))
		var left:=plane(Vector3(-width/2,1.1,0),Vector2(depth,2.2),true);left.rotation.y=PI/2;walls.append(left)
		var right:=plane(Vector3(width/2,1.1,0),Vector2(depth,2.2),true);right.rotation.y=-PI/2;walls.append(right)
		var roof:=plane(Vector3(0,2.2,0),Vector2(width,depth));roof.rotation.z=PI;walls.append(roof)
		camera.position=Vector3(-.10,1.2,depth/2-.5);camera.look_at(Vector3(0,.98,-depth/2));camera.fov=68
		environment.ambient_light_energy=.30;key_light.light_energy=0;lamp.position=camera.position+Vector3(.25,.35,-.2);lamp.omni_range=9;lamp.light_energy=2.0
		for size in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(844,390)]:
			root.size=size;caption.text=row.id+" · "+str(size.x)+"×"+str(size.y)+" · metric room / torch"
			await capture(row.id+"-"+str(size.x))
		for wall in walls:wall.hide()
		root.size=Vector2i(1280,720);environment.ambient_light_energy=.55;key_light.light_energy=.8;lamp.light_energy=0
		camera.position=Vector3(width*.95,5.2,depth*.80);camera.look_at(Vector3(0,.3,-.4));caption.text=row.id+" · neutral layout overview"
		await capture(row.id+"-overview")
		prop.queue_free()
		for node in room+walls:node.queue_free()
		await settle()
	var report:={"checks":checks,"failures":failures,"captures":captures,"scene_counts":counts,
	 "renderer":RenderingServer.get_current_rendering_method(),"physical_iPhone":false,"live_bindings_changed":false}
	FileAccess.open(out.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	world.queue_free();ui.queue_free();await settle();print("DAMP_SITES_CHECKS=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
