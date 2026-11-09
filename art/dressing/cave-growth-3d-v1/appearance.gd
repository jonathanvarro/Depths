extends Node3D
## Static decor with optional mood-only fungal emission.
@export var palette_material: StandardMaterial3D
@export var glow_enabled := false:
	set(value):
		glow_enabled=value
		if is_node_ready(): _apply()
@export var animate_motion := false:
	set(value):
		animate_motion=value
		if is_node_ready(): _apply()
var _caps: StandardMaterial3D
var _has_caps := false
var _phase := 0.0

func _ready() -> void:
	_caps=palette_material.duplicate()
	_caps.emission=Color("#778b58")
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mesh.name.begins_with("Caps"):
			mesh.material_override=_caps
			_has_caps=true
		else: mesh.material_override=palette_material
	_apply()

func set_motion(enabled: bool) -> void:
	animate_motion=enabled

func _apply() -> void:
	_phase=0
	_caps.emission_enabled=glow_enabled and _has_caps
	_caps.emission_energy_multiplier=.12
	set_process(glow_enabled and _has_caps and animate_motion)

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_phase=fmod(_phase+delta,8.0)
	_caps.emission_energy_multiplier=.12+.025*sin(_phase*TAU/8.0)
