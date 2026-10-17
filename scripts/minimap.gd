extends Control
## Top-down map of explored cells, with an arrow for the party's position and
## facing. Two modes share the same drawing:
## - corner minimap (default): a fixed window that follows the party, so it
##   stays small however large the floor is. Tapping/clicking it emits
##   `pressed`.
## - full view (`full_view = true`): everything explored so far, scaled to
##   fill the control. Used by the full-screen map.

signal pressed

const TILE := 12.0
const VIEW_CELLS := 15  # odd, so the party sits in the middle
const PADDING := 6.0
## Full view never zooms in further than this many cells across, so a barely
## explored floor isn't drawn with giant tiles.
const FULL_VIEW_MIN_CELLS := 15
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
const COLOR_CLOSED_PASSAGE := Color("9fb4c7")  # pale blue-grey, distinct from the floor
const COLOR_BLOCKED_PASSAGE := Color("24160e")  # near-black, distinct from encounters
## Contents visible from a distance (no need to step in to discover them).
const SEEN_FROM_AFAR := [6, 7]  # STAIRS_DOWN, STAIRS_UP

var map  # dungeon_map.gd
var party_cell := Vector2i.ZERO
var party_facing := 0
var full_view := false
## Debug: show every cell and its contents, explored or not.
var reveal_all := false:
	set(value):
		reveal_all = value
		queue_redraw()


func setup(dungeon_map) -> void:
	map = dungeon_map
	if not full_view:
		custom_minimum_size = Vector2.ONE * (VIEW_CELLS * TILE + PADDING * 2)
		mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func on_party_moved(cell: Vector2i, facing: int) -> void:
	party_cell = cell
	party_facing = facing
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if full_view:
		return
	var tapped: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed)
	if tapped:
		accept_event()
		pressed.emit()


func _draw() -> void:
	if map == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BACKGROUND)
	var cells := _visible_cells()
	var tile := TILE
	var origin := Vector2(PADDING, PADDING)
	if full_view:
		var room := size - Vector2.ONE * PADDING * 2
		tile = floorf(minf(room.x / cells.size.x, room.y / cells.size.y))
		origin = (size - Vector2(cells.size) * tile) / 2.0

	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			var c := Vector2i(x, y)
			if not (reveal_all or map.explored.has(c)) or c.x < 0 or c.y < 0 or c.x >= map.width or c.y >= map.height:
				continue
			var color: Color = COLOR_WALL if map.is_wall(c) else COLOR_FLOOR
			var tile_rect := Rect2(origin + Vector2(c - cells.position) * tile, Vector2(tile, tile) - Vector2.ONE)
			draw_rect(tile_rect, color)
			_draw_passage(c, tile_rect)
			# Contents appear once discovered (or always, in debug).
			var content: int = map.content_at(c)
			if content != 0 and (reveal_all or map.discovered.has(c) or content in SEEN_FROM_AFAR):
				var marker: Color = CONTENT_COLORS[content]
				if map.triggered.has(c):
					marker = marker.darkened(0.4)
				draw_circle(tile_rect.get_center(), tile * 0.3, marker)

	_draw_arrow(origin + (Vector2(party_cell - cells.position) + Vector2(0.5, 0.5)) * tile, tile)


## Which cells to draw: the window around the party, or (full view) the
## explored part of the floor plus a margin.
func _visible_cells() -> Rect2i:
	if not full_view:
		var half := int(VIEW_CELLS / 2.0)
		return Rect2i(party_cell - Vector2i(half, half), Vector2i(VIEW_CELLS, VIEW_CELLS))
	var bounds := Rect2i(party_cell, Vector2i.ONE)
	if reveal_all:
		bounds = Rect2i(0, 0, map.width, map.height)
	else:
		for c in map.explored:
			bounds = bounds.expand(c).expand(c + Vector2i.ONE)
	# Pad small areas out to a minimum size, keeping them centred.
	var grow := (Vector2i(FULL_VIEW_MIN_CELLS, FULL_VIEW_MIN_CELLS) - bounds.size).maxi(0)
	return Rect2i(bounds.position - grow / 2, bounds.size + grow)


## Closed and blocked passages: a bar across the corridor.
func _draw_passage(c: Vector2i, tile_rect: Rect2) -> void:
	var door: int = map.door_at(c)
	if door != 1 and door != 3:  # CLOSED, BLOCKED
		return
	var color := COLOR_CLOSED_PASSAGE if door == 1 else COLOR_BLOCKED_PASSAGE
	var runs_east_west: bool = map.is_wall(c + Vector2i.UP) and map.is_wall(c + Vector2i.DOWN)
	var bar := tile_rect.grow(-1.0)
	var thickness := maxf(3.0, tile_rect.size.x * 0.25)
	if runs_east_west:
		bar = Rect2(bar.get_center() - Vector2(thickness / 2.0, bar.size.y / 2.0), Vector2(thickness, bar.size.y))
	else:
		bar = Rect2(bar.get_center() - Vector2(bar.size.x / 2.0, thickness / 2.0), Vector2(bar.size.x, thickness))
	draw_rect(bar, color)


## Arrow pointing the way the party faces (rotation 0 = north = up).
func _draw_arrow(center: Vector2, tile: float) -> void:
	var angle := party_facing * PI / 2.0
	var points := PackedVector2Array([Vector2(0, -0.4), Vector2(0.32, 0.32), Vector2(-0.32, 0.32)])
	for i in points.size():
		points[i] = center + points[i].rotated(angle) * tile
	draw_colored_polygon(points, COLOR_PARTY)
