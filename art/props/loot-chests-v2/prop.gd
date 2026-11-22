extends Node3D
## #279: presentation only. The caller owns drops, rarity and saved state.
const MATERIALS := preload("res://art/materials/worked-props-v2/materials.gd")
@export_enum("closed","open","empty") var state := "closed":
	set(value):
		if value not in ["closed","open","empty"]:return
		if state==value:return
		state=value
		if is_node_ready():_apply(animate_motion)
@export var animate_motion := true:
	set(value):
		animate_motion=value
		if is_node_ready():_apply(false)
var _tween: Tween

func _ready() -> void:
	MATERIALS.apply(self,MATERIALS.make())
	_apply(false)

func set_state(value: StringName) -> void:
	state=String(value)

func set_motion(enabled: bool) -> void:
	animate_motion=enabled

func _apply(animate: bool) -> void:
	if _tween:
		_tween.kill()
		_tween=null
	$Contents.visible=state=="open"
	var angle:=0.0 if state=="closed" else deg_to_rad(-102)
	if animate:
		_tween=create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property($LidPivot,"rotation:x",angle,.32)
	else:$LidPivot.rotation.x=angle
