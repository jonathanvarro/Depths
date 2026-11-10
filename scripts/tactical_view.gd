extends Node3D
## Tactical view prototype (owner, 2026-11-08): first-person exploration,
## but a fight on the map lifts the camera above the room so the board can
## be read - where everyone stands, which tiles each foe threatens next,
## and who the party can reach. When the fight ends the camera drops back
## into the party's eyes. The rules don't change; this is how it looks.
##
## Switched on and off in Settings ("tactical_view"). Main calls enter()
## when a fight on the map begins and exit() when it ends.
##
## On the board (owner: "keep it, go further", 2026-11-08): tap a tile next
## to the party to step there (facing stays, so you can back away), tap a
## foe beside you to turn and strike it, or one along an open line to shoot
## it if anyone can. Pale outlines show where the party can step.

const TWEEN_TIME := 0.8
const HEIGHT := 8.0  # metres above the party
const BACK := 3.4  # metres behind the party, so the board tilts towards you
const FOG := 0.012  # the cave's fog, thinned so the room reads from above
const THREAT := Color(0.9, 0.16, 0.1, 0.42)  # a tile a foe will strike next
const REACH := Color(0.95, 0.55, 0.15, 0.75)  # a tile a foe can reach (outlined)
const TARGET := Color(0.95, 0.85, 0.35, 0.9)  # a foe the party can hit now
const PARTY := Color(0.95, 0.8, 0.35)
const STEP := Color(0.85, 0.85, 0.8, 0.45)  # a tile the party can step to

var active := false
var _main
var _state
var _camera: Camera3D
var _light: OmniLight3D
var _party_token: Node3D
var _marks: Array[Node3D] = []
var _hidden: Array[Node3D] = []
var _env: Environment
var _fog_before := 0.0
var _ambient_before := 0.0
var _tween: Tween
var _refresh := 0.0
var _last_key := ""


## Lifts the view above the fight. `main` is main.gd; `state` the fight.
func enter(main, state) -> void:
	_main = main
	_state = state
	active = true
	var eye: Camera3D = main._party.camera
	if _camera == null:
		_camera = Camera3D.new()
		_camera.fov = 50.0
		add_child(_camera)
	_camera.global_transform = eye.global_transform
	_camera.make_current()
	_build_party_token()
	_light = OmniLight3D.new()
	_light.light_color = Color("e8c08a")
	_light.light_energy = 1.3
	_light.omni_range = 13.0
	_light.omni_attenuation = 0.8
	add_child(_light)
	_env = _find_env(main)
	if _env:
		_fog_before = _env.fog_density
		_ambient_before = _env.ambient_light_energy
	_hide_overhead(main)
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_camera, "global_transform", _board_transform(), TWEEN_TIME)
	if _env:
		_tween.tween_property(_env, "fog_density", FOG, TWEEN_TIME)
		_tween.tween_property(_env, "ambient_light_energy", maxf(_ambient_before, 1.1), TWEEN_TIME)
	_last_key = ""
	_update_marks()


## Drops the view back into the party's eyes.
func exit() -> void:
	if not active:
		return
	active = false
	_clear_marks()
	if is_instance_valid(_party_token):
		_party_token.queue_free()
	if _tween:
		_tween.kill()
	var eye: Camera3D = _main._party.camera
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_camera, "global_transform", eye.global_transform, TWEEN_TIME)
	if _env:
		_tween.tween_property(_env, "fog_density", _fog_before, TWEEN_TIME)
		_tween.tween_property(_env, "ambient_light_energy", _ambient_before, TWEEN_TIME)
	await _tween.finished
	if active:
		return  # a new fight began meanwhile
	eye.make_current()
	for node in _hidden:
		if is_instance_valid(node):
			node.visible = true
	_hidden.clear()
	if is_instance_valid(_light):
		_light.queue_free()


