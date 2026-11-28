extends Control
## Discovered route only; dashed gaps are never drawn as walkable links.
var terrain
var party

func _draw() -> void:
	if terrain == null or party == null: return
	var span := minf(size.x/10.0, size.y/10.0)
	var origin := (size-Vector2(10,10)*span)*0.5
	for a: Vector2i in terrain.links:
		if not terrain.explored.has(a): continue
		for b: Vector2i in terrain.links[a]:
			if terrain.explored.has(b):
				draw_line(origin+(Vector2(a)+Vector2.ONE*0.5)*span, origin+(Vector2(b)+Vector2.ONE*0.5)*span, Color("7b7563"), 3, true)
	for c: Vector2i in terrain.heights:
		if not terrain.explored.has(c): continue
		var colour := Color("778e94") if terrain.heights[c] < -0.01 else Color("c4b58d")
		if terrain.bridge_cells.has(c): colour = Color("9b7149")
		var centre := origin+(Vector2(c)+Vector2.ONE*0.5)*span
		draw_rect(Rect2(centre-Vector2.ONE*span*0.23, Vector2.ONE*span*0.46), colour)
		if c in [terrain.arrival, terrain.destination]: draw_circle(centre, span*0.35, Color("d8b56e"), false, 2, true)
	var at := origin+(Vector2(party.cell)+Vector2.ONE*0.5)*span
	var forward := Vector2(terrain.CARDINALS[party.facing])
	var side := forward.orthogonal()
	draw_colored_polygon(PackedVector2Array([at+forward*span*.44, at-forward*span*.25+side*span*.27, at-forward*span*.25-side*span*.27]), Color("fff0c9"))
