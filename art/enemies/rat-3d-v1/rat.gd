extends Node3D
## Presentation contract for #251: callers dispatch play() instead of assuming Sprite.
## Local +Z is the snout. The root never follows a clip's body displacement.
@export var animate_motion := true
@export var palette_material: Material
var player: AnimationPlayer
var current_pose := "idle"
const STATIC_TIME := {"idle":0.0,"attack":0.29,"hurt":0.125,"fall":0.6666667,"walk":0.0,"run":0.0}

func _ready() -> void:
	player=find_child("AnimationPlayer",true,false) as AnimationPlayer
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		mesh.material_override=palette_material
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for name in player.get_animation_list():
		player.get_animation(name).loop_mode=Animation.LOOP_LINEAR if name in ["idle","walk","run"] else Animation.LOOP_NONE
	player.animation_finished.connect(_finished)
	play(current_pose)

func play(pose: String) -> void:
	if not is_node_ready():
		current_pose=pose
		return
	if not player.has_animation(pose): pose="idle"
	current_pose=pose
	player.play(pose)
	player.advance(0)
	if not animate_motion: sample(pose,float(STATIC_TIME.get(pose,0)))

func sample(pose: String, seconds: float) -> void:
	if not player.has_animation(pose): return
	current_pose=pose
	player.play(pose)
	player.seek(clampf(seconds,0,player.get_animation(pose).length),true)
	player.advance(0)
	player.pause()

func set_motion(enabled: bool) -> void:
	animate_motion=enabled
	if is_node_ready(): play(current_pose)

func _finished(pose: StringName) -> void:
	if pose in [&"attack",&"hurt"]: play("idle")
