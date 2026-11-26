extends Node
## Keep low, floor-registered models in the usable first-person combat view.
## Camera-only presentation: never move a foe or change its cell/reach.
var main: Node
var camera: Camera3D
var base_pitch:=0.0
var base_fov:=70.0
var active:=false
var target_pitch:=0.0
var target_fov:=70.0

func _init(owner_main: Node=null) -> void:main=owner_main

func _process(delta: float) -> void:
	if main==null or not is_instance_valid(main._party) or main._party.camera==null:return
	var eye: Camera3D=main._party.camera
	var state=main._combat._state
	var field: bool=main._in_combat and state!=null and state.field and not main._tactical.active
	if not field:
		restore()
		return
	var low:=INF;var high:=-INF
	var refined_visible:=false
	var basis: Basis=main._party.global_basis.inverse()
	for foe in state.living_foes():
		if not is_instance_valid(foe.node) or not foe.node.visible:continue
		var refined: bool=foe.node.has_method("framing_bounds")
		var bounds: AABB=foe.node.framing_bounds() if refined else AABB(Vector3(-.35,0,-.35),Vector3(.7,float(foe.node.get_meta("visual_height",1.4)),.7))
		for corner in 8:
			var point: Vector3=foe.node.global_transform*bounds.get_endpoint(corner)
			var relative:=basis*(point-eye.global_position)
			if relative.z>=-.08 or absf(atan2(relative.x,-relative.z))>deg_to_rad(60):continue
			if refined:refined_visible=true
			var angle:=atan2(relative.y,-relative.z)
			low=minf(low,angle);high=maxf(high,angle)
	if low==INF or not refined_visible:
		restore()
		return
	if not active:
		camera=eye;base_pitch=eye.rotation.x;base_fov=eye.fov;active=true
	var viewport_height:=main.get_viewport().get_visible_rect().size.y
	var panel_top: float=main._combat._actions.get_global_rect().position.y
	var bottom_fraction:=clampf(panel_top/viewport_height-.025,.48,.90)
	var top_fraction:=.08
	target_fov=base_fov
	var lower:=base_pitch;var upper:=base_pitch
	while true:
		var half:=tan(deg_to_rad(target_fov)*.5)
		var top_angle:=atan((1-2*top_fraction)*half)
		var bottom_angle:=atan((1-2*bottom_fraction)*half)
		lower=high-top_angle;upper=low-bottom_angle
		if lower<=upper or target_fov>=88:break
		target_fov+=1
	target_pitch=clampf(clampf(base_pitch,lower,upper) if lower<=upper else (lower+upper)*.5,deg_to_rad(-42),deg_to_rad(10))
	var blend:=minf(1,delta*10)
	eye.rotation.x=lerp_angle(eye.rotation.x,target_pitch,blend)
	eye.fov=lerpf(eye.fov,target_fov,blend)

func restore() -> void:
	if active and is_instance_valid(camera):
		camera.rotation.x=base_pitch;camera.fov=base_fov
	active=false

func _exit_tree() -> void:restore()