func _process(delta: float) -> void:
	if not active or _main == null:
		return
	# Follow the party as it steps and turns.
	if _tween == null or not _tween.is_running():
		_camera.global_transform = _camera.global_transform.interpolate_with(_board_transform(), minf(1.0, delta * 6.0))
	var at: Vector3 = _main._party.global_position
	_light.global_position = at + Vector3(0, 6.0, 0)
	if is_instance_valid(_party_token):
		_party_token.global_position = Vector3(at.x, 0.02, at.z)
		_party_token.rotation.y = _main._party.rotation.y
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = 0.15
		_update_marks()


## A tap or click on the board (#248).
func _unhandled_input(event: InputEvent) -> void:
	if not active or _main == null or not _main._combat.awaiting_field_action:
		return
	var at := Vector2(-1, -1)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		at = event.position
	elif event is InputEventScreenTouch and event.pressed:
		at = event.position
	if at.x < 0.0:
		return
	var cell := cell_at(at)
	if cell != Vector2i(-1, -1) and act_on(cell):
		get_viewport().set_input_as_handled()


## The map cell under a point on screen, or (-1, -1).
func cell_at(point: Vector2) -> Vector2i:
	var origin := _camera.project_ray_origin(point)
	var direction := _camera.project_ray_normal(point)
	if absf(direction.y) < 0.001:
		return Vector2i(-1, -1)
	var t := -origin.y / direction.y
	if t <= 0.0:
		return Vector2i(-1, -1)
	var hit := origin + direction * t
	var size: float = _main.CELL_SIZE
	return Vector2i(roundi(hit.x / size), roundi(hit.z / size))


## Does what a tap on `cell` means. True if it did something.
func act_on(cell: Vector2i) -> bool:
	var combat = _main._combat
	var party_cell: Vector2i = _state.party_cell
	var foe = null
	for f in _state.living_foes():
		if f.cell == cell:
			foe = f
	var d := cell - party_cell
	var adjacent := absi(d.x) + absi(d.y) == 1
	if foe:
		combat._select_target(foe)
		if adjacent:
			_main._face_toward(cell)  # turning is free
			if _state.foe_ahead() == foe:
				combat._action_chosen.emit({"kind": "strike"})
				return true
		if not _state.shooters(foe).is_empty():
			combat._action_chosen.emit({"kind": "shoot"})
			return true
		return true  # chosen: its intent shows on the panel
	if adjacent and _main._map.is_passable(cell):
		_main._party._try_step(d)  # the step is the party's action
		return true
	return false


## Above and a little behind the party, looking down at it, turned with it.
func _board_transform() -> Transform3D:
	var party: Node3D = _main._party
	var at: Vector3 = party.global_position
	var back: Vector3 = party.global_transform.basis.z.normalized()  # the party looks along -Z
	var eye := at + Vector3(0, HEIGHT, 0) + back * BACK
	return Transform3D(Basis(), eye).looking_at(at, -party.global_transform.basis.z.normalized())


## Ceilings and anything hung from them would hide the board.
func _hide_overhead(main) -> void:
	_hidden.clear()
	var top: float = main.WALL_HEIGHT - 0.6
	for node in main._level.find_children("*", "Node3D", true, false):
		if node.visible and (node.is_in_group("ceiling") or (node.get_parent() and node.get_parent().name == "Dressing" and node.position.y >= top)):
			node.visible = false
			_hidden.append(node)


func _find_env(main) -> Environment:
	for child in main.get_children():
		if child is WorldEnvironment:
			return child.environment
	return null


func _build_party_token() -> void:
	if is_instance_valid(_party_token):
		_party_token.queue_free()
	_party_token = Node3D.new()
	add_child(_party_token)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.72
	ring.mesh = torus
	ring.material_override = _flat(PARTY)
	_party_token.add_child(ring)
	var arrow := MeshInstance3D.new()  # which way the party faces
	var prism := PrismMesh.new()
	prism.size = Vector3(0.5, 0.55, 0.06)
	arrow.mesh = prism
	arrow.material_override = _flat(PARTY)
	arrow.rotation_degrees = Vector3(-90, 0, 0)
	arrow.position = Vector3(0, 0.05, -0.95)
	_party_token.add_child(arrow)


