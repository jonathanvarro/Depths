extends Node3D
## Ready/disarmed/resolved presentation. Events own all outcomes and persistence.
@export var palette_material: Material
@export_enum("closed","open","empty") var state := "closed":
	set(value):
		if value not in ["closed","open","empty"]: return
		state=value
		if is_node_ready(): _apply()
@export var animate_motion := true:
	set(value):
		animate_motion=value
		if is_node_ready(): _apply()
var _water: ShaderMaterial
var _phase := 0.0

func _ready() -> void:
	for item: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		item.material_override=palette_material
		item.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if item.name.begins_with("Water"):
			if _water==null:
				_water=ShaderMaterial.new()
				_water.shader=load("res://art/props/traps-sites-3d-v1/pool.gdshader")
				_water.set_shader_parameter("water_texture",load("res://art/textures/drowned-water-v1/shallow.png"))
			item.material_override=_water
	_apply()

func set_state(value: StringName) -> void: state=String(value)
func set_motion(enabled: bool) -> void: animate_motion=enabled

func mount_in_cell(map, cell: Vector2i, cell_size: float) -> void:
	var ports:=get_node_or_null("Ports")
	if ports==null: return
	ports.hide()
	for distance in range(1,9):
		for side in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			if map.is_wall(cell+side*distance):
				ports.position=Vector3(side.x,0,side.y)*((distance-.5)*cell_size-.015)
				ports.position.y=.48
				ports.rotation.y=atan2(-float(side.x),-float(side.y))
				ports.show()
				return

func _apply() -> void:
	var desired: String="Open" if state=="open" and has_node("Open") else ("Spent" if state!="closed" else "Fresh")
	for label in ["Fresh","Open","Spent"]:
		var node:=get_node_or_null(label)
		if node!=null: node.visible=label==desired
	if _water!=null:
		_water.set_shader_parameter("disturbed",state!="closed")
	set_process(_water!=null and state!="closed" and animate_motion)

func _process(delta: float) -> void:
	_phase=fmod(_phase+delta,60.0)
	_water.set_shader_parameter("phase",_phase)
