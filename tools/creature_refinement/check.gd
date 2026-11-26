extends SceneTree
## Native skin, pose, material and first-person framing regressions for #292.
var FOLDER="res://art/enemies/creatures-refined-v2/"
const VIEW=preload("res://scripts/foe_view.gd")
var checks:=0
var failures: Array[String]=[]
var output: String

func _initialize() -> void:
	output=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://build/creature-refinement-check"
	if OS.get_cmdline_user_args().size()>1:FOLDER="res://art/enemies/"+OS.get_cmdline_user_args()[1]+"/"
	DirAccess.make_dir_recursive_absolute(output)
	Engine.set_meta("depths_settings",preload("res://scripts/settings.gd").DEFAULTS.duplicate())
	Engine.set_meta("depths_settings_loaded",true)
	preload("res://scripts/save_game.gd").set_path(output.path_join("private-test-save.dat"))
	call_deferred("run")

func check(label: String,ok: bool) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 8:await process_frame

func skin_points(actor: Node3D) -> PackedVector3Array:
	var points:=PackedVector3Array()
	var skeleton: Skeleton3D=actor.find_children("*","Skeleton3D",true,false)[0]
	skeleton.force_update_all_bone_transforms()
	for mesh: MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
		if mesh.skin==null:continue
		for surface in mesh.mesh.get_surface_count():
			var arrays:=mesh.mesh.surface_get_arrays(surface)
			var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			var influences:=weights.size()/verts.size()
			for v in verts.size():
				var point:=Vector3.ZERO
				for k in int(influences):
					var index:=v*int(influences)+k
					if weights[index]<=0:continue
					var bind:=bones[index];var bone:=mesh.skin.get_bind_bone(bind)
					if bone<0:bone=skeleton.find_bone(mesh.skin.get_bind_name(bind))
					point+=(skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bind)*verts[v])*weights[index]
				points.append(skeleton.global_transform*point)
	return points

func bounds(points: PackedVector3Array) -> AABB:
	var box:=AABB(points[0],Vector3.ZERO)
	for p in points:box=box.expand(p)
	return box

func gap(a: PackedVector3Array,b: PackedVector3Array) -> float:
	var result:=0.0
	for i in mini(a.size(),b.size()):result=maxf(result,a[i].distance_to(b[i]))
	return result

