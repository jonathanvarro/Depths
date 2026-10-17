extends Control
## Top-down map of explored cells around the party, with an arrow for the
## party's position and facing. Shows a fixed window that follows the party,
## so it stays small however large the floor is.

const TILE := 12.0
const VIEW_CELLS := 15  # odd, so the party sits in the middle
const PADDING := 6.0
const COLOR_BACKGROUND := Color(0.08, 0.08, 0.08, 0.85)
const COLOR_FLOOR := Color("8c7b5e")  # dirty parchment
const COLOR_WALL := Color("2f4a4a")   # muted teal
const COLOR_PARTY := Color("e8a84a")  # lantern amber

var map  # dungeon_map.gd
var party_cell := Vector2i.ZERO
var party_facing := 0


func setup(dungeon_map) -> void:
	map = dungeon_map
	custom_minimum_size = Vector2.ONE * (VIEW_CELLS * TILE + PADDING * 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func on_party_moved(cell: Vector2i, facing: int) -> void:
	party_cell = cell
	party_facing = facing
	queue_redraw()


func _draw() -> void:
	if map == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BACKGROUND)
	var half := int(VIEW_CELLS / 2.0)
	var top_left := party_cell - Vector2i(half, half)
	var origin := Vector2(PADDING, PADDING)
	for y in VIEW_CELLS:
		for x in VIEW_CELLS:
			var c := top_left + Vector2i(x, y)
			if not map.explored.has(c) or c.x < 0 or c.y < 0 or c.x >= map.width or c.y >= map.height:
				continue
			var color: Color = COLOR_WALL if map.is_wall(c) else COLOR_FLOOR
			draw_rect(Rect2(origin + Vector2(x, y) * TILE, Vector2(TILE, TILE) - Vector2.ONE), color)

	# Arrow pointing the way the party faces (rotation 0 = north = up).
	var center := origin + (Vector2(half, half) + Vector2(0.5, 0.5)) * TILE
	var angle := party_facing * PI / 2.0
	var points := PackedVector2Array([Vector2(0, -0.4), Vector2(0.32, 0.32), Vector2(-0.32, 0.32)])
	for i in points.size():
		points[i] = center + points[i].rotated(angle) * TILE
	draw_colored_polygon(points, COLOR_PARTY)
