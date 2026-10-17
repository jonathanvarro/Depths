extends Node3D
## The 3D geometry of one floor: walls, floor, ceiling, passages, and the
## ways up and down, dressed by an EnvironmentTheme.
##
## Features use the theme's scene if it has one, otherwise a simple tinted
## placeholder shape, so real art can be dropped in without code changes.

const DungeonMap := preload("res://scripts/dungeon_map.gd")

var cell_size: float
var wall_height: float

var _map  # dungeon_map.gd
var _theme: EnvironmentTheme
var _door_nodes := {}  # Vector2i -> Node3D currently shown for that passage


func build(map, theme: EnvironmentTheme, size: float, height: float) -> void:
	_map = map
	_theme = theme
	cell_size = size
	wall_height = height

	var wall_mesh := _box(Vector3(cell_size, wall_height, cell_size), theme.wall_material)
	var variant_mesh := _box(wall_mesh.size, theme.wall_variant_material if theme.wall_variant_material else theme.wall_material)
	var tile_mesh := _plane(theme.floor_material, false)
	var ceiling_mesh := _plane(theme.ceiling_material, true)

	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			var at := _cell_center(cell)
			if map.is_wall(cell):
				if map.is_exposed_wall(cell):
					# Stable variation without consuming the floor generator's RNG.
					var mesh := variant_mesh if (x * 7 + y * 11) % 5 == 0 else wall_mesh
					_add_mesh(mesh, at + Vector3(0, wall_height / 2.0, 0))
				continue
			var content: int = map.content_at(cell)
			if content != DungeonMap.Content.STAIRS_DOWN:
				_add_mesh(tile_mesh, at)
			_add_mesh(ceiling_mesh, at + Vector3(0, wall_height, 0))
			if content == DungeonMap.Content.STAIRS_DOWN:
				_add_feature(theme.descent_scene, _make_descent(), cell)
			elif content == DungeonMap.Content.STAIRS_UP:
				_add_feature(theme.ascent_scene, _make_ascent(), cell)
			if map.door_at(cell) != DungeonMap.Door.NONE:
				refresh_door(cell)


## Shows the right model for a passage's current state (call after opening).
func refresh_door(cell: Vector2i) -> void:
	if _door_nodes.has(cell):
		_door_nodes[cell].queue_free()
		_door_nodes.erase(cell)
	var node: Node3D
	match _map.door_at(cell):
		DungeonMap.Door.CLOSED:
			node = _add_feature(_theme.closed_scene, _make_slab(_theme.closed_color, 0.12), cell)
		DungeonMap.Door.BLOCKED:
			node = _add_feature(_theme.blocked_scene, _make_slab(_theme.blocked_color, 0.5), cell)
		DungeonMap.Door.OPEN:
			if _theme.opened_scene:
				node = _add_feature(_theme.opened_scene, null, cell)
	if node:
		_door_nodes[cell] = node


## Places a theme scene (or the placeholder) at a cell, turned to face along
## the passage: a corridor with walls east and west runs north-south.
func _add_feature(scene: PackedScene, placeholder: Node3D, cell: Vector2i) -> Node3D:
	var node: Node3D = scene.instantiate() if scene else placeholder
	if node == null:
		return null
	if placeholder and node != placeholder:
		placeholder.free()
	node.position = _cell_center(cell)
	var runs_east_west: bool = _map.is_wall(cell + Vector2i.UP) and _map.is_wall(cell + Vector2i.DOWN)
	node.rotation.y = PI / 2.0 if runs_east_west else 0.0
	add_child(node)
	return node


## A panel filling the passage, `thickness` deep (web, door, roots...).
func _make_slab(color: Color, thickness: float) -> Node3D:
	var mesh := _box(Vector3(cell_size, wall_height, thickness), _tint(color))
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position.y = wall_height / 2.0
	var root := Node3D.new()
	root.add_child(instance)
	return root


## A dark shaft dropping through the floor (pit, stairwell).
func _make_descent() -> Node3D:
	var shaft := CylinderMesh.new()
	shaft.top_radius = cell_size * 0.42
	shaft.bottom_radius = cell_size * 0.3
	shaft.height = 3.0
	shaft.material = _tint(_theme.descent_color)
	var instance := MeshInstance3D.new()
	instance.mesh = shaft
	instance.position.y = -1.5
	# Floor around the hole, so the shaft reads as a hole in the ground.
	var rim := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = cell_size * 0.42
	ring.outer_radius = cell_size * 0.5
	ring.material = _theme.floor_material
	rim.mesh = ring
	rim.scale.y = 0.2
	var root := Node3D.new()
	root.add_child(instance)
	root.add_child(rim)
	return root


## Strands hanging from the ceiling to the floor (roots, rope, a stair rail).
func _make_ascent() -> Node3D:
	var root := Node3D.new()
	var material := _tint(_theme.ascent_color)
	for offset in [Vector2(-0.35, -0.2), Vector2(0.1, 0.3), Vector2(0.3, -0.25), Vector2(-0.1, 0.05)]:
		var strand := CylinderMesh.new()
		strand.top_radius = 0.06
		strand.bottom_radius = 0.03
		strand.height = wall_height
		strand.material = material
		var instance := MeshInstance3D.new()
		instance.mesh = strand
		instance.position = Vector3(offset.x, wall_height / 2.0, offset.y) * Vector3(cell_size, 1, cell_size)
		root.add_child(instance)
	return root


func _cell_center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)


func _add_mesh(mesh: Mesh, at: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	add_child(instance)


func _box(size: Vector3, material: Material) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	return mesh


func _plane(material: Material, flipped: bool) -> PlaneMesh:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(cell_size, cell_size)
	mesh.flip_faces = flipped
	mesh.material = material
	return mesh


func _tint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
