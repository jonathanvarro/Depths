extends Control
## Top-down map of explored cells, with an arrow for the party's position and facing.

const TILE := 14.0
const COLOR_BACKGROUND := Color(0.08, 0.08, 0.08, 0.85)
const COLOR_FLOOR := Color("8c7b5e")  # dirty parchment
const COLOR_WALL := Color("2f4a4a")   # muted teal
const COLOR_PARTY := Color("e8a84a")  # lantern amber

var map  # dungeon_map.gd
var party_cell := Vector2i.ZERO
var party_facing := 0


func setup(dungeon_map) -> void:
	map = dungeon_map
	custom_minimum_size = Vector2(map.width, map.height) * TILE + Vector2(16, 16)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func on_party_moved(cell: Vector2i, facing: int) -> void:
	party_cell = cell
	party_facing = facing
	queue_redraw()


func _draw() -> void:
	if map == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BACKGROUND)
	var origin := Vector2(8, 8)
	for c in map.explored:
		if c.x < 0 or c.y < 0 or c.x >= map.width or c.y >= map.height:
			continue
		var color: Color = COLOR_WALL if map.is_wall(c) else COLOR_FLOOR
		draw_rect(Rect2(origin + Vector2(c) * TILE, Vector2(TILE, TILE) - Vector2.ONE), color)

	# Arrow pointing the way the party faces (rotation 0 = north = up).
	var center := origin + (Vector2(party_cell) + Vector2(0.5, 0.5)) * TILE
	var angle := party_facing * PI / 2.0
	var points := PackedVector2Array([Vector2(0, -0.4), Vector2(0.32, 0.32), Vector2(-0.32, 0.32)])
	for i in points.size():
		points[i] = center + points[i].rotated(angle) * TILE
	draw_colored_polygon(points, COLOR_PARTY)
