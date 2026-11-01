extends SceneTree
## Isolated assets/composition/rendering. Never opens Main or a player file.
const COMPOSER:=preload("res://art/items/brews-v1/compose.gd")
const OUT:="res://art/concepts/descent-completion-v1/"
var checks:=0
var failures:Array[String]=[]
var thumbnails:Array[Dictionary]=[]

func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func settle() -> void:
	for i in 8:await process_frame
func save_json(path:String,data:Dictionary) -> void:
	var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(data,"\t")+"\n")

func run() -> void:
	var folder:="res://art/ui/expedition-v1/"
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"catalog.json"))
	for id in catalog.glyphs:
		var im:=Image.new()
		check(im.load_svg_from_string(FileAccess.get_file_as_string(folder+id+".svg"))==OK,"SVG "+id)
		check(im.get_size()==Vector2i(32,32),"Native glyph32 "+id)
		check(im.save_png(folder+id+".png")==OK,"Raster "+id)
	for i in 6:
		var im:=Image.new();check(im.load_svg_from_string(FileAccess.get_file_as_string(folder+"splash/frame-%d.svg"%i))==OK,"Splash SVG")
		check(im.get_size()==Vector2i(64,64),"Splash native64")
		im.save_png(folder+"splash/frame-%d.png"%i)
	var splash:=SpriteFrames.new();splash.remove_animation("default");splash.add_animation("shatter")
	splash.set_animation_loop("shatter",false);splash.set_animation_speed("shatter",12)
	for i in 6:splash.add_frame("shatter",load(folder+"splash/frame-%d.png"%i))
	check(ResourceSaver.save(splash,folder+"splash/frames.tres")==OK,"Six-frame tintable splash resource")
	var identities:={}
	var atlas:=Image.create(36*64,6*64,false,Image.FORMAT_RGBA8)
	for shape:String in COMPOSER.SHAPES:
		for colour in 6:
			for mark:String in COMPOSER.MARKS:
				var im:Image=COMPOSER.compose(shape,colour,mark)
				check(im.get_size()==Vector2i(64,64),"Composed64")
				var colours:={};var binary:=true
				for y in 64:
					for x in 64:
						var p:=im.get_pixel(x,y)
						binary=binary and (p.a==0 or p.a==1)
						if p.a>0:colours[p.to_rgba32()]=true
				check(binary,"Composed hard alpha")
				check(colours.size()<=32,"Composed palette32")
				identities[im.get_data().hex_encode().sha256_text()]=true
				atlas.blit_rect(im,Rect2i(0,0,64,64),Vector2i((colour*6+COMPOSER.MARKS.find(mark))*64,COMPOSER.SHAPES.find(shape)*64))
				if colour==COMPOSER.SHAPES.find(shape) and mark==COMPOSER.MARKS[colour]:im.save_png(OUT+"brew-demo-"+shape+".png")
	check(identities.size()==216,"All 216 visual identities distinct")
	atlas.save_png(OUT+"brew-atlas.png")
	for shape:String in COMPOSER.SHAPES:
		for kind in ["restorative","caustic","slumber","frenzy","revealing"]:
			var im:Image=COMPOSER.compose(shape,0,"eye",kind)
			check(im.get_size()==Vector2i(64,64),"Identified layer "+shape+kind)
	COMPOSER.compose("squat",0,"eye","restorative").save_png(OUT+"brew-identified.png")
	# Derive neutral journal outlines from each enemy's actual idle frame.
	DirAccess.make_dir_recursive_absolute(folder+"thumbnails")
	for file in DirAccess.get_files_at("res://data/enemies"):
		if not file.ends_with(".tres"):continue
		var enemy:EnemyType=load("res://data/enemies/"+file)
		if enemy.scene==null:continue
		var instance=enemy.scene.instantiate();var sprite=instance.find_child("Sprite",true,false)
		var tex:Texture2D
		if sprite is AnimatedSprite3D:
			var frames:SpriteFrames=sprite.sprite_frames
			if frames and frames.has_animation("idle") and frames.get_frame_count("idle")>0:tex=frames.get_frame_texture("idle",0)
		elif sprite is Sprite3D:tex=sprite.texture
		if tex:
			var im:=tex.get_image();var used:=im.get_used_rect();im=im.get_region(used)
			var scale:=minf(56.0/im.get_width(),56.0/im.get_height())
			im.resize(maxi(1,roundi(im.get_width()*scale)),maxi(1,roundi(im.get_height()*scale)),Image.INTERPOLATE_NEAREST)
			var silhouette:=Image.create(64,64,false,Image.FORMAT_RGBA8)
			for y in im.get_height():
				for x in im.get_width():
					if im.get_pixel(x,y).a>=0.5:silhouette.set_pixel(x+(64-im.get_width())/2,y+(64-im.get_height())/2,Color("302d25"))
			var path:=folder+"thumbnails/"+file.trim_suffix(".tres")+".png";silhouette.save_png(path)
			thumbnails.append({"enemy":file,"source_scene":enemy.scene.resource_path,"source_texture":tex.resource_path,"thumbnail":path})
			check(not silhouette.is_empty(),"Journal silhouette "+file)
		instance.free()
	save_json(folder+"thumbnails/catalog.json",{"items":thumbnails,"knowledge_state_owned_by_caller":true})
	for id in ["reservoir-wall","reservoir-floor","reservoir-ceiling"]:
		var m:StandardMaterial3D=load("res://art/textures/reservoir-v1/"+id+".tres")
		check(m!=null and m.albedo_texture.get_size()==Vector2(128,128),"Reservoir material "+id)
		check(m.texture_filter==0 and m.texture_repeat,"Nearest repeat "+id)
	for id in ["stairs","water-edge"]:
		var node=load("res://art/props/reservoir-finish-v1/"+id+".tscn").instantiate()
		check(node.get_node("Sprite").billboard==0,"Fixed wall "+id);node.free()
	if DisplayServer.get_name()!="headless":await render_world()
	save_json(OUT+"godot-validation.json",{"checks":checks,"failures":failures,"identities":identities.size(),"journal_thumbnails":thumbnails.size(),"renderer":RenderingServer.get_current_rendering_method(),"uses_player_files":false})
	print("DESCENT_GODOT: %d checks, %d failures, %d silhouettes"%[checks,failures.size(),thumbnails.size()])
	quit(0 if failures.is_empty() else 1)

