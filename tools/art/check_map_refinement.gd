extends SceneTree
## Owner's #50 refinement: legible marks and a moving hand's reliable sketch.
const DM := preload("res://scripts/dungeon_map.gd")
const MAP := preload("res://scripts/minimap.gd")
const OUT := "res://art/concepts/map/refinement-v2/"
var checks := 0
var failures: Array[String]=[]
var captures: Array[String]=[]

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(OUT)
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

func _fixture():
	var rows:=PackedStringArray()
	for y in 13:rows.append("#".repeat(23))
	for room in [Rect2i(1,1,7,4),Rect2i(11,1,9,4),Rect2i(1,7,7,5),Rect2i(11,7,9,5)]:
		for y in range(room.position.y,room.end.y):
			for x in range(room.position.x,room.end.x):rows[y][x]="."
	for x in range(8,11):rows[3][x]=".";rows[9][x]="."
	for y in range(5,7):rows[y][4]=".";rows[y][15]="."
	for entry in [[Vector2i(2,2),"<"],[Vector2i(13,2),"C"],[Vector2i(18,3),"C"],[Vector2i(3,9),"R"],[Vector2i(13,9),"O"],[Vector2i(18,10),">"],[Vector2i(15,7),"T"],[Vector2i(9,3),"D"],[Vector2i(9,9),"B"]]:
		rows[entry[0].y][entry[0].x]=entry[1]
	var map=DM.new(rows)
	for y in map.height:
		for x in map.width:map.explored[Vector2i(x,y)]=true
	for cell in map.contents:map.discovered[cell]=true
	map.triggered[Vector2i(18,3)]=true
	return map

func _invariants() -> void:
	var rows:=PackedStringArray(["#######","#S..###","###.###","###..>#","#######"])
	var a=DM.new(rows);a.explored={Vector2i(1,1):true,Vector2i(2,1):true,Vector2i(1,0):true,Vector2i(2,0):true}
	var b=DM.new(PackedStringArray(["#######","#S..#.#","#.#...#","#..C..#","#######"]))
	b.explored=a.explored.duplicate()
	var first=MAP.new();first.setup(a);first._cache_geometry()
	var second=MAP.new();second.setup(b);second.full_view=true;second._cache_geometry()
	check(first._known_floor.size()==2 and first._edges.size()==6,"Merge only known floor; no grid shared edges")
	check(first._edges==second._edges,"Unseen walls/content cannot change visible ink")
	check(first._notes().is_empty() and second._notes().is_empty(),"Unseen discoveries cannot become notes")
	var before: Array=first._edges.duplicate(true)
	for facing in 4:first.on_party_moved(Vector2i(2,1),facing);first._cache_geometry()
	check(first._edges==before,"Walking/turning leaves ink stable")
	var bent := false
	var bounded := true
	var vertices: Dictionary={}
	for edge in first._edges:
		var points: PackedVector2Array=edge.points
		for i in range(1,points.size()-1):
			var chord: Vector2=points[0].lerp(points[-1],float(i)/6.0)
			var drift: float=chord.distance_to(points[i])
			bent=bent or drift>.02
			bounded=bounded and drift<.14
		for p: Vector2 in [points[0],points[-1]]:
			var key:=Vector2i(roundi(p.x),roundi(p.y))
			if vertices.has(key):bounded=bounded and vertices[key].is_equal_approx(p)
			vertices[key]=p
	check(bent,"Charcoal strokes visibly bend between shared corners")
	check(bounded,"Bends stay bounded and adjacent corners stay joined")
	var chest: Image=MAP.marker_for(2,false).get_image()
	var searched: Image=MAP.marker_for(2,true).get_image()
	var red:=0
	var preserved:=0
	var ink:=0
	for y in 32:
		for x in 32:
			var original:=chest.get_pixel(x,y)
			var marked:=searched.get_pixel(x,y)
			if marked.a>.5 and marked.r>marked.g*1.6 and marked.r>marked.b*1.6:red+=1
			if original.a>.5:
				ink+=1
				if original.is_equal_approx(marked):preserved+=1
	check(red>100,"Searched chest has a strong red cross")
	check(float(preserved)/ink>.50,"Searched mark retains the same recognizable chest")
	check(MAP.GLYPHS.closed!=MAP.GLYPHS.blocked,"Door and blocked passage have distinct silhouettes")
	first.free();second.free()

func _run() -> void:
	_invariants()
	for size in [Vector2i(1280,720),Vector2i(1278,590),Vector2i(1334,750)]:
		root.size=size
		var tag: String="desktop" if size.x==1280 else str(size.x)
		var main=load("res://scenes/main.tscn").instantiate()
		main.play_opening=false;main.floor_seed=31;main.simulate_phone_safe_area=size.x!=1280
		root.add_child(main);await create_timer(.3).timeout
		main._message_label.modulate.a=0
		main._full_map_view.setup(_fixture());main._full_map_view.on_party_moved(Vector2i(4,3),0)
		main._set_full_map(true);await snap("symbols-"+tag)
		check(main._full_map.find_children("*","HFlowContainer",true,false).is_empty(),"No legend "+tag)
		check(main._full_map_view.size.y>root.size.y/root.content_scale_factor*.58,"Paper uses freed legend space "+tag)
		check(root.get_visible_rect().encloses(main._full_map_close.get_global_rect()),"Close in safe viewport "+tag)
		root.content_scale_factor=1.3;await snap("symbols-"+tag+"-larger")
		check(root.get_visible_rect().encloses(main._full_map_close.get_global_rect()),"Close fits Larger "+tag)
		main._full_map_close.pressed.emit()
		check(not main._full_map.visible and not main._party.locked,"Close restores movement "+tag)
		root.content_scale_factor=1
		main._minimap.setup(_fixture());main._minimap.on_party_moved(Vector2i(15,3),2)
		await snap("corner-"+tag)
		main._minimap.pressed.emit();await settle()
		check(main._full_map.visible,"Corner map opens full map "+tag)
		main._set_full_map(false)
		main._go_to_floor(2,main.Arrival.FROM_ABOVE);await settle()
		for y in main._map.height:
			for x in main._map.width:main._map.explored[Vector2i(x,y)]=true
		for cell in main._map.events:main._map.discovered[cell]=true
		main._full_map_view.setup(main._map);main._set_full_map(true)
		await snap("generated-"+tag)
		root.content_scale_factor=1.3;await snap("generated-"+tag+"-larger")
		var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;Input.parse_input_event(escape);await settle()
		check(not main._full_map.visible,"Escape closes map "+tag)
		root.content_scale_factor=1
		main._set_full_map(true)
		var touch:=InputEventScreenTouch.new();touch.pressed=true;touch.position=main._full_map_view.get_global_rect().get_center();Input.parse_input_event(touch);await settle()
		check(not main._full_map.visible,"Touch on paper closes map "+tag)
		touch.pressed=false;Input.parse_input_event(touch)
		main.queue_free();await create_timer(.2).timeout
	FileAccess.open(OUT+"validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"fixtures":"Symbols fixture explicitly revealed for visual review; generated floor2 separately. Physical iPhone untested."},"  ")+"\n")
	print("MAP_REFINEMENT: ",checks," failures: ",failures.size()," captures: ",captures.size())
	quit(0 if failures.is_empty() else 1)
