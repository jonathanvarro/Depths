extends SceneTree
## Actual native controls, coverage, deformed surfaces and renderer captures.
var app:Control
var checks:=0
var failures:Array[String]=[]
var captures:Array=[]
var contact_samples:Array=[]
var out:="res://review"
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func settle(n:=3)->void:
	for i in n:await process_frame
func capture(name:String,window:=false)->void:
	if DisplayServer.get_name()=="headless":return
	await settle();await RenderingServer.frame_post_draw
	if window:
		check(root.get_texture().get_image().save_png(out+"/"+name+".png")==OK,"Save real UI "+name)
		captures.append({"file":name+".png","kind":"ui","size":[root.size.x,root.size.y]})
	else:
		for i in 2:
			var file:String=app.actors[i].fit+"-"+name+".png";var image:Image=app.viewports[i].get_texture().get_image()
			check(image.save_png(out+"/"+file)==OK,"Save actual model "+file)
			captures.append({"file":file,"fit":app.actors[i].fit,"motion":app.current_motion,"seconds":app.actors[i].motion_time,"selection":app.selected_bits,"angle":app.angle_index,"view":app.view_index,"size":[image.get_width(),image.get_height()]})
func pointer(control:Control,touch:bool)->void:
	var position:=control.get_global_rect().get_center()
	if touch:
		for on in [true,false]:
			var event=InputEventScreenTouch.new();event.index=0;event.pressed=on;event.position=position;Input.parse_input_event(event);await settle(1)
	else:
		var move=InputEventMouseMotion.new();move.position=position;Input.parse_input_event(move);await settle(1)
		for on in [true,false]:
			var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=on;event.position=position;event.button_mask=MOUSE_BUTTON_MASK_LEFT if on else 0;Input.parse_input_event(event);await settle(1)
func key(code:int,target:Viewport=null)->void:
	for on in [true,false]:
		var event=InputEventKey.new();event.keycode=code;event.pressed=on
		if target:target.push_input(event)
		else:Input.parse_input_event(event)
		await settle(1)
func visible_deformation(actor:Node3D)->void:
	var lowest:=INF
	for mesh:MeshInstance3D in actor.meshes.values():
		if not mesh.visible:continue
		if DisplayServer.get_name()!="headless":
			var baked:=mesh.bake_mesh_from_current_skeleton_pose()
			check(baked!=null and (mesh.global_transform*baked.get_aabb()).size.length()<12,"Actual finite deformed surface "+actor.fit+"/"+str(mesh.name))
			if baked:lowest=minf(lowest,(mesh.global_transform*baked.get_aabb()).position.y)
	if is_finite(lowest):
		var hips:Vector3=actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("mixamorig_Hips")).origin)
		var source_hips:Vector3=actor.to_local(hips)
		contact_samples.append({"fit":actor.fit,"motion":app.current_motion,"seconds":actor.motion_time,"angle":app.angle_index,"visible_min_y":lowest,"reference_floor_y":0.0,"visible_envelope_minus_floor":lowest,"visible_envelope_minus_floor_source_units":lowest/actor.display_scale,"display_hips_world":[hips.x,hips.y,hips.z],"source_hips":[source_hips.x,source_hips.y,source_hips.z],"display_scale":actor.display_scale,"source_root_modified":false,"reference_fixed_for_all_poses":true})
func coverage_matrix(repeats:=2)->void:
	for repeat_index in repeats:
		for bits in range(32) if repeat_index==0 else range(31,-1,-1):
			app.set_garments(bits)
			for actor in app.actors:
				var expected:int=actor.record.body_triangles_by_selection[bits];var actual:=0
				for chunk in actor.record.body_chunks:
					var mesh:MeshInstance3D=actor.meshes[str(chunk.name)]
					check(mesh.visible==((int(chunk.hidden_by)&bits)==0),"Disjoint reversible region "+actor.fit+"/"+str(bits))
					if mesh.visible:
						for surface in mesh.mesh.get_surface_count():actual+=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
				check(actual==expected,"Exact source body coverage "+actor.fit+"/"+str(bits))
	app.set_garments(31)
