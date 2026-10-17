extends Node3D
## The party's first-person viewpoint. Moves one grid cell at a time.
##
## Controls (keyboard or the on-screen buttons, which press the same actions):
##   move_forward  W / Up       move_back   S / Down
##   turn_left     A / Left     turn_right  D / Right
## Holding an action repeats it once each move finishes.

const DungeonMap := preload("res://scripts/dungeon_map.gd")

signal moved(cell: Vector2i, facing: int)
## Fires when a step into a new cell finishes (not on turns or wall bumps).
signal entered_cell(cell: Vector2i)
## The party opened a closed passage instead of stepping (it stays put).
signal opened_door(cell: Vector2i)
## The party walked into a blocked passage.
signal blocked_by(cell: Vector2i)

## Facing index: 0 north, 1 east, 2 south, 3 west.
const DIRECTIONS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const MOVE_TIME := 0.22
const TURN_TIME := 0.16
const BUMP_DISTANCE := 0.15
const EYE_HEIGHT := 1.2

var map  # dungeon_map.gd
var cell_size: float
var cell := Vector2i.ZERO
var facing := 0

## While true the party ignores movement input (e.g. a prompt is open).
var locked := false

var _busy := false


## Creates the camera and lantern. Call once, then place() on each floor.
func setup(size: float) -> void:
	cell_size = size
	var camera := Camera3D.new()
	camera.position.y = EYE_HEIGHT
	camera.fov = 70.0
	add_child(camera)

	# The party's lantern: the only light in the dungeon.
	var lantern := OmniLight3D.new()
	lantern.position = Vector3(0.3, EYE_HEIGHT - 0.2, 0.0)
	lantern.light_color = Color("e8a84a")
	lantern.light_energy = 1.6
	lantern.omni_range = cell_size * 3.5
	lantern.omni_attenuation = 1.2
	add_child(lantern)


## Puts the party on a floor at `at`, facing an open direction.
func place(dungeon_map, at: Vector2i) -> void:
	map = dungeon_map
	cell = at
	for f in DIRECTIONS.size():
		if map.is_passable(cell + DIRECTIONS[f]):
			facing = f
			break
	position = _cell_to_world(cell)
	rotation.y = _facing_to_yaw(facing)
	map.reveal_around(cell)
	moved.emit(cell, facing)


func _process(_delta: float) -> void:
	if _busy or locked:
		return
	if Input.is_action_pressed("move_forward"):
		_try_step(DIRECTIONS[facing])
	elif Input.is_action_pressed("move_back"):
		_try_step(-DIRECTIONS[facing])
	elif Input.is_action_pressed("turn_left"):
		_turn(-1)
	elif Input.is_action_pressed("turn_right"):
		_turn(1)


func _try_step(direction: Vector2i) -> void:
	_busy = true
	var target := cell + direction
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if map.door_at(target) == DungeonMap.Door.CLOSED:
		map.open_door(target)
		map.reveal_around(target)
		opened_door.emit(target)
		tween.tween_interval(MOVE_TIME)
	elif not map.is_passable(target):
		if map.door_at(target) == DungeonMap.Door.BLOCKED:
			blocked_by.emit(target)
		# Bump against the wall so the player knows the input registered.
		var bump := position + Vector3(direction.x, 0, direction.y) * BUMP_DISTANCE
		tween.tween_property(self, "position", bump, MOVE_TIME * 0.4)
		tween.tween_property(self, "position", position, MOVE_TIME * 0.4)
	else:
		cell = target
		tween.tween_property(self, "position", _cell_to_world(cell), MOVE_TIME)
		map.reveal_around(cell)
		moved.emit(cell, facing)
		tween.finished.connect(func(): entered_cell.emit(cell))
	tween.finished.connect(func(): _busy = false)


## step: -1 turns left (counter-clockwise), 1 turns right (clockwise).
func _turn(step: int) -> void:
	_busy = true
	facing = wrapi(facing + step, 0, 4)
	# Rotate relative to the current yaw so the turn never spins the long way round.
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation:y", rotation.y - step * PI / 2.0, TURN_TIME)
	tween.finished.connect(func(): _busy = false)
	moved.emit(cell, facing)


func _cell_to_world(c: Vector2i) -> Vector3:
	return Vector3(c.x * cell_size, 0.0, c.y * cell_size)


func _facing_to_yaw(f: int) -> float:
	return -f * PI / 2.0
