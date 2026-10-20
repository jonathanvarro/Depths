extends SceneTree
## Standalone material/attachment/animation review. Does not instantiate Main,
## change any theme, save, place live dressing or create a gameplay controller.
const OUT := "res://art/concepts/cave-dressing-v1/"
const DIR := "res://art/dressing/cave-v1/"
const DM := preload("res://scripts/dungeon_map.gd")
const BUILDER := preload("res://scripts/level_builder.gd")
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var dressing: Node3D
var world: Node3D
var environment: Environment
var lantern: OmniLight3D

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures.append(label);push_error(label)

func attach(id: String,point: Vector3,rotation_y := 0.0) -> Node3D:
	var art: Node3D=load(DIR+id+".tscn").instantiate()
	dressing.add_child(art);art.position=point;art.rotation.y=rotation_y
	return art

func snap(name: String) -> void:
	for tick in 6:await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"Saved "+name)
	captures.append(name)

func _run() -> void:
	var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"catalog.json"))
	for entry: Dictionary in catalogue.assets:
		var texture: Texture2D=load(entry.texture)
		check(texture!=null and texture.get_size()==Vector2(128,128),"Imported native "+entry.id)
		var scene: Node3D=load(entry.scene).instantiate()
		check(scene.find_children("*","CollisionObject3D",true,false).is_empty(),"Dressing adds no collider "+entry.id)
		var sprite: Sprite3D=scene.get_node("Sprite")
		check(sprite.shaded and sprite.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST,"Lit nearest texture "+entry.id)
		check(sprite.billboard==0 if entry.mount in ["wall","floor-decal","corner"] or entry.id.begins_with("mine-") else sprite.billboard==2,"Mount orientation "+entry.id)
		scene.free()
	var fx: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/effects/ambient-v1/catalog.json"))
	for entry: Dictionary in fx.effects:
		var texture: Texture2D=load(entry.texture)
		check(texture.get_width()<=4096 and texture.get_height()<=4096,"Phone atlas dimensions "+entry.id)
		if entry.has("frames"):
			var frames: SpriteFrames=load(entry.frames)
			check(frames.get_frame_count("loop")==entry.frame_count,"Every animation frame imported "+entry.id)
			if entry.id.begins_with("eyes"):
				var closed: Image=frames.get_frame_texture("loop",5).get_image()
				var clear:=true
				for y in closed.get_height():
					for x in closed.get_width():
						clear=clear and closed.get_pixel(x,y).a==0.0
				check(clear,"Imported closed eye frame has no leftover glint "+entry.id)
			if entry.id=="darkness":
				var first: Image=frames.get_frame_texture("loop",0).get_image()
				var clear:=true
				for y in range(108,252):
					for x in range(192,448):
						clear=clear and first.get_pixel(x,y).a==0.0
				check(clear,"Imported darkness keeps the centre clear")
	var strip: Image=(load("res://art/effects/ambient-v1/fog-strip.png") as Texture2D).get_image()
	var wrap:=true
	for y in strip.get_height():
		wrap=wrap and strip.get_pixel(0,y)==strip.get_pixel(255,y)
	check(wrap,"Fog strip joins exactly at wrap")
	world=Node3D.new();root.add_child(world)
	environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("0d100e")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=.28
	var env:=WorldEnvironment.new();env.environment=environment;world.add_child(env)
	var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(4,1.2,6.4);camera.fov=70;camera.current=true
	lantern=OmniLight3D.new();world.add_child(lantern);lantern.position=Vector3(4.25,1.4,6.5);lantern.omni_range=10;lantern.light_color=Color(1,.78,.53);lantern.light_energy=1.2
	var map=DM.new(PackedStringArray(["#####","#,,,#","#,,,#","#,,,#","#####"]))
	var level=BUILDER.new();world.add_child(level);level.build(map,load("res://themes/cave.tres"),2.0,2.4)
	var layer:=CanvasLayer.new();root.add_child(layer)
	var title:=Label.new();layer.add_child(title);title.position=Vector2(16,12);title.add_theme_font_size_override("font_size",22)
	title.add_theme_color_override("font_shadow_color",Color.BLACK);title.add_theme_constant_override("shadow_offset_x",2);title.add_theme_constant_override("shadow_offset_y",2)
	for phone in [false,true]:
		root.size=Vector2i(1278,590) if phone else Vector2i(1280,720)
		var tag:="phone" if phone else "desktop"
		for setting in ["old-workings","damp-cave","goblin-wall","floor-details","wall-close"]:
			dressing=Node3D.new();world.add_child(dressing)
			camera.position=Vector3(4,1.2,6.4)
			lantern.light_energy=1.2;environment.ambient_light_energy=.28
			match setting:
				"old-workings":
					attach("mine-support",Vector3(4,0,4))
					attach("mine-rails",Vector3(4,0,5.2),PI/2)
					attach("burnt-sconce",Vector3(2.1,1.3,1.02))
					attach("chalk-cross",Vector3(5.6,1.15,1.02))
					attach("floor-gravel",Vector3(3.1,0,4.9))
				"damp-cave":
					attach("stalactite-pair",Vector3(2.6,2.4,3.6))
					attach("stalactite-cluster",Vector3(5.3,2.4,2.0))
					attach("stalagmite-stub",Vector3(2.5,0,2.4))
					attach("flowstone",Vector3(4.6,1.25,1.02))
					attach("corner-web",Vector3(1.15,2.3,1.03))
					attach("puddle-wide",Vector3(4.4,0,4.9))
					attach("pale-mushrooms",Vector3(2.7,0,3.6))
					attach("wall-fungus",Vector3(5.8,.55,1.03))
					var fog:=MeshInstance3D.new()
					var quad:=QuadMesh.new();quad.size=Vector2(3,.35);fog.mesh=quad
					var material:=ShaderMaterial.new();material.shader=load("res://art/effects/ambient-v1/fog-scroll.gdshader")
					material.set_shader_parameter("fog_texture",load("res://art/effects/ambient-v1/fog-strip.png"))
					fog.material_override=material;dressing.add_child(fog);fog.position=Vector3(4,.18,4.2)
				"goblin-wall":
					attach("goblin-torch-lit",Vector3(3.1,1.2,1.03))
					attach("goblin-daubs",Vector3(4.6,1.25,1.03))
					attach("hanging-trophies",Vector3(5.6,2.4,1.4))
					attach("goblin-litter",Vector3(4.5,0,4.4))
					lantern.light_energy=.3;environment.ambient_light_energy=.16
				"floor-details":
					attach("puddle-small",Vector3(3.0,0,4.0))
					attach("tracks-drag",Vector3(4.6,0,4.5))
					attach("floor-crack",Vector3(3.6,0,3.2))
					attach("old-scorch",Vector3(5.4,0,5.1))
					attach("rat-nest",Vector3(1.5,0,3.0))
				"wall-close":
					camera.position=Vector3(4,1.2,3.6)
					attach("goblin-torch-lit",Vector3(3.1,1.2,1.03))
					attach("burnt-sconce",Vector3(4.9,1.2,1.03))
					attach("goblin-daubs",Vector3(4,1.0,1.03))
					attach("hanging-trophies",Vector3(5.6,2.4,1.4))
					lantern.light_energy=.3;environment.ambient_light_energy=.16
			title.text=setting+" / "+tag+" / standalone asset fixture"
			await snap(setting+"-"+tag)
			dressing.queue_free();await process_frame
	var report:={"checks":checks,"failures":failures,"captures":captures,"dressing_assets":catalogue.assets.size(),"effects":fx.effects.size(),
		"limits":"Standalone fixture; no live placement/controller, gameplay, save or theme changes. Phone is a desktop-size simulation."}
	var file:=FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("CAVE_DRESSING checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
