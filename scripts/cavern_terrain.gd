extends RefCounted
## Deterministic elevation on the existing quest-safe topology, without RNG
## consumption or replacing any event, package, trigger, loot or passage.
const SIDES := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const VERSION := 1

static func ensure(map) -> void:
	if map.terrain_version >= VERSION: return
	var groups := {}; var cells: Array[Vector2i] = []
	for y in map.height:
		for x in map.width:
			var c := Vector2i(x,y)
			if map.is_wall(c): continue
			groups[c] = c; cells.append(c)
			if map._is_room_cell(c) or map.door_at(c) != 0: map.flat_landings[c] = true
	for c in cells:
		if map._is_room_cell(c):
			for d in SIDES:
				if groups.has(c+d) and map._is_room_cell(c+d): _join(groups,c,c+d)
		# Two full pads must never meet at differing heights. Passage/stair
		# aprons and their immediate neighbours remain level, too.
		if map.door_at(c) != 0 or map.content_at(c) in [map.Content.STAIRS_DOWN,map.Content.STAIRS_UP]:
			for d in SIDES:
				if groups.has(c+d): _join(groups,c,c+d)
	for site: Rect2i in map.story_sites():
		var anchor := Vector2i(-1,-1)
		for c in cells:
			if site.has_point(c):
				if anchor.x < 0: anchor = c
				_join(groups,anchor,c); map.flat_landings[c] = true
	# Full room tiles that touch each other must share a plane.
	for c in cells:
		if not map.flat_landings.has(c): continue
		for d in SIDES:
			if map.flat_landings.has(c+d): _join(groups,c,c+d)
	if not map.marks.has("cavern_bridge"):
		map.marks["cavern_bridge"] = {}
		for c in cells:
			var run: Array[Vector2i] = []
			for i in 4: run.append(c+Vector2i.RIGHT*i)
			if not run.all(func(p): return groups.has(p) and not map.flat_landings.has(p) and not map.in_story_site(p,1) and map.is_wall(p+Vector2i.UP) and map.is_wall(p+Vector2i.DOWN)): continue
			for p in run: map.marks["cavern_bridge"][p] = true; _join(groups,c,p)
			break
	var graph := {}
	for c in cells:
		var a := _root(groups,c)
		if not graph.has(a): graph[a] = []
		for d in SIDES:
			if groups.has(c+d):
				var b := _root(groups,c+d)
				if a != b and b not in graph[a]: graph[a].append(b)
	var start: Vector2i = map.find_content(map.Content.STAIRS_UP)
	if not groups.has(start): start = cells[0]
	var origin := _root(groups,start)
	var distance := {origin:0}; var queue: Array[Vector2i] = [origin]; var i := 0
	while i < queue.size():
		var a := queue[i]; i += 1
		for b: Vector2i in graph[a]:
			if not distance.has(b): distance[b] = distance[a]+1; queue.append(b)
	# Half-height rises keep the shortest room-to-corridor connector at or
	# below the approved study's 26.6 degree grade (0.2m across 0.4m).
	for c in cells: map.elevations[c] = -.2*mini(12,distance.get(_root(groups,c),0))
	map.terrain_version = VERSION
	map.marks["cavern_elevation"] = true

static func _root(groups: Dictionary,c: Vector2i) -> Vector2i:
	var root := c
	while groups[root] != root: root = groups[root]
	while groups[c] != c:
		var next: Vector2i = groups[c]; groups[c] = root; c = next
	return root

static func _join(groups: Dictionary,a: Vector2i,b: Vector2i) -> void:
	groups[_root(groups,b)] = _root(groups,a)

static func ground_branch(node: Node3D,map,size: float) -> void:
	if node.position.y < -10: return  # rift columns mount on the deep rock
	if absf(node.position.x)+absf(node.position.z) > .01:
		node.position.y += map.surface_y(node.position,size)
		return
	for child in node.get_children():
		if child is Node3D: ground_branch(child,map,size)
