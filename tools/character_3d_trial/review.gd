extends Control
## Independent project: never loads Depths Main, player saves or Settings.
const Character = preload("res://character.gd")
var characters: Array = []
var viewport: SubViewport
var camera: Camera3D
var stage: Node3D
var benches: Array = []
var selectors: Dictionary = {}
var stats: Label
var pose_index := 0
var view_index := 0
var angle_index := 0
var outfit_index := 0
var back_index := 0
var animation_enabled := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background=ColorRect.new();background.color=Color("161d23");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
	add_child(margin)
	var column=VBoxContainer.new();column.add_theme_constant_override("separation",8);margin.add_child(column)
	var heading=Label.new();heading.text="MODULAR 3D COMPANIONS / technical blockout";heading.add_theme_font_size_override("font_size",23);column.add_child(heading)
	var note=Label.new();note.text="Two identity studies · shared 16-bone rig · original procedural meshes · no live portraits replaced";note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(note)
	var controls=HFlowContainer.new();controls.add_theme_constant_override("h_separation",12);column.add_child(controls)
	add_choice(controls,"Outfit",Character.OUTFITS,func(i):outfit_index=i;apply_state())
	add_choice(controls,"Utility",Character.BACKS,func(i):back_index=i;apply_state())
	add_choice(controls,"Pose",Character.POSES,func(i):pose_index=i;apply_state())
	add_choice(controls,"View",["Full body","Portrait bust"],func(i):view_index=i;apply_state())
	add_choice(controls,"Angle",["Front","Three-quarter","Back"],func(i):angle_index=i;apply_state())
	var animate_button=CheckButton.new();animate_button.text="Blink / talk";animate_button.toggled.connect(func(on):animation_enabled=on;apply_state());controls.add_child(animate_button)
	var container=SubViewportContainer.new();container.stretch=true;container.size_flags_vertical=Control.SIZE_EXPAND_FILL;container.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_child(container)
	viewport=SubViewport.new();viewport.size=Vector2i(1024,600);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;container.add_child(viewport)
	stage=Node3D.new();viewport.add_child(stage)
	var world=WorldEnvironment.new();var environment=Environment.new();world.environment=environment
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("29343b")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("bbc4c5");environment.ambient_light_energy=.65
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;stage.add_child(world)
	var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,-30,0);key.light_color=Color("ffe6c6");key.light_energy=1.6;key.shadow_enabled=true;stage.add_child(key)
	var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,140,0);fill.light_color=Color("a6c5dc");fill.light_energy=.65;stage.add_child(fill)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true;viewport.add_child(camera)
	for i in 2:
		var person=Character.new();person.name="RookStudy" if i==0 else "BrannaStudy";stage.add_child(person);person.setup("rook" if i==0 else "branna");characters.append(person)
		var bench=MeshInstance3D.new();var mesh=BoxMesh.new();mesh.size=Vector3(.55,.07,.40);bench.mesh=mesh;bench.position=Vector3(-.48 if i==0 else .48,.45,-.02)
		var mat=StandardMaterial3D.new();mat.albedo_color=Color("493c33");mat.roughness=.9;bench.material_override=mat;stage.add_child(bench);benches.append(bench)
	var ground=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(4,3);ground.mesh=plane
	var stone=StandardMaterial3D.new();stone.albedo_color=Color("323b3e");stone.roughness=1;ground.material_override=stone;stage.add_child(ground)
	stats=Label.new();stats.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(stats)
	var footer=Label.new();footer.text="Rook-inspired study (left) / Branna-inspired study (right). Likenesses, proportions and style are exploratory. Rigid parts; no cloth physics or production skinning.";footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;footer.add_theme_font_size_override("font_size",13);column.add_child(footer)
	apply_state()

func add_choice(parent: Control, label: String, options: Array, callback: Callable) -> void:
	var group=VBoxContainer.new();parent.add_child(group)
	var title=Label.new();title.text=label;group.add_child(title)
	var choice=OptionButton.new();choice.custom_minimum_size=Vector2(150,44)
	for option in options:choice.add_item(option)
	choice.item_selected.connect(callback);group.add_child(choice);selectors[label]=choice

func apply_state() -> void:
	if characters.is_empty():return
	for person in characters:
		person.set_outfit(outfit_index);person.set_back(back_index);person.set_pose(pose_index);person.animate=animation_enabled
		if not animation_enabled:person.set_expression(false,false)
	var yaw=[0.0,.42,PI][angle_index]
	for i in characters.size():
		characters[i].position.x=-.48 if i==0 else .48
		characters[i].rotation.y=yaw
		benches[i].visible=pose_index>0 and view_index==0
	var focus_height=1.65 if view_index==1 else .93
	if pose_index>0:focus_height-=.43
	var focus=Vector3(0,focus_height,0)
	camera.position=focus+Vector3(0,.035 if view_index==1 else .6,5)
	camera.look_at(focus)
	camera.size=.58 if view_index==1 else 2.12
	if view_index==1:
		characters[0].position.x=-.20;characters[1].position.x=.20
	stats.text="%s · %s · %s | %d meshes / %d triangles per assembled identity (includes hidden variants)"%[Character.OUTFITS[outfit_index],Character.BACKS[back_index],Character.POSES[pose_index],characters[0].mesh_stats().meshes,characters[0].mesh_stats().triangles]

func select_state(outfit: int, utility: int, pose: int, view: int, angle: int) -> void:
	outfit_index=outfit;back_index=utility;pose_index=pose;view_index=view;angle_index=angle
	selectors.Outfit.select(outfit);selectors.Utility.select(utility);selectors.Pose.select(pose);selectors.View.select(view);selectors.Angle.select(angle)
	apply_state()
