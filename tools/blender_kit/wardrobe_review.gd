extends Control
## #214: isolated native review, never loads the game, saves or preferences.
const Actor=preload("res://actor.gd")
var MOTIONS:Array=["rest","idle","walk","sit_down","seated","dying"]
const ANGLES=["Front","Three-quarter","Side","Back"]
const PIECES=["tunic","belt","trousers","boot.left","boot.right"]
var manifest:Dictionary
var actors:Array=[]
var viewports:Array[SubViewport]=[]
var cameras:Array[Camera3D]=[]
var panels:Array[Control]=[]
var counts:Array[Label]=[]
var selectors:Dictionary={}
var garment_buttons:Array[Button]=[]
var touch_controls:Array[Control]=[]
var timeline:HSlider
var play_button:Button
var frame_buttons:Array[Button]=[]
var time_label:Label
var margin:MarginContainer
var preview_row:HBoxContainer
var details:PopupPanel
var details_text:RichTextLabel
var controls_button:Button
var tool_rows:Array[Control]=[]
var current_motion:="rest"
var selected_bits:=31
var fit_index:=0
var view_index:=0
var angle_index:=1
var paused:=true
var phone_insets:=true
var review_time:=0.0

func _ready()->void:
	get_tree().root.gui_embed_subwindows=true
	manifest=JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	MOTIONS=manifest.get("motion_order",MOTIONS)
	var kit_theme=Theme.new();kit_theme.default_font_size=16
	for state in ["normal","hover","pressed","focus"]:
		var style=StyleBoxFlat.new();style.bg_color=Color("655438") if state=="pressed" else Color("28312f")
		style.border_color=Color("e0c084") if state in ["pressed","focus"] else Color("677267")
		style.set_border_width_all(2 if state=="focus" else 1);style.set_corner_radius_all(3)
		style.content_margin_left=8;style.content_margin_right=8
		for kind in ["Button","OptionButton"]:kit_theme.set_stylebox(state,kind,style)
	theme=kit_theme
	var paper=StyleBoxFlat.new();paper.bg_color=Color("202827");paper.border_color=Color("bda478");paper.set_border_width_all(1);paper.set_corner_radius_all(3)
	paper.content_margin_left=16;paper.content_margin_right=16;paper.content_margin_top=14;paper.content_margin_bottom=14
	kit_theme.set_stylebox("panel","PopupPanel",paper)
	var background=ColorRect.new();background.color=Color("151c1c");background.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(background)
	margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(margin)
	var column=VBoxContainer.new();column.add_theme_constant_override("separation",5);margin.add_child(column)
	var heading_row=HBoxContainer.new();column.add_child(heading_row)
	var heading=Label.new();heading.text="DEPTHS / FIELD CLOTHING";heading.add_theme_font_size_override("font_size",20);heading.size_flags_horizontal=SIZE_EXPAND_FILL;heading_row.add_child(heading)
	controls_button=button(heading_row,"Controls",94);controls_button.toggle_mode=true;controls_button.button_pressed=true
	controls_button.toggled.connect(func(on):
		for row in tool_rows:row.visible=on
		call_deferred("frame_cameras")
	)
	var detail_button=button(heading_row,"Details",76);detail_button.pressed.connect(show_details)
	var choices=HBoxContainer.new();choices.add_theme_constant_override("separation",8);column.add_child(choices);tool_rows.append(choices)
	selectors.fit=choice(choices,["Fit: Both","Fit: Female","Fit: Male"],110)
	selectors.fit.item_selected.connect(func(index):fit_index=index;update_panels())
	selectors.motion=choice(choices,manifest.get("motion_labels",["Neutral fit","Idle · fitting","Walk · fitting","Sit down · chair","Ground sit · fitting","Dying · original"]),170)
	selectors.motion.item_selected.connect(func(index):set_motion(MOTIONS[index],0,true))
	selectors.view=choice(choices,["Full figure","Portrait"],115)
	selectors.view.item_selected.connect(func(index):view_index=index;frame_cameras())
	selectors.angle=choice(choices,ANGLES,115);selectors.angle.select(1)
	selectors.angle.item_selected.connect(func(index):angle_index=index;frame_cameras())
	var garments=HBoxContainer.new();garments.add_theme_constant_override("separation",6);column.add_child(garments);tool_rows.append(garments)
	for index in PIECES.size():
		var control=button(garments,["Tunic","Belt","Trousers","L boot","R boot"][index],68)
		control.toggle_mode=true;control.button_pressed=true;garment_buttons.append(control)
		control.toggled.connect(func(on):set_piece(index,on))
	var all_button=button(garments,"All",48);all_button.pressed.connect(func():set_garments(31))
	var none_button=button(garments,"None",58);none_button.pressed.connect(func():set_garments(0))
	var transport=HBoxContainer.new();transport.add_theme_constant_override("separation",6);column.add_child(transport);tool_rows.append(transport)
	play_button=button(transport,"Play",66);play_button.pressed.connect(toggle_play)
	var previous=button(transport,"−1f",48);previous.pressed.connect(func():step_frame(-1));frame_buttons.append(previous)
	var next=button(transport,"+1f",48);next.pressed.connect(func():step_frame(1));frame_buttons.append(next)
	timeline=HSlider.new();timeline.name="Timeline";timeline.custom_minimum_size=Vector2(120,44);timeline.size_flags_horizontal=SIZE_EXPAND_FILL;timeline.step=1.0/120.0;timeline.focus_mode=FOCUS_ALL;transport.add_child(timeline);touch_controls.append(timeline)
	timeline.drag_started.connect(func():set_paused(true))
	timeline.value_changed.connect(func(value):set_motion(current_motion,value,true))
	time_label=Label.new();time_label.custom_minimum_size.x=122;transport.add_child(time_label)
	preview_row=HBoxContainer.new();preview_row.size_flags_vertical=SIZE_EXPAND_FILL;preview_row.add_theme_constant_override("separation",10);column.add_child(preview_row)
	for fit in ["female","male"]:make_panel(fit)
	var footer=Label.new();footer.text=manifest.get("review_footer","Temporary fitting motions · final clips pending #215 · source faces unchanged");footer.add_theme_font_size_override("font_size",13);footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(footer)
	details=PopupPanel.new();details.theme=kit_theme;add_child(details)
	var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(500,250);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;details.add_child(scroll)
	details_text=RichTextLabel.new();details_text.name="DetailsText";details_text.fit_content=true;details_text.custom_minimum_size.x=480;details_text.size_flags_horizontal=SIZE_EXPAND_FILL;details_text.bbcode_enabled=true;scroll.add_child(details_text)
	resized.connect(update_layout);update_layout();set_motion("rest",0,true);set_garments(31)
	set_process(true)

