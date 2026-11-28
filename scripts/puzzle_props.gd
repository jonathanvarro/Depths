extends RefCounted
## #281: production fittings; puzzle state, reachability and interaction stay in
## Puzzles/Main. Preserve the original mounts, bolt face and opening direction.
const GATE := preload("res://art/props/fortress-waterworks-3d-v1/flow-gate.tscn")
const BARRED := preload("res://art/props/puzzle-fittings-v1/barred-door.tscn")
const LOCKED := preload("res://art/props/puzzle-fittings-v1/locked-door.tscn")
const LEVER := preload("res://art/props/puzzle-fittings-v1/lever.tscn")
const KEY := preload("res://art/props/puzzle-fittings-v1/recovered-key.tscn")
const NEIGHBOURS: Array[Vector2i] = [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]

class Piece extends Node3D:
	var gate: Node3D
	var _motion := true
	func set_motion(enabled: bool) -> void:
		_motion=enabled
		gate.set_motion(enabled)
	func set_open(open: bool,animate := true) -> void:
		gate.set("animate_motion",animate and _motion)
		gate.set("state","open" if open else "closed")

static func _wall_side(map,cell: Vector2i) -> Vector2i:
	for n in NEIGHBOURS:
		if map.is_wall(cell+n):return n
	return Vector2i.UP

static func build(p: Dictionary,part: String,map,cell_size: float,wall_height: float) -> Node3D:
	var cell: Vector2i=p[part]
	var piece: Node3D
	match part:
		"door":
			var east_west: bool=map.is_wall(cell+Vector2i.UP) and map.is_wall(cell+Vector2i.DOWN)
			if p["kind"]=="lever":
				var wrapper:=Piece.new()
				wrapper.gate=GATE.instantiate();wrapper.add_child(wrapper.gate)
				piece=wrapper
			else:
				piece=(BARRED if p["kind"]=="oneway" else LOCKED).instantiate()
				var bolt_dir: Vector2i=p.get("bolt",cell+Vector2i.DOWN)-cell
				var local_z:=float(bolt_dir.x) if east_west else float(bolt_dir.y)
				if east_west:local_z=-local_z
				piece.bolt_side=1.0 if local_z>=0 else -1.0
			piece.rotation.y=PI/2 if east_west else 0.0
			piece.scale=Vector3(cell_size/2.0,wall_height/2.4,cell_size/2.0)
		"lever","key":
			piece=(LEVER if part=="lever" else KEY).instantiate()
			var wall:=_wall_side(map,cell)
			piece.position=Vector3(wall.x,0,wall.y)*cell_size*(.36 if part=="lever" else .3)
			piece.rotation.y=atan2(-float(wall.x),-float(wall.y))
		_:
			return null
	piece.position+=map.world_at(cell,cell_size)
	return piece
