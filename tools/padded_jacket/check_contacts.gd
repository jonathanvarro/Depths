extends SceneTree
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func run() -> void:
	root.size=Vector2i(1278,590)
	var app=load("res://review.tscn").instantiate();root.add_child(app)
	check(app.actors.size()==2 and app.stools.size()==2,"Both bodies and fixed seats loaded")
	for actor in app.actors:
		check(actor.skeleton!=null and actor.player!=null and actor.duration()>0,"Complete rig and sequence loaded")
	if not failures.is_empty():quit(1);return
	var anchors: Array=[]
	for seat in app.stools:anchors.append(seat.transform)
	for size in [Vector2i(1278,590),Vector2i(852,393)]:
		root.size=size
		for angle in [0,2,3]:
			app.angle_index=angle;app.selectors.angle.select(angle)
			for sample in [["approach",0],["hold-early",1],["hold-late",2],["rise-early",3],["rise-late",4]]:
				app.set_motion("chair_sequence",0,true)
				for actor in app.actors:
					var joins: Array=actor.join_times("chair_sequence")
					var times: Array=[float(joins[0])*.70,float(joins[0])+.10,
						float(joins[1])-.10,float(joins[1])+.40,float(joins[1])+.85]
					actor.set_motion("chair_sequence",times[sample[1]])
				app.frame_cameras()
				for i in 4:await process_frame
				app.time_label.text="%.2fs female · %.2fs male" % [app.actors[0].motion_time,app.actors[1].motion_time]
				await process_frame
				for i in app.actors.size():
					check(app.stools[i].transform==anchors[i],"Seat remains fixed")
					var actor=app.actors[i];var before=actor.bone_points()
					actor.set_outfit("tunic");actor.set_outfit("jacket")
					check(before==actor.bone_points(),"Swap preserves paused bones")
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://review/%s-%d-%d.png" % [sample[0],angle,size.x])
	app.set_motion("rest",0,true);app.angle_index=1;app.frame_cameras()
	for i in 4:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://review/rest-fits.png")
	app.set_garments(1);app.angle_index=3;app.frame_cameras()
	for i in 4:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://review/jacket-only-back.png")
	FileAccess.open("res://contact-native.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTACT_CHECK ",checks," failures=",failures)
	app.free();await process_frame;quit(0 if failures.is_empty() else 1)
