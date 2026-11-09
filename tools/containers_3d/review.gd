extends Control
const ART := "res://art/props/expedition-3d-v1/"
const IDS := ["chest", "strongbox", "abandoned-pack", "dry-alcove", "cold-camp", "old-workings", "rails", "rails-broken"]
const LABELS := ["Chest", "Strongbox", "Abandoned pack", "Dry alcove", "Cold campsite", "Old workings", "Mine rails", "Broken rails"]
const STATES := ["closed", "open", "empty"]
var selected := 0
var angle := 0
var state := "closed"
var cave := true
var motion := true
var controls: Array[Control] = []
var prop: Node3D
var stage: Node3D
var viewport: SubViewport
var camera: Camera3D
var key: DirectionalLight3D
var environment: Environment

func _ready() -> void:
	var back := ColorRect.new()
	back.color = Color("#141b1d")
	back.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(back)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right"]: margin.add_theme_constant_override("margin_"+side,44)
	for side in ["top", "bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var title := Label.new()
	title.text = "DEPTHS / CONTAINERS, REST SITES AND OLD WORKINGS"
	column.add_child(title)
	var toolbar := HFlowContainer.new()
	column.add_child(toolbar)
	for values in [LABELS,["Three-quarter","Front","High view"],["Closed / fresh","Open","Empty / used"]]:
		var picker := OptionButton.new()
		for text in values: picker.add_item(text)
		toolbar.add_child(picker)
		controls.append(picker)
	(controls[0] as OptionButton).item_selected.connect(func(index): selected=index; load_prop())
	(controls[1] as OptionButton).item_selected.connect(func(index): angle=index; frame_prop())
	(controls[2] as OptionButton).item_selected.connect(func(index): state=STATES[index]; apply_state())
	for text in ["Neutral","Animate lid"]:
		var toggle := CheckButton.new()
		toggle.text = text
		toolbar.add_child(toggle)
		controls.append(toggle)
	(controls[3] as CheckButton).toggled.connect(func(value): cave=not value; frame_prop())
	(controls[4] as CheckButton).toggled.connect(func(value): motion=value; apply_state())
	for control in controls: control.custom_minimum_size.y=44
	var holder := SubViewportContainer.new()
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
	var world := WorldEnvironment.new()
	environment=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("#202a2b")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment=environment
	stage.add_child(world)
	key=DirectionalLight3D.new()
	key.rotation_degrees=Vector3(-45,-30,0)
	stage.add_child(key)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size=Vector2(6,6)
	floor_mesh.mesh=plane
	floor_mesh.material_override=surface("floor")
	stage.add_child(floor_mesh)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.current=true
	stage.add_child(camera)
	var note := Label.new()
	note.text="Worn containers • searched packs • cold rest sites • worked-out mine"
	column.add_child(note)
	resized.connect(frame_prop)
	load_prop()

func surface(id: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture=load("res://art/textures/cave-v1/"+id+".png")
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.roughness=1
	return material

func load_prop() -> void:
	if prop!=null:
		stage.remove_child(prop)
		prop.queue_free()
	if selected>=6 or (selected>=2 and state=="open"): state="closed"
	prop=load(ART+IDS[selected]+".tscn").instantiate()
	prop.animate_motion=motion
	prop.state=state
	stage.add_child(prop)
	(controls[2] as OptionButton).set_item_disabled(1,selected>=2)
	(controls[2] as OptionButton).disabled=selected>=6
	(controls[4] as CheckButton).disabled=selected>=2
	apply_state()
	call_deferred("frame_prop")

func apply_state() -> void:
	prop.animate_motion=motion
	prop.state=state
	frame_prop()

func frame_prop() -> void:
	if prop==null: return
	(controls[0] as OptionButton).select(selected)
	(controls[1] as OptionButton).select(angle)
	(controls[2] as OptionButton).select(STATES.find(state))
	(controls[3] as CheckButton).set_pressed_no_signal(not cave)
	(controls[4] as CheckButton).set_pressed_no_signal(motion)
	key.light_color=Color("#f3bb80") if cave else Color("#fff7ec")
	key.light_energy=1.5 if cave else 1.8
	environment.ambient_light_color=Color("#707b80") if cave else Color("#b8c4c8")
	environment.ambient_light_energy=.30 if cave else .70
	# A fixed envelope keeps every state at the same camera scale and registration.
	var bounds := AABB()
	var first := true
	for mesh: MeshInstance3D in prop.find_children("*","MeshInstance3D",true,false):
		var piece := mesh.global_transform*mesh.get_aabb()
		if first:
			bounds=piece
			first=false
		else: bounds=bounds.merge(piece)
	if selected<2: bounds=AABB(Vector3(-.55,0,-1.0),Vector3(1.1,1.15,1.6))
	var focus := bounds.get_center()
	var direction: Vector3 = [Vector3(1,1.6,1.8),Vector3(0,.6,2),Vector3(.2,1.8,.6)][angle]
	camera.position=focus+direction*2
	camera.look_at(focus)
	var inverse := camera.global_transform.affine_inverse()
	var projected := AABB(inverse*bounds.position,Vector3.ZERO)
	for x in [bounds.position.x,bounds.end.x]:
		for y in [bounds.position.y,bounds.end.y]:
			for z in [bounds.position.z,bounds.end.z]: projected=projected.expand(inverse*Vector3(x,y,z))
	var aspect := float(maxi(1,viewport.size.x))/maxi(1,viewport.size.y)
	camera.size=maxf(.45,maxf(projected.size.y+.1,(projected.size.x+.1)/aspect))*1.13
