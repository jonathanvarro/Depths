extends Node3D
## Model presentation only; callers still own intent, damage, visibility and loot.
@export var animate_motion:=true
@export var palette_material: Material
var player: AnimationPlayer
var current_pose:="idle"
const STATIC_TIME:={"idle":0.0,"walk":0.0,"attack":0.29,"hurt":0.125,"fall":1.0,"web":0.25,"venom":0.29,"draw":0.38,"brace":0.38,"drum":0.46,"snare":0.38,"enraged":0.46,"call":0.38,"cast":0.50,"defend":0.33}

func _ready() -> void:
	player=find_child("AnimationPlayer",true,false) as AnimationPlayer
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		mesh.material_override=palette_material
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for pose in player.get_animation_list():
		player.get_animation(pose).loop_mode=Animation.LOOP_LINEAR if pose in ["idle","walk","run"] else Animation.LOOP_NONE
	player.animation_finished.connect(_finished)
	play(current_pose)

func play(pose: String) -> void:
	if not is_node_ready():current_pose=pose;return
	if not player.has_animation(pose):pose="idle"
	current_pose=pose
	player.play(pose);player.advance(0)
	if not animate_motion:
		sample(pose,player.get_animation(pose).length if pose=="fall" else float(STATIC_TIME.get(pose,0)))

func sample(pose: String, seconds: float) -> void:
	if not player.has_animation(pose):return
	current_pose=pose;player.play(pose)
	player.seek(clampf(seconds,0,player.get_animation(pose).length),true);player.advance(0);player.pause()

func set_motion(enabled: bool) -> void:
	animate_motion=enabled
	if is_node_ready():play(current_pose)

func set_equipment(piece: String, enabled: bool) -> void:
	if piece not in ["Knife","RoleKit","Kit"]:return
	var node:=find_child(piece,true,false)
	if node is Node3D:node.visible=enabled

func _finished(pose: StringName) -> void:
	if pose not in [&"fall",&"idle",&"walk",&"run"]:play("idle")
