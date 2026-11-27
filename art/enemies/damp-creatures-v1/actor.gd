extends "res://art/enemies/combat-roster-3d-v1/actor.gd"
## Same presentation API as the rats; no rules, fades only when requested.
const SOLID=preload("res://art/enemies/damp-creatures-v1/biology.gdshader")
const FADE=preload("res://art/enemies/damp-creatures-v1/biology-fade.gdshader")
const CONTACT=preload("res://art/enemies/creatures-refined-v2/contact.gdshader")
const STILL={"rear":.50,"submerge":1.0,"emerge":.50,"grab":.70,"hold":0.0,"release":.50,"spread":.50,"regroup":.50,"burn":.38}
@export var pose_bounds: Dictionary
@export var contact_size:=Vector2(.7,1.1)
var surfaces: Array[ShaderMaterial]=[]
var contact: MeshInstance3D
var _opacity:=1.0
var _envelope:=AABB()

func _ready() -> void:
	for value: AABB in pose_bounds.values():
		_envelope=value if _envelope.size==Vector3.ZERO else _envelope.merge(value)
	super._ready()
	var kinds:={"Skin":0,"Gill":1,"Shell":2,"Details":3}
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		mesh.material_override=null
		for index in mesh.mesh.get_surface_count():
			var original:=mesh.mesh.surface_get_material(index)
			var material:=ShaderMaterial.new();material.shader=SOLID
			material.set_shader_parameter("surface_kind",kinds.get(original.resource_name,0))
			mesh.set_surface_override_material(index,material);surfaces.append(material)
	contact=MeshInstance3D.new();contact.name="ContactShade"
	var plane:=PlaneMesh.new();plane.size=contact_size;contact.mesh=plane;contact.position.y=.006
	var shade:=ShaderMaterial.new();shade.shader=CONTACT;shade.set_shader_parameter("strength",.13)
	contact.material_override=shade;contact.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(contact);set_opacity(_opacity)

func play(pose: String) -> void:
	super.play(pose)
	if is_node_ready() and not animate_motion and current_pose in STILL:sample(current_pose,STILL[current_pose])
	if contact:contact.visible=_opacity>=1.0 and current_pose!="submerge"

func _finished(pose: StringName) -> void:
	if pose==&"grab":play("hold")
	elif pose in [&"fall",&"submerge"]:sample(String(pose),player.get_animation(pose).length)
	else:super._finished(pose)

func sample(pose: String, seconds: float) -> void:
	super.sample(pose,seconds)
	if contact:contact.visible=_opacity>=1.0 and current_pose!="submerge"

func framing_bounds() -> AABB:
	# Include both ends of a cross-fade; changing poses must not clip a rear.
	return _envelope if _envelope.size!=Vector3.ZERO else AABB(Vector3(-.4,0,-.9),Vector3(.8,.9,1.8))

func tag_clearance() -> float:return .12

func set_opacity(value: float) -> void:
	_opacity=clampf(value,0.0,1.0)
	for material in surfaces:
		material.shader=SOLID if _opacity>=1.0 else FADE
		material.set_shader_parameter("opacity",_opacity)
	if contact:contact.visible=_opacity>=1.0 and current_pose!="submerge"
