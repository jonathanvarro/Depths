extends SceneTree
## Gate state persistence and larger-map/phone-SE presentation checks.
const DM := preload("res://scripts/dungeon_map.gd")
var checks := 0
var failures: Array[String]=[]
var captures: Array[String]=[]
func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func settle() -> void:
	for i in 5:await process_frame
func snap(name: String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://art/concepts/campaign-v1/"+name+".png")==OK,name)
	captures.append(name)
func _run() -> void:
	var map=DM.new(PackedStringArray(["#######","#.B.D.#","#######"]))
	var gate:=Vector2i(2,1);var door:=Vector2i(4,1)
	map.marks={"gates":[gate]}
	var level=load("res://scripts/level_builder.gd").new()
	root.add_child(level);level.build(map,load("res://themes/fortress.tres"),2.4,2.6);await settle()
	check(level._door_nodes[gate].scene_file_path.ends_with("gate-barred.tscn"),"Marked gate begins barred")
	check(level._door_nodes[door].scene_file_path.ends_with("hall-closed.tscn"),"Ordinary door begins closed")
	map.doors[gate]=DM.Door.OPEN;map.doors[door]=DM.Door.OPEN
	level.refresh_door(gate);level.refresh_door(door);await settle()
	check(level._door_nodes[gate].scene_file_path.ends_with("gate-broken.tscn"),"Opened gate keeps broken remains")
	check(level._door_nodes[door].scene_file_path.ends_with("hall-open.tscn"),"Opened ordinary door uses its own frame")
	level.queue_free();await settle()
	for resolution in [Vector2i(1278,590),Vector2i(1334,750)]:
		root.size=resolution
		var main=load("res://scenes/main.tscn").instantiate()
		main.play_opening=false;main.use_debug_layout=false;main.floor_seed=31;main.simulate_phone_safe_area=true
		root.add_child(main);await create_timer(.3).timeout
		main._go_to_floor(2,main.Arrival.FROM_ABOVE);await settle()
		# A fully explored review fixture; no player save/discovery behaviour is changed.
		for y in main._map.height:
			for x in main._map.width:main._map.explored[Vector2i(x,y)]=true
		for cell in main._map.events:main._map.discovered[cell]=true
		main._full_map_view.setup(main._map);main._set_full_map(true)
		var tag:=str(resolution.x)
		await snap("map-complex-"+tag)
		check(main._full_map_view._known_floor.size()>100,"Complex known geometry "+tag)
		check(root.get_visible_rect().encloses(main._full_map_close.get_global_rect()),"Map close within safe viewport "+tag)
		root.content_scale_factor=1.3
		await snap("map-complex-"+tag+"-larger")
		check(root.get_visible_rect().encloses(main._full_map_close.get_global_rect()),"Map close fits Larger "+tag)
		main._full_map_close.pressed.emit();check(not main._full_map.visible,"Close map Larger "+tag)
		root.content_scale_factor=1.0
		# Sparse exploration and unfinished boundaries remain readable on the HUD.
		main._map.explored.clear();main._map.discovered.clear();main._map.reveal_around(main._party.cell)
		main._minimap.setup(main._map);main._full_map_view.setup(main._map)
		main._set_full_map(true);await snap("map-sparse-"+tag)
		main._set_full_map(false);main._camp.open(main._camp_state,main._party_state);main._ending=true
		await snap("camp-after-"+tag)
		check(root.get_visible_rect().encloses(main._camp._buttons.fire.get_global_rect()),"Camp target within safe viewport "+tag)
		main.queue_free();await settle()
	FileAccess.open("res://art/concepts/campaign-v1/map-feature-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"fixtures":"Real generated floor2; discovery set explicitly for art review. Physical iPhone untested."},"  ")+"\n")
	print("CAMPAIGN_MAP_FEATURES: ",checks," failures: ",failures.size()," captures: ",captures.size())
	quit(0 if failures.is_empty() else 1)
