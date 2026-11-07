extends Node3D
## Visual states for #241. World lighting and event outcomes belong to the caller.
@export var palette_material: Material
@export_enum("closed", "empty") var state := "closed":
	set(value):
		state = value
		if is_node_ready(): _apply()
@export var lit := true:
	set(value):
		lit = value
		if is_node_ready(): _apply()
@export var candle_glow_enabled := true:
	set(value):
		candle_glow_enabled = value
		if is_node_ready(): _apply()
@export var animate_glow := true:
	set(value):
		animate_glow = value
		if is_node_ready(): _apply()

var _glass: StandardMaterial3D
var _phase := 0.0
var _has_glow := false
var _active := false

func set_motion(enabled: bool) -> void:
	animate_glow = enabled

func _ready() -> void:
	_glass = StandardMaterial3D.new()
	_glass.roughness = .85
	_glass.metallic_specular = .1
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mesh.name.begins_with("Glass") or mesh.name.begins_with("Flame"):
			mesh.material_override = _glass
			_has_glow = true
		else:
			mesh.material_override = palette_material
	_apply()

func _apply() -> void:
	var fresh := get_node_or_null("Fresh")
	var spent := get_node_or_null("Spent")
	var flames := get_node_or_null("Flames")
	var available := state != "empty"
	if fresh != null:
		fresh.visible = available
		spent.visible = not available
	_active = available and lit and candle_glow_enabled and _has_glow
	if flames != null: flames.visible = _active
	_glass.albedo_color = Color("#ae7838") if _active else Color("#353d38")
	_glass.emission_enabled = _active
	_glass.emission = Color("#e3a14b")
	_phase = 0.0
	_glass.emission_energy_multiplier = .75 if _active else 0.0
	set_process(_active and animate_glow)

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_phase = fmod(_phase + delta, TAU * 10)
	_glass.emission_energy_multiplier = .75 + .045 * sin(_phase * 7.0) + .025 * sin(_phase * 13.0)
