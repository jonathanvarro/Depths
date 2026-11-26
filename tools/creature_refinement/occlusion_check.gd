extends SceneTree
## #297: compare real custom-shader surface visibility with an opaque oracle.
const FOLDER="res://art/enemies/creatures-predatory-v3/"
var out: String
var stage: Node3D
var camera: Camera3D
var checks:=0
var failures: Array[String]=[]
var legacy_leaks:=0

func _initialize() -> void:
	out=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://build/creature-occlusion"
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("run")

func check(label: String,ok: bool) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func capture(path: String="") -> Image:
	for i in 4:await process_frame
	await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	if path!="":picture.save_png(out.path_join(path+".png"))
	return picture

func masks(slots: Array,mode: String) -> void:
	for slot in slots:
		var colour: Color=Color.GREEN if slot.kind==0 else (Color.RED if slot.kind==1 else Color.BLUE)
		var material: Material
		if mode=="reference":
			var solid:=StandardMaterial3D.new();solid.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;solid.albedo_color=colour
			material=solid
		else:
			var source: ShaderMaterial=slot.material
			var code: String=source.shader.code
			if mode=="legacy":code=FileAccess.get_file_as_string(source.shader.resource_path.get_basename()+"-fade.gdshader")
			var last:=code.rfind("}")
			code=code.substr(0,last)+"ALBEDO=vec3(0.0);EMISSION=vec3(%f,%f,%f);SPECULAR=0.0;ROUGHNESS=1.0;"%[colour.r,colour.g,colour.b]+code.substr(last)
			var shader:=Shader.new();shader.code=code
			var custom:=source.duplicate() as ShaderMaterial;custom.shader=shader
			custom.render_priority=1 if mode=="legacy" and slot.kind==2 else 0
			custom.set_shader_parameter("opacity",1.0);material=custom
		slot.mesh.set_surface_override_material(slot.surface,material)

func leaks(actual: Image,reference: Image) -> int:
	var result:=0
	for y in reference.get_height():
		for x in reference.get_width():
			var expected:=reference.get_pixel(x,y)
			# A body pixel must not become a skin/claw pixel from behind it.
			if expected.g<.15 or expected.g<expected.r*1.8 or expected.g<expected.b*1.8:continue
			var pixel:=actual.get_pixel(x,y)
			if maxf(pixel.r,pixel.b)>pixel.g*1.8 and maxf(pixel.r,pixel.b)>.15:result+=1
	return result

func run() -> void:
	root.size=Vector2i(844,590)
	stage=Node3D.new();root.add_child(stage)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("252925")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_energy=.6
	stage.add_child(environment)
	var lamp:=DirectionalLight3D.new();lamp.rotation_degrees=Vector3(-40,-30,0);lamp.light_energy=1.0;stage.add_child(lamp)
	camera=Camera3D.new();camera.fov=40;stage.add_child(camera);camera.make_current()
	for id: String in ["rat","great-rat"]:
		var actor: Node3D=load(FOLDER+id+".tscn").instantiate();stage.add_child(actor)
		actor.set_motion(false);actor.contact.visible=false
		var slots:=[]
		for mesh: MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
			if mesh.skin==null:continue
			for surface in mesh.mesh.get_surface_count():
				var material: ShaderMaterial=mesh.get_active_material(surface)
				slots.append({"mesh":mesh,"surface":surface,"material":material,"kind":int(material.get_shader_parameter("surface_kind"))})
				check(id+" opaque shader",not material.shader.code.contains("ALPHA=" ) and not material.shader.code.contains("ALPHA ="))
				check(id+" ordinary depth priority",material.render_priority==0)
		var original_shaders: Array=actor.surfaces.map(func(material):return material.shader)
		for alpha in [.0,.4,.88,1.0]:
			actor.set_opacity(alpha)
			check(id+" cosmetic opacity "+str(alpha),actor.surfaces.all(func(material):return is_equal_approx(material.get_shader_parameter("opacity"),alpha)))
			for index in actor.surfaces.size():check(id+" opaque restored / fade selected",(actor.surfaces[index].shader==original_shaders[index])==(alpha==1.0))
		for pose: String in ["idle","attack","hurt"]:
			actor.sample(pose,0 if pose=="idle" else .29)
			for yaw in [0.0,40.0,90.0]:
				var target:=Vector3(0,.26 if id=="rat" else .32,0)
				camera.position=target+Vector3(sin(deg_to_rad(yaw))*2.25,.42,cos(deg_to_rad(yaw))*2.25);camera.look_at(target)
				var label:="%s-%s-%d"%[id,pose,roundi(yaw)]
				for slot in slots:slot.mesh.set_surface_override_material(slot.surface,slot.material)
				await capture(label)
				masks(slots,"reference");var reference: Image=await capture()
				masks(slots,"actual");var actual: Image=await capture()
				var leaked:=leaks(actual,reference)
				check(label+" hides rear surfaces ("+str(leaked)+" pixels)",leaked<=2)
				masks(slots,"legacy");var legacy: Image=await capture()
				legacy_leaks+=leaks(legacy,reference)
				if pose=="idle" and yaw==0:
					actual.save_png(out.path_join(id+"-opaque-mask.png"));reference.save_png(out.path_join(id+"-reference-mask.png"));legacy.save_png(out.path_join(id+"-legacy-mask.png"))
		actor.queue_free();await process_frame
	check("regression fixture exposes previous transparent ordering",legacy_leaks>20)
	FileAccess.open(out.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"legacy_leaked_pixels":legacy_leaks},"  "))
	print("CREATURE_OCCLUSION checks=",checks," failures=",failures.size()," legacy_leaks=",legacy_leaks)
	quit(0 if failures.is_empty() else 1)
