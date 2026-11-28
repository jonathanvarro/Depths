extends SceneTree
## Real Main integration: private save/profile, never the owner's game.
const Q := preload("res://scripts/quests.gd")
const Save := preload("res://scripts/save_game.gd")
const Settings := preload("res://scripts/settings.gd")
var main
var checks := 0
var failures: Array[String] = []
var shots: Array[String] = []
var output: String
var motion_samples := 0

func game(continued := false) -> void:
	Save.set_continue_requested(continued)
	main=load("res://scenes/main.tscn").instantiate()
	main.play_opening=false; main.wandering=false; main.floor_seed=31
	root.add_child(main); await settle(10)

func floor_colliders() -> void:
	var body := StaticBody3D.new(); main._level.add_child(body)
	for mesh: MeshInstance3D in main._level.find_children("*","MeshInstance3D",true,false):
		if mesh.name not in ["ElevatedStone","ElevatedTimber"] and not (mesh.get_parent()==main._level and mesh.mesh is PlaneMesh and absf(mesh.position.y)<.001): continue
		var shape := CollisionShape3D.new(); shape.shape=mesh.mesh.create_trimesh_shape(); body.add_child(shape)
		shape.global_transform=mesh.global_transform
	await physics_frame

func support(at: Vector3,label: String) -> void:
	var ray := PhysicsRayQueryParameters3D.create(at+Vector3.UP*.08,at-Vector3.UP*.12)
	var hit: Dictionary = main.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and absf(hit.position.y-at.y)<.003,label)

func step(to: Vector2i) -> void:
	var p=main._party
	p.locked=false
	p._try_step(to-p.cell)
	var began := Time.get_ticks_msec()
	while p._busy and Time.get_ticks_msec()-began<2000:
		await process_frame; support(p.position,"actual tween supported"); motion_samples+=1
	check(p.cell==to and not p._busy,"live party arrives on slope")
	check(absf(p.position.y-main._map.floor_y(to))<.001,"live party settles at terrain height")

func finish_fight() -> void:
	for foe in main._combat._state.foes: foe.health=0
	main._combat._state._check_end()
	for i in 60:
		if not main._in_combat: break
		if main._combat._actions.visible: main._combat._action_chosen.emit({"kind":"defend"})
		await create_timer(.05).timeout
	check(not main._in_combat,"field combat finishes normally")

func _initialize() -> void:
	output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)

