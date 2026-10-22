extends SceneTree
## Actual resource, Main placement, room rendering and Pack review, without
## entering Main's scene tree or opening/writing a save slot.
const OUT := "res://art/concepts/events-trinkets-v1/"
const DM := preload("res://scripts/dungeon_map.gd")
const BUILDER := preload("res://scripts/level_builder.gd")
const PACK := preload("res://scripts/pack_screen.gd")
const PARTY := preload("res://scripts/party_state.gd")
const SG := preload("res://scripts/save_game.gd")
var results: Array=[]
var captures: Array=[]
func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")
func check(ok: bool,label: String) -> void:
	results.append({"check":label,"ok":ok})
	if not ok:push_error(label)
func settle() -> void:
	for i in 6:await process_frame
func snap(name: String) -> void:
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Saved "+name)
	captures.append(name)
func _run() -> void:
	var cat: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/items/trinkets-v1/catalog.json"))
	for entry: Dictionary in cat.items:
		for path: String in entry.resources:
			var gear: Equipment=load(path)
			check(gear.icon.resource_path==entry.icon and gear.icon.get_size()==Vector2(128,128),"Runtime trinket binding "+path)
			check(gear.slot=="trinket","Retained slot "+path)
			if gear.cleansed:check(gear.icon==gear.cleansed.icon,"Curse image reveals nothing "+path)
	for entry: Dictionary in cat.props:
		var prop: Node3D=load(entry.scene).instantiate()
		prop.state="empty";root.add_child(prop)
		var sprite: Sprite3D=prop.get_node("Sprite")
		check(sprite.texture==prop.empty_texture,"Pre-ready resolved restore "+entry.id)
		var held: Transform3D=sprite.transform
		prop.state="closed"
		check(sprite.texture==prop.closed_texture,"Fresh restore "+entry.id)
		check(sprite.shaded and sprite.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST,"Lit nearest "+entry.id)
		check(sprite.billboard==(0 if entry.mount=="wall" else 2),"Mount "+entry.id)
		check(prop.find_children("*","CollisionObject3D",true,false).is_empty() and prop.find_children("*","Light3D",true,false).is_empty(),"No physics or party light "+entry.id)
		prop.state="empty";check(sprite.transform==held,"Registered state swap "+entry.id)
		prop.queue_free()
	await settle()
	# Exercise production placement and rebuild calls on a detached Main.
	# Its _ready(), opening, autosave, music and campaign never run.
	var main=load("res://scripts/main.gd").new()
	var holder:=Node3D.new();root.add_child(holder);main._level=holder
	main._party_state=PARTY.new()
	main._party_state.add_member(load("res://data/companions/mara.tres"))
	for entry: Dictionary in cat.props:
		var event: RoomEvent=load(entry.event)
		var map=DM.new(PackedStringArray(["#####","#,,,#","#,,,#","#,,,#","#####"]))
		var cell:=Vector2i(2,1);map.events[cell]=event;map.contents[cell]=event.kind;main._map=map
		main._add_room_props()
		var node: Node3D=main._props[cell]
		check(node.state=="closed","Main starts fresh "+entry.id)
		check(node.position.distance_to(Vector3(4,0,2))>0.9 if event.prop_on_wall else node.position==Vector3(4,0,2),"Actual Main mount "+entry.id)
		main._map.triggered[cell]=true;main._empty_prop(cell)
		check(node.state=="empty" and node.get_node("Sprite").texture==node.empty_texture,"Main completion changes art "+entry.id)
		var packed: Dictionary=SG.pack_object(map)
		var restored=DM.new(map._rows,map.depth);SG.unpack_into(restored,packed);main._map=restored
		for child in holder.get_children():child.free()
		main._add_room_props()
		check(main._props[cell].state=="empty" and restored.enter(cell)==DM.Content.NONE,"Save data/revisit keeps resolved art "+entry.id)
		for child in holder.get_children():child.free()
	main._level=null;main.free();holder.queue_free();await settle()
	var world:=Node3D.new();root.add_child(world)
	var environment:=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("0d100e")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=.28
	var env:=WorldEnvironment.new();env.environment=environment;world.add_child(env)
	var camera:=Camera3D.new();world.add_child(camera);camera.fov=70;camera.current=true
	var light:=OmniLight3D.new();world.add_child(light);light.position=Vector3(4.25,1.4,6);light.omni_range=10;light.light_color=Color(1,.78,.53);light.light_energy=1.2
	var room=DM.new(PackedStringArray(["#####","#,,,#","#,,,#","#,,,#","#####"]))
	var level=BUILDER.new();world.add_child(level);level.build(room,load("res://themes/cave.tres"),2,2.4)
	for phone in [false,true]:
		root.size=Vector2i(1278,590) if phone else Vector2i(1280,720)
		var tag: String="phone" if phone else "desktop"
		for entry: Dictionary in cat.props:
			var art: Node3D=load(entry.scene).instantiate();world.add_child(art)
			art.position=Vector3(4,0,1.03) if entry.mount=="wall" else Vector3(4,0,3)
			camera.position=Vector3(4,1.2,3.5) if entry.mount=="wall" else Vector3(4,1.2,5.5)
			for state in ["closed","empty"]:
				art.state=state;await snap(entry.id+"-"+state+"-"+tag)
			art.queue_free();await settle()
	world.visible=false
	var party=PARTY.new();party.add_member(load("res://data/companions/mara.tres"))
	for entry: Dictionary in cat.items:party.supplies.gear.append(load(entry.resources[0]))
	var pack=PACK.new();root.add_child(pack);pack.setup(party);await settle()
	var textures: Array=pack.find_children("*","TextureRect",true,false)
	for entry: Dictionary in cat.items:
		check(textures.any(func(t):return t.texture!=null and t.texture.resource_path==entry.icon),"Actual Pack draws "+entry.id)
	for phone in [false,true]:
		root.size=Vector2i(1278,590) if phone else Vector2i(1280,720);await settle()
		for id in ["bloodstone","shield-bearers-token","goblin-gold-torc"]:
			var target: TextureRect=textures.filter(func(t):return t.texture!=null and t.texture.resource_path.ends_with("/"+id+".png"))[0]
			var row: Control=target
			while row.get_parent()!=pack._list:row=row.get_parent()
			pack._inventory_scroll.ensure_control_visible(row)
			await snap("pack-"+id+("-phone" if phone else "-desktop"))
	pack.queue_free();world.queue_free();await settle()
	var failed: int=results.filter(func(r):return not r.ok).size()
	var file:=FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"issue":142,"checks":results.size(),"failed":failed,"results":results,"captures":captures},"\t"));file.close()
	print("EVENT_TRINKET_GODOT: ",results.size()," checks, ",failed," failed; ",captures.size()," actual captures")
	quit(1 if failed else 0)
