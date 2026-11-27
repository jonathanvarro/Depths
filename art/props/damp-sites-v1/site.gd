extends Node3D
## Registered appearance/placement hints only. Events and maps retain authority.
const WET=preload("res://art/dressing/damp-dressing-v1/wet.tres")
@export var states: PackedStringArray=["static"]
@export var mount_mode: String="floor"
@export var state: String="static":
	set(value):
		var resolved:=_resolve(value)
		if resolved not in states:return
		state=resolved;_apply()
var _motion:=false
var _time:=0.0
var _fish: Dictionary={}

func _resolve(value: String) -> String:
	if value=="closed":return "fresh" if "fresh" in states else ("ready" if "ready" in states else value)
	if value=="empty" and states.size()==2:return states[1]
	return value

func _ready() -> void:
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		var ancestor: Node=mesh
		while ancestor!=self and ancestor!=null:
			if ancestor.get_meta("physical_surface",false):
				mesh.material_override=WET;break
			ancestor=ancestor.get_parent()
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for node: Node3D in find_children("*","Node3D",true,false):
		if node.get_meta("swimming_fish",false):_fish[node]=node.transform
	_apply();set_motion(_motion)

func set_state(value: String,_animate:=false) -> bool:
	var resolved:=_resolve(value)
	if resolved not in states:return false
	state=resolved;return true

func _apply() -> void:
	var mount:=get_node_or_null("Mount")
	if mount:
		for node in mount.get_children():
			if node is Node3D and node.has_meta("appearance_state"):node.visible=node.get_meta("appearance_state")==state
	_reset_fish();set_process(_motion and state=="fresh" and not _fish.is_empty())

func _reset_fish() -> void:
	_time=0.0
	for node: Node3D in _fish:
		if is_instance_valid(node):node.transform=_fish[node]

func set_motion(enabled: bool) -> void:
	_motion=enabled;_reset_fish();_forward_motion(self,enabled)
	set_process(enabled and state=="fresh" and not _fish.is_empty())

func _forward_motion(parent: Node,enabled: bool) -> void:
	for child in parent.get_children():
		if child.has_method("set_motion"):child.set_motion(enabled)
		else:_forward_motion(child,enabled)

func _process(delta: float) -> void:
	_time+=delta;sample(_time)

func sample(time: float) -> void:
	if state!="fresh":return
	var i:=0
	for node: Node3D in _fish:
		node.transform=_fish[node]
		node.position.x+=.035*sin(time*TAU/7.0+i*1.6)
		node.position.z+=.025*sin(time*TAU/9.0+i*.9)
		node.rotation.y+=.12*sin(time*TAU/7.0+i*1.6)
		i+=1

func mount_in_cell(map,cell: Vector2i,cell_size: float) -> bool:
	## Root must already be at the cell centre. Only the seep uses a real wall.
	if mount_mode!="wall-floor":return true
	var mount:=get_node("Mount") as Node3D
	for distance in range(1,9):
		for side: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			if map.is_wall(cell+side*distance):
				mount.position=Vector3(side.x,0,side.y)*((distance-.5)*cell_size-.012)
				mount.rotation.y=atan2(-float(side.x),-float(side.y));show();return true
	hide();return false