func settle(count := 5) -> void:
	for i in count: await process_frame

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await settle(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png")); shots.append(name+".png")

func run() -> void:
	AudioServer.set_bus_mute(0,true)
	Save.set_path("user://cavern_live_test.dat")
	Settings.set_value("flashes",false)
	await game()
	Q.set_stage(main._camp_state,"left_behind",Q.Stage.RESOLVED)
	main._go_to_area("cavern",main.Arrival.FROM_ABOVE); await settle()
	check(main._map.terrain_version==1,"live Cavern has metric terrain")
	check(main._exit_to("rest")!=Vector2i(-1,-1),"live Cavern has an actual way to the Rest Area")
	check(main.environment_theme.display_name=="Cavern","Cavern identity theme live")
	var map=main._map
	var lowest := 0.0
	for c: Vector2i in map.elevations:
		lowest=minf(lowest,map.floor_y(c))
		for d in main.Party.DIRECTIONS:
			if map.is_wall(c+d): continue
			check(absf(map.floor_y(c)-map.floor_y(c+d))<=.401,"bounded adjacent height")
	check(lowest<=-2.4,"multiple landing elevations")
	check(absf(main._party.position.y-map.floor_y(main._party.cell))<.001,"arrival grounded")
	check(main._missing_quest_site(map,3)==false,"mandatory quests remain")
	await shot("cavern-arrival")
	await floor_colliders()
	for c: Vector2i in map.elevations:
		if map.content_at(c)==map.Content.STAIRS_DOWN: continue
		support(map.world_at(c,main.CELL_SIZE),"rendered landing supports its cell")
		for d in [Vector2i.RIGHT,Vector2i.DOWN]:
			var n: Vector2i=c+d
			if not map.linked(c,n) or map.content_at(n)==map.Content.STAIRS_DOWN: continue
			for progress in [.13,.37,.61,.87]: support(map.step_position(c,n,progress,main.CELL_SIZE),"rendered connector supports its height profile")
	var bridge: Dictionary=map.marks.get("cavern_bridge",{})
	if not bridge.is_empty():
		var view: Vector2i=bridge.keys()[0]
		main._party.place(map,view); main._party.facing=1; main._party.rotation.y=-PI/2
		await shot("cavern-bridge")
	var slope := Vector2i(-1,-1); var other := Vector2i(-1,-1)
	for c: Vector2i in map.elevations:
		for d in main.Party.DIRECTIONS:
			var n: Vector2i=c+d
			if not map.can_step(c,n) or absf(map.floor_y(c)-map.floor_y(n))<.01: continue
			if map.door_at(c)!=0 or map.door_at(n)!=0 or map.content_at(c)!=0 or map.content_at(n)!=0: continue
			slope=c; other=n; break
		if slope.x>=0: break
	check(slope.x>=0,"a playable ramp exists")
	main._party.entered_cell.disconnect(main._on_party_entered_cell)
	if slope.x>=0:
		main._party.place(map,slope)
		main._party.facing=main.Party.DIRECTIONS.find(other-slope); main._party.rotation.y=-main._party.facing*PI/2
		await step(other); await step(slope)
		await shot("cavern-slope")
		# The same adapter grounds approaching packs and field actors.
		var type: EnemyType=load("res://data/enemies/goblin.tres")
		var group=main.Roamers.Group.new(); group.cell=slope; group.types.assign([type]); main._place_group(group)
		group.cell=other; main._move_group_node(group)
		while group.node.get_meta("terrain_tween").is_running():
			await process_frame; support(group.node.position,"roaming actor follows ramp")
		check(absf(group.node.position.y-map.floor_y(other))<.001,"pack grounded on arrival")
		group.node.queue_free(); main._groups.erase(group)
	# Full room and quest-site landings are level, not tilted combat arenas.
	for site: Rect2i in map.story_sites():
		var heights := {}
		for c: Vector2i in map.elevations:
			if site.has_point(c): heights[map.floor_y(c)]=true
		check(heights.size()<=1,"whole quest site is a level landing")
	for c: Vector2i in map.events:
		if main._props.has(c): check(absf(main._props[c].position.y-map.floor_y(c))<.001,"live event prop grounded")
	# Saving a legacy floor keeps its layout, events and used-content records.
	map.triggered[slope]=true; map.explored[slope]=true
	var rows: PackedStringArray=map._rows.duplicate(); var events: Dictionary=map.events.duplicate()
	var legacy: Dictionary=main._save_data()
	for pair in legacy.floors:
		if pair[0]==3:
			for field in ["elevations","flat_landings","terrain_version"]: pair[1].erase(field)
	Save.write(legacy); main.queue_free(); await settle(3); await game(true)
	map=main._map
	check(map.terrain_version==1 and map._rows==rows,"legacy Cavern upgraded without replacing layout")
	check(map.triggered.has(slope) and map.explored.has(slope) and map.events==events,"legacy content progress preserved")
	var heights: Dictionary=map.elevations.duplicate()
	main._save_now(); main.queue_free(); await settle(3); await game(true)
	check(main._map.elevations==heights,"height data survives an actual file reload")
	check(absf(main._party.position.y-main._map.floor_y(main._party.cell))<.001,"continued party grounded")
	# Start a real three-model field encounter on a lower room landing, save
	# while it is active, then continue through the normal Main startup path.
	var room := Vector2i(-1,-1)
	for c: Vector2i in main._map.elevations:
		if main._map.floor_y(c)<-1 and main._map.is_passable(c) and main._map._is_room_cell(c) and main._map.room_around(c).size()>=9:
			room=c; break
	check(room.x>=0,"lower encounter room available")
	if room.x>=0:
		main._party.place(main._map,room)
		var types: Array[EnemyType]=[load("res://data/enemies/goblin.tres"),load("res://data/enemies/goblin_archer.tres"),load("res://data/enemies/rat.tres")]
		main._start_combat(room,types); await create_timer(.8).timeout
		check(main._in_combat and main._combat._state.field,"real encounter runs in elevated cave")
		for foe in main._combat._state.living_foes(): check(absf(foe.node.position.y-main._map.floor_y(foe.cell))<.001,"field model feet grounded")
		await shot("cavern-field-combat")
		main._save_now(); main.queue_free(); await settle(3); await game(true); await create_timer(.8).timeout
		check(main._in_combat and main._map.elevations==heights,"active encounter resumes with saved terrain")
		await finish_fight()
	# A synthetic forbidden cliff edge also blocks melee, reach and pathfinding.
	var cliff=main.DungeonMap.new(PackedStringArray(["#####","#<..#","#####"]))
	cliff.elevations={Vector2i(1,1):0.0,Vector2i(2,1):-2.0,Vector2i(3,1):-2.0}
	check(cliff.walking_path(Vector2i(1,1),Vector2i(3,1)).is_empty(),"pathfinding cannot cross an unsupported height jump")
	check(not main.Roamers.sees(cliff,Vector2i(1,1),Vector2i(3,1),4),"pack sight cannot treat a cliff as a corridor")
	var cliff_types: Array[EnemyType]=[load("res://data/enemies/goblin.tres")]
	var combat=main.CombatState.new(main._party_state,cliff_types)
	combat.field=true; combat.party_cell=Vector2i(1,1); combat.facing=Vector2i.RIGHT; combat.foes[0].cell=Vector2i(2,1)
	combat.linked_cell=cliff.linked
	check(combat.foe_ahead()==null and combat.line_to(combat.foes[0])==Vector2i.ZERO,"melee and reach reject unconnected ledges")
	main._go_to_area("rest",main.Arrival.FROM_ABOVE); await settle()
	check(main._map.marks.has("rest_approach"),"full Rest Area reserved")
	check(main._props.has(main.RestApproach.REFUGE),"refuge interaction uses existing authority")
	check(main._props[main.RestApproach.REFUGE].get_meta("asset_id")=="rest-area-approach","full scene bound")
	check(main._map.walking_path(main._map.start_cell,main._map.find_content(6)).size()>0,"Rest Area through route reachable")
	await shot("rest-arrival")
	await floor_colliders()
	# Walk through the actual 3D entrance into the refuge; its event opens
	# the approved Overlook, with the real party/stash/rest APIs unchanged.
	main._party.place(main._map,Vector2i(7,9)); main._party.facing=0; main._party.rotation.y=0
	main._party.locked=false; main._party._try_step(Vector2i.UP)
	while main._party._busy: await process_frame; support(main._party.position,"Rest Area entrance has real continuous floor")
	await shot("rest-threshold")
	await step(Vector2i(6,8))
	main._party._try_step(Vector2i.UP)
	while main._party._busy: await process_frame
	check(main._party.cell==Vector2i(6,8) and main._overlook.visible,"furniture blocks walking and opens existing refuge controls")
	main._overlook_target("mine")
	await step(Vector2i(7,8))
	main._party._try_step(Vector2i.UP)
	while main._party._busy: await process_frame; support(main._party.position,"refuge route has real continuous floor")
	check(main._overlook!=null and main._overlook.visible,"approach opens existing refuge experience")
	main._overlook_target("stash"); await settle()
	check(main._overlook_stash.visible,"existing stash accessible")
	main._overlook_stash.closed.emit(); await settle(); main._overlook_target("mine")
	main._map.triggered[main.RestApproach.REFUGE]=true; main._empty_prop(main.RestApproach.REFUGE)
	check(main._props[main.RestApproach.REFUGE].state=="used","used refuge banks full 3D fire")
	main._save_now(); main.queue_free(); await settle(3); await game(true)
	check(main._props[main.RestApproach.REFUGE].state=="used","saved full refuge restores used appearance")
	main._go_to_area("fortress",main.Arrival.FROM_ABOVE); await settle()
	main._go_to_area("rest",main.Arrival.FROM_BELOW,"fortress"); await settle()
	check(main._party.cell==main._exit_to("fortress"),"paired fortress return")
	main._go_to_area("cavern",main.Arrival.FROM_BELOW,"rest"); await settle()
	check(main._party.cell==main._exit_to("rest") and main._map.elevations==heights,"paired elevated Cavern return keeps terrain")
	main.SaveGame.set_path(output.path_join("export-cavern-save.dat")); main._save_now()
	main.SaveGame.set_path("user://cavern_live_test.dat")  # later travel must not overwrite the Cavern fixture
	for dimensions in [Vector2i(1278,590),Vector2i(844,390),Vector2i(667,375)]:
		root.size=dimensions; main.simulate_phone_safe_area=true; await settle(8)
		await shot("cavern-return-%dx%d" % [dimensions.x,dimensions.y])
	main._go_to_area("rest",main.Arrival.FROM_ABOVE); await settle()
	main._party.place(main._map,Vector2i(7,8)); main._party.facing=0; main._party.rotation.y=0
	await shot("rest-used-phone")
	# Ready-to-use exported-build smoke input, always a separate private file.
	main.SaveGame.set_path(output.path_join("export-save.dat")); main._save_now()
	var report := {"checks":checks,"failures":failures,"captures":shots,"motion_samples":motion_samples}
	FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report)); main.queue_free(); await settle(2); quit(0 if failures.is_empty() else 1)
