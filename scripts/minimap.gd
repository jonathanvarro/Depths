extends Control
## Reliable explored geometry, rendered as the party's charcoal sketch (#50).
signal pressed

const TILE := 12.0
const VIEW_CELLS := 15
const PADDING := 6.0
const FULL_VIEW_MIN_CELLS := 15
const COLOR_BACKGROUND := Color("62513d")
const COLOR_FLOOR := Color("d6c3a1")
const COLOR_WALL := Color("443a2b")
const COLOR_PARTY := Color("d3a44d")
const COLOR_CLOSED_PASSAGE := Color("655136")
const COLOR_BLOCKED_PASSAGE := Color("3f3025")
const CONTENT_COLORS := {1:Color("783f30"),2:Color("655136"),3:Color("783f30"),4:Color("51422e"),5:Color("51422e"),6:Color("443a2b"),7:Color("443a2b")}
const SEEN_FROM_AFAR := [6,7]
const PAPER := preload("res://art/ui/map-v1/paper.tres")
const QUIET_PAPER := preload("res://art/ui/map-v1/quiet-centre.png")
const INK := Color("403529")
const GLYPHS := {
	"party":preload("res://art/ui/backlog96-v1/map/party.png"),
	"up":preload("res://art/ui/backlog96-v1/map/up.png"),
	"down":preload("res://art/ui/backlog96-v1/map/down.png"),
	"rest":preload("res://art/ui/backlog96-v1/map/rest.png"),
	"chest":preload("res://art/ui/backlog96-v1/map/chest.png"),
	"chest-empty":preload("res://art/ui/backlog96-v1/map/chest-empty.png"),
	"closed":preload("res://art/ui/backlog96-v1/map/closed.png"),
	"blocked":preload("res://art/ui/backlog96-v1/map/blocked.png"),
	"danger":preload("res://art/ui/backlog96-v1/map/danger.png"),
	"object":preload("res://art/ui/backlog96-v1/map/object.png"),
	"frontier":preload("res://art/ui/backlog96-v1/map/frontier.png")
}

var map
var party_cell := Vector2i.ZERO
var party_facing := 0
var full_view := false
var reveal_all := false:
	set(value):
		reveal_all=value
		queue_redraw()
var _cache_key := -1
var _edges: Array = []
var _known_floor := {}

func setup(dungeon_map) -> void:
	map=dungeon_map
	_cache_key=-1
	if not full_view:
		custom_minimum_size=Vector2.ONE*(VIEW_CELLS*TILE+PADDING*2)
		mouse_filter=Control.MOUSE_FILTER_STOP
	queue_redraw()