func button(parent:Control,text:String,width:int)->Button:
	var control=Button.new();control.text=text;control.name=text.replace(" ","");control.custom_minimum_size=Vector2(width,44);control.add_theme_font_size_override("font_size",16);parent.add_child(control);touch_controls.append(control);return control

func choice(parent:Control,labels:Array,width:int)->OptionButton:
	var control=OptionButton.new();control.custom_minimum_size=Vector2(width,44);control.size_flags_horizontal=SIZE_EXPAND_FILL;control.add_theme_font_size_override("font_size",16)
	for label in labels:control.add_item(label)
	parent.add_child(control);touch_controls.append(control);return control

func make_panel(fit:String)->void:
	var panel=VBoxContainer.new();panel.size_flags_horizontal=SIZE_EXPAND_FILL;panel.size_flags_stretch_ratio=1;preview_row.add_child(panel);panels.append(panel)
	var title=Label.new();title.text=fit.capitalize()+" fit";title.add_theme_font_size_override("font_size",16);panel.add_child(title)
	var container=SubViewportContainer.new();container.stretch=true;container.size_flags_vertical=SIZE_EXPAND_FILL;container.size_flags_horizontal=SIZE_EXPAND_FILL;container.custom_minimum_size.y=100;panel.add_child(container)
	var viewport=SubViewport.new();viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_4X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;container.add_child(viewport);viewports.append(viewport)
	var stage=Node3D.new();viewport.add_child(stage)
	var world=WorldEnvironment.new();var environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("293335");environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("b7c3c4");environment.ambient_light_energy=.65;world.environment=environment;stage.add_child(world)
	var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,-25,0);key.light_energy=1.4;key.light_color=Color("fff0db");key.shadow_enabled=true;stage.add_child(key)
	var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,150,0);fill.light_energy=.5;fill.light_color=Color("a6bdcb");stage.add_child(fill)
	var actor=Actor.new();stage.add_child(actor);actor.setup(fit,manifest.fits[fit]);actors.append(actor)
	var ground=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(30,30);ground.mesh=plane;ground.position.y=0;var material=StandardMaterial3D.new();material.albedo_color=Color("303b3b");material.roughness=1;ground.material_override=material;stage.add_child(ground)
	var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true;stage.add_child(camera);cameras.append(camera)
	var count=Label.new();count.add_theme_font_size_override("font_size",13);count.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;panel.add_child(count);counts.append(count)

