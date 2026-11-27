extends "res://tools/creature_refinement/check.gd"
## Actual imported skin, clip, floor, fade and phone art fixture. No Main lifecycle.
var world: Node3D
var camera: Camera3D
var environment: Environment
var key_light: DirectionalLight3D
var lamp: OmniLight3D
var caption: Label
var captures: Array[String]=[]
var costs: Dictionary={}

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	super._initialize()

func shot(name: String) -> void:
	await snap(name)
	if DisplayServer.get_name()!="headless":captures.append(name+".png")

func view(actor: Node3D,angle: String,neutral: bool) -> void:
	var box:=bounds(skin_points(actor));var target:=box.get_center();target.y=maxf(.16,target.y)
	var extent:=maxf(maxf(box.size.x,box.size.z),box.size.y)
	var distance:=maxf(1.4,extent*1.65)
	var direction:=Vector3(0,.36,1) if angle=="front" else (Vector3(1,.36,0) if angle=="side" else Vector3(.80,.55,1))
	camera.position=target+direction.normalized()*distance;camera.look_at(target);camera.fov=58
	environment.ambient_light_energy=.48 if neutral else .21;key_light.light_energy=.8 if neutral else 0
	lamp.light_energy=0 if neutral else 1.7;lamp.position=camera.position+Vector3(.35,.3,-.25)

