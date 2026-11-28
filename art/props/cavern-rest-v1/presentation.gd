extends Node3D
## Visual states only. Caller owns terrain, rest, route, interactions and saves.
const Materials=preload("res://art/materials/worked-props-v2/materials.gd")
const Rock=preload("res://art/props/cavern-rest-v1/rock.tres")
@export var states:=PackedStringArray(["static"])
@export var state: String="static":
	set(value):
		var resolved:=_resolve(value)
		if resolved=="":return
		state=resolved
		if is_node_ready():_show_state()
@export var motion:=false

func _resolve(value: String) -> String:
	if value in states:return value
	if value=="closed":return states[0]
	if value in ["empty","open","used"] and states.size()==2:return states[1]
	return ""

func _ready() -> void:
	var shared:=Materials.make()
	var ember:=StandardMaterial3D.new();ember.vertex_color_use_as_albedo=true;ember.roughness=1
	shared["Ember"]=ember
	for node: Node3D in find_children("*","Node3D",true,false):
		if node is MeshInstance3D and node.get_meta("metre_uv",false) and node.mesh is BoxMesh:
			var arrays: Array=node.mesh.get_mesh_arrays()
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
			for i in vertices.size():
				var p:=vertices[i];var n:=normals[i]
				uv[i]=Vector2(p.x,p.z)*.5 if absf(n.y)>.5 else (Vector2(p.z,p.y)*.5 if absf(n.x)>.5 else Vector2(p.x,p.y)*.5)
			arrays[Mesh.ARRAY_TEX_UV]=uv
			var mapped:=ArrayMesh.new();mapped.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);node.mesh=mapped
		if node.get_meta("worked_surface",false):
			var selected:=shared.duplicate()
			if node.get_meta("cavern_rock",false):selected["Stone"]=Rock
			Materials.apply(node,selected)
		if node.get_meta("canopy",false):node.add_to_group("ceiling")
	_show_state()

func set_state(value: String,_animate:=false) -> bool:
	if _resolve(value)=="":return false
	state=value
	return true

func set_searched(value: bool) -> void:
	set_state(states[-1] if value else states[0])

func _show_state() -> void:
	for node: Node3D in find_children("*","Node3D",true,false):
		if node.has_meta("appearance_state"):node.visible=node.get_meta("appearance_state")==state
	set_motion(motion)

func set_motion(enabled: bool) -> void:
	motion=enabled
	if not is_node_ready():return
	for node: Node3D in find_children("*","Node3D",true,false):
		if node.has_method("set_motion"):
			node.set_motion(enabled and node.is_visible_in_tree())
	set_process(false)

func set_canopy_hidden(hidden: bool) -> void:
	for node: Node3D in find_children("*","Node3D",true,false):
		if node.get_meta("canopy",false):node.visible=not hidden