func snap(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await settle();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func eye_marks_render(foe,eye: Camera3D) -> void:
	# Catch the actual #294 transparent-fur ordering defect, which skin
	# bounds alone could not see. Inspect only projected red eye regions.
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	var capture:=root.get_texture().get_image()
	var projection:=eye.get_camera_projection()
	var view:=eye.get_camera_transform().affine_inverse()
	var points:=skin_points(foe.node);var index:=0
	var groups:=[PackedVector2Array(),PackedVector2Array()]
	for mesh: MeshInstance3D in foe.node.find_children("*","MeshInstance3D",true,false):
		if mesh.skin==null:continue
		for surface in mesh.mesh.get_surface_count():
			var colours: PackedColorArray=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
			for colour in colours:
				if colour.r>colour.g*2 and colour.r>.2:
					var local: Vector3=view*points[index]
					var clip: Vector4=projection*Vector4(local.x,local.y,local.z,1.0)
					var pixel:=Vector2((clip.x/clip.w*.5+.5)*capture.get_width(),(-clip.y/clip.w*.5+.5)*capture.get_height())
					groups[0 if foe.node.to_local(points[index]).x<0 else 1].append(pixel)
				index+=1
	for side in 2:
		var region:=Rect2(groups[side][0],Vector2.ZERO)
		for point in groups[side]:region=region.expand(point)
		region=region.grow(2)
		var visible:=0
		for y in range(maxi(0,int(region.position.y)),mini(capture.get_height(),ceili(region.end.y))):
			for x in range(maxi(0,int(region.position.x)),mini(capture.get_width(),ceili(region.end.x))):
				var colour:=capture.get_pixel(x,y)
				if colour.r>colour.g*1.6 and colour.r>colour.b*1.6 and colour.r>.12:visible+=1
		check(foe.name+" rendered eye "+str(side)+" stays visible at "+str(root.size.x),visible>0)

func run() -> void:
	if FOLDER.contains("predatory"):
		var earlier: Node3D=load("res://art/enemies/creatures-refined-v2/cave-bat.tscn").instantiate()
		var revised: Node3D=load(FOLDER+"cave-bat.tscn").instantiate()
		root.add_child(earlier);root.add_child(revised);await settle()
		for pose: String in ["idle","attack","hurt","fall"]:
			var length: float=earlier.player.get_animation(pose).length
			for step in 9:
				earlier.sample(pose,length*step/8.0);revised.sample(pose,length*step/8.0)
				check("approved flying bat unchanged "+pose+str(step),gap(skin_points(earlier),skin_points(revised))<.00001)
		earlier.queue_free();revised.queue_free();await settle()
	for id: String in ["rat","great-rat","cave-bat","whisker"]:
		var actor: Node3D=load(FOLDER+id+".tscn").instantiate();root.add_child(actor);await settle()
		var skeleton: Skeleton3D=actor.find_children("*","Skeleton3D",true,false)[0]
		check(id+" original rat / articulated bat bones",skeleton.get_bone_count()==(13 if id=="cave-bat" else 21))
		check(id+" no lights or collision",actor.find_children("*","Light3D",true,false).is_empty() and actor.find_children("*","CollisionObject3D",true,false).is_empty())
		check(id+" owns material instances",actor.surfaces.size()>=3 and actor.surfaces.all(func(m):return m is ShaderMaterial))
		var count:=0
		for mesh: MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
			if mesh.skin!=null:count+=mesh.mesh.get_faces().size()/3
		check(id+" conservative triangle budget",count<4500)
		if FOLDER.contains("predatory"):check(id+" within previous triangle budget",count<=(1226 if id=="cave-bat" else (2876 if id=="rat" else 2918)))
		var poses: PackedStringArray=actor.player.get_animation_list()
		for pose: String in poses:
			var animation: Animation=actor.player.get_animation(pose)
			var loop:=animation.loop_mode;animation.loop_mode=Animation.LOOP_NONE
			var first:=PackedVector3Array();var last:=PackedVector3Array()
			for step in 9:
				actor.sample(pose,animation.length*step/8.0);await process_frame
				var points:=skin_points(actor);var box:=bounds(points)
				check(id+" "+pose+" finite skin",box.position.is_finite() and box.size.length()<4)
				check(id+" "+pose+" floor contact",box.position.y>=-.014)
				check(id+" "+pose+" fixed tile",actor.transform==Transform3D.IDENTITY and box.position.x>=-1.05 and box.end.x<=1.05 and box.position.z>=-1.05 and box.end.z<=1.05)
				check(id+" "+pose+" declared framing contains skin",actor.framing_bounds().grow(.035).encloses(box))
				if step==0:first=points
				last=points
			if pose in ["idle","walk","run","landed"]:check(id+" "+pose+" closes without jump",gap(first,last)<.015)
			animation.loop_mode=loop
		actor.set_motion(false);actor.play("attack")
		var time: float=actor.player.current_animation_position
		await create_timer(.08).timeout
		check(id+" exact still pose",actor.player.current_animation_position==time)
		actor.set_opacity(.4);check(id+" cosmetic fade",actor.surfaces.all(func(m):return is_equal_approx(m.get_shader_parameter("opacity"),.4)))
		if id=="cave-bat":
			actor.sample("landed",0);actor.play("hurt")
			check("grounded bat keeps grounded hurt",actor.current_pose=="hurt-ground")
			actor.sample("landed",0);actor.play("fall")
			check("grounded bat keeps grounded fall",actor.current_pose=="fall-ground")
		actor.queue_free();await settle()
	# Live front-view combat, including compact phones and the Larger setting.
	for id: String in ["rat","great_rat","cave_bat"]:
		var main=load("res://scenes/main.tscn").instantiate()
		main.play_opening=false;main.use_debug_layout=true;main.wandering=false
		root.add_child(main);await create_timer(.5).timeout
		var types: Array[EnemyType]=[load("res://data/enemies/"+id+".tres")]
		var here: Vector2i=main._party.cell;var next:=here
		for direction in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			if not main._map.is_wall(here+direction):next=here+direction;break
		var group=preload("res://scripts/roamers.gd").Group.new();group.cell=next;group.types=types
		main.use_debug_layout=false;main._engaged=group;main._next_opening="party"
		var original_pitch: float=main._party.camera.rotation.x;var original_fov: float=main._party.camera.fov
		main._start_combat(next,types);await create_timer(.5).timeout
		main._combat.set_process(false)
		var foe=main._combat._state.foes[0]
		main._combat._busy[foe]=true # manual posed captures keep their sampled action
		check(id+" live 3D field binding",VIEW.is_model(foe.node) and main._combat._state.field)
		var frame_controller=main.get_children().filter(func(node):return node.get_script()==preload("res://scripts/creature_framing.gd"))[0]
		var cell_before: Vector2i=foe.cell;var position_before: Vector3=foe.node.position
		for shape in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(844,390),Vector2i(667,375)]:
			for ui_scale in [1.0,1.3]:
				root.size=shape;root.content_scale_factor=ui_scale;main.simulate_phone_safe_area=shape.x<1280;main._apply_safe_area();await settle()
				for pose: String in (["idle","attack"] if id!="cave_bat" else ["idle","landed","bite"]):
					if id=="cave_bat":
						foe.row_override="back" if pose=="idle" else "front";foe.intent=main.CombatState.Intent.SWOOP if pose=="idle" else main.CombatState.Intent.BITE
					main._combat._process(0)
					foe.node.sample(pose,.29 if pose in ["attack","bite"] else 0)
					frame_controller._process(1);await settle();frame_controller._process(1)
					main._combat._process(0) # tag follows the sampled pose and settled camera
					var eye: Camera3D=main._party.camera
					var points:=skin_points(foe.node)
					var bottom: float=main._combat._actions.global_position.y
					var lowest:=-INF;var highest:=INF
					for point in points:
						var projected:=eye.unproject_position(point)
						lowest=maxf(lowest,projected.y);highest=minf(highest,projected.y)
					var tag:="%s %s %d %.1f"%[id,pose,shape.x,ui_scale]
					check(tag+" visible above combat actions",lowest<bottom-2 and highest>=0)
					if id=="cave_bat" and pose=="landed" and FOLDER.contains("predatory"):
						var label: Button=main._combat._tags[foe]
						check(tag+" grounded tag clears model",label.get_global_rect().end.y<highest-2)
					check(tag+" camera preserves enemy cell and floor",foe.cell==cell_before and foe.node.position.is_equal_approx(position_before))
					if ui_scale==1.0:
						await snap("field-%s-%s-%d"%[id,pose,shape.x])
						if id!="cave_bat" and pose=="idle" and FOLDER.contains("predatory"):await eye_marks_render(foe,eye)
		if id=="rat":
			# Presentation probe: a taller model in the next row must stay in
			# frame when a floor-level rat asks the camera to look down.
			var tall_type: EnemyType=load("res://data/enemies/goblin.tres")
			var tall=main.CombatState.Foe.new(tall_type,"Mixed framing probe")
			tall.node=tall_type.model.instantiate();main.add_child(tall.node)
			tall.node.global_transform=foe.node.global_transform
			tall.node.global_position+=-main._party.global_basis.z*2
			tall.node.set_motion(false);tall.node.sample("idle",0)
			main._combat._state.foes.append(tall)
			frame_controller._process(1);await settle()
			for candidate in [foe,tall]:
				var mixed_box:=bounds(skin_points(candidate.node))
				var eye: Camera3D=main._party.camera
				check("mixed rat/goblin height fits "+candidate.name,eye.unproject_position(mixed_box.position).y<main._combat._actions.global_position.y and eye.unproject_position(mixed_box.end).y>=0)
			main._combat._state.foes.erase(tall);tall.node.queue_free()
		main._tactical.active=true;frame_controller._process(1)
		check(id+" leaves board camera unchanged",not frame_controller.active)
		main._tactical.active=false
		main._in_combat=false;frame_controller._process(1)
		check(id+" restores exploration camera",is_equal_approx(main._party.camera.rotation.x,original_pitch) and is_equal_approx(main._party.camera.fov,original_fov))
		main.queue_free();await settle()
	FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_iPhone":false},"  "))
	print("CREATURE_REFINEMENT checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
