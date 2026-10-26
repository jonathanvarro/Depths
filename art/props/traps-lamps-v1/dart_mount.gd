extends "res://art/props/cave-events-v1/container.gd"
## Keep trap silhouettes within their cell, toward its nearest wall.
## The dart plate's separate ports attach to that real rock face.
func mount_in_cell(map, cell: Vector2i, cell_size: float) -> void:
	var ports: Sprite3D = get_node_or_null("Ports")
	if ports:
		ports.hide()
	for distance in range(1, 9):
		for side in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if map.is_wall(cell + side * distance):
				var sprite: Sprite3D = get_node("Sprite")
				var inset := 0.45 if sprite.billboard == 0 else 0.18
				sprite.position.x = side.x * inset
				sprite.position.z = side.y * inset
				if ports:
					ports.position = Vector3(side.x, 0, side.y) * ((distance - 0.5) * cell_size - 0.015)
					ports.position.y = 0.48
					ports.rotation.y = atan2(-float(side.x), -float(side.y))
					ports.show()
				return
