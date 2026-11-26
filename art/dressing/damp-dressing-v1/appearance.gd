extends Node3D
## Appearance only. State aliases fit the old container API; no outcomes here.
const WET=preload("res://art/dressing/damp-dressing-v1/wet.tres")
const MINE=preload("res://art/dressing/damp-dressing-v1/mine.tres")
@export var states: PackedStringArray=["static"]
@export var variant: String="damp"
@export var optional_glow:=false
@export var state: String="static":
	set(value):
		var resolved:=_resolve(value)
		if resolved not in states:return
		state=resolved
		_apply_state()
var _motion:=false
var _time:=0.0
var _material: ShaderMaterial

func _resolve(value: String) -> String:
	if value=="closed" and "fresh" in states:return "fresh"
	if value=="empty" and "used" in states:return "used"
	return value

func _ready() -> void:
	_material=MINE if variant=="mine" else WET
	if optional_glow:
		_material=_material.duplicate()
		_material.set_shader_parameter("glow_strength",.08)
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		if mesh.is_in_group("damp_water_effect"):continue
		mesh.material_override=_material
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if get_meta("mount","")=="ceiling":
		for child in get_children():
			if child is Node3D:child.add_to_group("ceiling")
	_apply_state();set_process(_motion and optional_glow)

func _apply_state() -> void:
	for child in get_children():
		if child is Node3D and child.has_meta("appearance_state"):
			child.visible=child.get_meta("appearance_state")==state

func set_state(value: String,_animate:=false) -> bool:
	var resolved:=_resolve(value)
	if resolved not in states:return false
	state=resolved;return true

func set_searched(searched: bool) -> void:
	set_state("empty" if searched else "closed")

func set_motion(enabled: bool) -> void:
	_motion=enabled;_time=0.0
	if optional_glow and _material:_material.set_shader_parameter("glow_strength",.08)
	for child in get_children():
		if child.has_method("set_motion"):child.set_motion(enabled)
	set_process(enabled and optional_glow)

func _process(delta: float) -> void:
	_time+=delta
	_material.set_shader_parameter("glow_strength",.08+.025*sin(_time*TAU/8.0))
