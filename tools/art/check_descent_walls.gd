extends SceneTree
## #126: standalone library, existing LevelBuilder geometry, neutral/warm views.
const DM=preload("res://scripts/dungeon_map.gd")
const BUILDER=preload("res://scripts/level_builder.gd")
const OUT="res://art/concepts/descent-walls-v1/"
var checks:=0
var failures:Array[String]=[]
var captures:Array[String]=[]

func _initialize()->void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("_run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func _run()->void:
	var catalogue:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/textures/descent-walls-v1/catalog.json"))
	var original_cave:EnvironmentTheme=load("res://themes/cave.tres")
	var original_wall:=original_cave.wall_material
	var world:=Node3D.new();root.add_child(world)
	var environment:=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("111510")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color.WHITE
	var env_node:=WorldEnvironment.new();env_node.environment=environment;world.add_child(env_node)
	var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(8,1.35,14);camera.fov=70;camera.current=true
	var lantern:=OmniLight3D.new();world.add_child(lantern);lantern.position=Vector3(8.25,1.4,13.3);lantern.omni_range=16;lantern.light_color=Color(1,.76,.48)
	var ui:=CanvasLayer.new();root.add_child(ui)
	var label:=Label.new();ui.add_child(label);label.position=Vector2(18,14);label.add_theme_font_size_override("font_size",24)
	label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2)
	var map=DM.new(PackedStringArray(["#########","#.......#","#.......#","#..###..#","#.......#","#.......#","#.......#","#...S...#","#########"]))
	for asset:Dictionary in catalogue.assets:
		var material:StandardMaterial3D=load(asset.material)
		check(material.albedo_texture.get_size()==Vector2(128,128),asset.id+" native texture imported")
		check(material.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST and material.texture_repeat,asset.id+" nearest repeated material")
		check(not material.emission_enabled and material.roughness==1.0,asset.id+" no baked glow/expensive surface features")
		var theme:EnvironmentTheme=original_cave.duplicate()
		theme.wall_material=material;theme.wall_variant_material=material
		var level=BUILDER.new();world.add_child(level);level.build(map,theme,2.0,2.7)
		check(level.get_child_count()>0,asset.id+" actual LevelBuilder walls")
		for setting:String in ["neutral","lantern","phone-lantern"]:
			root.size=Vector2i(1278,590) if setting=="phone-lantern" else Vector2i(1280,720)
			environment.ambient_light_energy=.85 if setting=="neutral" else .2
			lantern.light_energy=0.0 if setting=="neutral" else 2.0
			label.text=asset.label+" / "+setting+" / material review"
			for tick in 5:await process_frame
			await RenderingServer.frame_post_draw
			var path:String=OUT+asset.id+"-"+setting+".png"
			check(root.get_texture().get_image().save_png(path)==OK,"Saved "+path)
			captures.append(path)
		level.queue_free();await process_frame
	check(original_cave.wall_material==original_wall,"Live cave theme remains unchanged")
	var report:={"checks":checks,"failures":failures,"materials":catalogue.assets.size(),"captures":captures,
		"geometry":"Existing LevelBuilder BoxMesh walls and cave floor/ceiling; no UV or live-floor changes.",
		"lighting":"Shared neutral ambient or warm test lantern; not a new fuel/light mechanic.","phone":"1278x590 desktop simulation, not physical iPhone validation."}
	var file:=FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("DESCENT_WALLS checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
