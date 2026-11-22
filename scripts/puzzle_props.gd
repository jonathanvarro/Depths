extends RefCounted
## How the floor puzzles look (owner, 2026-11-21; rules in puzzles.gd).
## Simple built shapes for now, in the cave's dark palette:
##   one-way door - iron-banded planks; a heavy bolt on the bolt side only.
##   locked door  - the same planks with an iron lock plate on both faces.
##   lever gate   - the waterworks' chain-hoisted gate (#246), raised when open.
##   lever        - an iron lever on a stone block by the wall; down once pulled.
##   key          - a dead explorer slumped by the wall, a key glinting in
##                  hand (gone once taken).
## Static helpers; each piece is a Piece with set_open(open, animate).

const GATE := preload("res://art/props/fortress-waterworks-3d-v1/flow-gate.tscn")
const BODY := "res://art/dressing/bone-decor-v1/seated-skeleton.tscn"
const NEIGHBOURS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

const WOOD := Color("4a3424")
const WOOD_DARK := Color("2e2118")
const IRON := Color("3b3b3d")
const STONE := Color("4b4842")
const BRASS := Color("c9a24a")
## The lever is lighter than the rock so it can be found by lamplight.
const LEVER_STONE := Color("7a7264")
const LEVER_IRON := Color("8a8278")
const GRIP := Color("9a7048")


## A puzzle piece that can be shown opened (or pulled, or taken).
class Piece extends Node3D:
	var swing: Node3D  # turns open (a door, a lever handle)
	var swing_to := Vector3.ZERO
	var gate: Node  # the chain gate's own state
	var hide_when_open: Array[Node3D] = []

	func set_open(open: bool, animate := true) -> void:
		if gate:
			gate.set("animate_motion", animate)
			gate.set("state", "open" if open else "closed")
		if swing:
			var target: Vector3 = swing_to if open else Vector3.ZERO
			if animate and is_inside_tree():
				create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).tween_property(swing, "rotation", target, 0.7)
			else:
				swing.rotation = target
		for node in hide_when_open:
			node.visible = not open


static func _mat(color: Color, metal := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.5 if metal else 0.9
	m.metallic = 0.6 if metal else 0.0
	return m


static func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color, metal := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _mat(color, metal)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


static func _wall_side(map, cell: Vector2i) -> Vector2i:
	for n in NEIGHBOURS:
		if map.is_wall(cell + n):
			return n
	return Vector2i.UP


## The piece for `part` ("door", "lever" or "key") of puzzle `p`.
static func build(p: Dictionary, part: String, map, cell_size: float, wall_height: float) -> Node3D:
	var cell: Vector2i = p[part]
	var piece := Piece.new()
	piece.position = Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)
	match part:
		"door":
			# Across the passage: turned when it runs east-west.
			var east_west: bool = map.is_wall(cell + Vector2i.UP) and map.is_wall(cell + Vector2i.DOWN)
			piece.rotation.y = PI / 2.0 if east_west else 0.0
			if p["kind"] == "lever":
				var gate: Node3D = GATE.instantiate()
				piece.add_child(gate)
				piece.gate = gate
			else:
				_door(piece, p, cell, cell_size, wall_height, east_west)
		"lever":
			_lever(piece, map, cell, cell_size)
		"key":
			_key(piece, map, cell, cell_size)
	piece.set_open(p["open"] if part != "key" else p.get("held", false), false)
	return piece


