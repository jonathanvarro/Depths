extends SceneTree
## Actual Main event completion, abandoned events, trap visibility and reloads.
const DM := preload("res://scripts/dungeon_map.gd")
const SG := preload("res://scripts/save_game.gd")
const OUT := "res://art/concepts/room-states-v1/"
const EVENTS := ["chest_old_workings","object_pale_idol","object_still_pool","rest_dry_alcove","rest_old_camp","trap_tripwire","trap_hollow_floor","chest_strongbox"]
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
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Capture "+name)
	captures.append(name)

func fixture(event: RoomEvent):
	var map=DM.new(PackedStringArray(["#########","#.......#","#.......#","#.......#","#.......#","#.......#","#########"]),2)
	map.contents[Vector2i(4,3)]=event.kind
	map.events[Vector2i(4,3)]=event
	return map

func _run() -> void:
	for phone in [false,true]:
		root.size=Vector2i(1278,590) if phone else Vector2i(1280,720)
		var tag: String="phone" if phone else "desktop"
		var main=load("res://scenes/main.tscn").instantiate()
		main.play_opening=false;main.floor_seed=31;main.simulate_phone_safe_area=phone
		root.add_child(main);await create_timer(.3).timeout
		main.environment_theme=load("res://themes/cave.tres")
		main._message_label.modulate.a=0
		main._depth=2
		var hero: Companion=main._party_state.members[0]
		var original_trait: String=hero.trait_id
		var cell:=Vector2i(4,3)
		for id in EVENTS:
			var event: RoomEvent=load("res://data/events/"+id+".tres")
			# Floor art is reviewed before approaching: at one cell its near
			# edge extends below the first-person camera's field of view.
			var viewing_cell:=Vector2i(4,5) if id in ["object_still_pool","trap_hollow_floor"] else Vector2i(4,4)
			hero.trait_id="keen_eyes"
			main._map=fixture(event);main._party.place(main._map,viewing_cell);main._build_level();await settle()
			check(main._props.has(cell),"Unresolved prop visible to Keen eyes "+id+tag)
			var before: Node3D=main._props[cell]
			var sprite: Sprite3D=before.get_node("Sprite")
			check(sprite.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST and sprite.shaded,"Lit nearest sprite "+id)
			check(before.state=="closed" and sprite.texture==before.closed_texture,"Starts with original artwork "+id)
			if id!="chest_strongbox":
				var old_path: String=before.closed_texture.resource_path.trim_suffix(".png")+".tscn"
				var old=load(old_path).instantiate();var old_sprite: Sprite3D=old.get_node("Sprite")
				check(sprite.transform==old_sprite.transform and sprite.pixel_size==old_sprite.pixel_size and sprite.billboard==old_sprite.billboard,"Original registration/orientation "+id)
				old.free()
			else:check(not event.prop.resource_path.contains("tutorial"),"Strongbox owns its iron artwork")
			await snap(id+"-before-"+tag)
			# Leaving an actual Main event must keep its unspent appearance.
			main._map.enter(cell);main._run_event(cell);await settle()
			main._event_screen._finish({"left":true,"ambush":[] as Array[EnemyType]});await settle()
			check(not main._map.triggered.has(cell) and before.state=="closed","Leave preserves unresolved state "+id)
			if event.kind==DM.Content.TRAP:
				hero.trait_id="grudge";main._build_level();await settle()
				check(not main._props.has(cell),"Non-Keen hero cannot see untriggered trap "+id)
				await snap(id+"-hidden-"+tag)
			# Resolve through the production event-completion signal. This also
			# checks creation of a spent trap that had no visible node before.
			main._map.enter(cell);main._run_event(cell);await settle()
			main._event_screen._finish({"left":false,"ambush":[] as Array[EnemyType]});await settle()
			check(main._props.has(cell),"Resolved event has a visible prop "+id)
			var used: Node3D=main._props[cell]
			check(used.state=="empty" and used.get_node("Sprite").texture==used.empty_texture,"Main switches to used art "+id)
			check(used.closed_texture!=used.empty_texture,"Used art visibly differs "+id)
			hero.trait_id=original_trait
			await snap(id+"-used-"+tag)
			main._build_level();await settle()
			check(main._props[cell].state=="empty","Floor rebuild retains resolved art "+id)
			var packed: Dictionary=SG.pack_object(main._map)
			var restored=DM.new(main._map._rows,main._map.depth)
			SG.unpack_into(restored,packed)
			main._map=restored;main._party.place(restored,viewing_cell);main._build_level();await settle()
			check(main._props[cell].state=="empty" and restored.triggered.has(cell),"Existing save fields restore used art "+id)
			check(restored.enter(cell)==DM.Content.NONE,"Resolved event cannot repeat "+id)
		# Used traps remain visible even after reopening with a non-Keen hero.
		hero.trait_id="grudge"
		for id in ["trap_tripwire","trap_hollow_floor"]:
			main._map=fixture(load("res://data/events/"+id+".tres"));main._map.triggered[cell]=true
			main._build_level();await settle()
			check(main._props.has(cell) and main._props[cell].state=="empty","Non-Keen revisit shows spent trap "+id)
		hero.trait_id=original_trait
		for theme_id in ["stone","fortress"]:
			main.environment_theme=load("res://themes/"+theme_id+".tres")
			for direction in ["up","down"]:
				main._map=fixture(load("res://data/events/chest_strongbox.tres"));main._map.events.clear()
				main._map.contents[cell]=DM.Content.STAIRS_UP if direction=="up" else DM.Content.STAIRS_DOWN
				main._party.place(main._map,Vector2i(4,4));main._build_level();await settle()
				var nodes: Array=main._level.get_children().filter(func(n):return n.has_meta("direction"))
				check(nodes.size()==1 and nodes[0].get_meta("direction")==direction,"Theme uses dedicated stairs "+theme_id+direction)
				if direction=="down":check(nodes[0].get_node("Ground").mesh.material==main.environment_theme.floor_material,"Down stairs fill floor with theme material "+theme_id)
				check(main._map.enter(cell)!=DM.Content.NONE and main._map.enter(cell)!=DM.Content.NONE,"Stairs remain repeatable "+direction)
				await snap(theme_id+"-stairs-"+direction+"-"+tag)
		var cave: EnvironmentTheme=load("res://themes/cave.tres")
		check(cave.ascent_scene.resource_path.contains("cave-v1") and cave.descent_scene.resource_path.contains("cave-v1"),"Cave roots and pit preserved")
		main.queue_free();await create_timer(.2).timeout
	FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"fixtures":"Actual Main resolution/Leave/rebuild and in-memory save roundtrip; isolated room fixture. Physical iPhone untested."},"  ")+"\n")
	print("ROOM_STATES: ",checks," failures: ",failures.size()," captures: ",captures.size())
	quit(0 if failures.is_empty() else 1)
