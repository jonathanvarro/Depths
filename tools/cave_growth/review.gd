extends Control
const ART := "res://art/dressing/cave-growth-3d-v1/"
var catalog: Dictionary
var selected := 0
var angle := 0
var cave := true
var glow := false
var motion := false
var controls: Array[Control] = []
var prop: Node3D
var stage: Node3D
var viewport: SubViewport
var camera: Camera3D
var key: DirectionalLight3D
var environment: Environment
var wall: MeshInstance3D
var ceiling: MeshInstance3D
var floor_mesh: MeshInstance3D

func _ready() -> void:
	catalog=JSON.parse_string(FileAccess.get_file_as_string(ART+"catalog.json"))
	var background:=ColorRect.new()
	background.color=Color("#141b1d")
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,44)
	for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	add_child(margin)
	var column:=VBoxContainer.new()
	margin.add_child(column)
	var title:=Label.new()
	title.text="DEPTHS / CAVE FORMATIONS, ROOTS AND FUNGI"
	column.add_child(title)
	var toolbar:=HFlowContainer.new()
	column.add_child(toolbar)
	var items:=OptionButton.new()
	for entry in catalog.assets: items.add_item(str(entry.id).replace("-"," ").capitalize())
	toolbar.add_child(items)
	controls.append(items)
	items.item_selected.connect(func(index): selected=index; load_prop())
	var angles:=OptionButton.new()
	for label in ["Three-quarter","Front","Side"]: angles.add_item(label)
	toolbar.add_child(angles)
	controls.append(angles)
	angles.item_selected.connect(func(index): angle=index; frame_prop())
	for text in ["Neutral","Fungal glow","Animate"]:
		var toggle:=CheckButton.new()
		toggle.text=text
		toolbar.add_child(toggle)
		controls.append(toggle)
	(controls[2] as CheckButton).toggled.connect(func(value): cave=not value; frame_prop())
	(controls[3] as CheckButton).toggled.connect(func(value): glow=value; apply_effects())
	(controls[4] as CheckButton).toggled.connect(func(value): motion=value; apply_effects())
	for control in controls: control.custom_minimum_size.y=44
	var holder:=SubViewportContainer.new()
	holder.stretch=true
	holder.size_flags_vertical=SIZE_EXPAND_FILL
	column.add_child(holder)
	viewport=SubViewport.new()
	viewport.own_world_3d=true
	viewport.msaa_3d=Viewport.MSAA_4X
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	holder.add_child(viewport)
	stage=Node3D.new()
	viewport.add_child(stage)
	var world:=WorldEnvironment.new()
	environment=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("#202a2b")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment=environment
	stage.add_child(world)
	key=DirectionalLight3D.new()
	key.rotation_degrees=Vector3(-45,-30,0)
	stage.add_child(key)
	floor_mesh=plane(Vector2(5,5),"floor",Vector3.ZERO,Vector3.ZERO)
	wall=plane(Vector2(4,2.4),"wall",Vector3(0,1.2,-.012),Vector3(90,0,0))
	ceiling=plane(Vector2(4,4),"ceiling",Vector3(0,2.4,0),Vector3(180,0,0))
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.current=true
	stage.add_child(camera)
	var footer:=Label.new()
	footer.text="Metric mounts • faceted mineral, roots and growth • optional still glow"
	column.add_child(footer)
	resized.connect(frame_prop)
	load_prop()

func surface(id: String) -> StandardMaterial3D:
	var value:=StandardMaterial3D.new()
	value.albedo_texture=load("res://art/textures/cave-v1/"+id+".png")
	value.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	value.roughness=1
	return value

func plane(size: Vector2, material: String, at: Vector3, rotation: Vector3) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	var mesh:=PlaneMesh.new()
	mesh.size=size
	node.mesh=mesh
	node.position=at
	node.rotation_degrees=rotation
	node.material_override=surface(material)
	stage.add_child(node)
	return node

func load_prop() -> void:
	if prop!=null:
		stage.remove_child(prop)
		prop.queue_free()
	var entry: Dictionary=catalog.assets[selected]
	prop=load(ART+entry.id+".tscn").instantiate()
	prop.glow_enabled=glow
	prop.animate_motion=motion
	if entry.mount=="ceiling": prop.position.y=2.4
	elif entry.mount=="wall": prop.position.y=1.2
	stage.add_child(prop)
	wall.visible=entry.mount=="wall"
	ceiling.visible=entry.mount=="ceiling"
	(controls[3] as CheckButton).disabled=not entry.optional_glow
	(controls[4] as CheckButton).disabled=not entry.optional_glow
	call_deferred("frame_prop")

func apply_effects() -> void:
	prop.glow_enabled=glow
	prop.set_motion(motion)
	frame_prop()

func frame_prop() -> void:
	if prop==null: return
	(controls[0] as OptionButton).select(selected)
	(controls[1] as OptionButton).select(angle)
	(controls[2] as CheckButton).set_pressed_no_signal(not cave)
	(controls[3] as CheckButton).set_pressed_no_signal(glow)
	(controls[4] as CheckButton).set_pressed_no_signal(motion)
	key.light_color=Color("#f3bb80") if cave else Color("#fff7ec")
	key.light_energy=1.5 if cave else 1.8
	environment.ambient_light_color=Color("#707b80") if cave else Color("#b8c4c8")
	environment.ambient_light_energy=.3 if cave else .7
	var bounds:=AABB()
	var first:=true
	for mesh: MeshInstance3D in prop.find_children("*","MeshInstance3D",true,false):
		var piece:=mesh.global_transform*mesh.get_aabb()
		bounds=piece if first else bounds.merge(piece)
		first=false
	var focus:=bounds.get_center()
	var mount: String=catalog.assets[selected].mount
	var directions: Array=[Vector3(1,.8,1.8),Vector3(0,.3,2),Vector3(1.8,.3,.4)]
	if mount=="ceiling": directions=[Vector3(1,-.6,1.8),Vector3(0,-.2,2),Vector3(1.8,-.3,.4)]
	camera.position=focus+directions[angle]*2
	camera.look_at(focus)
	var inverse:=camera.global_transform.affine_inverse()
	var projected:=AABB(inverse*bounds.position,Vector3.ZERO)
	for x in [bounds.position.x,bounds.end.x]:
		for y in [bounds.position.y,bounds.end.y]:
			for z in [bounds.position.z,bounds.end.z]: projected=projected.expand(inverse*Vector3(x,y,z))
	var aspect:=float(maxi(1,viewport.size.x))/maxi(1,viewport.size.y)
	camera.size=maxf(.35,maxf(projected.size.y+.10,(projected.size.x+.10)/aspect))*1.13
