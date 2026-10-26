extends SceneTree
## Three-pose scene with real BattleStage, CombatScreen and PartyCards; no Main/save.
const OUT:="res://art/concepts/underhound-poses-v1/"
const SCENE:=preload("res://art/enemies/underhound-v1/scene.tscn")
const CS:=preload("res://scripts/combat_state.gd")
const SCREEN:=preload("res://scripts/combat_screen.gd")
const STAGE:=preload("res://scripts/battle_stage.gd")
const SETTINGS:=preload("res://scripts/settings.gd")
var checks:=0
var failures:Array[String]=[]
var captures:Array[String]=[]
var world:Node3D
var camera:Camera3D
var ui:CanvasLayer
var safe:Control
var row:HBoxContainer
var cards:Array=[]
var screen
var actor:Node3D
var party
var state

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	Engine.set_meta("depths_settings",SETTINGS.DEFAULTS.duplicate())
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

func visible_rect(sprite:AnimatedSprite3D) -> Rect2:
	var box:=sprite.sprite_frames.get_frame_texture(sprite.animation,0).get_image().get_used_rect()
	var top:=sprite.global_position+Vector3((box.position.x-64)*sprite.pixel_size,(64-box.position.y)*sprite.pixel_size,0)
	var bottom:=sprite.global_position+Vector3((box.end.x-64)*sprite.pixel_size,(64-box.end.y)*sprite.pixel_size,0)
	return Rect2(camera.unproject_position(top),camera.unproject_position(bottom)-camera.unproject_position(top))

func fit_family() -> void:
	# One offset for the whole family, never a new fit/baseline for each pose.
	actor.position.y=0
	var lowest:=camera.unproject_position(actor.global_position+Vector3(0,-8.0*0.8/89.0,0)).y
	var limit:=minf(row.get_global_rect().position.y,screen._actions.get_global_rect().position.y)-10
	if lowest>limit:
		var metres:=2.0*2.4*tan(deg_to_rad(camera.fov)/2.0)/root.get_visible_rect().size.y
		actor.position.y+=(lowest-limit)*metres

