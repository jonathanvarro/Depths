extends SceneTree
## Live floor two, transition/restore and gameplay independence; private save.
const SAVE:=preload("res://scripts/save_game.gd")
const THEME:=preload("res://themes/fungal-caverns.tres")
const DM:=preload("res://scripts/dungeon_map.gd")
const OUT:="res://art/concepts/fungal-caverns-v1/"
var checks:=0
var failures:Array[String]=[]
var captures:Array[String]=[]
var main

func _initialize() -> void:
	SAVE.set_path("res://build/fungal-review/main-save.dat");SAVE.set_continue_requested(false)
	Engine.set_meta("depths_settings",preload("res://scripts/settings.gd").DEFAULTS.duplicate())
	Engine.set_meta("depths_settings_loaded",true)
	call_deferred("run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func settle() -> void:
	for i in 8:await process_frame

func snap(name:String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Capture "+name)
	captures.append(name+".png")

func signature() -> Array:
	return main._level.get_node("Dressing").get_children().map(func(p):return [p.get_meta("dressing_id"),p.position,p.rotation])

func run() -> void:
	root.size=Vector2i(1280,720)
	main=load("res://scenes/main.tscn").instantiate()
	main.play_opening=false;main.floor_seed=31;main.simulate_phone_safe_area=true
	root.add_child(main);await create_timer(0.6).timeout
	AudioServer.set_bus_mute(0,true)
	main._go_to_floor(1,main.Arrival.FROM_ABOVE);await settle()
	check(main.environment_theme.resource_path=="res://themes/cave.tres","Floor one keeps original mine theme")
	check(main._level.get_children().any(func(n):return n is MeshInstance3D and n.mesh is BoxMesh),"Old theme keeps original box UVs")
	main._go_to_floor(2,main.Arrival.FROM_ABOVE);await settle()
	check(main.environment_theme==THEME and main._level._theme==THEME,"Actual floor two uses the complete fungal theme")
	check(main._level.get_node("Dressing").get_script()==THEME.dressing_script,"Theme selects its own dresser")
	check(main._ambience_player.playing and main._ambience_player.stream==THEME.ambience,"Theme ambience runs through existing bus/player")
	var dressing=main._level.get_node("Dressing")
	check(dressing.get_child_count()>0,"Real generated floor has growth")
	var bad:=[]
	var landmark_cells:={}
	for landmark in main._map.landmarks:
		for cell in landmark.cells:landmark_cells[cell]=true
	for piece in dressing.get_children():
		var cell:Vector2i=piece.get_meta("cell")
		if main._map.encounter_zones.has(cell) or landmark_cells.has(cell) or main._map.content_at(cell)!=DM.Content.NONE or cell==main._map.start_cell:bad.append(cell)
	check(bad.is_empty(),"Live props avoid entire encounter rooms, landmarks and usable cells")
	var before:=signature()
	var gameplay:=var_to_str([main._party_state.time_elapsed,main._party_state.supplies.oil,main._party_state.supplies.source,main._party_state.members[0].strain,main._rng.state])
	main._build_level();await settle()
	check(signature()==before,"Rebuilding the live floor retains every placement")
	check(gameplay==var_to_str([main._party_state.time_elapsed,main._party_state.supplies.oil,main._party_state.supplies.source,main._party_state.members[0].strain,main._rng.state]),"Rebuilding cosmetics changes no time, oil, source, nerves or gameplay RNG")
	# Find actual nearby growth with an open cell from which to see it.
	var view_cell:Vector2i=main._map.start_cell
	var facing:=0
	var review_pieces:Array=main._level.get_node("Dressing").get_children()
	var preferred:={"moss-curtain-lit":0,"wall-roots":1,"moss-curtain":2}
	review_pieces.sort_custom(func(a,b):return preferred.get(a.get_meta("dressing_id"),10)<preferred.get(b.get_meta("dressing_id"),10))
	for piece in review_pieces:
		var cell:Vector2i=piece.get_meta("cell")
		var found:=false
		for dir_index in 4:
			var candidate:Vector2i=cell-main.Party.DIRECTIONS[dir_index]
			if main._map.is_passable(candidate) and main._map.content_at(candidate)==DM.Content.NONE:
				view_cell=candidate;facing=dir_index;found=true;break
		if found:break
	main._party.locked=true
	main._party.position=Vector3(view_cell.x*2,0,view_cell.y*2);main._party.rotation.y=-facing*PI/2
	main._party_state.supplies.source=1;main._party_state.supplies.has_lantern=true;main._party_state.supplies.oil=80
	main._update_lantern()
	main._message_label.modulate.a=0;main._message_tween.kill()
	for shape in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=shape
		for factor in [1.0,1.3]:
			root.content_scale_factor=factor;main._apply_safe_area();await settle()
			await snap("main-%d-%s"%[shape.x,"larger" if factor>1 else "normal"])
	root.content_scale_factor=1.0;main._apply_safe_area()
	main.environment_theme=main._cave_theme;main._build_level();await settle()
	await snap("main-phone-before")
	main.environment_theme=THEME;main._build_level();await settle()
	# The fallback light band remains Out despite emissive dressing.
	main._party_state.supplies.oil=0;main._update_lantern();await settle()
	check(main._party_state.supplies.light_band()==0,"Cosmetic glow cannot supply carried light")
	await snap("main-phone-out")
	main._save_now();var data:=SAVE.read()
	check(not data.is_empty(),"Private floor-two save is written")
	main._go_to_floor(3,main.Arrival.FROM_ABOVE);await settle()
	check(main.environment_theme.resource_path=="res://themes/cave.tres","Floor three keeps its original outskirts look")
	main._go_to_floor(4,main.Arrival.FROM_ABOVE);await settle()
	check(main.environment_theme==main.FORTRESS_THEME,"Fortress keeps its own theme")
	main._restore(data);await settle()
	check(main._depth==2 and main.environment_theme==THEME,"Restoring floor two reselects the theme without a save-format change")
	check(signature()==before,"Restored environment keeps its stable dressing")
	main.use_debug_layout=true;main._apply_theme()
	check(main.environment_theme==main._cave_theme,"Debug themes remain unchanged")
	main.use_debug_layout=false;main._cave_theme=load("res://themes/stone_dungeon.tres") if ResourceLoader.exists("res://themes/stone_dungeon.tres") else main.FORTRESS_THEME
	main._apply_theme();check(main.environment_theme==main._cave_theme,"A custom environment is not replaced")
	main.free();main=null;data.clear();await settle()
	var file:=FileAccess.open(OUT+"main-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"physical_iPhone":false,"private_save":"build/fungal-review/main-save.dat"},"\t")+"\n");file.close()
	print("FUNGAL_MAIN: checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
