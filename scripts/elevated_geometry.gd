extends RefCounted
## Landing/ramp surfaces for optional metric maps, keeping normal floors intact.
const SIDES := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]

static func build(parent: Node3D,map,theme: EnvironmentTheme,size: float) -> void:
	var stone := SurfaceTool.new(); stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wood := SurfaceTool.new(); wood.begin(Mesh.PRIMITIVE_TRIANGLES); wood.set_color(Color("50351f"))
	var bridges: Dictionary = map.marks.get("cavern_bridge",{})
	for c: Vector2i in map.elevations:
		var at: Vector3 = map.world_at(c,size); var r: float = map.landing_radius(c,size)
		var builder := wood if bridges.has(c) else stone
		if map.content_at(c) != map.Content.STAIRS_DOWN and not map.marks.get("floor_cut",{}).has(c):
			_slab(builder,[at+Vector3(-r,0,-r),at+Vector3(r,0,-r),at+Vector3(r,0,r),at+Vector3(-r,0,r)], .18 if bridges.has(c) else .7)
		for d in [Vector2i.RIGHT,Vector2i.DOWN]:
			var n: Vector2i = c+d
			if not map.linked(c,n): continue
			var nr: float = map.landing_radius(n,size)
			if r+nr >= size-.001: continue
			var direction := Vector3(d.x,0,d.y)
			var across := Vector3(-d.y,0,d.x)*minf(r,nr)
			var a := at+direction*r; var b: Vector3 = map.world_at(n,size)-direction*nr
			var corners: Array[Vector3] = [a-across,b-across,b+across,a+across]
			if (corners[2]-corners[0]).cross(corners[1]-corners[0]).y<0: corners.reverse()
			_slab(wood if bridges.has(c) and bridges.has(n) else stone,corners,.65)
		if bridges.has(c):
			for sign in [-1,1]:
				_box(wood,at+Vector3(0,.8,sign*.77),Vector3(size,.08,.08))
				_box(wood,at+Vector3(0,.4,sign*.77),Vector3(.08,.88,.08))
	var material: Material = load("res://art/materials/worked-props-v2/wood.tres")
	for spec in [[stone,theme.floor_material,"ElevatedStone"],[wood,material,"ElevatedTimber"]]:
		var arrays: Array = spec[0].commit_to_arrays()
		if arrays[Mesh.ARRAY_VERTEX] == null or arrays[Mesh.ARRAY_VERTEX].is_empty(): continue
		var mesh := ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var node := MeshInstance3D.new(); node.name = spec[2]; node.mesh=mesh; node.material_override=spec[1]; node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(node)
	# Full room/site walls remain real. Corridor sides overlook the rift.
	var rock := SurfaceTool.new(); rock.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in map.height:
		for x in map.width:
			var c := Vector2i(x,y)
			if not map.is_wall(c): continue
			for side in SIDES:
				var near: Vector2i = c+side
				if map.is_wall(near) or not map.flat_landings.has(near) and not map.marks.get("wall_lights",{}).has(near): continue
				var at: Vector3 = map.world_at(near,size)+Vector3(-side.x,0,-side.y)*size*.5
				var along := Vector3(side.y,0,-side.x)*size*.5
				_quad(rock,at+along+Vector3.DOWN*9,at-along+Vector3.DOWN*9,at-along+Vector3.UP*14,at+along+Vector3.UP*14)
	var walls: Array = rock.commit_to_arrays()
	if walls[Mesh.ARRAY_VERTEX] != null and not walls[Mesh.ARRAY_VERTEX].is_empty():
		var mesh := ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,walls)
		var wall := MeshInstance3D.new(); wall.name="RiftWalls"; wall.mesh=mesh
		var wall_material: Material=theme.wall_material.duplicate()
		if wall_material is StandardMaterial3D: wall_material.cull_mode=BaseMaterial3D.CULL_DISABLED
		wall.material_override=wall_material; wall.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; parent.add_child(wall)
	var bottom := MeshInstance3D.new(); bottom.name="RiftBottom"
	var plane := PlaneMesh.new(); plane.size=Vector2(map.width,map.height)*size
	bottom.mesh=plane; bottom.material_override=theme.floor_material; bottom.position=Vector3((map.width-1)*size*.5,-17,(map.height-1)*size*.5); parent.add_child(bottom)

static func _quad(builder: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	var normal := (c-a).cross(b-a).normalized()
	for p in [a,b,c,a,c,d]:
		builder.set_normal(normal); builder.set_uv(Vector2(p.x,p.z)*.5 if absf(normal.y)>.5 else Vector2(p.x+p.z,p.y)*.5); builder.add_vertex(p)

static func _slab(builder: SurfaceTool,p: Array[Vector3],depth: float) -> void:
	_quad(builder,p[0],p[1],p[2],p[3])
	for i in 4: _quad(builder,p[(i+1)%4],p[i],p[i]-Vector3.UP*depth,p[(i+1)%4]-Vector3.UP*depth)

static func _box(builder: SurfaceTool,at: Vector3,span: Vector3) -> void:
	var r := span*.5
	_slab(builder,[at+Vector3(-r.x,r.y,-r.z),at+Vector3(r.x,r.y,-r.z),at+Vector3(r.x,r.y,r.z),at+Vector3(-r.x,r.y,r.z)],span.y)
