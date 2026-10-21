extends SceneTree
## Isolated #132 mount/state/map review; no Main, gameplay or save fixture.
const OUT := "res://art/concepts/landmarks-v1/"
const DIR := "res://art/dressing/landmarks-v1/"
const DM := preload("res://scripts/dungeon_map.gd")
const BUILDER := preload("res://scripts/level_builder.gd")
const MAP := preload("res://scripts/minimap.gd")
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var world: Node3D
var dressing: Node3D

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures.append(label)
		push_error(label)

func attach(id: String, point: Vector3) -> Node3D:
	var art: Node3D=load(DIR+id+".tscn").instantiate()
	dressing.add_child(art)
	art.position=point
	return art

func snap(name: String) -> void:
	for tick in 6: await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Saved "+name)
	captures.append(name)

func _run() -> void:
	var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"catalog.json"))
	for entry: Dictionary in catalogue.assets:
		var texture: Texture2D=load(entry.texture)
		check(texture!=null and texture.get_size()==Vector2(128,128),"Native imported "+entry.id)
		var art: Node3D=load(entry.scene).instantiate()
		check(art.find_children("*","CollisionObject3D",true,false).is_empty(),"No collision "+entry.id)
		var sprite: Sprite3D=art.get_node("Sprite")
		check(sprite.shaded and sprite.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST,"Lit nearest pixels "+entry.id)
		check(is_equal_approx(sprite.pixel_size,entry.pixel_size),"Physical scale "+entry.id)
		check(sprite.billboard==(2 if entry.mount in ["ceiling","floor-edge"] else 0),"Mount orientation "+entry.id)
		if entry.mount=="floor-decal":
			check(is_equal_approx(sprite.rotation_degrees.x,-90) and sprite.position.y>0,"Flat offset decal "+entry.id)
		if entry.mount=="ceiling":
			check(is_equal_approx(sprite.position.y+(64-entry.pivot[1])*sprite.pixel_size,0),"Top anchor "+entry.id)
		if entry.mount=="floor-edge":
			check(is_equal_approx(sprite.position.y-(entry.pivot[1]-64)*sprite.pixel_size,0),"Foot anchor "+entry.id)
		art.free()
	var shrine: Node3D=load(catalogue.event_scene).instantiate()
	shrine.state="empty" # Setting before _ready supports a resolved room restore.
	root.add_child(shrine)
	check(shrine.get_node("Sprite").texture==shrine.empty_texture,"Pre-ready resolved niche")
	check(shrine.get_node("Offerings").texture==shrine.spent_offerings_texture,"Resolved offerings")
	check(not shrine.get_node("Glow").visible and not shrine.get_node("Glow").is_playing(),"Resolved candles stay out")
	var positions: Array=shrine.get_children().map(func(n):return n.position)
	shrine.state="closed"
	check(shrine.get_node("Sprite").texture==shrine.closed_texture and shrine.get_node("Offerings").texture==shrine.offerings_texture,"Fresh state restores both layers")
	check(shrine.get_node("Glow").visible and shrine.get_node("Glow").is_playing(),"Fresh glow plays")
	shrine.candle_glow_enabled=false
	check(not shrine.get_node("Glow").visible,"Optional glow disables")
	shrine.candle_glow_enabled=true
	check(shrine.get_children().map(func(n):return n.position)==positions,"State changes preserve physical registration")
	check(shrine.get_node("Glow").sprite_frames.get_frame_count("glow")==2,"Two imported glow frames")
	check(shrine.find_children("*","Light3D",true,false).is_empty(),"Candle accent never changes held-light rules")
	shrine.queue_free()
	await process_frame

	world=Node3D.new()
	root.add_child(world)
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("0d100e")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color.WHITE
	environment.ambient_light_energy=.28
	var env:=WorldEnvironment.new()
	env.environment=environment
	world.add_child(env)
	var camera:=Camera3D.new()
	world.add_child(camera)
	camera.position=Vector3(4,1.2,6.4)
	camera.fov=70
	camera.current=true
	var lantern:=OmniLight3D.new()
	world.add_child(lantern)
	lantern.position=Vector3(4.25,1.4,6.5)
	lantern.omni_range=10
	lantern.light_color=Color(1,.78,.53)
	lantern.light_energy=1.2
	var room=DM.new(PackedStringArray(["#####","#,,,#","#,,,#","#,,,#","#####"]))
	var level=BUILDER.new()
	world.add_child(level)
	level.build(room,load("res://themes/cave.tres"),2.0,2.4)
	var layer:=CanvasLayer.new()
	root.add_child(layer)
	var title:=Label.new()
	layer.add_child(title)
	title.position=Vector2(16,12)
	title.add_theme_font_size_override("font_size",22)
	title.add_theme_color_override("font_shadow_color",Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x",2)
	title.add_theme_constant_override("shadow_offset_y",2)
	for phone in [false,true]:
		root.size=Vector2i(1278,590) if phone else Vector2i(1280,720)
		var tag:="phone" if phone else "desktop"
		for setting in ["roots","cache","shrine-fresh","shrine-used","shrine-glow-off"]:
			dressing=Node3D.new()
			world.add_child(dressing)
			camera.position=Vector3(4,1.2,6.4)
			match setting:
				"roots":
					attach("root-curtain-a",Vector3(2.8,2.4,3.4))
					attach("root-curtain-b",Vector3(5.0,2.4,3.2))
					attach("wall-roots",Vector3(3,1.25,1.03))
					attach("root-foot-tangle",Vector3(2.1,0,2.2))
					attach("floor-crossing-root",Vector3(4,0,4.3))
				"cache":
					attach("collapsed-crates",Vector3(2.8,0,2.2))
					attach("split-barrel",Vector3(5.7,0,2.0))
					attach("fallen-banner",Vector3(4.7,0,4.1))
					attach("cache-rubble-planks",Vector3(3.0,0,4.4))
					attach("cache-spilled-grain",Vector3(5.4,0,3.5))
				_:
					camera.position=Vector3(4,1.2,3.6)
					var event:=attach("miners-shrine-event",Vector3(4,0,1.03))
					event.set("state","empty" if setting=="shrine-used" else "closed")
					event.set("candle_glow_enabled",setting!="shrine-glow-off")
			title.text=setting+" / "+tag+" / standalone art fixture"
			await snap(setting+"-"+tag)
			dressing.queue_free()
			await process_frame
	world.visible=false
	title.visible=false
	var map=DM.new(PackedStringArray(["#########","#<......#","#.###.#.#","#...#.#.#","#...#...#","#...###.#","#.......#","#########"]))
	for y in map.height:
		for x in map.width:
			map.explored[Vector2i(x,y)]=true
	map.landmarks=[{"id":"root_fixture","name":"Root junction","centre":Vector2i(3,4),"seen":true},{"id":"hidden_fixture","name":"Unseen cache","centre":Vector2i(7,4),"seen":false}]
	var full:=MAP.new()
	layer.add_child(full)
	full.full_view=true
	full.setup(map)
	full.on_party_moved(Vector2i(3,6),0)
	var mini:=MAP.new()
	layer.add_child(mini)
	mini.setup(map)
	mini.on_party_moved(Vector2i(3,6),0)
	check(MAP.GLYPHS.landmark.get_size()==Vector2(32,32),"32px live glyph")
	check(full._notes().any(func(n):return n.title=="Root junction"),"Known landmark in discoveries")
	check(not full._notes().any(func(n):return n.title=="Unseen cache"),"Unknown landmark stays unnamed")
	for phone in [false,true]:
		root.size=Vector2i(1278,590) if phone else Vector2i(1280,720)
		full.position=Vector2(16,16)
		full.size=Vector2(root.size)-Vector2(260,32)
		mini.position=Vector2(root.size.x-220,24)
		mini.size=mini.custom_minimum_size
		full.queue_redraw()
		await snap("map-"+("phone" if phone else "desktop"))
	var report:={"checks":checks,"failures":failures,"captures":captures,"limits":"Standalone mounted art and real Minimap. No live placement, Main or saves. Desktop phone-size simulation, not physical iPhone."}
	var file:=FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	file.close()
	print("LANDMARK_ART checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
