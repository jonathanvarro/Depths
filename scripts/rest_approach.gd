extends RefCounted
## Reserved terrain for the delivered full refuge. Existing Refuge.EVENT
## still owns resting, stash access, present companions and the secured route.
const ANCHOR := Vector2i(7,6)
const REFUGE := Vector2i(7,7)
const SITE := Rect2i(5,4,5,5)
const FURNITURE := [Vector2i(6,5),Vector2i(6,6),Vector2i(6,7),Vector2i(8,6)]
const SCENE := preload("res://art/props/cavern-rest-v1/rest-area-approach.tscn")

static func layout() -> PackedStringArray:
	var rows := PackedStringArray()
	for y in 15:
		var row := ""
		for x in 15:
			var c := Vector2i(x,y)
			var symbol := "#"
			if x==7 and y>=5 and y<=11 or y==10 and x>=7 and x<=11: symbol="."
			if x>=6 and x<=8 and y>=5 and y<=8: symbol=","
			if c==REFUGE: symbol="R"
			if c==Vector2i(7,9): symbol="<"
			if c==Vector2i(11,10): symbol=">"
			row+=symbol
		rows.append(row)
	return rows

static func geometry(level: Node3D,size: float,material: Material) -> void:
	# East-side lookout slabs already supply their floor, avoiding coplanar
	# ground. The clear central route is supported by this single floor.
	var floor := MeshInstance3D.new(); floor.name="RefugeFloor"
	var plane := PlaneMesh.new(); plane.size=Vector2(6.4,9)
	floor.mesh=plane
	var surface: Material=material.duplicate()
	if surface is StandardMaterial3D: surface.uv1_scale=Vector3(3.2,4.5,1)
	floor.material_override=surface; floor.position=Vector3(ANCHOR.x*size-.8,0,ANCHOR.y*size+.5)
	level.add_child(floor)