func update_layout()->void:
	var phone:=size.y<=750
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,44 if phone and phone_insets else 16)
	margin.add_theme_constant_override("margin_top",8 if phone else 16);margin.add_theme_constant_override("margin_bottom",20 if phone and phone_insets else 16)
	call_deferred("frame_cameras")

func update_panels()->void:
	for i in 2:panels[i].visible=fit_index==0 or fit_index==i+1
	if not actors.is_empty():set_motion(current_motion,minf(review_time,review_duration()),true)
	call_deferred("frame_cameras")

func set_piece(index:int,on:bool)->void:
	set_garments((selected_bits|(1<<index)) if on else (selected_bits&~(1<<index)))

func set_garments(bits:int)->void:
	selected_bits=bits
	for i in 5:garment_buttons[i].set_pressed_no_signal((bits&(1<<i))!=0)
	for i in 2:
		actors[i].set_garments(bits);var data:Dictionary=actors[i].stats()
		counts[i].text="%d triangles · %d surfaces · %d joints"%[data.triangles,data.surfaces,data.bones]
	frame_cameras()

func set_motion(key:String,time:float,stop:bool)->void:
	current_motion=key;selectors.motion.select(MOTIONS.find(key))
	for actor in actors:actor.set_motion(key,time)
	review_time=clampf(time,0,review_duration())
	if stop:set_paused(true)
	timeline.max_value=review_duration();timeline.set_value_no_signal(review_time);timeline.editable=key!="rest"
	play_button.disabled=key=="rest"
	for control in frame_buttons:control.disabled=key=="rest"
	refresh_time();frame_cameras()

func review_duration()->float:
	var length:=0.0
	for i in actors.size():
		if fit_index==0 or fit_index==i+1:length=maxf(length,actors[i].duration())
	return length

func set_motion_fraction(key:String,fraction:float,stop:bool)->void:
	# Matrix inspection samples each body's own clip, including its real end.
	# Interactive playback still advances both at their original seconds/FPS.
	set_motion(key,0,stop)
	for actor in actors:actor.set_motion(key,clampf(fraction,0,1)*actor.duration())
	review_time=clampf(fraction,0,1)*review_duration()
	timeline.set_value_no_signal(review_time);refresh_time();frame_cameras()

func set_paused(value:bool)->void:
	paused=value;play_button.text="Play" if paused else "Pause"
	for actor in actors:actor.playing=not paused

func toggle_play()->void:
	if paused and review_time>=review_duration():set_motion(current_motion,0,true)
	set_paused(not paused)

func step_frame(direction:int)->void:
	set_motion(current_motion,review_time+direction/60.0,true)

func refresh_time()->void:
	time_label.text="%.2f / %.2fs"%[review_time,review_duration()]

