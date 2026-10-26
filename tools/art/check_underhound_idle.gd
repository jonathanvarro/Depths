extends SceneTree
## Idle candidate scene/phone review only; no Main, save, combat or enemy rules.
const OUT:="res://art/concepts/underhound-idle-v1/"
const IDLE:=preload("res://art/enemies/underhound-v1/scene.tscn")
const BREACH:=preload("res://art/enemies/monsters-v1/breach-hound/scene.tscn")
const BUILDER:=preload("res://scripts/level_builder.gd")
const DM:=preload("res://scripts/dungeon_map.gd")
var checks:=0
var failures:Array[String]=[]
var captures:Array[String]=[]

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
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

func run() -> void:
	preload("res://scripts/ui_theme.gd").install()
	var world:=Node3D.new();root.add_child(world)
	var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("131713")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("1a2424");env.ambient_light_energy=0.4
	var we:=WorldEnvironment.new();we.environment=env;world.add_child(we)
	var party:=preload("res://scripts/party.gd").new();world.add_child(party);party.setup(2)
	party.position=Vector3(10,0,12);party.locked=true;party.camera.current=true;party.set_light(0.8)
	var underhound:=IDLE.instantiate();world.add_child(underhound);underhound.position=Vector3(10,0,9.6)
	var reference:=BREACH.instantiate();world.add_child(reference);reference.position=Vector3(9.4,0,9.6);reference.hide()
	var sprite:AnimatedSprite3D=underhound.get_node("Sprite")
	var texture:=sprite.sprite_frames.get_frame_texture(&"idle",0)
	check(texture.get_size()==Vector2(128,128),"Exact native128 canvas imports")
	check(sprite.sprite_frames.has_animation(&"idle") and sprite.sprite_frames.get_frame_count(&"idle")==1,"Approved idle remains a single authored drawing")
	check(sprite.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST and sprite.alpha_cut==SpriteBase3D.ALPHA_CUT_DISCARD,"Nearest sampling and hard alpha")
	check(sprite.shaded and sprite.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"Shaded sprite without a painted/cast floor shadow")
	check(is_equal_approx(sprite.position.y+(64-120)*sprite.pixel_size,0.0),"Pixel120 contact registers on the world floor")
	await settle()
	check(underhound.get_meta("pivot")==Vector2(64,120),"Common family pivot retained")
	check(absf(float(underhound.get_meta("art_height",underhound.get_meta("visual_height")))-0.8)<0.02,"Pose-aware art bounds match the 0.8m body")
	var image:=texture.get_image();var original:=Image.new()
	check(original.load_png_from_buffer(FileAccess.get_file_as_bytes("res://art/enemies/underhound-v1/idle.png"))==OK,"Native PNG bytes decode")
	var colors:={};var alpha_ok:=true;var bottom:=-1;var clear_rgb:=true
	for y in 128:
		for x in 128:
			var pixel:=image.get_pixel(x,y)
			alpha_ok=alpha_ok and (pixel.a==0 or pixel.a==1)
			if pixel.a>0:colors[pixel.to_rgba32()]=true;bottom=maxi(bottom,y)
			# Godot's ordinary alpha-border importer may pad invisible RGB;
			# the exported PNG must stay clear, while imported alpha stays hard.
			var source_pixel:=original.get_pixel(x,y)
			if source_pixel.a==0:clear_rgb=clear_rgb and source_pixel.r==0 and source_pixel.g==0 and source_pixel.b==0
	check(alpha_ok and clear_rgb,"Binary imported alpha and clear invisible RGB in the native PNG")
	check(colors.size()<=32 and colors.size()>1,"At most 32 visible colours")
	check(bottom==120,"Lowest visible contact is exactly y120")
	var map=DM.new(PackedStringArray(["###########","#.........#","#.........#","#.........#","#.........#","#.........#","#....S....#","#.........#","###########"]),2)
	var ui:=CanvasLayer.new();root.add_child(ui)
	var title:=Label.new();title.text="Underhound · idle candidate";title.position=Vector2(20,12)
	title.add_theme_font_size_override("font_size",23);ui.add_child(title)
	var note:=Label.new();note.text="Art fixture · native128 · 0.8m body · no encounter assignment";note.position=Vector2(20,44)
	note.add_theme_font_size_override("font_size",17);ui.add_child(note)
	for family in ["cave","fungal-caverns"]:
		var level:=BUILDER.new();world.add_child(level);level.build(map,load("res://themes/"+family+".tres"),2,2.4)
		for shape in [Vector2i(1280,720),Vector2i(1278,590)]:
			root.size=shape;reference.hide();underhound.position.x=10
			await snap("idle-%s-%d"%[family,shape.x])
			var top:=party.camera.unproject_position(underhound.position+Vector3(0,0.8,0))
			var foot:=party.camera.unproject_position(underhound.position)
			check(top.y>80 and foot.y<shape.y-10,"Full body fits first-person %s %d"%[family,shape.x])
			if family=="cave":
				underhound.position.x=10.6;reference.show()
				title.text="Existing breach hound (left) · Underhound idle (right)"
				await snap("family-%d"%shape.x)
				title.text="Underhound · idle candidate"
		level.free()
	var file:=FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"physical_iPhone":false,"uses_Main_or_saves":false,"scope":"Idle-only scene and first-person display-size review, not combat integration"},"\t")+"\n");file.close()
	ui.free();world.free();await settle()
	print("UNDERHOUND_IDLE: checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
