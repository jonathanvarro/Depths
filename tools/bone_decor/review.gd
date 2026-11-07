extends Control
## #239 scenery comparison in an isolated world.
const ROOT_DIR := "res://art/dressing/bone-decor-v1/"
const NAMES := ["scattered-bones", "small-remains", "fallen-skeleton", "seated-skeleton"]
var viewports: Array[SubViewport] = []
var cameras: Array[Camera3D] = []
var props: Array[Node3D] = []
var lights: Array[DirectionalLight3D] = []
var environments: Array[Environment] = []
var angle := 0
var cave := true
var controls: Array[Control] = []

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("#141b1d")
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 44)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var toolbar := HBoxContainer.new()
	column.add_child(toolbar)
	var title := Label.new()
	title.text = "DEPTHS / BONES AND REMAINS"
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	toolbar.add_child(title)
	var lighting := OptionButton.new()
	lighting.add_item("Cave light")
	lighting.add_item("Neutral light")
	lighting.custom_minimum_size = Vector2(160, 44)
	toolbar.add_child(lighting)
	controls.append(lighting)
	lighting.item_selected.connect(func(index): cave = index == 0; update_stage())
	var angles := OptionButton.new()
	for text in ["Three-quarter", "Front", "Side", "High view"]:
		angles.add_item(text)
	angles.custom_minimum_size = Vector2(160, 44)
	toolbar.add_child(angles)
	controls.append(angles)
	angles.item_selected.connect(func(index): angle = index; update_stage())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	for id in NAMES:
		make_panel(grid, id)
	var footer := Label.new()
	footer.text = "CC0 KayKit scenery / warm bone palette and cave grain / #239"
	column.add_child(footer)
	resized.connect(update_stage)
	call_deferred("update_stage")

func surface(path: String) -> StandardMaterial3D:
	var value := StandardMaterial3D.new()
	value.albedo_texture = load(path)
	value.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	value.roughness = 1
	value.uv1_scale = Vector3(1.5, 1.5, 1.5)
	return value

func make_panel(parent: Control, id: String) -> void:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	parent.add_child(panel)
	var label := Label.new()
	label.text = id.replace("-", " ").capitalize()
	if id.ends_with("skeleton"):
		label.text += " study"
	panel.add_child(label)
	var container := SubViewportContainer.new()
	container.stretch = true
	container.size_flags_vertical = SIZE_EXPAND_FILL
	container.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.add_child(container)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	viewports.append(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#222a2c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment = environment
	stage.add_child(world)
	environments.append(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -30, 0)
	stage.add_child(key)
	lights.append(key)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4, 4)
	floor_mesh.mesh = plane
	floor_mesh.material_override = surface("res://art/textures/cave-v1/floor.png")
	stage.add_child(floor_mesh)
	var wall := MeshInstance3D.new()
	var wall_plane := PlaneMesh.new()
	wall_plane.size = Vector2(4, 2)
	wall.mesh = wall_plane
	wall.rotation_degrees.x = 90
	wall.position = Vector3(0, 1, -1)
	wall.material_override = surface("res://art/textures/cave-v1/wall.png")
	stage.add_child(wall)
	var prop: Node3D = load(ROOT_DIR + id + ".tscn").instantiate()
	stage.add_child(prop)
	props.append(prop)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	stage.add_child(camera)
	cameras.append(camera)

func update_stage() -> void:
	for index in props.size():
		lights[index].light_color = Color("#f3bb80") if cave else Color("#fff7ec")
		lights[index].light_energy = 1.5 if cave else 1.8
		environments[index].ambient_light_color = Color("#707b80") if cave else Color("#b8c4c8")
		environments[index].ambient_light_energy = .30 if cave else .70
		var directions := [Vector3(1, .85, 1.4), Vector3(0, .6, 1.6), Vector3(1.6, .6, .1), Vector3(.3, 1.8, .6)]
		var bounds := AABB()
		var first := true
		for mesh: MeshInstance3D in props[index].find_children("*", "MeshInstance3D", true, false):
			var piece := mesh.global_transform * mesh.get_aabb()
			if first:
				bounds = piece
				first = false
			else:
				bounds = bounds.merge(piece)
		var focus := bounds.get_center()
		cameras[index].position = focus + directions[angle]
		cameras[index].look_at(focus)
		var aspect := float(maxi(1, viewports[index].size.x)) / maxi(1, viewports[index].size.y)
		var inverse := cameras[index].global_transform.affine_inverse()
		var projected := AABB(inverse * bounds.position, Vector3.ZERO)
		for x in [bounds.position.x, bounds.end.x]:
			for y in [bounds.position.y, bounds.end.y]:
				for z in [bounds.position.z, bounds.end.z]:
					projected = projected.expand(inverse * Vector3(x, y, z))
		cameras[index].size = maxf(.7, maxf(projected.size.y + .18, (projected.size.x + .18) / maxf(.2, aspect))) * 1.14
