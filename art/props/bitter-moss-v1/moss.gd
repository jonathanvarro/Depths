@tool
extends Node3D
## Bitter Moss on a low wet slab. The event owns the gathered flag.
@export_enum("closed", "empty") var state: String = "closed":
	set(value):
		state = value
		if is_node_ready():
			_full.visible = value == "closed"
			_scraped.visible = value != "closed"

var _full: MeshInstance3D
var _scraped: MeshInstance3D

func _ready() -> void:
	var points: Array[Vector3] = [
		Vector3(-.53,.12,-.33), Vector3(-.19,.17,-.42), Vector3(.35,.14,-.36),
		Vector3(.53,.095,-.07), Vector3(.42,.11,.27), Vector3(.03,.15,.37),
		Vector3(-.36,.10,.30), Vector3(-.57,.084,.04),
	]
	var rock := SurfaceTool.new()
	rock.begin(Mesh.PRIMITIVE_TRIANGLES)
	var centre := Vector3(.012,.218,-.012)
	for i in points.size():
		var first := points[i]
		var second := points[(i+1) % points.size()]
		var foot_a := Vector3(first.x*.9,.004,first.z*.94)
		var foot_b := Vector3(second.x*.9,.004,second.z*.94)
		var base := Color("#55584f").darkened(.06 * (i % 3))
		triangle(rock, centre, first, second, base)
		triangle(rock, first, foot_a, second, base.darkened(.22))
		triangle(rock, second, foot_a, foot_b, base.darkened(.26))
	add_surface(rock, .57)

	var growth := SurfaceTool.new()
	var scraps := SurfaceTool.new()
	growth.begin(Mesh.PRIMITIVE_TRIANGLES)
	scraps.begin(Mesh.PRIMITIVE_TRIANGLES)
	var random := RandomNumberGenerator.new()
	random.seed = 117257
	var carpet: Array[Vector3] = []
	for i in points.size():
		var reach := .68 + .21 * sin(i * 2.7)
		carpet.append(centre.lerp(points[i],reach) + Vector3.UP*.01)
	for i in carpet.size():
		triangle(growth,centre+Vector3.UP*.015,carpet[i],carpet[(i+1)%carpet.size()],
			Color("#798264").lerp(Color("#526448"),random.randf()))
	for i in 132:
		var side := i % points.size()
		var a := random.randf_range(.14,.96)
		var b := random.randf()
		var p := centre.lerp(points[side].lerp(points[(side+1)%points.size()],b),a)
		p.y += .014
		var width := random.randf_range(.018,.048)
		var tuft := p + Vector3(width*.3,random.randf_range(.02,.045),-.01)
		var stem := Color("#9da881").lerp(Color("#505f3e"),random.randf())
		triangle(growth, p+Vector3(-width,0,0), p+Vector3(width,0,0), tuft, stem)
		triangle(growth, p+Vector3(0,0,-width), tuft, p+Vector3(0,0,width), stem.darkened(.12))
		if a > .82 and side in [0,1,5,6,7]:
			triangle(scraps, p+Vector3(-width,0,0), p+Vector3(width,0,0),tuft,stem.darkened(.26))
	for i in range(2,6):
		var x := -.17+i*.066
		triangle(scraps,Vector3(x,.213,-.052),Vector3(x+.043,.213,.042),
			Vector3(x+.075,.21,-.003),Color("#857b63"))
	_full = add_surface(growth, .9)
	_scraped = add_surface(scraps, .7)
	_full.visible = state == "closed"
	_scraped.visible = state != "closed"

func triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, colour: Color) -> void:
	for point in [a,b,c]:
		surface.set_color(colour.srgb_to_linear())
		surface.add_vertex(point)

func add_surface(surface: SurfaceTool, roughness: float) -> MeshInstance3D:
	surface.generate_normals()
	var model := MeshInstance3D.new()
	model.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = roughness
	model.material_override = material
	add_child(model)
	return model
