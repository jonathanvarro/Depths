extends Control
const RAT := "res://art/enemies/rat-3d-v1/scene.tscn"
const ART := "res://art/props/shrine-events-3d-v1/"
const IDS := ["rat","defiled-shrine","fouled-well","buried-cache"]
const POSES := ["idle","attack","hurt","fall","walk","run"]
var selected := 0
var angle := 0
var pose := "idle"
var state := "closed"
var motion := false
var cave := true
var time := 0.0
var controls: Array[Control]=[]
var prop: Node3D
var stage: Node3D
var viewport: SubViewport
var camera: Camera3D
var key: DirectionalLight3D
var environment: Environment
var slider: HSlider
var label: Label
var tiles: Node3D

func _ready() -> void:
	var bg:=ColorRect.new(); bg.color=Color("141b1d"); bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(bg)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(margin)
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,44)
	for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,12)
	var column:=VBoxContainer.new();margin.add_child(column)
	label=Label.new();label.text="DEPTHS / RAT PILOT + EVENT LANDMARKS";column.add_child(label)
	var bar:=HFlowContainer.new();column.add_child(bar)
	for options in [["Rat pilot","Defiled shrine","Fouled well","Buried cache"],["Three-quarter","Front","Overhead close","Board 8 m","First person"],POSES]:
		var picker:=OptionButton.new()
		for text in options:picker.add_item(text)
		bar.add_child(picker);controls.append(picker)
	(controls[0] as OptionButton).item_selected.connect(func(i):selected=i;load_prop())
	(controls[1] as OptionButton).item_selected.connect(func(i):angle=i;frame_prop())
	(controls[2] as OptionButton).item_selected.connect(func(i):pose=POSES[i];time=0;apply_state())
	for text in ["Resolved","Play","Neutral"]:
		var button:=CheckButton.new();button.text=text;bar.add_child(button);controls.append(button)
	(controls[3] as CheckButton).toggled.connect(func(on):state="empty" if on else "closed";apply_state())
	(controls[4] as CheckButton).toggled.connect(func(on):
		if not on and selected==0:
			pose=prop.current_pose;time=prop.player.current_animation_position
		motion=on;apply_state())
	(controls[5] as CheckButton).toggled.connect(func(on):cave=not on;frame_prop())
	for c in controls:c.custom_minimum_size.y=44
	var holder:=SubViewportContainer.new();holder.stretch=true;holder.size_flags_vertical=SIZE_EXPAND_FILL;column.add_child(holder)
	viewport=SubViewport.new();viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_4X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;holder.add_child(viewport)
	stage=Node3D.new();viewport.add_child(stage)
	var world:=WorldEnvironment.new();environment=Environment.new();world.environment=environment;stage.add_child(world)
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("202a2b");environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-48,-32,0);stage.add_child(key)
	var floor_mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(14,14);floor_mesh.mesh=plane
	var floor_material:=surface("floor");floor_material.uv1_scale=Vector3(7,7,1);floor_mesh.material_override=floor_material;stage.add_child(floor_mesh)
	tiles=Node3D.new();stage.add_child(tiles)
	for x in range(-2,3):
		for z in range(-2,3):
			var item:=MeshInstance3D.new();var ring:=TorusMesh.new();ring.inner_radius=0.89;ring.outer_radius=0.91;ring.rings=4;ring.ring_segments=24;item.mesh=ring
			var mat:=StandardMaterial3D.new();mat.albedo_color=Color("7a6e53");mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;item.material_override=mat;item.position=Vector3(x*2,0.007,z*2);tiles.add_child(item)
	camera=Camera3D.new();camera.current=true;stage.add_child(camera)
	var scrub:=HBoxContainer.new();column.add_child(scrub)
	for direction in [-1,1]:
		var step:=Button.new();step.text="− frame" if direction<0 else "+ frame";step.custom_minimum_size=Vector2(90,44);scrub.add_child(step)
		step.pressed.connect(func():motion=false;time=maxf(0,time+direction/24.0);apply_state())
	slider=HSlider.new();slider.min_value=0;slider.max_value=0.667;slider.step=1.0/24;slider.size_flags_horizontal=SIZE_EXPAND_FILL;slider.custom_minimum_size.y=44;scrub.add_child(slider)
	slider.value_changed.connect(func(value):time=value;motion=false;apply_state())
	resized.connect(frame_prop);load_prop()

func _process(_delta: float) -> void:
	if motion and selected==0 and prop and prop.player:
		pose=prop.current_pose;time=prop.player.current_animation_position
		(controls[2] as OptionButton).select(POSES.find(pose))
		slider.max_value=prop.player.get_animation(pose).length;slider.set_value_no_signal(time)
		label.text="DEPTHS / RAT  ·  "+pose+" %.3f s" % time

func surface(id: String) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_texture=load("res://art/textures/cave-v1/"+id+".png");m.roughness=1;m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS;return m

func load_prop() -> void:
	if prop:
		stage.remove_child(prop);prop.queue_free()
	prop=load(RAT if selected==0 else ART+IDS[selected]+".tscn").instantiate();stage.add_child(prop)
	apply_state();call_deferred("frame_prop")

func apply_state() -> void:
	if prop==null:return
	(controls[0] as OptionButton).select(selected)
	(controls[2] as OptionButton).disabled=selected!=0
	(controls[2] as OptionButton).select(POSES.find(pose))
	(controls[3] as CheckButton).disabled=selected==0
	(controls[4] as CheckButton).disabled=selected!=0
	(controls[3] as CheckButton).set_pressed_no_signal(state=="empty")
	(controls[4] as CheckButton).set_pressed_no_signal(motion)
	if selected==0:
		prop.animate_motion=motion
		if motion:prop.play(pose)
		else:prop.sample(pose,time)
		slider.max_value=prop.player.get_animation(pose).length;time=minf(time,slider.max_value);slider.set_value_no_signal(time)
	else:prop.state=state
	slider.editable=selected==0
	frame_prop()

func frame_prop() -> void:
	if prop==null:return
	key.light_color=Color("f3bb80") if cave else Color("fff7ec");key.light_energy=1.5 if cave else 1.8
	environment.ambient_light_color=Color("707b80") if cave else Color("b8c4c8");environment.ambient_light_energy=0.30 if cave else 0.70
	(controls[1] as OptionButton).select(angle);(controls[5] as CheckButton).set_pressed_no_signal(not cave)
	prop.position=Vector3.ZERO;tiles.visible=angle==3
	var focus:=Vector3(0,0.30,0) if selected==0 else Vector3(0,0.65,0.24) if selected==1 else Vector3(0,0.24,0)
	if angle==3:
		camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=50;camera.position=Vector3(0,8,3.4);camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	elif angle==4:
		camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=70;camera.position=Vector3(0,1.05,3.2);camera.look_at(Vector3(0,0.7,0))
	else:
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL
		camera.position=focus+[Vector3(1.6,1.1,2),Vector3(0,0.55,2),Vector3(0.05,2,0.85)][angle];camera.look_at(focus)
		camera.size=2.0 if selected!=1 else 2.3
	label.text="DEPTHS / "+IDS[selected].to_upper()+"  ·  "+(pose+" %.3f s" % time if selected==0 else state)
