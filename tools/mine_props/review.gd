extends Control
const ART := "res://art/dressing/mine-3d-v1/"
const IDS := ["support", "support-damaged", "lantern-standing", "lantern-hanging", "miners-shrine"]
var selected := 0
var angle := 0
var used := false
var cave := true
var still := true
var prop: Node3D
var stage: Node3D
var camera: Camera3D
var viewport: SubViewport
var key: DirectionalLight3D
var environment: Environment
var wall: MeshInstance3D
var controls: Array[Control] = []

func _ready() -> void:
	var back := ColorRect.new()
	back.color = Color("#141b1d")
	back.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(back)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 44)
	for side in ["top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var title := Label.new()
	title.text = "DEPTHS / TIMBER, LANTERNS AND THE MINERS’ SHRINE"
	column.add_child(title)
	var toolbar := HFlowContainer.new()
	column.add_child(toolbar)
	var items := OptionButton.new()
	for id in IDS: items.add_item(id.replace("-", " ").capitalize())
	items.item_selected.connect(func(index): selected = index; load_prop())
	toolbar.add_child(items)
	controls.append(items)
	var angles := OptionButton.new()
	for text in ["Three-quarter", "Front", "Side"]: angles.add_item(text)
	angles.item_selected.connect(func(index): angle = index; update_stage())
	toolbar.add_child(angles)
	controls.append(angles)
	for text in ["Used / out", "Neutral", "Animate"]:
		var toggle := CheckButton.new()
		toggle.text = text
		toolbar.add_child(toggle)
		controls.append(toggle)
	controls[2].toggled.connect(func(value): used = value; apply_state())
	controls[3].toggled.connect(func(value): cave = not value; update_stage())
	controls[4].toggled.connect(func(value): still = not value; apply_state())
	for control in controls: control.custom_minimum_size.y = 44
	var holder := SubViewportContainer.new()
	holder.stretch = true
	holder.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(holder)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	var world := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#202a2b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment = environment
	stage.add_child(world)
	key = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -30, 0)
	stage.add_child(key)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6, 6)
	floor_mesh.mesh = plane
	floor_mesh.material_override = surface("floor")
	stage.add_child(floor_mesh)
	wall = MeshInstance3D.new()
	var wall_plane := PlaneMesh.new()
	wall_plane.size = Vector2(4, 2.4)
	wall.mesh = wall_plane
	wall.rotation_degrees.x = 90
	wall.position = Vector3(0, 1.2, -.02)
	wall.material_override = surface("wall")
	stage.add_child(wall)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	stage.add_child(camera)
	var note := Label.new()
	note.text = "Worn framing • shared cave grain • fresh and resolved states"
	column.add_child(note)
	resized.connect(update_stage)
	load_prop()

func surface(id: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://art/textures/cave-v1/" + id + ".png")
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.roughness = 1
	return material

func load_prop() -> void:
	if prop != null:
		stage.remove_child(prop)
		prop.queue_free()
	prop = load(ART + IDS[selected] + ".tscn").instantiate()
	prop.animate_glow = not still
	prop.state = "empty" if used else "closed"
	prop.lit = not used
	if selected == 3: prop.position.y = 1.8
	stage.add_child(prop)
	wall.visible = selected >= 3
	apply_state()
	call_deferred("update_stage")

func apply_state() -> void:
	prop.state = "empty" if used else "closed"
	prop.lit = not used
	prop.animate_glow = not still
	update_stage()

func update_stage() -> void:
	if prop == null: return
	(controls[0] as OptionButton).select(selected)
	(controls[1] as OptionButton).select(angle)
	(controls[2] as CheckButton).set_pressed_no_signal(used)
	(controls[3] as CheckButton).set_pressed_no_signal(not cave)
	(controls[4] as CheckButton).set_pressed_no_signal(not still)
	key.light_color = Color("#f3bb80") if cave else Color("#fff7ec")
	key.light_energy = 1.5 if cave else 1.8
	environment.ambient_light_color = Color("#707b80") if cave else Color("#b8c4c8")
	environment.ambient_light_energy = .3 if cave else .7
	var bounds := AABB()
	var first := true
	for mesh: MeshInstance3D in prop.find_children("*", "MeshInstance3D", true, false):
		var piece := mesh.global_transform * mesh.get_aabb()
		if first:
			bounds = piece
			first = false
		else: bounds = bounds.merge(piece)
	var focus := bounds.get_center()
	var direction: Vector3 = [Vector3(1, .55, 1.8), Vector3(0, .15, 2), Vector3(1.8, .35, .35)][angle]
	camera.position = focus + direction * 2
	camera.look_at(focus)
	var inverse := camera.global_transform.affine_inverse()
	var projected := AABB(inverse * bounds.position, Vector3.ZERO)
	for x in [bounds.position.x, bounds.end.x]:
		for y in [bounds.position.y, bounds.end.y]:
			for z in [bounds.position.z, bounds.end.z]: projected = projected.expand(inverse * Vector3(x,y,z))
	var aspect := float(maxi(1, viewport.size.x)) / maxi(1, viewport.size.y)
	camera.size = maxf(.45, maxf(projected.size.y+.10, (projected.size.x+.10)/aspect)) * 1.13
