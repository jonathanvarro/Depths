extends Node3D
## #278: cosmetic state only; game lighting and outcomes remain caller-owned.
const MATERIALS := preload("res://art/materials/worked-props-v2/materials.gd")
@export_enum("closed","empty") var state := "closed":
	set(value):
		if value not in ["closed","empty"]:return
		state=value
		if is_node_ready():_apply()
@export var lit := true:
	set(value):
		lit=value
		if is_node_ready():_apply()
@export var candle_glow_enabled := true:
	set(value):
		candle_glow_enabled=value
		if is_node_ready():_apply()
@export var animate_glow := true:
	set(value):
		animate_glow=value
		if is_node_ready():_apply()
var _glass: StandardMaterial3D
var _has_glow := false
var _phase := 0.0

func _ready() -> void:
	MATERIALS.apply(self,MATERIALS.make())
	_glass=StandardMaterial3D.new()
	_glass.roughness=.85
	_glass.metallic_specular=.10
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		if mesh.name.begins_with("Glass") or mesh.name.begins_with("Flame"):
			mesh.material_override=_glass
			_has_glow=true
	_apply()

func set_state(value: StringName) -> void:
	state=String(value)

func set_motion(enabled: bool) -> void:
	animate_glow=enabled

func _apply() -> void:
	if not is_instance_valid(_glass):return
	var fresh:=get_node_or_null("Fresh")
	var spent:=get_node_or_null("Spent")
	if fresh:fresh.visible=state!="empty"
	if spent:spent.visible=state=="empty"
	var active:=state!="empty" and lit and candle_glow_enabled and _has_glow
	var flames:=get_node_or_null("Flames")
	if flames:flames.visible=active
	_glass.albedo_color=Color("ad8546") if active else Color("303832")
	_glass.emission_enabled=active
	_glass.emission=Color("dfa049")
	_glass.emission_energy_multiplier=.60 if active else 0.0
	_phase=0.0
	set_process(active and animate_glow)

func _process(delta: float) -> void:
	if not is_visible_in_tree():return
	_phase=fmod(_phase+delta,TAU*10)
	_glass.emission_energy_multiplier=.60+.025*sin(_phase*7.0)+.015*sin(_phase*13.0)
