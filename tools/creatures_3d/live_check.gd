extends SceneTree
## Candidate insertion only. Production EnemyType resources/rules are untouched.
const ART:="res://art/enemies/field-creatures-3d-v1/"
const IDS:=["spider","webspinner","venom-spider","goblin"]
const TYPES:=["spider","webspinner","venom_spider","goblin"]
var checks:=0
var failures: Array[String]=[]
var captures: Array[String]=[]
var out:=""
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func snap(name: String) -> void:
	for i in 8:await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(out+"/"+name+".png")==OK,"Capture "+name);captures.append(name+".png")
func light_band(main,band: int) -> void:
	var s=main._party_state.supplies;s.glow_left=0;s.oil=0;s.torch_left=0;s.has_lantern=false;s.source=s.Source.NONE
	if band==2:s.source=s.Source.TORCH;s.torch_left=s.TORCH_BURN_TIME
	if band==3:s.source=s.Source.LANTERN;s.has_lantern=true;s.oil=s.LANTERN_CAPACITY
	s.changed.emit();s.light_band_changed.emit(s.light_band())
	await create_timer(.8).timeout
	check(s.light_band()==band,"Current light band "+str(band))
	var height: float=main._tactical._camera.global_position.y-main._party.global_position.y
	check(absf(height-float(main._tactical.CAMERA[band][0]))<.12,"Current light-aware camera "+str(band))
func run() -> void:
	out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	var Settings=load("res://scripts/settings.gd")
	Settings.set_value("tactical_view",true);Settings.set_value("flashes",false);Settings.set_value("fullscreen",false);Settings.set_value("text_size","Normal")
	root.size=Vector2i(1278,590)
	var main=load("res://scenes/main.tscn").instantiate();main.play_opening=false;main.floor_seed=11;root.add_child(main)
	await create_timer(.7).timeout
	check(not main._groups.is_empty(),"Live group available")
	if main._groups.is_empty():quit(1);return
	var group=main._groups[0]
	for side in [Vector2i.DOWN,Vector2i.UP,Vector2i.LEFT,Vector2i.RIGHT]:
		var at: Vector2i=group.cell+side*2
		if main._map.is_passable(at) and main._map.is_passable(group.cell+side):
			main._party.place(main._map,at);main._party.facing=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT].find(-side);main._party.rotation.y=-main._party.facing*PI/2;break
	group.types.clear();group.types.append(load("res://data/enemies/spider.tres"));group.noticed=true;main._engage(group)
	await create_timer(1.3).timeout
	var foe=main._combat._state.living_foes()[0]
	foe.cell=main._party.cell+main._party.DIRECTIONS[main._party.facing];main._lift_field_foes()
	for g in main._groups:
		if is_instance_valid(g.node):g.node.visible=false
	foe.node.get_node("Sprite").visible=false;main._message_label.text=""
	check(main._tactical.active,"Real tactical view active")
	for index in IDS.size():
		var id: String=IDS[index]
		foe.type=load("res://data/enemies/"+TYPES[index]+".tres");foe.name=foe.type.display_name;foe.health=foe.type.max_health
		var actor: Node3D=load(ART+id+".tscn").instantiate();foe.node.add_child(actor);actor.set_motion(false)
		foe.node.set_meta("visual_height",1.3 if id=="goblin" else .5)
		actor.look_at(Vector3(main._party.global_position.x,actor.global_position.y,main._party.global_position.z),Vector3.UP,true)
		await light_band(main,2)
		check(main._tactical.seen.has(foe.cell) and foe.node.visible,"Candidate visible on reachable tile "+id)
		for dimensions in [Vector2i(1278,590),Vector2i(852,393),Vector2i(667,375)]:
			root.size=dimensions;main.simulate_phone_safe_area=dimensions.x<1000
			for pose in ["idle","attack","hurt","fall"]:
				actor.play(pose);check(is_zero_approx(actor.position.y),"Candidate keeps floor origin "+id)
				await snap("%s-steady-%s-%d" % [id,pose,dimensions.x])
		root.size=Vector2i(852,393)
		for band in [0,3]:
			await light_band(main,band);actor.play("idle");check(foe.node.visible,"Adjacent candidate visible at band "+str(band));await snap("%s-band%d-idle-852" % [id,band])
		await light_band(main,2)
		if id in ["webspinner","venom-spider"]:
			var pose: String="web" if id=="webspinner" else "venom";actor.play(pose);await snap(id+"-steady-"+pose+"-852")
		root.size=Vector2i(1278,590);await main._tactical.exit();actor.play("idle")
		# Keep the model on the floor; do not apply the sprite-only UI lift.
		foe.node.position=Vector3(foe.cell.x*2,0,foe.cell.y*2)
		await snap(id+"-first-person-1278")
		main._tactical.enter(main,main._combat._state);await create_timer(.9).timeout
		foe.node.remove_child(actor);actor.queue_free();await process_frame
	FileAccess.open(out+"/live-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"runtime_only_insertion":true,"renderer":RenderingServer.get_current_rendering_method()},"  ")+"\n")
	print("CREATURE_LIVE ",checks," failures=",failures)
	main.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