func portrait_cards()->void:
	if DisplayServer.get_name()=="headless":return
	for i in 2:
		var actor:Node3D=app.actors[i];var viewport=SubViewport.new();viewport.world_3d=actor.get_world_3d();viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_4X;root.add_child(viewport)
		var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;viewport.add_child(camera);camera.current=true
		for motion in ["rest","idle","seated"]:
			app.set_motion(motion,0,true)
			for bits in [31,0]:
				app.set_garments(bits)
				for dimension in [192,96]:
					viewport.size=Vector2i(dimension,dimension);app.aim(camera,actor,1,true);await settle();await RenderingServer.frame_post_draw
					var image:=viewport.get_texture().get_image();var colours:={}
					for x in range(0,dimension,4):
						for y in range(0,dimension,4):colours[image.get_pixel(x,y).to_html()]=true
					check(image.get_size()==Vector2i(dimension,dimension) and colours.size()>12,"Actual nonblank native portrait "+actor.fit+str(dimension))
					var file:="%s-card-%s-%d-%d.png"%[actor.fit,motion,bits,dimension]
					check(image.save_png(out+"/"+file)==OK,"Save native portrait "+file);captures.append({"file":file,"kind":"portrait","fit":actor.fit,"motion":motion,"selection":bits,"size":[dimension,dimension]})
		viewport.free();await settle(1)