func aim(camera:Camera3D,actor:Node3D,aspect:float,portrait:bool)->void:
	var direction:Vector3=[Vector3(0,0,1),Vector3(.65,0,1),Vector3(1,0,0),Vector3(0,0,-1)][angle_index].normalized()
	var points:Array[Vector3]=actor.bone_points();var bounds:=AABB(points[0],Vector3.ZERO)
	for point in points:bounds=bounds.expand(point)
	var unit:float=actor.display_scale
	var focus:Vector3=actor.head_position()+Vector3(0,.08*unit,0) if portrait else bounds.get_center()
	camera.position=focus+direction*10+Vector3(0,(.03 if portrait else .12)*unit,0);camera.look_at(focus)
	if portrait:camera.size=1.12*unit;return
	var inverse:=camera.global_transform.affine_inverse();var projected:=AABB(inverse*points[0],Vector3.ZERO)
	for point in points:projected=projected.expand(inverse*point)
	camera.size=maxf(projected.size.y+.55*unit,(projected.size.x+.55*unit)/maxf(.2,aspect))*1.10

func frame_cameras()->void:
	if cameras.size()!=2:return
	for i in 2:
		var aspect:=float(maxi(1,viewports[i].size.x))/maxi(1,viewports[i].size.y)
		aim(cameras[i],actors[i],aspect,view_index==1)

func show_details()->void:
	var text:="[b]Editable kit / local review[/b]\n\nAll original bodies, rigs and skin pixels are retained. Garments use independently named meshes and reversible body regions. No live game or player files are loaded.\n\n"
	text+="[b]Animation limits[/b]\n"+str(manifest.get("animation_limits","#215's body-specific downloads are not present. Idle, walk, chair sit-down and ground-seated clips are temporary legacy retargets. Chair sit-down and ground idle are not a continuous sequence. Extra female finger joints retain parent-relative rest articulation. Source lateral travel is retained; no floor/seat/hand IK. Playback stops at each real endpoint: looping and in-place status are not approved."))+"\n\n"
	text+="[b]Display normalization[/b]\nOne common scale presents the two bodies at about1.70m/1.80m, preserving their6% height difference. Each fixed rest-sole reference is at y=0. Only the presentation parent changes; source mesh, rest rig, Actions and Mixamo uploads remain unchanged. This is a review reference, not a character-height stat or animated foot correction.\n\n"
	for actor in actors:
		var data:Dictionary=actor.stats();text+="[b]%s[/b] · %d triangles / %d surfaces / %d materials / %d joints\n%d textures / %d pixels (RGBA8 base level ≈ %.2f MiB; GPU overhead/mips excluded).\n"%[actor.fit.capitalize(),data.triangles,data.surfaces,data.materials,data.bones,data.texture_count,data.texture_pixels,data.texture_pixels*4/1048576.0]
		for motion in actor.record.motions:text+="%s · %s · %s · %d–%d @ %dfps\n"%[motion.id,motion.source,motion.action,motion.frames[0],motion.frames[1],motion.fps]
		text+="\n"
	text+="96/192 renders judge source geometry and clothing readability only. Featureless source heads are unchanged; these are not new faces or approved likenesses. Phone-shaped desktop renders do not establish physical-iPhone performance.\n\nSpace: play/pause · Left/Right: one source frame · Home/End: clip endpoints · Escape: close details."
	details_text.text=text
	details.size=Vector2i(mini(700,int(size.x)-90),mini(500,int(size.y)-40));details.popup_centered()

func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:details.hide()
		elif event.keycode==KEY_SPACE and current_motion!="rest":toggle_play();get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_LEFT,KEY_RIGHT]:step_frame(-1 if event.keycode==KEY_LEFT else 1);get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_HOME,KEY_END]:set_motion(current_motion,0 if event.keycode==KEY_HOME else review_duration(),true);get_viewport().set_input_as_handled()

func _process(delta:float)->void:
	if actors.is_empty():return
	if not paused:
		review_time=minf(review_duration(),review_time+delta)
		for actor in actors:actor.set_motion(current_motion,review_time)
		timeline.set_value_no_signal(review_time);refresh_time()
		if review_time>=review_duration():set_paused(true)
	frame_cameras()
