extends Node3D
## Presentation only. Fortress, flood, quest and travel state belong to the caller.
signal pose_changed(value: float)
@export var palette_material: Material
@export var lift_metres := 0.0
@export var lift_origin := Vector3.ZERO
@export var spin_axis := Vector3(0,0,1)
@export_enum("closed", "open", "empty") var state := "closed":
	set(value):
		if value not in ["closed", "open", "empty"]:
			push_warning("Unknown structure state " + value)
			return
		if state == value: return
		state = value
		if is_node_ready(): _apply(animate_motion)
@export var animate_motion := true:
	set(value):
		if animate_motion == value and value: return
		animate_motion = value
		if is_node_ready() and not value: _apply(false)
var _tween: Tween
var _progress := 0.0

func _ready() -> void:
	for item: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		item.material_override = palette_material
		item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_apply(false)

func set_state(value: StringName) -> void:
	state = String(value)

func set_motion(enabled: bool) -> void:
	animate_motion = enabled

func set_display_phase(value: float) -> void:
	## Paused inspection. Does not change the authoritative requested state.
	_stop_tween()
	_pose(clampf(value,0,1))

func _stop_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null

func _pose(value: float) -> void:
	_progress = value
	var lift := get_node_or_null("Lift")
	if lift != null: lift.position = lift_origin + Vector3(0,lift_metres*value,0)
	var wheel := get_node_or_null("Wheel")
	if wheel != null: wheel.rotation = spin_axis * TAU * value
	pose_changed.emit(value)

func _apply(animate: bool) -> void:
	_stop_tween()
	var fresh := get_node_or_null("Fresh")
	var spent := get_node_or_null("Spent")
	if fresh != null: fresh.visible = state != "empty"
	if spent != null: spent.visible = state == "empty"
	var target := 0.0 if state == "closed" else 1.0
	if get_node_or_null("Lift") != null and animate and is_inside_tree():
		_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_method(_pose,_progress,target,.65)
	else:
		_pose(target)
