extends Node3D
## Face the camera as one layered object. The slight forward light offset
## illuminates the lit sprite plane instead of sitting exactly within it.
## Visual only: no collision, rest, inventory, time or event behaviour.

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var target := Vector3(camera.global_position.x, global_position.y, camera.global_position.z)
	if global_position.distance_squared_to(target) > 0.0001:
		look_at(target, Vector3.UP, true)
