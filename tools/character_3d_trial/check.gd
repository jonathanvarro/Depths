extends SceneTree
const Review=preload("res://review.tscn")
var failures: Array[String]=[]
var checks:=0
var output:=""
var app:Control

func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func settle(count:=6) -> void:
	for i in count:await process_frame
func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless" or output=="":return
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output+"/"+label+".png")==OK,"Save "+label)
	# Raw viewport captures have no UI text or fake art; same actual renderer.
	check(app.viewport.get_texture().get_image().save_png(output+"/"+label+"-render.png")==OK,"Save raw "+label)

func prepare_export(node:Node, scene_root:Node) -> void:
	node.set_script(null)
	if node!=scene_root:node.owner=scene_root
	for child in node.get_children():prepare_export(child,scene_root)

func save_native_scenes() -> void:
	if output=="":return
	app.select_state(0,1,0,0,0)
	await settle()
	for person in app.characters:
		var scene_root=person.duplicate(0)
		prepare_export(scene_root,scene_root)
		scene_root.position=Vector3.ZERO
		var packed=PackedScene.new()
		check(packed.pack(scene_root)==OK,"Pack standalone native scene")
		check(ResourceSaver.save(packed,output+"/"+person.identity+"-study.tscn")==OK,"Save native model")
		scene_root.free()

func portrait_cards() -> void:
	if DisplayServer.get_name()=="headless" or output=="":return
	var cards=SubViewport.new();cards.world_3d=app.stage.get_world_3d();cards.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(cards)
	var portrait_camera=Camera3D.new();portrait_camera.projection=Camera3D.PROJECTION_ORTHOGONAL;portrait_camera.size=.55;cards.add_child(portrait_camera);portrait_camera.current=true
	for outfit in 3:
		app.select_state(outfit,1,0,0,0)
		for person in app.characters:
			var focus=Vector3(person.position.x,1.57,0)
			portrait_camera.position=focus+Vector3(0,.015,5);portrait_camera.look_at(focus)
			for dimension in [192,96]:
				cards.size=Vector2i(dimension,dimension);await settle();await RenderingServer.frame_post_draw
				var rendered=cards.get_texture().get_image()
				var colours={}
				for x in range(0,dimension,8):
					for y in range(0,dimension,8):colours[rendered.get_pixel(x,y).to_html()]=true
				check(colours.size()>8,"Portrait contains rendered detail, not blank world")
				check(rendered.save_png(output+"/"+person.identity+"-"+str(outfit)+"-"+str(dimension)+".png")==OK,"Native card render")
	cards.queue_free();await settle(2)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):output=arg.substr(4)
	if output!="":DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,800);app=Review.instantiate();root.add_child(app);await settle()
	check(app.characters.size()==2,"Two distinct identities")
	var first=app.characters[0];var second=app.characters[1]
	check(first.identity!=second.identity,"Separate identity IDs")
	check(first.skeleton.get_bone_count()==16,"Shared sixteen-bone contract")
	for i in 16:
		check(first.skeleton.get_bone_name(i)==second.skeleton.get_bone_name(i),"Same bone "+str(i))
		check(first.skeleton.get_bone_rest(i)==second.skeleton.get_bone_rest(i),"Same rest "+str(i))
	for outfit in 3:
		for utility in 3:
			for pose in 3:
				app.select_state(outfit,utility,pose,0,0);await settle(2)
				for person in app.characters:
					for i in 3:
						for node in person.wardrobes[i]:check(node.visible==(i==outfit),"Exclusive outfit")
						for node in person.back_items[i]:check(node.visible==(i==utility),"Exclusive utility")
					check(person.prop_book.visible==(pose==2),"Reading prop state")
					check(is_equal_approx(person.skeleton.get_bone_pose_position(0).y,.91 if pose==0 else .48),"Rest-relative pelvis height")
					for i in 16:check(person.skeleton.get_bone_global_pose(i).origin.is_finite(),"Finite pose")
	for outfit in 3:
		app.select_state(outfit,outfit,0,0,1);await capture("standing-"+str(outfit))
		app.select_state(outfit,outfit,0,1,0);await capture("portrait-"+str(outfit))
		app.select_state(outfit,outfit,1,0,1);await capture("seated-"+str(outfit))
		app.select_state(outfit,outfit,2,0,1);await capture("reading-"+str(outfit))
	for utility in 3:
		app.select_state(1,utility,0,0,2);await capture("back-"+str(utility))
	root.size=Vector2i(1278,590);app.select_state(1,2,1,0,1);await settle()
	if DisplayServer.get_name()!="headless":check(root.get_texture().get_image().get_size()==root.size,"Phone capture matches actual window dimensions")
	check(app.viewport.size.y>100,"Phone viewport has usable height")
	for option in app.selectors.values():check(option.size.y>=44,"Touch control size")
	await capture("phone-1278")
	root.size=Vector2i(1334,750);app.select_state(0,1,0,1,0);await settle();await capture("phone-1334")
	first.set_expression(true,false);check(not first.eyes[0].visible and first.lids[0].visible,"Blink replaces eyes")
	first.set_expression(false,true);check(first.eyes[0].visible and not first.lids[0].visible and is_equal_approx(first.mouth.scale.y,.018),"Talk/open eye reset")
	first.set_expression(false,false);check(is_equal_approx(first.mouth.scale.y,.006),"Neutral mouth scale preserved")
	await portrait_cards()
	await save_native_scenes()
	var report={"checks":checks,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"display":DisplayServer.get_name(),"meshes_including_hidden":first.mesh_stats(),"identity_ids":[first.identity,second.identity],"combinations_per_identity":27,"note":"Original procedural rigid-part trial. No live game, assets, saves or settings loaded."}
	if output!="":var file=FileAccess.open(output+"/report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("CHARACTER3D: %d checks / %d failures"%[checks,failures.size()])
	app.queue_free();await settle(2);quit(0 if failures.is_empty() else 1)
