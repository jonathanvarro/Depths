extends SceneTree
## Isolated fixture: insert candidates at runtime; no game resources are changed.
var checks:=0
var failures: Array[String]=[]
var captures: Array[String]=[]
var out:=""
const RAT := "res://art/enemies/rat-3d-v1/scene.tscn"
const ART := "res://art/props/shrine-events-3d-v1/"

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func snap(name: String) -> void:
	for i in 8:await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(out+"/"+name+".png")==OK,"Capture "+name)
	captures.append(name+".png")

func run() -> void:
	var args:=OS.get_cmdline_user_args()
	out=args[0];DirAccess.make_dir_recursive_absolute(out)
	var Settings=load("res://scripts/settings.gd")
	Settings.set_value("tactical_view",true)
	Settings.set_value("text_size","Normal")
	Settings.set_value("flashes",false)
	var main=load("res://scenes/main.tscn").instantiate()
	main.play_opening=false;main.floor_seed=11;main.use_debug_layout=false
	root.size=Vector2i(1278,590);root.add_child(main)
	await create_timer(0.7).timeout
	check(not main._groups.is_empty(),"Live group available")
	if main._groups.is_empty():quit(1);return
	var group=main._groups[0]
	for side in [Vector2i.DOWN,Vector2i.UP,Vector2i.LEFT,Vector2i.RIGHT]:
		var at: Vector2i=group.cell+side*2
		if main._map.is_passable(at) and main._map.is_passable(group.cell+side):
			main._party.place(main._map,at)
			main._party.facing=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT].find(-side)
			main._party.rotation.y=-main._party.facing*PI/2.0
			break
	group.types.clear();group.types.append(load("res://data/enemies/rat.tres"))
	group.noticed=true;main._engage(group)
	await create_timer(1.3).timeout
	check(main._tactical.active,"Real tactical camera active")
	var foes: Array=main._combat._state.living_foes()
	check(foes.size()==1,"Rat only pilot fight")
	var foe=foes[0]
	var front: Vector2i=main._party.cell+main._party.DIRECTIONS[main._party.facing]
	check(main._map.is_passable(front),"Clear front tile for art comparison")
	foe.cell=front;main._lift_field_foes()
	# Clear unrelated roaming art from this controlled comparison only.
	for other in main._groups:
		if is_instance_valid(other.node):other.node.visible=false
	main._message_label.text=""
	await snap("live-board-old-1278")
	var model=load(RAT).instantiate()
	foe.node.get_node("Sprite").visible=false
	foe.node.add_child(model);model.set_motion(false)
	model.look_at(Vector3(main._party.global_position.x,model.global_position.y,main._party.global_position.z),Vector3.UP,true)
	check(model.global_position.y==0,"Rat uses live tile floor")
	for dimensions in [Vector2i(1278,590),Vector2i(852,393),Vector2i(667,375)]:
		root.size=dimensions;main.simulate_phone_safe_area=dimensions.x<1000
		for pose in ["idle","attack","hurt","fall"]:
			model.play(pose);await snap("live-board-%s-%d" % [pose,dimensions.x])
	root.size=Vector2i(1278,590)
	await main._tactical.exit();main._lift_field_foes();model.play("idle")
	await snap("live-first-person-1278")
	check(not main._tactical.active,"View restores to first person")
	# Existing event placement/restore, with duplicates of the three definitions.
	main._in_combat=false;main._combat.visible=false
	main._roamer_root.visible=false
	var landmark_cell:=Vector2i(-1,-1)
	var view_cell:=Vector2i(-1,-1)
	var direction:=Vector2i.ZERO
	for y in main._map.height:
		for x in main._map.width:
			var c:=Vector2i(x,y)
			if landmark_cell.x>=0 or not main._map.is_passable(c) or main._map.content_at(c)!=0:continue
			for side in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
				if main._map.is_wall(c+side) and main._map.is_passable(c-side):
					landmark_cell=c;view_cell=c-side;direction=side;break
	check(landmark_cell.x>=0,"Wall-backed event review cell")
	main._party.place(main._map,view_cell)
	main._party.facing=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT].find(direction)
	main._party.rotation.y=-main._party.facing*PI/2
	for entry in [["object_defiled_shrine","defiled-shrine"],["object_fouled_well","fouled-well"],["chest_buried_cache","buried-cache"]]:
		var event=load("res://data/events/"+entry[0]+".tres").duplicate()
		event.prop=load(ART+entry[1]+".tscn")
		var cell: Vector2i=landmark_cell
		var node: Node3D=main._create_room_prop(cell,event)
		check(node!=null,"Actual event placement "+entry[1])
		if event.prop_on_wall:
			check(node.position.distance_to(Vector3(cell.x*2,0,cell.y*2))>0.9,"Wall anchor applied")
		for state in ["closed","empty"]:
			node.state=state
			check(node.get_node("Spent").visible==(state=="empty"),"Actual restore state "+entry[1])
			await snap("live-%s-%s" % [entry[1],state])
		main._props.erase(cell);node.queue_free();await process_frame
	FileAccess.open(out+"/live-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"runtime_only_injection":true},"  ")+"\n")
	print("RAT_LANDMARK_LIVE ",checks," failures=",failures)
	main.queue_free();await process_frame;await process_frame
	quit(0 if failures.is_empty() else 1)
