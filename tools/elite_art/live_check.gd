extends SceneTree
const ELITES:=preload("res://scripts/elites.gd")
const VIEW:=preload("res://scripts/foe_view.gd")
var failures: Array[String]=[]
var checks:=0
var output: String
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func snap(name: String) -> void:
	for i in 8:await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"capture "+name)
func run() -> void:
	output=OS.get_cmdline_user_args()[0]
	var settings=load("res://scripts/settings.gd")
	settings.set_value("fullscreen",false);settings.set_value("enemy_models",true)
	settings.set_value("view_above",false);settings.set_value("flashes",false)
	for id: String in ELITES.PACKS:
		root.size=Vector2i(1280,720)
		var main=load("res://scenes/main.tscn").instantiate()
		main.play_opening=false;main.floor_seed=900;main.wandering=false
		root.add_child(main);await create_timer(.5).timeout
		main._clear_groups();await process_frame
		var cell:=Vector2i(-1,-1);var near:=cell
		for at: Vector2i in main._map.walking_distances(main._party.cell):
			if not main._map._is_room_cell(at):continue
			for side in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
				if main._map.is_passable(at+side) and main._map.is_passable(at+side*2) and main._map.door_at(at+side)==0:
					cell=at;near=at+side*2;break
			if cell.x>=0:break
		check(cell.x>=0,"review room available")
		main._party.place(main._map,near);main._face_toward(near+(cell-near)/2)
		main._map.reveal_around(near,3)
		main._map.marks["elite"]={"id":id,"cell":cell,"beaten":false}
		main._spawn_elite()
		var group=main._groups[0]
		check(VIEW.is_model(group.node) and group.node.attachments.size()>0,id+" production patrol variant")
		check(group.node.get_node_or_null("EliteGlow")!=null,id+" existing pack glow")
		await snap(id+"-patrol")
		main._engage(group);await create_timer(.6).timeout
		var foe=main._combat._state.foes[0]
		check(main._in_combat and not main._tactical.active,id+" first-person combat")
		check(foe.name==ELITES.PACKS[id].leader and VIEW.is_model(foe.node) and foe.node.attachments.size()>0,
			id+" named combat leader uses variant")
		check(foe.type.scene==load(ELITES.ENEMIES % ELITES.PACKS[id].types[0]).scene,id+" original sprite fallback")
		for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(667,375)]:
			root.size=size;main.simulate_phone_safe_area=size.x<1000
			await snap(id+"-combat-"+str(size.x))
		VIEW.play(foe.node,"attack");await snap(id+"-combat-attack")
		main.queue_free();await process_frame;await process_frame
	settings.set_value("enemy_models",false)
	for id: String in ELITES.PACKS:
		check(ELITES.types(id)[0].view_scene()==load(ELITES.ENEMIES % ELITES.PACKS[id].types[0]).scene,id+" models-off fallback")
	FileAccess.open(output.path_join("leader-live-validation.json"),FileAccess.WRITE).store_string(JSON.stringify(
		{"checks":checks,"failures":failures,"physical_iPhone":false},"\t"))
	print("LIVE_LEADERS ",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
