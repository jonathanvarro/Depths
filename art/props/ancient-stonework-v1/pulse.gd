extends Node3D
## Optional mood layer, never a source of world light or quest state.
var _motion := false
var _phase := 0.0

func _ready() -> void:
	set_motion(false)

func set_motion(enabled: bool) -> void:
	_motion = enabled
	set_process(enabled)
	if not enabled:
		set_phase(0.0)

func set_effects(enabled: bool) -> void:
	$Pulse.visible = enabled

func set_phase(phase: float) -> void:
	_phase = phase
	$Pulse.modulate.a = 0.035 + 0.085 * (0.5 - 0.5 * cos(_phase))

func _process(delta: float) -> void:
	if is_visible_in_tree() and $Pulse.visible:
		set_phase(fmod(_phase + delta * TAU / 8.0, TAU))
