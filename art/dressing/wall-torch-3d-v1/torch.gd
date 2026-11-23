extends Node3D
## Existing wall-height / +Z mount. Mood light only; no supply or fuel authority.
const Materials := preload("res://art/materials/worked-props-v2/materials.gd")
const Preferences := preload("res://scripts/settings.gd")
@export var lit := false
@export var follow_settings := true
var _motion := true
var _phase := 0.0
var _flame: ShaderMaterial

func _ready() -> void:
	var shared:=Materials.make()
	_flame=ShaderMaterial.new()
	_flame.shader=preload("res://art/features/campfire-3d-v1/flame.gdshader")
	shared["Flame"]=_flame
	Materials.apply(self,shared)
	$Flames.visible=lit
	$MoodLight.visible=lit
	if follow_settings:_motion=Preferences.get_value("flashes")
	set_motion(_motion)

func set_motion(enabled: bool) -> void:
	_motion=enabled
	_phase=0.0
	if is_node_ready():
		_flame.set_shader_parameter("phase",0.0)
		$MoodLight.light_energy=.4
		set_process(lit and (enabled or follow_settings))

func _process(delta: float) -> void:
	if follow_settings:
		var enabled: bool=Preferences.get_value("flashes")
		if enabled!=_motion:set_motion(enabled)
	if not _motion:return
	_phase=fmod(_phase+delta,120.0)
	_flame.set_shader_parameter("phase",_phase)
	$MoodLight.light_energy=.415+.035*sin(_phase*8.0)+.01*sin(_phase*17.0)
