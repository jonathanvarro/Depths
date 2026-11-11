extends Control
const ART:="res://art/enemies/fortress-goblins-3d-v1/"
const CAMERAS:={3:Vector3(0,8,3.4),5:Vector3(0,5.5,2.4),6:Vector3(0,9,3.8)}
var ids: Array=[]
var selected:=0
var angle:=0
var pose:="idle"
var time:=0.0
var motion:=false
var cave:=true
var controls: Array[Control]=[]
var prop: Node3D
var stage: Node3D
var viewport: SubViewport
var camera: Camera3D
var key: DirectionalLight3D
var environment: Environment
var slider: HSlider
var label: Label
var poses: Array=[]
var tiles: Node3D

func _ready() -> void:
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ART+"catalog.json"))
	for a in catalog.assets:ids.append(a.id)
	var bg:=ColorRect.new();bg.color=Color("141a1b");bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(bg)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(margin)
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,44)
	for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,12)
	var column:=VBoxContainer.new();margin.add_child(column)
	label=Label.new();column.add_child(label)
	var bar:=HFlowContainer.new();column.add_child(bar)
	for options in [ids,["Three-quarter","Front","Overhead close","Steady board","First person","Dark board","Bright board"],[]]:
		var picker:=OptionButton.new()
		for text in options:picker.add_item(text)
		bar.add_child(picker);controls.append(picker)
	(controls[0] as OptionButton).item_selected.connect(func(i):selected=i;load_prop())
	(controls[1] as OptionButton).item_selected.connect(func(i):angle=i;frame_prop())
	(controls[2] as OptionButton).item_selected.connect(func(i):pose=poses[i];time=0;apply_pose())
	for text in ["Play","Neutral","Equipment"]:
		var b:=CheckButton.new();b.text=text;bar.add_child(b);controls.append(b)
	(controls[3] as CheckButton).toggled.connect(func(on):
		if not on:pose=prop.current_pose;time=prop.player.current_animation_position
		motion=on;apply_pose())
	(controls[4] as CheckButton).toggled.connect(func(on):cave=not on;frame_prop())
	(controls[5] as CheckButton).toggled.connect(func(on):toggle_equipment(on))
	for c in controls:c.custom_minimum_size.y=44
	var holder:=SubViewportContainer.new();holder.stretch=true;holder.size_flags_vertical=SIZE_EXPAND_FILL;column.add_child(holder)
	viewport=SubViewport.new();viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_4X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;holder.add_child(viewport)
	stage=Node3D.new();viewport.add_child(stage)
	var world:=WorldEnvironment.new();environment=Environment.new();world.environment=environment;stage.add_child(world)
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("1b2527");environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-48,-32,0);stage.add_child(key)
	var floor_mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(14,14);floor_mesh.mesh=plane
	var mat:=StandardMaterial3D.new();mat.albedo_texture=load("res://art/textures/cave-v1/floor.png");mat.uv1_scale=Vector3(7,7,1);mat.roughness=1;floor_mesh.material_override=mat;stage.add_child(floor_mesh)
	tiles=Node3D.new();stage.add_child(tiles)
	for x in range(-2,3):
		for z in range(-2,3):
			var item:=MeshInstance3D.new();var ring:=TorusMesh.new();ring.inner_radius=0.89;ring.outer_radius=0.91;ring.rings=4;ring.ring_segments=24;item.mesh=ring
			var m:=StandardMaterial3D.new();m.albedo_color=Color("7a6e53");m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;item.material_override=m;item.position=Vector3(x*2,0.007,z*2);tiles.add_child(item)
	camera=Camera3D.new();camera.current=true;stage.add_child(camera)
	var scrub:=HBoxContainer.new();column.add_child(scrub)
	for direction in [-1,1]:
		var b:=Button.new();b.text="− frame" if direction<0 else "+ frame";b.custom_minimum_size=Vector2(90,44);scrub.add_child(b)
		b.pressed.connect(func():motion=false;time=maxf(0,time+direction/24.0);apply_pose())
	slider=HSlider.new();slider.step=1.0/24;slider.size_flags_horizontal=SIZE_EXPAND_FILL;slider.custom_minimum_size.y=44;scrub.add_child(slider)
	slider.value_changed.connect(func(t):time=t;motion=false;apply_pose())
	resized.connect(frame_prop);load_prop()

func _process(_dt: float) -> void:
	if motion and prop and prop.player:
		pose=prop.current_pose;time=prop.player.current_animation_position
		(controls[2] as OptionButton).select(poses.find(pose));update_slider()
		label.text="DEPTHS / "+ids[selected].to_upper()+"  ·  "+pose+" %.3f s" % time

func load_prop() -> void:
	if prop:stage.remove_child(prop);prop.queue_free()
	prop=load(ART+ids[selected]+".tscn").instantiate();stage.add_child(prop)
	poses.clear();var picker:=controls[2] as OptionButton;picker.clear()
	for p in ["idle","attack","hurt","fall","walk","run","draw","brace","drum","snare","enraged","call","web","venom","defend","cast","plant"]:
		if prop.player.has_animation(p):poses.append(p);picker.add_item(p)
	if pose not in poses:pose="idle"
	(controls[5] as CheckButton).set_pressed_no_signal(true)
	(controls[5] as CheckButton).disabled = not prop.find_child('RoleKit',true,false) and not prop.find_child('Kit',true,false)
	apply_pose();call_deferred("frame_prop")

func toggle_equipment(enabled: bool) -> void:
	for piece in ['RoleKit','Kit','Knife']: prop.set_equipment(piece,enabled)

func apply_pose() -> void:
	if prop==null:return
	(controls[0] as OptionButton).select(selected);(controls[2] as OptionButton).select(poses.find(pose));(controls[3] as CheckButton).set_pressed_no_signal(motion)
	prop.animate_motion=motion
	if motion:prop.play(pose)
	else:prop.sample(pose,time)
	update_slider()
	frame_prop()

func update_slider() -> void:
	# Changing max_value can clamp the old value and emit value_changed.
	# Keep that UI update from replacing a requested sample with the clip end.
	slider.set_block_signals(true)
	slider.max_value=prop.player.get_animation(pose).length
	time=minf(time,slider.max_value);slider.set_value_no_signal(time)
	slider.set_block_signals(false)

func frame_prop() -> void:
	if prop==null:return
	(controls[1] as OptionButton).select(angle);(controls[4] as CheckButton).set_pressed_no_signal(not cave)
	key.light_color=Color("f3bb80") if cave else Color("fff7ec");key.light_energy=1.5 if cave else 1.8
	environment.ambient_light_color=Color("707b80") if cave else Color("b8c4c8");environment.ambient_light_energy=0.32 if cave else 0.70
	prop.position=Vector3.ZERO;tiles.visible=angle in CAMERAS
	var focus:=Vector3(0,float(prop.get_meta("visual_height"))*.5,0)
	if angle in CAMERAS:
		camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=50;camera.position=CAMERAS[angle];camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	elif angle==4:
		camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=70;camera.position=Vector3(0,1.2,3.2);camera.look_at(Vector3(0,0.7,0))
	else:
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL
		camera.size=2.45 if ids[selected]=="goblin-king" else 2.05
		camera.position=focus+[Vector3(1.6,1.1,2),Vector3(0,.55,2),Vector3(.05,2,.85)][angle];camera.look_at(focus)
	label.text="DEPTHS / "+ids[selected].to_upper()+"  ·  "+pose+" %.3f s" % time
