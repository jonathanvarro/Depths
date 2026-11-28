extends "res://scripts/party.gd"
## Uses the real Party's input/turn/camera/lantern, with an isolated height
## adapter. No campaign movement or map serialization changes.

func _cell_to_world(c: Vector2i) -> Vector3:
	return map.world(c)

func _try_step(direction: Vector2i) -> void:
	var target := cell + direction
	if not map.can_step(cell, target):
		# Base bump handling also covers adjacent pads without a connecting ramp.
		var previous := step_check
		step_check = func(_c): return "There is no path across that edge."
		super(direction)
		step_check = previous
		return
	var reason: String = step_check.call(target) if step_check.is_valid() else ""
	if reason != "" or map.solid.has(target) or map.door_at(target) != DungeonMap.Door.NONE:
		super(direction)
		return
	_busy = true
	var from := cell
	cell = target
	panic_rest = maxi(0,panic_rest-1)
	stepped.emit(cell)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(progress: float): position = map.step_position(from, target, progress), 0.0, 1.0, move_time)
	_reveal(cell)
	moved.emit(cell, facing)
	tween.finished.connect(func():
		position = map.world(cell)
		_busy = false
		entered_cell.emit(cell))
