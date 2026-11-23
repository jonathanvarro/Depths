extends Node3D
## A visual hearth only. Main owns its solid cell, tutorial and room fill light.
const Materials := preload("res://art/materials/worked-props-v2/materials.gd")
const Preferences := preload("res://scripts/settings.gd")
@export var follow_settings := false
var _motion := true
var _phase := 0.0
var _flame: ShaderMaterial
var _ember: StandardMaterial3D

func _ready() -> void:
	var shared := Materials.make()
	_ember = StandardMaterial3D.new()
	_ember.vertex_color_use_as_albedo = true
	_ember.roughness = 1.0
	_ember.emission_enabled = true
	_ember.emission = Color("8a3617")
	_ember.emission_energy_multiplier = 0.35
	shared["Ember"] = _ember
	_flame = ShaderMaterial.new()
	_flame.shader = preload("res://art/features/campfire-3d-v1/flame.gdshader")
	shared["Flame"] = _flame
	Materials.apply(self, shared)
	if follow_settings:_motion = Preferences.get_value("flashes")
	_reset()
	set_process(_motion or follow_settings)

func set_motion(enabled: bool) -> void:
	_motion = enabled
	if is_node_ready():
		_reset()
		set_process(enabled or follow_settings)

func _reset() -> void:
	_phase = 0.0
	_flame.set_shader_parameter("phase", 0.0)
	$Light.light_energy = 0.85

func _process(delta: float) -> void:
	if follow_settings:
		var enabled: bool = Preferences.get_value("flashes")
		if enabled != _motion:set_motion(enabled)
	if not _motion:return
	_phase = fmod(_phase + delta, 120.0)
	_flame.set_shader_parameter("phase", _phase)
	# Same restrained warmth range as the old tutorial light (.82-.94).
	$Light.light_energy = 0.88 + 0.04 * sin(_phase * 5.1) + 0.02 * sin(_phase * 11.3)