## Planks on a hinge at one side of the passage, swinging away from the
## bolt side (a one-way door) or inward (a locked one).
static func _door(piece: Piece, p: Dictionary, cell: Vector2i, cell_size: float, wall_height: float, east_west: bool) -> void:
	var width := cell_size * 0.86
	var height := wall_height * 0.86
	# Frame: two posts and a lintel, so it reads as built into the rock.
	for x in [-1.0, 1.0]:
		_box(piece, Vector3(0.14, wall_height, 0.24), Vector3(x * (width / 2.0 + 0.07), wall_height / 2.0, 0), WOOD_DARK)
	_box(piece, Vector3(width + 0.28, 0.16, 0.24), Vector3(0, height + 0.08, 0), WOOD_DARK)
	var hinge := Node3D.new()
	hinge.position = Vector3(-width / 2.0, 0, 0)
	piece.add_child(hinge)
	var leaf := Node3D.new()
	leaf.position = Vector3(width / 2.0, 0, 0)
	hinge.add_child(leaf)
	_box(leaf, Vector3(width, height, 0.08), Vector3(0, height / 2.0, 0), WOOD)
	for y in [0.22, 0.5, 0.8]:
		_box(leaf, Vector3(width, 0.07, 0.1), Vector3(0, height * y, 0), IRON, true)
	# Which face is the bolt side: the door's local +Z or -Z.
	var bolt_dir: Vector2i = p.get("bolt", cell + Vector2i.DOWN) - cell
	var local_z := float(bolt_dir.x) if east_west else float(bolt_dir.y)
	if east_west:
		local_z = -local_z  # turned a quarter: +X maps to -Z
	var side := 1.0 if local_z >= 0.0 else -1.0
	if p["kind"] == "oneway":
		# A heavy bar on the bolt side only; the other face is bare planks.
		_box(leaf, Vector3(width * 0.7, 0.09, 0.08), Vector3(width * 0.12, height * 0.52, side * 0.09), IRON, true)
		_box(leaf, Vector3(0.1, 0.18, 0.1), Vector3(width * 0.45, height * 0.52, side * 0.1), IRON, true)
	else:
		for face in [-1.0, 1.0]:
			_box(leaf, Vector3(0.16, 0.22, 0.03), Vector3(width * 0.36, height * 0.48, face * 0.055), IRON, true)
			_box(leaf, Vector3(0.03, 0.07, 0.035), Vector3(width * 0.36, height * 0.47, face * 0.07), Color("0b0a09"))
	piece.swing = hinge
	piece.swing_to = Vector3(0, -side * deg_to_rad(100.0), 0)


## A stone block by the wall with an iron lever; pulled, it drops forward.
static func _lever(piece: Piece, map, cell: Vector2i, cell_size: float) -> void:
	var wall := _wall_side(map, cell)
	var mount := Node3D.new()
	mount.position = Vector3(wall.x, 0, wall.y) * cell_size * 0.36
	mount.rotation.y = atan2(-float(wall.x), -float(wall.y))  # handle faces the room
	piece.add_child(mount)
	# A worked stone block, an iron plate bolted to the rock above it and a
	# chain running up into the dark: it reads as machinery from a way off.
	_box(mount, Vector3(0.6, 0.55, 0.45), Vector3(0, 0.275, 0), LEVER_STONE)
	_box(mount, Vector3(0.5, 0.7, 0.06), Vector3(0, 0.95, 0.24), LEVER_IRON, true)
	for i in 6:
		_box(mount, Vector3(0.05, 0.12, 0.05), Vector3(0.18, 1.0 + i * 0.16, 0.2), LEVER_IRON, true)
	# The pivot turns (set_open); inside it the handle leans back to the wall
	# while up, and drops forward once pulled.
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0.55, 0)
	mount.add_child(pivot)
	var lean := Node3D.new()
	lean.rotation.x = deg_to_rad(-35.0)
	pivot.add_child(lean)
	_box(lean, Vector3(0.08, 0.85, 0.08), Vector3(0, 0.42, 0), LEVER_IRON, true)
	_box(lean, Vector3(0.14, 0.2, 0.14), Vector3(0, 0.86, 0), GRIP)
	piece.swing = pivot
	piece.swing_to = Vector3(deg_to_rad(70.0), 0, 0)


## A dead explorer slumped against the wall, a key in hand.
static func _key(piece: Piece, map, cell: Vector2i, cell_size: float) -> void:
	var wall := _wall_side(map, cell)
	var seat := Node3D.new()
	seat.position = Vector3(wall.x, 0, wall.y) * cell_size * 0.3
	seat.rotation.y = atan2(-float(wall.x), -float(wall.y))
	piece.add_child(seat)
	if ResourceLoader.exists(BODY):
		seat.add_child(load(BODY).instantiate())
	else:
		_box(seat, Vector3(0.4, 0.5, 0.3), Vector3(0, 0.25, 0), Color("8a8170"))
	var key := Node3D.new()
	key.position = Vector3(0.18, 0.32, 0.32)
	seat.add_child(key)
	_box(key, Vector3(0.05, 0.05, 0.22), Vector3.ZERO, BRASS, true)
	_box(key, Vector3(0.12, 0.12, 0.03), Vector3(0, 0, -0.12), BRASS, true)
	_box(key, Vector3(0.05, 0.08, 0.03), Vector3(0, -0.05, 0.09), BRASS, true)
	var glint := OmniLight3D.new()
	glint.light_color = Color("ffd88a")
	glint.light_energy = 0.6
	glint.omni_range = 0.9
	key.add_child(glint)
	piece.hide_when_open.append(key)
