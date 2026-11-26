extends "res://art/enemies/combat-roster-3d-v1/actor.gd"
## #292: per-surface biology, registered pose envelopes and cheap contact ink.
@export var pose_bounds: Dictionary
@export var flying := false
const FUR:=preload("res://art/enemies/creatures-refined-v2/fur.tres")
const SKIN:=preload("res://art/enemies/creatures-refined-v2/skin.tres")
const DETAILS:=preload("res://art/enemies/creatures-refined-v2/details.tres")
const MEMBRANE:=preload("res://art/enemies/creatures-refined-v2/membrane.tres")
const CONTACT:=preload("res://art/enemies/creatures-refined-v2/contact.gdshader")
var surfaces: Array[ShaderMaterial]=[]
var contact: MeshInstance3D

func play(pose: String) -> void:
	var grounded:=flying and current_pose in ["landed","bite","hurt-ground","fall-ground"]
	if grounded and pose in ["hurt","fall"]:pose+="-ground"
	super.play(pose)
	if is_node_ready() and not animate_motion and pose in ["hurt-ground","fall-ground"]:
		sample(pose,player.get_animation(pose).length if pose=="fall-ground" else .125)

func _finished(pose: StringName) -> void:
	if flying and pose in [&"swoop",&"bite",&"hurt-ground"]:play("landed")
	elif pose!=&"fall-ground":super._finished(pose)

func _ready() -> void:
	super._ready()
	var kinds:={"Fur":FUR,"Skin":SKIN,"Membrane":MEMBRANE,"Details":DETAILS}
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		mesh.material_override=null
		for surface in mesh.mesh.get_surface_count():
			var original:=mesh.mesh.surface_get_material(surface)
			var material: ShaderMaterial=kinds.get(original.resource_name,FUR).duplicate()
			mesh.set_surface_override_material(surface,material);surfaces.append(material)
	contact=MeshInstance3D.new();contact.name="ContactShade"
	var plane:=PlaneMesh.new();plane.size=Vector2(.65,.55) if flying else Vector2(.75,1.0)
	contact.mesh=plane;contact.position=Vector3(0,.006,0)
	var shade:=ShaderMaterial.new();shade.shader=CONTACT
	contact.material_override=shade;contact.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(contact)
	_process(0)

func _process(_delta: float) -> void:
	if contact:
		var grounded:=not flying or current_pose in ["landed","bite","fall","hurt-ground","fall-ground"]
		contact.material_override.set_shader_parameter("strength",.15 if grounded else .025)

func framing_bounds() -> AABB:
	return pose_bounds.get(current_pose,pose_bounds.get("idle",AABB(Vector3(-.4,0,-.8),Vector3(.8,.6,1.6))))

func set_opacity(value: float) -> void:
	for material in surfaces:material.set_shader_parameter("opacity",value)
	if contact:contact.visible=value>.9
