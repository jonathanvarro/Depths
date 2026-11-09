extends Node3D
## Visual state only. Loot, rest effects and saved event state belong to the caller.
@export var palette_material: Material
@export_enum("closed", "open", "empty") var state := "closed":
	set(value):
		if value not in ["closed", "open", "empty"]:
			push_warning("Unknown prop state " + value)
			return
		if state == value: return
		state = value
		if is_node_ready(): _apply(animate_motion)
@export var animate_motion := true:
	set(value):
		animate_motion = value
		if is_node_ready(): _apply(false)
var _tween: Tween

func _ready() -> void:
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = palette_material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_apply(false)

func set_state(value: StringName) -> void:
	state = String(value)

func set_searched(searched: bool) -> void:
	state = "empty" if searched else "closed"

func set_motion(enabled: bool) -> void:
	animate_motion = enabled

func _apply(animate: bool) -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	var fresh := get_node_or_null("Fresh")
	var spent := get_node_or_null("Spent")
	var contents := get_node_or_null("Contents")
	if fresh != null: fresh.visible = state != "empty"
	if spent != null: spent.visible = state == "empty"
	if contents != null: contents.visible = state == "open"
	var lid := get_node_or_null("LidPivot")
	if lid != null:
		var target := 0.0 if state == "closed" else deg_to_rad(-102)
		if animate and is_inside_tree():
			_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_tween.tween_property(lid, "rotation:x", target, .32)
		else:
			lid.rotation.x = target
