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
## Marker colours for cell contents, keyed by dungeon_map.gd's Content values.
const CONTENT_COLORS := {
	1: Color("b03a2e"),  # ENCOUNTER
	2: Color("d9b44a"),  # CHEST
	3: Color("8e5ba8"),  # TRAP
	4: Color("5fb3b3"),  # STRANGE_OBJECT
	5: Color("6fa35a"),  # REST_SPOT
	6: Color("e8e2d0"),  # STAIRS_DOWN
	7: Color("e8e2d0"),  # STAIRS_UP
}
const COLOR_CLOSED_PASSAGE := Color("b08850")
const COLOR_BLOCKED_PASSAGE := Color("8a2f24")
## Contents visible from a distance (no need to step in to discover them).
const SEEN_FROM_AFAR := [6, 7]  # STAIRS_DOWN, STAIRS_UP

var map  # dungeon_map.gd
var party_cell := Vector2i.ZERO
var party_facing := 0
## Debug: show every cell and its contents, explored or not.
var reveal_all := false:
	set(value):
		reveal_all = value
		queue_redraw()


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
			if not (reveal_all or map.explored.has(c)) or c.x < 0 or c.y < 0 or c.x >= map.width or c.y >= map.height:
				continue
			var color: Color = COLOR_WALL if map.is_wall(c) else COLOR_FLOOR
			var tile_rect := Rect2(origin + Vector2(x, y) * TILE, Vector2(TILE, TILE) - Vector2.ONE)
			draw_rect(tile_rect, color)
			_draw_passage(c, tile_rect)
			# Contents appear once discovered (or always, in debug).
			var content: int = map.content_at(c)
			if content != 0 and (reveal_all or map.discovered.has(c) or content in SEEN_FROM_AFAR):
				var marker: Color = CONTENT_COLORS[content]
				if map.triggered.has(c):
					marker = marker.darkened(0.4)
				draw_circle(origin + (Vector2(x, y) + Vector2(0.5, 0.5)) * TILE, TILE * 0.3, marker)

	_draw_arrow(origin, half)


## Closed and blocked passages: a bar across the corridor.
func _draw_passage(c: Vector2i, tile_rect: Rect2) -> void:
	var door: int = map.door_at(c)
	if door != 1 and door != 3:  # CLOSED, BLOCKED
		return
	var color := COLOR_CLOSED_PASSAGE if door == 1 else COLOR_BLOCKED_PASSAGE
	var runs_east_west: bool = map.is_wall(c + Vector2i.UP) and map.is_wall(c + Vector2i.DOWN)
	var bar := tile_rect.grow(-1.0)
	if runs_east_west:
		bar = Rect2(bar.get_center() - Vector2(1.5, bar.size.y / 2.0), Vector2(3, bar.size.y))
	else:
		bar = Rect2(bar.get_center() - Vector2(bar.size.x / 2.0, 1.5), Vector2(bar.size.x, 3))
	draw_rect(bar, color)


func _draw_arrow(origin: Vector2, half: int) -> void:
	# Arrow pointing the way the party faces (rotation 0 = north = up).
	var center := origin + (Vector2(half, half) + Vector2(0.5, 0.5)) * TILE
	var angle := party_facing * PI / 2.0
	var points := PackedVector2Array([Vector2(0, -0.4), Vector2(0.32, 0.32), Vector2(-0.32, 0.32)])
	for i in points.size():
		points[i] = center + points[i].rotated(angle) * TILE
	draw_colored_polygon(points, COLOR_PARTY)