func on_party_moved(cell: Vector2i, facing: int) -> void:
	party_cell=cell
	party_facing=facing
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if full_view:return
	if (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		accept_event()
		pressed.emit()

static func marker_for(content: int, used := false) -> Texture2D:
	match content:
		1,3:return GLYPHS.danger
		2:return GLYPHS["chest-empty"] if used else GLYPHS.chest
		4:return GLYPHS.object
		5:return GLYPHS.rest
		6:return GLYPHS.down
		7:return GLYPHS.up
	return null

## Stable shared vertices keep joints joined; jitter never moves route centres.
func _hash_point(v: Vector2i) -> int:
	return absi((v.x*73856093)^(v.y*19349663)^(map.depth*83492791))

func _vertex(v: Vector2i) -> Vector2:
	var n:=_hash_point(v)
	return Vector2(v)+Vector2(float(n%17)/16.0-.5,float(int(n/17)%17)/16.0-.5)*.13

## A drifting pen, rather than displaced route geometry. Endpoints are shared.
func _stroke(a: Vector2, b: Vector2, outward: Vector2, seed_value: int) -> PackedVector2Array:
	var points:=PackedVector2Array([a])
	var bow: float=(float(seed_value%19)/18.0-.5)*.18
	var wobble: float=(float(int(seed_value/19)%13)/12.0-.5)*.09
	for step in range(1,6):
		var t: float=step/6.0
		points.append(a.lerp(b,t)+outward*(sin(PI*t)*bow+sin(TAU*t)*wobble))
	points.append(b)
	return points

func _cache_geometry() -> void:
	var key: int=hash([map.explored,map._rows,reveal_all])
	if key==_cache_key:return
	_cache_key=key
	_edges.clear()
	_known_floor.clear()
	if reveal_all:
		for y in map.height:
			for x in map.width:
				var c:=Vector2i(x,y)
				if not map.is_wall(c):_known_floor[c]=true
	else:
		for cell in map.explored:
			if not map.is_wall(cell):_known_floor[cell]=true
	var directions: Array[Vector2i]=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
	var corners: Array[Vector2i]=[Vector2i.ZERO,Vector2i.RIGHT,Vector2i.ONE,Vector2i.DOWN]
	for c: Vector2i in _known_floor:
		for side in 4:
			var neighbor: Vector2i=c+directions[side]
			if _known_floor.has(neighbor):continue
			var a:=_vertex(c+corners[side])
			var b:=_vertex(c+corners[(side+1)%4])
			var n:=_hash_point(c+corners[side])
			var outward:=Vector2(directions[side])
			var points:=_stroke(a,b,outward,n)
			# Unknown neighbours stay unknown, regardless of actual wall data.
			var frontier: bool=not reveal_all and not map.explored.has(neighbor)
			_edges.append({"cell":c,"points":points,"frontier":frontier,"outward":outward,"hatch":n%5==0})

func _draw() -> void:
	if map==null:return
	if full_view:draw_style_box(PAPER,Rect2(Vector2.ZERO,size))
	else:draw_texture_rect(QUIET_PAPER,Rect2(Vector2.ZERO,size),false)
	_cache_geometry()
	var cells:=_visible_cells()
	var tile:=TILE
	var origin:=Vector2(PADDING,PADDING)
	var notes:=_notes() if full_view else []
	var rail:=minf(196.0,size.x*.22) if not notes.is_empty() else 0.0
	if full_view:
		var room:=size-Vector2(40.0+rail,40.0)
		tile=maxf(1.0,floorf(minf(room.x/cells.size.x,room.y/cells.size.y)))
		origin=Vector2(20,20)+(room-Vector2(cells.size)*tile)/2.0
	var width:=clampf(tile*.075,1.0,2.0)
	for cell: Vector2i in _known_floor:
		if cells.has_point(cell):
			var at:=origin+Vector2(cell-cells.position)*tile
			draw_rect(Rect2(at,Vector2.ONE*tile),Color(.40,.31,.20,.045))
	for edge in _edges:
		if not cells.has_point(edge.cell):continue
		var points:=PackedVector2Array()
		for p in edge.points:points.append(origin+(p-Vector2(cells.position))*tile)
		if edge.frontier:
			draw_polyline(points.slice(0,3),Color(INK,.66),width,true)
			draw_polyline(points.slice(4,6),Color(INK,.48),width,true)
		else:
			draw_polyline(points,INK,width,true)
			if full_view and edge.hatch and tile>=12:
				# The occasional faint second pass leaves a little charcoal pressure.
				var trace:=PackedVector2Array()
				for p in points.slice(1,5):trace.append(p+edge.outward*tile*.045)
				draw_polyline(trace,Color(INK,.24),1.0,true)
			if full_view and edge.hatch and tile>=9:
				var middle: Vector2=points[3]
				var tangent: Vector2=(points[-1]-points[0]).normalized()
				for i in [-1,0,1]:
					var p: Vector2=middle+tangent*i*tile*.17+edge.outward*tile*.16
					draw_line(p,p+edge.outward*tile*.24+tangent*tile*.10,Color(INK,.32),1.0,true)
	for cell: Vector2i in _known_floor:
		if not cells.has_point(cell):continue
		var center:=origin+(Vector2(cell-cells.position)+Vector2.ONE*.5)*tile
		var content: int=map.content_at(cell)
		if content!=0 and (reveal_all or map.discovered.has(cell) or content in SEEN_FROM_AFAR):
			var used: bool=map.triggered.has(cell)
			_draw_marker(marker_for(content,used),center,tile,Color(1,1,1,.58 if used and content!=2 else 1.0))
		var door: int=map.door_at(cell)
		if door==1 or door==3:_draw_marker(GLYPHS.closed if door==1 else GLYPHS.blocked,center,tile)
	# Landmarks (#117) the party has stood in: a small inked diamond.
	for landmark: Dictionary in map.landmarks:
		var spot: Vector2i=landmark["centre"]
		if (landmark["seen"] or reveal_all) and cells.has_point(spot):
			_draw_landmark(origin+(Vector2(spot-cells.position)+Vector2.ONE*.5)*tile,tile)
	_draw_arrow(origin+(Vector2(party_cell-cells.position)+Vector2.ONE*.5)*tile,tile)
	if full_view and rail>0:_draw_notes(notes,Rect2(Vector2(size.x-rail-10,30),Vector2(rail-12,size.y-50)))

func _draw_marker(texture: Texture2D, center: Vector2, tile: float, tint:=Color.WHITE) -> void:
	if texture==null:return
	var extent:=clampf(tile*.90,14.0 if full_view else 10.0,28.0 if full_view else 20.0)
	draw_texture_rect(texture,Rect2(center-Vector2.ONE*extent*.5,Vector2.ONE*extent),false,tint)

## A landmark's mark: a hollow diamond with a dot, drawn in the map's ink.
func _draw_landmark(center: Vector2, tile: float) -> void:
	var r:=clampf(tile*.42,6.0 if full_view else 4.5,12.0 if full_view else 8.0)
	var points:=PackedVector2Array([center+Vector2(0,-r),center+Vector2(r,0),center+Vector2(0,r),center+Vector2(-r,0),center+Vector2(0,-r)])
	draw_polyline(points,INK,clampf(r*.22,1.2,2.2),true)
	draw_circle(center,maxf(1.2,r*.2),INK)

func _notes() -> Array:
	var notes: Array=[]
	for landmark: Dictionary in map.landmarks:
		if landmark["seen"]:notes.append({"title":landmark["name"],"used":false,"content":-1})
	var titles: Dictionary={}
	var known: Array=map.discovered.keys()
	known.sort_custom(func(a,b):return a.y<b.y or (a.y==b.y and a.x<b.x))
	for cell in known:
		if not _known_floor.has(cell):continue
		if map.events.has(cell):
			var event: RoomEvent=map.events[cell]
			if titles.has(event.title):continue
			titles[event.title]=true
			var used: bool=map.triggered.has(cell)
			notes.append({"title":event.title,"used":used,"content":event.kind})
		elif map.content_at(cell) in SEEN_FROM_AFAR:
			notes.append({"title":"Way down" if map.content_at(cell)==6 else "Way up","used":false,"content":map.content_at(cell)})
		if notes.size()>=3:break
	return notes

func _draw_notes(notes: Array, rect: Rect2) -> void:
	var font:=get_theme_default_font()
	draw_string(font,rect.position+Vector2(0,16),"Discoveries",HORIZONTAL_ALIGNMENT_LEFT,rect.size.x,16,INK)
	var count:=clampi(int(floor((rect.size.y-58)/62))+1,0,notes.size())
	for i in count:
		var y: float=rect.position.y+40+i*62
		if notes[i].content==-1:_draw_landmark(Vector2(rect.position.x+8,y-4),20)
		else:_draw_marker(marker_for(notes[i].content,notes[i].used),Vector2(rect.position.x+8,y-4),20)
		var text: String=notes[i].title
		while text.length()>3 and font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x>rect.size.x-28:text=text.left(-2)+"…"
		draw_string(font,Vector2(rect.position.x+24,y),text,HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-24,14,INK)
		if notes[i].used and notes[i].content!=2:draw_string(font,Vector2(rect.position.x+24,y+18),"used",HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-24,12,Color(INK,.72))

func _visible_cells() -> Rect2i:
	if not full_view:
		var half:=int(VIEW_CELLS/2.0)
		return Rect2i(party_cell-Vector2i(half,half),Vector2i(VIEW_CELLS,VIEW_CELLS))
	var bounds:=Rect2i(party_cell,Vector2i.ONE)
	if reveal_all:bounds=Rect2i(0,0,map.width,map.height)
	else:
		for c in map.explored:bounds=bounds.expand(c).expand(c+Vector2i.ONE)
	var grow: Vector2i=(Vector2i(FULL_VIEW_MIN_CELLS,FULL_VIEW_MIN_CELLS)-bounds.size).maxi(0)
	return Rect2i(bounds.position-grow/2,bounds.size+grow)

func _draw_arrow(center: Vector2, tile: float) -> void:
	var angle:=party_facing*PI/2.0
	var extent:=maxf(tile,8.0)
	var points:=PackedVector2Array([Vector2(0,-.43),Vector2(.32,.32),Vector2(0,.17),Vector2(-.32,.32)])
	for i in points.size():points[i]=center+points[i].rotated(angle)*extent
	draw_colored_polygon(points,COLOR_PARTY)
	points.append(points[0]);draw_polyline(points,INK,1.2,true)
