extends Node3D
## #281: visual state only. Puzzles/Main own permission, timing and saved flags.
const MATERIALS := preload("res://art/materials/worked-props-v2/materials.gd")
@export_enum("barred","locked","lever","key") var kind := "barred"
@export var bolt_side := 1.0
var _opened := false
var _motion := true
var _tween: Tween

func _ready() -> void:
	MATERIALS.apply(self,MATERIALS.make())
	if kind=="barred":$Hinge/Bar.scale.z=bolt_side
	set_open(_opened,false)

func set_motion(enabled: bool) -> void:
	_motion=enabled
	if is_node_ready() and not enabled:set_open(_opened,false)

func set_open(opened: bool,animate := true) -> void:
	_opened=opened
	if not is_node_ready():return
	if _tween:_tween.kill();_tween=null
	if kind=="key":
		$Key.visible=not opened
		return
	var pivot: Node3D=$Pivot if kind=="lever" else $Hinge
	var angle:=Vector3(deg_to_rad(70) if opened else 0.0,0,0) if kind=="lever" else Vector3(0,-bolt_side*deg_to_rad(100) if opened else 0.0,0)
	var bar:=get_node_or_null("Hinge/Bar")
	var bar_x: float=-.28 if opened else 0.0
	if animate and _motion:
		_tween=create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(pivot,"rotation",angle,.7)
		if bar:_tween.tween_property(bar,"position:x",bar_x,.22)
	else:
		pivot.rotation=angle
		if bar:bar.position.x=bar_x