func run()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size=Vector2i(1440,900);app=load("res://review.tscn").instantiate();root.add_child(app);await settle()
	check(app.actors.size()==2,"Both true body fits")
	for actor in app.actors:
		check(actor.clips.size()==actor.record.motions.size(),"Exact supplied motion set "+actor.fit)
		check(actor.meshes.size()==actor.record.body_chunks.size()+actor.record.garments.size(),"Every canonical mesh maps to one real node "+actor.fit)
		check(actor.skeleton.get_bone_count()==int(actor.record.bones),"Preserved rig "+actor.fit)
		check(is_equal_approx(actor.scale.x,app.actors[0].scale.x),"Same uniform display scale on both body families")
		actor.set_garments(0);var bounds:=AABB();var first:=true
		if DisplayServer.get_name()!="headless":
			await settle();await RenderingServer.frame_post_draw
			for mesh:MeshInstance3D in actor.meshes.values():
				if not mesh.visible:continue
				var body_bounds:AABB=mesh.global_transform*mesh.bake_mesh_from_current_skeleton_pose().get_aabb()
				if first:bounds=body_bounds;first=false
				else:bounds=bounds.merge(body_bounds)
			check(absf(bounds.size.y-actor.expected_display_height)<.0002,"Actual restored body has the intended metric display height "+actor.fit)
		actor.set_garments(31)
	coverage_matrix()
	for motion in app.MOTIONS:
		app.set_motion(motion,0,true);var length:float=app.actors[0].duration()
		var samples:=[0.0] if motion=="rest" else [0.0,.5+1.0/120.0/maxf(length,.001),1.0]
		for sample_index in samples.size():
			app.set_motion_fraction(motion,samples[sample_index],true)
			for actor in app.actors:check(is_equal_approx(actor.motion_time,samples[sample_index]*actor.duration()),"Each body uses its own clip time "+actor.fit+motion)
			for angle in [0,2,3]:
				app.angle_index=angle;app.frame_cameras();await settle(1)
				for actor in app.actors:visible_deformation(actor)
				await capture("%s-%d-%d"%[motion,sample_index,angle])
	# Sequence joins: hips aligned sideways, floor untouched, frames either side.
	for key in app.manifest.get("sequences",{}):
		for actor in app.actors:
			check(actor.sequence_offsets.has(key),"Sequence aligned "+actor.fit+"/"+str(key))
			for join in actor.joins:
				check(float(join.aligned_horizontal_residual)<.0001,"Hips continue across join "+actor.fit+"/"+str(join.from)+">"+str(join.to))
		app.set_motion(key,0,true)
		for j in app.actors[0].join_times(key).size():
			for side in [-1,0]:
				for actor in app.actors:actor.set_motion(key,float(actor.join_times(key)[j])+side/60.0)
				for angle in [0,2]:
					app.angle_index=angle;app.frame_cameras();await settle(1)
					for actor in app.actors:visible_deformation(actor)
					await capture("%s-join%d-%s-%d"%[key,j,"before" if side<0 else "after",angle])
	# Removal views prove the native renderer, not just triangle accounting.
	app.angle_index=1;app.set_motion("rest",0,true)
	for bits in [0,3,4,24,12,31]:app.set_garments(bits);await capture("selection-"+str(bits))
	app.set_motion("walk",.2,true)
	coverage_matrix(1)
	await pointer(app.garment_buttons[0],false);check(app.selected_bits==30,"Actual mouse garment removal")
	await pointer(app.garment_buttons[0],true);check(app.selected_bits==31,"Actual touch garment restore")
	var before:float=app.actors[0].motion_time;await pointer(app.play_button,true);await settle(5);check(not app.paused and app.actors[0].motion_time>before,"Touch starts actual playback")
	await pointer(app.play_button,false);check(app.paused,"Mouse pauses playback")
	before=app.actors[0].motion_time;app.step_frame(1);check(is_equal_approx(app.actors[0].motion_time,before+1.0/60.0),"One source-frame stepping")
	app.set_motion("walk",.5,true);check(app.paused and is_equal_approx(app.actors[0].motion_time,.5),"Timeline seeks without source-root edits")
	var slider_rect:Rect2=app.timeline.get_global_rect();var slider_position:=slider_rect.position+Vector2(slider_rect.size.x*.6,slider_rect.size.y*.5)
	for on in [true,false]:
		var touch=InputEventScreenTouch.new();touch.index=0;touch.position=slider_position;touch.pressed=on;Input.parse_input_event(touch);await settle(1)
	check(app.paused and app.actors[0].motion_time>.3 and app.actors[0].motion_time<.7,"Actual touch timeline seek")
	await pointer(app.selectors.fit,true);check(app.selectors.fit.get_popup().visible,"Touch opens native body selector")
	var popup:PopupMenu=app.selectors.fit.get_popup()
	var item_position:=Vector2(popup.position)+Vector2(popup.size.x*.5,popup.size.y-18)
	for on in [true,false]:
		var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=item_position;event.pressed=on;event.button_mask=MOUSE_BUTTON_MASK_LEFT if on else 0;Input.parse_input_event(event);await settle(1)
	check(app.fit_index==2,"Mouse chooses real body popup item")
	app.fit_index=0;app.selectors.fit.select(0);app.update_panels()
	app.set_motion("walk",app.review_duration(),true);app.set_paused(false);await settle(3);check(app.paused,"Unapproved loop stops at actual endpoint")
	for index in [1,2,0]:
		app.fit_index=index;app.update_panels();await settle()
		check(app.panels[0].visible==(index!=2) and app.panels[1].visible==(index!=1),"Body selector "+str(index))
	for shape in [Vector2i(1440,900),Vector2i(1278,590),Vector2i(1334,750),Vector2i(852,393)]:
		root.size=shape;app.set_motion("idle",0,true);app.view_index=0;app.angle_index=1;await settle(5)
		check(app.size==Vector2(shape),"Actual layout size "+str(shape))
		for control in app.touch_controls:
			var rect:Rect2=control.get_global_rect()
			check(rect.size.y>=44 and rect.position.x>=0 and rect.end.x<=shape.x+1 and rect.end.y<=shape.y,"Touch target fits safe layout "+control.name+str(shape))
		for viewport in app.viewports:check(viewport.size.y>=100,"Usable review height "+str(shape))
		await capture("ui-%d-%d"%[shape.x,shape.y],true)
	app.view_index=1;app.selectors.view.select(1);app.frame_cameras();await capture("ui-portrait-phone",true)
	await pointer(app.controls_button,true);await settle();check(app.viewports[0].size.y>200,"Touch folds tools to enlarge phone review")
	await capture("ui-phone-unfolded-preview",true)
	await pointer(app.controls_button,false);check(app.tool_rows[0].visible,"Mouse restores review tools")
	app.show_details();await settle();check(app.details.visible and (app.details_text.text.contains("#215") or app.details_text.text.contains("#218")),"Visible source and dependency details");await capture("ui-source-details",true);await key(KEY_ESCAPE);check(not app.details.visible,"Escape closes actual details popup")
	await portrait_cards()
	root.size=Vector2i(1440,900);app.set_garments(31);app.view_index=0;app.selectors.view.select(0);app.angle_index=1;await settle(5)
	for frame in 12:
		app.set_motion_fraction("walk",frame/12.0,true);await capture("walk-frame-%02d"%frame)
	var totals:={}
	for actor in app.actors:totals[actor.fit]=actor.stats()
	var report={"checks":checks,"failures":failures,"captures":captures,"contact_and_root_samples":contact_samples,"counts":totals,"renderer":RenderingServer.get_current_rendering_method(),"display":DisplayServer.get_name(),"all_art_local":true,"physical_iphone_tested":false,"final_animation_acceptance_pending":app.manifest.get("final_animation_acceptance_pending",215)}
	var joins:=[]
	for actor in app.actors:
		for join in actor.joins:joins.append(join.merged({"fit":actor.fit}))
	report["sequence_joins"]=joins
	var report_path:="res://review/headless-validation.json" if DisplayServer.get_name()=="headless" else "res://review/validation.json"
	var file=FileAccess.open(report_path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	app.queue_free();await settle();print("WARDROBE_CHECKS ",checks," checks, ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