## Tiles: what each foe threatens next turn, what it could reach, and a
## ring under every foe the party can strike now. Rebuilt when they change.
func _update_marks() -> void:
	if _state == null:
		return
	var threat := {}
	var reach := {}
	var targets := []
	var party_cell: Vector2i = _state.party_cell
	for foe in _state.living_foes():
		for cell in _reach_cells(foe):
			reach[cell] = true
		if _state.foe_in_range(foe) and foe.intent != _state.Intent.RECOVER:
			threat[foe.marked_cell if foe.marked_cell != Vector2i(-1, -1) else party_cell] = true
		for hero in _state.party.living_members():
			if _state.can_hit(hero, foe):
				targets.append(foe.cell)
				break
	var steps := []
	if _main._combat.awaiting_field_action:
		for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = party_cell + side
			if _main._map.is_passable(next) and not _state.living_foes().any(func(f): return f.cell == next):
				steps.append(next)
	var key := str(threat.keys()) + str(reach.keys()) + str(targets) + str(party_cell) + str(steps)
	if key == _last_key:
		return
	_last_key = key
	_clear_marks()
	var size: float = _main.CELL_SIZE
	for cell in reach:
		if not threat.has(cell):
			_outline(cell, REACH, size * 0.86, 0.05)
	for cell in steps:
		if not reach.has(cell) and not threat.has(cell):
			_outline(cell, STEP, size * 0.7, 0.04)
	for cell in threat:
		_tile(cell, THREAT, size * 0.92, 0.07)
	for cell in targets:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = size * 0.32
		torus.outer_radius = size * 0.4
		ring.mesh = torus
		ring.material_override = _flat(TARGET)
		ring.position = Vector3(cell.x * size, 0.09, cell.y * size)
		add_child(ring)
		_marks.append(ring)


## The open tiles `foe` could strike from where it stands: beside it, and
## along straight open lines if it reaches or shoots.
func _reach_cells(foe) -> Array:
	var out := []
	var far: bool = foe.type.reach_back or foe.type.tactic == EnemyType.Tactic.ARCHER or foe.intent in [_state.Intent.REACH, _state.Intent.SWOOP, _state.Intent.SHOOT]
	var span: int = _state.FIELD_REACH if far else 1
	for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var cell: Vector2i = foe.cell
		for i in span:
			cell += side
			if not _main._map.is_passable(cell):
				break
			out.append(cell)
	return out


func _tile(cell: Vector2i, colour: Color, width: float, y: float) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(width, width)
	var mark := MeshInstance3D.new()
	mark.mesh = mesh
	mark.material_override = _flat(colour)
	var size: float = _main.CELL_SIZE
	mark.position = Vector3(cell.x * size, y, cell.y * size)
	add_child(mark)
	_marks.append(mark)


## A thin square frame round a tile: reachable, not yet threatened.
func _outline(cell: Vector2i, colour: Color, width: float, y: float) -> void:
	var size: float = _main.CELL_SIZE
	var centre := Vector3(cell.x * size, y, cell.y * size)
	var thick := 0.07
	for side in [Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(1, 0, 0)]:
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(width, thick) if side.x == 0 else Vector2(thick, width)
		var strip := MeshInstance3D.new()
		strip.mesh = mesh
		strip.material_override = _flat(colour)
		strip.position = centre + side * (width - thick) / 2.0
		add_child(strip)
		_marks.append(strip)


func _clear_marks() -> void:
	for mark in _marks:
		if is_instance_valid(mark):
			mark.queue_free()
	_marks.clear()


func _flat(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if colour.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = false
	return material
