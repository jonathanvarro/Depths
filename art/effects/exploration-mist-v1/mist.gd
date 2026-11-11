extends Node3D
## Three low world-registered sheets. No gameplay visibility or hazard authority.
@export_range(0,1,.01) var opacity := .32
@export var animate_motion := true
var _phase := 0.0
var _materials: Array[ShaderMaterial] = []
var _light := 1.0

func _ready() -> void:
	for i in 3:
		var item:=MeshInstance3D.new()
		item.name="MistLayer"+str(i)
		var plane:=PlaneMesh.new()
		plane.size=Vector2(11,11)
		item.mesh=plane
		item.position.y=.10+i*.19
		item.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material:=ShaderMaterial.new()
		material.shader=load("res://art/effects/exploration-mist-v1/mist.gdshader")
		material.set_shader_parameter("fog_texture",load("res://art/effects/ambient-v1/fog-strip.png"))
		material.set_shader_parameter("layer_offset",i*.37)
		material.set_shader_parameter("opacity",opacity*(1.0-i*.20))
		item.material_override=material
		_materials.append(material)
		add_child(item)
	visibility_changed.connect(_sync_motion)
	set_centre(global_position)
	set_light_strength(_light)
	_sync_motion()

func set_centre(at: Vector3) -> void:
	global_position=Vector3(at.x,0,at.z)
	for material in _materials: material.set_shader_parameter("centre",at)

func set_light_strength(value: float) -> void:
	_light=clampf(value,0,1)
	for material in _materials: material.set_shader_parameter("light_strength",_light)

func set_motion(enabled: bool) -> void:
	animate_motion=enabled
	if is_node_ready(): _sync_motion()

func set_display_phase(value: float) -> void:
	_phase=value
	for material in _materials: material.set_shader_parameter("phase",_phase)

func _sync_motion() -> void:
	set_process(animate_motion and is_visible_in_tree())

func _process(delta: float) -> void:
	set_display_phase(_phase+delta)