func run() -> void:
	SETTINGS.ensure_buses();AudioServer.set_bus_mute(0,true)
	preload("res://scripts/ui_theme.gd").install()
	world=Node3D.new();root.add_child(world)
	var environment:=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("12110e")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=0.35
	var we:=WorldEnvironment.new();we.environment=environment;world.add_child(we)
	camera=Camera3D.new();world.add_child(camera);camera.position=Vector3(0,1.2,0);camera.fov=70;camera.current=true
	var light:=OmniLight3D.new();world.add_child(light);light.position=Vector3(-0.4,1.8,0.2)
	light.light_color=Color(1,0.8,0.58);light.light_energy=1.4;light.omni_range=12
	var stage:=STAGE.new();camera.add_child(stage);stage.fit(camera);await stage.enter(false)
	ui=CanvasLayer.new();root.add_child(ui)
	safe=Control.new();safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(safe)
	row=HBoxContainer.new();row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	row.grow_vertical=Control.GROW_DIRECTION_BEGIN;row.offset_bottom=-16;row.offset_left=16
	row.add_theme_constant_override("separation",10);safe.add_child(row)
	party=preload("res://scripts/party_state.gd").new()
	for id in ["mara"]:
		party.add_member(load("res://data/companions/"+id+".tres"))
		var hero:Companion=party.members[-1];hero.speed_base=1000;hero.refresh_stats()
		var card:=preload("res://scripts/party_card.gd").new();row.add_child(card);card.show_companion(hero);cards.append(card)
	# Borrow existing hound numbers solely to exercise the current combat UI.
	var type:EnemyType=load("res://data/enemies/breach_hound.tres").duplicate()
	type.display_name="Underhound";type.scene=SCENE;type.initiative=0
	state=CS.new(party,[type] as Array[EnemyType])
	actor=SCENE.instantiate();world.add_child(actor);actor.position=Vector3(0,0,-2.4)
	state.foes[0].node=actor
	var sprite:AnimatedSprite3D=actor.get_node("Sprite")
	check(sprite.sprite_frames.get_animation_names().size()==3,"Exactly three authored states")
	var texture_paths:={}
	var union:={}
	for pose:String in ["idle","attack","hurt"]:
		check(sprite.sprite_frames.has_animation(pose) and sprite.sprite_frames.get_frame_count(pose)==1,"One distinct drawing for "+pose)
		var texture:=sprite.sprite_frames.get_frame_texture(pose,0)
		texture_paths[texture.resource_path]=true
		check(texture.get_size()==Vector2(128,128),"Native128 "+pose)
		var im:=texture.get_image();var alpha_ok:=true
		for y in 128:
			for x in 128:
				var pixel:=im.get_pixel(x,y)
				alpha_ok=alpha_ok and (pixel.a==0 or pixel.a==1)
				if pixel.a>0:union[pixel.to_rgba32()]=true
		check(alpha_ok,"Hard alpha "+pose)
	check(texture_paths.size()==3 and union.size()<=32,"No pose aliases and one shared 32-colour palette")
	check(is_equal_approx(sprite.pixel_size,0.8/89.0) and is_equal_approx(sprite.position.y,56*0.8/89.0),"Same approved physical scale and pivot for every state")
	STAGE.raise(actor)
	screen=SCREEN.new();ui.add_child(screen);screen.run(state,cards)
	screen._busy[state.foes[0]]=true  # hold the reviewed one-off pose; leave tag updates live
	var label:=Label.new();ui.add_child(label);label.position=Vector2(20,12)
	label.text="Underhound art review";label.add_theme_font_size_override("font_size",18)
	for shape in [Vector2i(1280,720),Vector2i(1278,590)]:
		root.size=shape
		for factor in [1.0,1.3]:
			root.content_scale_factor=factor
			var insets:=preload("res://scripts/safe_area.gd").insets(root,shape.y==590)
			safe.offset_left=insets.x;safe.offset_top=insets.y;safe.offset_right=-insets.z;safe.offset_bottom=-insets.w
			screen.content.offset_left=insets.x;screen.content.offset_top=insets.y
			screen.content.offset_right=-insets.z;screen.content.offset_bottom=-insets.w
			label.position=Vector2(insets.x+16,insets.y+48)
			stage.fit(camera);await settle();fit_family();await settle()
			var origin:=actor.position
			check(screen._actions.visible,"Real actions await player at %s / %s"%[shape,factor])
			check(not row.get_global_rect().intersects(screen._actions.get_global_rect()),"Preview portrait and actions remain separate")
			for pose:String in ["idle","attack","hurt"]:
				label.text="Art preview · "+pose
				sprite.play(pose);sprite.pause();await settle()
				var im:=sprite.sprite_frames.get_frame_texture(pose,0).get_image()
				var top:int=im.get_used_rect().position.y
				var actual_top:=sprite.position.y+(64-top)*sprite.pixel_size
				check(is_equal_approx(float(actor.get_meta("art_height")),actual_top) and is_equal_approx(float(actor.get_meta("visual_height")),actual_top+0.12),"Pose-aware art height and tag clearance "+pose)
				check(actor.position==origin,"No per-pose recenter/ground snap "+pose)
				var bounds:=visible_rect(sprite)
				check(root.get_visible_rect().encloses(bounds),"Complete pose fits viewport "+pose)
				check(bounds.end.y<=minf(row.get_global_rect().position.y,screen._actions.get_global_rect().position.y)-2,"Pose clears HUD "+pose)
				var tag:Button=screen._tags.values()[0]
				check(tag.get_global_rect().end.y<=bounds.position.y,"Name/intention clears pose "+pose)
				await snap("combat-%d-%s-%s"%[shape.x,"larger" if factor>1 else "normal",pose])
	screen.hide();await settle()
	ui.free();world.free();cards.clear();party=null;state=null;screen=null;actor=null;await settle()
	var file:=FileAccess.open(OUT+"godot-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"physical_iPhone":false,"uses_Main_or_saves":false,"balance":"Existing breach-hound numbers copied in memory for art review only; no new enemy definition"},"\t")+"\n");file.close()
	print("UNDERHOUND_FAMILY: checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