func run() -> void:
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"catalog.json"))
	world=Node3D.new();root.add_child(world)
	environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("111a1e")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("b9c6c9")
	var env:=WorldEnvironment.new();env.environment=environment;world.add_child(env)
	camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.near=.03
	key_light=DirectionalLight3D.new();world.add_child(key_light);key_light.rotation_degrees=Vector3(-35,-25,0)
	lamp=OmniLight3D.new();world.add_child(lamp);lamp.omni_range=7;lamp.light_color=Color(1,.77,.49)
	var floor_node:=MeshInstance3D.new();var floor_mesh:=PlaneMesh.new();floor_mesh.size=Vector2(5,5);floor_node.mesh=floor_mesh
	floor_node.position.y=-.004;floor_node.material_override=load("res://art/textures/damp-caves-v1/silt-floor.tres");world.add_child(floor_node)
	var ui:=CanvasLayer.new();root.add_child(ui);caption=Label.new();ui.add_child(caption);caption.position=Vector2(14,10)
	caption.add_theme_font_size_override("font_size",18);caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",2);caption.add_theme_constant_override("shadow_offset_y",2)
	for row: Dictionary in catalog.assets:
		var id: String=row.id
		var actor: Node3D=load(row.scene).instantiate();actor.set_motion(false);actor.set_opacity(1.0);world.add_child(actor);await settle()
		check(id+" model-aware adapter",VIEW.is_model(actor) and VIEW.has_pose(actor,"attack"))
		check(id+" unchanged export hash",FileAccess.get_sha256(row.model)==row.sha256)
		var skeleton: Skeleton3D=actor.find_children("*","Skeleton3D",true,false)[0]
		check(id+" declared bone budget",skeleton.get_bone_count()==int(row.bones) and skeleton.get_bone_count()<=25)
		check(id+" no art light/collision",actor.find_children("*","Light3D",true,false).is_empty() and actor.find_children("*","CollisionObject3D",true,false).is_empty())
		var triangles:=0;var draws:=0
		for mesh: MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
			if mesh.skin==null:continue
			check(id+" no material override or shadow draw",mesh.material_override==null and mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
			for surface in mesh.mesh.get_surface_count():
				var arrays:=mesh.mesh.surface_get_arrays(surface);triangles+=arrays[Mesh.ARRAY_INDEX].size()/3;draws+=1
				check(id+" vertex colour/skin weights",arrays[Mesh.ARRAY_COLOR]!=null and arrays[Mesh.ARRAY_WEIGHTS]!=null)
				var material: ShaderMaterial=mesh.get_active_material(surface)
				check(id+" normal biology truly opaque",material.shader==actor.SOLID and not material.shader.code.contains("ALPHA="))
		check(id+" exact mobile mesh budget",triangles==int(row.triangles) and triangles<=3000 and draws<=4)
		costs[id]={"triangles":triangles,"skinned_draws":draws,"bones":skeleton.get_bone_count()}
		for pose: String in row.clips:
			check(id+" supplies "+pose,actor.player.has_animation(pose));var animation: Animation=actor.player.get_animation(pose)
			check(id+" exact clip length "+pose,absf(animation.length-float(row.clips[pose].frames)/24)<.002)
			var loop:=animation.loop_mode;animation.loop_mode=Animation.LOOP_NONE
			var first:=PackedVector3Array();var last:=PackedVector3Array()
			for step in 9:
				actor.sample(pose,animation.length*step/8.0);await process_frame
				var points:=skin_points(actor);var box:=bounds(points)
				check(id+" "+pose+" finite skin "+str(step),box.position.is_finite() and box.size.length()<3)
				check(id+" "+pose+" real floor "+str(step),box.position.y>=-.004 and box.position.y<=.05)
				check(id+" "+pose+" two-metre tile "+str(step),box.position.x>=-1 and box.end.x<=1 and box.position.z>=-1 and box.end.z<=1 and actor.transform==Transform3D.IDENTITY)
				check(id+" "+pose+" framing contains skin "+str(step),actor.framing_bounds().grow(.018).encloses(box))
				for join: Dictionary in row.skin_joins:
					var a:=skeleton.find_bone(join.a);var b:=skeleton.find_bone(join.b)
					var joint:=skeleton.get_bone_global_rest(b).origin
					var from_a:=skeleton.get_bone_global_pose(a)*skeleton.get_bone_global_rest(a).affine_inverse()*joint
					var from_b:=skeleton.get_bone_global_pose(b).origin
					check(id+" "+pose+" connected joint "+join.b+str(step),from_a.distance_to(from_b)<.004)
				if step==0:first=points
				last=points
			if pose in row.loops:check(id+" "+pose+" clean loop",gap(first,last)<.004)
			animation.loop_mode=loop
			actor.sample(pose,animation.length if pose in ["fall","submerge"] else animation.length*.50)
			check(id+" sampled contact follows "+pose,actor.contact.visible==(pose!="submerge"))
			root.size=Vector2i(960,640);view(actor,"three-quarter",true);caption.text=id+" · "+pose+" · neutral pose"
			await shot(id+"-"+pose)
		actor.sample("idle",0)
		for angle: String in ["front","side","three-quarter"]:
			root.size=Vector2i(1280,720);view(actor,angle,true);caption.text=id+" · "+angle+" · "+str(triangles)+" triangles / "+str(draws)+" skin draws"
			await shot(id+"-"+angle)
		for size in [Vector2i(1278,590),Vector2i(844,390),Vector2i(667,375)]:
			for pose: String in ["idle","attack","fall"]:
				var length: float=actor.player.get_animation(pose).length;actor.sample(pose,length if pose=="fall" else length*.5)
				root.size=size;view(actor,"front",false);caption.text=id+" · "+pose+" · "+str(size.x)+"×"+str(size.y)+" / torch"
				var framed:=true
				for point in skin_points(actor):
					var screen:=camera.unproject_position(point)
					if camera.is_position_behind(point) or not Rect2(Vector2(6,32),Vector2(size)-Vector2(12,38)).has_point(screen):framed=false;break
				check(id+" complete phone silhouette "+pose+str(size.x),framed);await shot(id+"-"+pose+"-"+str(size.x))
		actor.set_motion(false);VIEW.play(actor,"attack");var rest:=skin_points(actor);var time: float=actor.player.current_animation_position
		await create_timer(.09).timeout
		check(id+" adapter exact still",time==actor.player.current_animation_position and gap(rest,skin_points(actor))<.00001)
		actor.set_opacity(.40);check(id+" explicit cached fade shader",actor.surfaces.all(func(m):return m.shader==actor.FADE and is_equal_approx(m.get_shader_parameter("opacity"),.4)))
		actor.set_opacity(1);check(id+" full opacity restores real solid",actor.surfaces.all(func(m):return m.shader==actor.SOLID))
		var full_envelope: AABB=actor.framing_bounds()
		actor.play("idle");actor.play("attack");await process_frame
		check(id+" cross-fade keeps whole framing envelope",actor.framing_bounds()==full_envelope and full_envelope.grow(.018).encloses(bounds(skin_points(actor))))
		actor.sample("fall",actor.player.get_animation("fall").length);rest=skin_points(actor);actor._finished(&"fall");await process_frame
		check(id+" fall remains terminal",actor.current_pose=="fall" and gap(rest,skin_points(actor))<.00001)
		if id=="blind-crawler":
			actor._finished(&"grab");check("grab enters held loop",actor.current_pose=="hold" and actor.player.get_animation("hold").loop_mode==Animation.LOOP_LINEAR)
		if id in ["pale-newt","drowned-mother"]:
			actor._finished(&"submerge");check(id+" submerge holds under caller pool",actor.current_pose=="submerge" and bounds(skin_points(actor)).end.y<.15)
		actor.queue_free();await settle()
	# Render the native vector map and bestiary symbols at actual small sizes.
	var card:=ColorRect.new();card.color=Color("11191b");card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(card)
	var list:=VBoxContainer.new();list.position=Vector2(30,35);card.add_child(list)
	for row: Dictionary in catalog.assets:
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",24);list.add_child(line)
		var label:=Label.new();label.text=row.id;label.custom_minimum_size=Vector2(230,75);line.add_child(label)
		for size in [16,24,32,64]:
			var icon:=TextureRect.new();icon.texture=load(row.map_symbol if size<=32 else row.bestiary_thumbnail);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(size,size);line.add_child(icon)
			check(row.id+" symbol loads "+str(size),icon.texture!=null)
	root.size=Vector2i(844,390);await shot("map-bestiary-symbols")
	var report:={"checks":checks,"failures":failures,"captures":captures,"costs":costs,"renderer":RenderingServer.get_current_rendering_method(),
	 "live_bindings_changed":false,"physical_iPhone":false,"concepts_approved":true,"private_save_only":true}
	FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	world.queue_free();ui.queue_free();await settle();print("DAMP_CREATURE_CHECKS=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
