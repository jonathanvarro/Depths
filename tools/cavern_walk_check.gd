extends SceneTree
## Actual movement, physics support and native screen-space UI checks (#311).
const STUDY := preload("res://scenes/prototypes/cavern_walk.tscn")
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var output: String
var study
var motion_samples := 0
var visual_body: StaticBody3D

func _initialize() -> void:
	output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)

func settle(frames := 3) -> void:
	for i in frames: await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await settle(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
	captures.append(label+".png")

func support(at: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.12, at-Vector3.UP*0.15, 1)
	return study.world.get_world_3d().direct_space_state.intersect_ray(query)

func grounded(at: Vector3, label: String) -> void:
	var hit := support(at)
	check(not hit.is_empty(), label+" has actual floor")
	if not hit.is_empty(): check(absf(hit.position.y-at.y)<.002, label+" meets floor")

func obstacle_colliders() -> void:
	visual_body = StaticBody3D.new(); visual_body.collision_layer = 2; study.world.add_child(visual_body)
	for mesh: MeshInstance3D in study.world.find_children("*","MeshInstance3D",true,false):
		if not mesh.is_visible_in_tree() or mesh.name in ["StonePath","BridgeDeck"]: continue
		var collider := CollisionShape3D.new(); collider.shape = mesh.mesh.create_trimesh_shape()
		collider.set_meta("source",str(mesh.get_path()))
		visual_body.add_child(collider); collider.global_transform = mesh.global_transform

func clear_sweep(from: Vector3, to: Vector3) -> void:
	if from.distance_to(to)<.001: return
	for height in [.18,.7,1.2]:
		for side in [Vector3.ZERO,Vector3(.2,0,.2),Vector3(-.2,0,-.2)]:
			var query := PhysicsRayQueryParameters3D.create(from+Vector3.UP*height+side,to+Vector3.UP*height+side,2)
			query.hit_back_faces = true
			var hit: Dictionary = study.world.get_world_3d().direct_space_state.intersect_ray(query)
			var detail := ""
			if not hit.is_empty():
				var owner: Node = visual_body.shape_owner_get_owner(visual_body.shape_find_owner(hit.shape))
				detail = " at %s against %s" % [hit.position,owner.get_meta("source")]
			check(hit.is_empty(),"movement clears visible scenery"+detail)

func move_to(target: Vector2i) -> void:
	var party = study.party
	var before: Vector2i = party.cell
	var completed: Array[Vector2i] = []
	var callback := func(c: Vector2i): completed.append(c)
	party.entered_cell.connect(callback)
	party._try_step(target-before)
	var started := Time.get_ticks_msec()
	var previous: Vector3 = party.position
	while party._busy and Time.get_ticks_msec()-started < 2000:
		await process_frame
		grounded(party.position, "tween %s -> %s" % [before,target]); motion_samples += 1
		clear_sweep(previous,party.position); previous = party.position
	party.entered_cell.disconnect(callback)
	check(not party._busy and party.cell == target, "arrived "+str(target))
	check(completed == [target], "one entered-cell signal "+str(target))
	check(party.position.distance_to(study.terrain.world(target))<.001, "exact landing "+str(target))
	check(absf(party.camera.global_position.y-party.position.y-party.EYE_HEIGHT)<.001, "fixed eye clearance")

func key(code: int, down: bool) -> void:
	var event := InputEventKey.new(); event.physical_keycode = code; event.pressed = down
	Input.parse_input_event(event)
	await process_frame

func pointer(control: Control, down: bool, touch: bool) -> void:
	var at := control.get_global_rect().get_center()
	if touch:
		var event := InputEventScreenTouch.new(); event.position = at; event.index = 0; event.pressed = down
		root.push_input(event,true)
	else:
		var event := InputEventMouseButton.new(); event.position = at; event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT; event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0; event.pressed = down
		root.push_input(event,true)
	await process_frame

func run() -> void:
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1280,720)
	study = STUDY.instantiate(); root.add_child(study); current_scene = study
	await settle(6); await physics_frame
	obstacle_colliders(); await physics_frame
	check(study.terrain.heights.size() == 27, "authored small layout")
	check(study.party.cell == study.terrain.arrival, "starts at arrival")
	check(study.party.position.y == 0, "upper landing height")
	check(not study.terrain.can_step(Vector2i(1,6),Vector2i(2,6)), "adjacent unequal ledges not connected")
	check(not study.terrain.can_step(Vector2i(1,7),Vector2i(2,7)), "second adjacent drop guarded")
	# BFS: every landing reachable via declared links; one reconnecting loop.
	var queue: Array[Vector2i] = [study.terrain.arrival]
	var seen := {study.terrain.arrival:true}; var edges := 0
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		edges += study.terrain.links[c].size()
		for next: Vector2i in study.terrain.links[c]:
			check(study.terrain.can_step(next,c), "reciprocal connection")
			check(c.distance_to(next) == 1, "cardinal connection")
			check(absf(study.terrain.heights[c]-study.terrain.heights[next]) <= .401, "bounded ramp rise")
			if not seen.has(next): seen[next] = true; queue.append(next)
	check(seen.size() == study.terrain.heights.size(), "whole route reachable")
	check(edges/2 == seen.size(), "one loop with two approach tails")
	for c: Vector2i in study.terrain.heights:
		grounded(study.terrain.world(c), "landing "+str(c))
		for next: Vector2i in study.terrain.links[c]:
			for j in range(1,10): grounded(study.terrain.step_position(c,next,j/10.0), "ramp sample")
	# Actual keyboard and on-screen held action reach the junction.
	await key(KEY_W,true); await settle(2); await key(KEY_W,false)
	while study.party._busy: await process_frame
	check(study.party.cell == Vector2i(1,6), "keyboard forward uses real Party")
	await pointer(study.buttons.Forward,true,true); await pointer(study.buttons.Forward,false,true)
	while study.party._busy: await process_frame
	check(study.party.cell == study.terrain.junction, "touch/mouse button action reaches junction")
	await pointer(study.buttons.Map,true,false); await pointer(study.buttons.Map,false,false)
	check(study.map_panel.visible,"mouse click opens map through GUI dispatch")
	await pointer(study.buttons.CloseMap,true,true); await pointer(study.buttons.CloseMap,false,true)
	check(not study.map_panel.visible,"touch closes map through GUI dispatch")
	for quarter in 4:
		Input.action_press("turn_right"); await settle(2); Input.action_release("turn_right")
		while study.party._busy: await process_frame
		check(study.party.facing == (quarter+1)%4,"keyboard quarter turn")
	await capture("arrival-upper-ledge")
	study.party.move_time = .09
	# Walk the full loop, including both slopes and the bridge, then reverse it.
	for i in range(1,study.terrain.loop.size()+1):
		await move_to(study.terrain.loop[i%study.terrain.loop.size()])
		if i == 3: await capture("bridge-entry")
		if i == 12: await capture("east-descent")
		if i == 17: await capture("lower-ledge")
	for i in range(study.terrain.loop.size()-1,-1,-1): await move_to(study.terrain.loop[i])
	# Refused drop must not change cell, elevation or trigger entry.
	study.party.place(study.terrain, Vector2i(1,6))
	# Every visible wooden surface has a supplied dark vertex palette; default
	# white would make these physically shaded materials look like fresh paint.
	var deck: MeshInstance3D = study.world.get_node("BridgeDeck")
	var colours: PackedColorArray = deck.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	check(not colours.is_empty() and colours[0].r<.5,"bridge uses authored timber colour")
	var origin: Vector3 = study.party.position
	study.party._try_step(Vector2i.RIGHT)
	while study.party._busy: await process_frame
	check(study.party.cell == Vector2i(1,6) and study.party.position.distance_to(origin)<.001, "drop bump stays on original landing")
	# Backwards movement descends, too; no camera pitch is required to move.
	study.party.place(study.terrain, study.terrain.junction); study.party.facing = 3
	Input.action_press("move_back"); await settle(2); Input.action_release("move_back")
	while study.party._busy: await process_frame
	check(study.party.cell == Vector2i(2,5) and absf(study.party.position.y+.4)<.001, "backwards step follows descending ramp")
	# Pause freezes a move in flight and clears held actions.
	study.party.move_time = .5; study.party._try_step(Vector2i.DOWN); await settle(2)
	study.toggle_menu(); var paused_at: Vector3 = study.party.position
	await settle(12)
	check(study.party.position == paused_at and paused, "menu freezes in-flight movement")
	for action in study.ACTIONS: check(not Input.is_action_pressed(action), "menu releases "+action)
	study.toggle_menu()
	while study.party._busy: await process_frame
	grounded(study.party.position,"resume")
	# Seen map should show landings; no campaign state is involved.
	for dimensions in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(844,390),Vector2i(667,375),Vector2i(2556,1179)]:
		root.size = dimensions; study.simulate_phone_safe_area = dimensions.x != 1280
		study._layout(); await settle()
		# Canvas transforms round fractional Retina coordinates to pixels.
		var safe_pixels := Rect2(study.safe_rect.position*study.ui.scale,study.safe_rect.size*study.ui.scale).grow(.5)
		for id in ["Map","Menu","Forward","Back","Left","Right"]:
			var control: Button = study.buttons[id]
			check(safe_pixels.encloses(control.get_global_rect()), "%s fits safe area %s" % [id,dimensions])
			check(control.get_global_rect().size.x>=44 and control.get_global_rect().size.y>=44,"44px target "+id)
			check(control.get_theme_stylebox("normal") is StyleBoxTexture,"brass style "+id)
		await capture("walk-%dx%d" % [dimensions.x,dimensions.y])
		study.buttons.Map.pressed.emit(); await settle()
		check(study.map_panel.visible and study.party.locked,"map stops new moves")
		check(safe_pixels.encloses(study.map_panel.get_global_rect()),"map fits safe area")
		await capture("map-%dx%d" % [dimensions.x,dimensions.y])
		await key(KEY_ESCAPE,true); await key(KEY_ESCAPE,false)
		check(not study.map_panel.visible and not study.menu.visible,"Escape closes map before menu")
		await key(KEY_ESCAPE,true); await key(KEY_ESCAPE,false)
		check(study.menu.visible and paused,"Escape opens pause menu")
		check(safe_pixels.encloses(study.menu.get_global_rect()),"menu fits safe area")
		await capture("menu-%dx%d" % [dimensions.x,dimensions.y])
		study.buttons.Continue.pressed.emit()
		check(not paused and not study.party.locked,"Continue restores movement")
	# Distinct eye-height views, facing along the real route, not a gallery camera.
	root.size = Vector2i(1280,720); study.simulate_phone_safe_area = false; study._layout()
	for view in [[Vector2i(2,3),1,"bridge-eye"], [Vector2i(8,3),2,"slope-down-eye"], [Vector2i(7,8),3,"lower-eye"], [Vector2i(2,7),0,"slope-up-eye"]]:
		study.party.place(study.terrain,view[0]); study.party.facing=view[1]; study.party.rotation.y=-view[1]*PI/2
		study._moved(view[0],view[1]); await capture(view[2])
	# The exit tail is also reachable; its arch must not block the camera lane.
	study.party.place(study.terrain,Vector2i(8,3)); study.party.move_time=.09
	await move_to(study.terrain.destination); await capture("rest-threshold-eye")
	study.buttons["Start again"].pressed.emit(); await settle(8); study = current_scene
	check(study.party.cell == study.terrain.arrival and not paused, "Start again reloads standalone scene")
	check(not FileAccess.file_exists("user://save.json"),"no expedition save created in private profile")
	var report := {"checks":checks,"failures":failures,"captures":captures,"motion_samples":motion_samples,"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info().string}
	var file := FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE); file.store_string(JSON.stringify(report,"  ")); file.close()
	print(JSON.stringify(report)); study.queue_free(); await settle(2)
	quit(0 if failures.is_empty() else 1)