func render_world() -> void:
	var world:=Node3D.new();root.add_child(world)
	var camera:=Camera3D.new();camera.position=Vector3(0,0.95,2.6);camera.current=true;world.add_child(camera)
	var lamp:=OmniLight3D.new();lamp.position=Vector3(0,1.4,1);lamp.omni_range=8;lamp.light_energy=1.2;world.add_child(lamp)
	for kind in ["wall","left","right","floor","ceiling"]:
		var mesh:=MeshInstance3D.new()
		if kind in ["wall","left","right"]:
			var quad:=QuadMesh.new();quad.size=Vector2(4 if kind=="wall" else 6,2);mesh.mesh=quad
			mesh.position=Vector3(0,1,-1) if kind=="wall" else Vector3(-2 if kind=="left" else 2,1,0.5)
			if kind!="wall":mesh.rotation.y=PI/2 if kind=="left" else -PI/2
		else:
			var plane:=PlaneMesh.new();plane.size=Vector2(4,6);mesh.mesh=plane;mesh.position.z=0.5
			if kind=="ceiling":mesh.position.y=2;mesh.rotation.x=PI
		var family:String="wall" if kind in ["left","right"] else kind
		mesh.material_override=load("res://art/textures/reservoir-v1/reservoir-"+family+".tres").duplicate()
		mesh.material_override.uv1_scale=Vector3(2,1 if family=="wall" else 3,1)
		world.add_child(mesh)
	for shape in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=shape
		for id in ["surfaces","stairs","water-edge"]:
			var prop:Node3D
			if id!="surfaces":
				prop=load("res://art/props/reservoir-finish-v1/"+id+".tscn").instantiate();prop.position.z=-0.93;world.add_child(prop)
			await settle();await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(OUT+"world-%s-%d.png"%[id,shape.x])==OK,"Renderer capture "+id)
			if prop:prop.free()
	world.free();await process_frame
	var backdrop:=TextureRect.new();backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture=load("res://art/illustrations/descent-v1/vision.png");backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;root.add_child(backdrop)
	var vision=load("res://scripts/vision_filter.gd").new();root.add_child(vision)
	vision._material.set_shader_parameter("strength",1.0);vision._material.set_shader_parameter("shimmer",0.0);vision._rect.visible=true
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+"vision-filter-still.png")==OK,"Actual vision filter, effects off")
	vision.free();backdrop.free();await process_frame
