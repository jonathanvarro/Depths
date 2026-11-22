extends "res://tools/mine_polish/capture.gd"
const ELITES:=preload("res://scripts/elites.gd")
var failures: Array[String]=[]
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func run() -> void:
	root.size=Vector2i(1280,720)
	for id: String in ELITES.PACKS:
		var types:=ELITES.types(id)
		var base: EnemyType=load(ELITES.ENEMIES % ELITES.PACKS[id].types[0])
		check(types[0]!=base and types[0].model!=base.model,id+" private leader resource")
		for prop in base.get_property_list():
			if prop.usage & PROPERTY_USAGE_STORAGE and prop.name not in ["model","resource_path"]:
				check(types[0].get(prop.name)==base.get(prop.name),id+" preserves "+prop.name)
		for i in range(1,types.size()):
			check(types[i]==load(ELITES.ENEMIES % ELITES.PACKS[id].types[i]),id+" unchanged follower")
		show_asset(types[0].model.resource_path)
		check(subject.attachments.size()>0,id+" bone details loaded")
		check(subject.find_children("*","CollisionObject3D",true,false).is_empty(),id+" no collision authority")
		check(subject.find_children("*","Light3D",true,false).is_empty(),id+" keeps existing patrol light")
		var original: Node3D=base.model.instantiate();stage.add_child(original);original.set_motion(false)
		var source_player: AnimationPlayer=original.find_child("AnimationPlayer",true,false)
		check(subject.player.get_animation_list()==source_player.get_animation_list(),id+" same pose inventory")
		for pose in subject.player.get_animation_list():
			if pose=="RESET":continue
			var a: Animation=subject.player.get_animation(pose)
			var b: Animation=source_player.get_animation(pose)
			check(a.length==b.length and a.get_track_count()==b.get_track_count(),id+" preserved clip "+pose)
			for seconds in [0.0,a.length*.5,a.length]:
				subject.sample(pose,seconds)
				await process_frame
				for mount: BoneAttachment3D in subject.attachments:
					var mesh: Node3D=mount.get_child(0)
					check(mesh.global_transform.origin.is_finite() and mesh.global_transform.basis.determinant()!=0,
						id+" finite attachment during "+pose)
					var rig: Skeleton3D=mount.get_parent()
					check(mount.global_transform.is_equal_approx(rig.global_transform*rig.get_bone_global_pose(mount.get_bone_idx())),
						id+" detail follows its animated bone during "+pose)
		original.free();subject.sample("idle",0)
		await snap(id+"-neutral")
		var mount: BoneAttachment3D=subject.attachments[0]
		var still:=mount.global_transform
		for i in 8:await process_frame
		check(mount.global_transform.is_equal_approx(still),id+" exact still mode")
		# Early pose requests and transformed callers must keep the same fit.
		var early: Node3D=types[0].model.instantiate()
		early.position=Vector3(2,.2,-1);early.rotation.y=.7;early.scale=Vector3.ONE*.75
		early.play("attack");early.set_motion(false);stage.add_child(early)
		check(early.current_pose=="attack" and not early.player.is_playing(),id+" pre-ready pose and still mode")
		early.sample("idle",0);await process_frame
		for i in early.attachments.size():
			check(early.attachments[i].get_child(0).transform.is_equal_approx(subject.attachments[i].get_child(0).transform),
				id+" fit independent of caller placement")
		early.free()
		for pose in ["attack","hurt","fall"]:
			if subject.player.has_animation(pose):
				subject.sample(pose,subject.player.get_animation(pose).length*(1.0 if pose=="fall" else .5))
				await snap(id+"-"+pose)
		for size in [Vector2i(844,390),Vector2i(667,375)]:
			root.size=size;show_asset(types[0].model.resource_path,"closed",false)
			await snap(id+"-phone-"+str(size.x))
		root.size=Vector2i(1280,720)
	setup(true)
	for i in ELITES.PACKS.size():
		var id: String=ELITES.PACKS.keys()[i]
		var actor: Node3D=ELITES.LEADER_MODELS[id].instantiate()
		actor.set_motion(false);actor.position.x=(i-2)*1.9;stage.add_child(actor)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5.5
	camera.position=Vector3(1.3,2.4,9);camera.look_at(Vector3(0,.6,0))
	await snap("leader-lineup")
	FileAccess.open(output.path_join("leader-validation.json"),FileAccess.WRITE).store_string(JSON.stringify(
		{"checks":checks,"failures":failures,"physical_iPhone":false},"\t"))
	print("Leader checks ",checks,"; failures ",failures.size())
	quit(0 if failures.is_empty() else 1)
