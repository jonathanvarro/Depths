extends Node3D
## One small opaque falling bead and expanding ripple. No particles, RNG or light.
const MATERIAL=preload("res://art/dressing/damp-dressing-v1/water.tres")
@export var fall_distance:=2.16
@export var phase_offset:=0.0
@export var motion:=false
var _time:=0.0
var _drop: MeshInstance3D
var _ripple: MeshInstance3D

func _ready() -> void:
	_drop=MeshInstance3D.new();_drop.name="WaterBead"
	var bead:=SphereMesh.new();bead.radius=.011;bead.height=.036;bead.radial_segments=8;bead.rings=4
	_drop.mesh=bead;_drop.material_override=MATERIAL;_drop.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_drop)
	_drop.add_to_group("damp_water_effect")
	_ripple=MeshInstance3D.new();_ripple.name="Ripple"
	var ring:=TorusMesh.new();ring.inner_radius=.046;ring.outer_radius=.050;ring.rings=20;ring.ring_segments=4
	_ripple.mesh=ring;_ripple.material_override=MATERIAL;_ripple.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ripple);_ripple.add_to_group("damp_water_effect");add_to_group("ceiling");set_motion(motion)

func set_motion(enabled: bool) -> void:
	motion=enabled;_time=0.0
	if _drop:_sample(0.0)
	set_process(enabled)

func _process(delta: float) -> void:
	_time+=delta
	_sample(fposmod(_time+phase_offset,2.8))

func _sample(time: float) -> void:
	var falling:=time<.68
	_drop.visible=falling
	_drop.position=Vector3(0,-.035-fall_distance*pow(clampf(time/.68,0,1),2),0)
	_ripple.visible=time>=.68 and time<1.28
	_ripple.position=Vector3(0,-fall_distance-.030,0)
	var size:=lerpf(.3,3.2,clampf((time-.68)/.60,0,1))
	_ripple.scale=Vector3(size,.18,size)

func sample(time: float) -> void:
	## Review/paused presentation sampling only; caller supplies phase if desired.
	_sample(fposmod(maxf(time,0),2.8))
