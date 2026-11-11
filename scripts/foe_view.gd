extends RefCounted
## What a foe looks like, whichever kind of art it has (#251, 2026-11-11):
## the painted sprite families (an AnimatedSprite3D named "Sprite", poses
## as animations) or ChatGPT's 3D models (a scene root with play(pose),
## sample(pose, seconds), set_motion(on) and an AnimationPlayer `player`;
## feet on the floor, facing local +Z, `visual_height` metadata). Combat
## asks this for poses, fades and framing, so either kind works and the
## sprites stay the fallback.

const STAGE_PRIORITY := 10  # battle_stage.gd FOE_PRIORITY: drawn over the fog

## A model's own name for a sprite family's pose, where they differ.
const MODEL_POSES := {
	"set-snare": "snare",
	"defeated": "fall",
	"burst": "fall",
	"lunge": "attack",
	"windup": "attack",
	"wind-up": "attack",
}


static func sprite_of(node: Node) -> AnimatedSprite3D:
	return node.get_node_or_null("Sprite") as AnimatedSprite3D if node else null


## True for a 3D model (no Sprite child, and it can play poses).
static func is_model(node: Node) -> bool:
	return node != null and sprite_of(node) == null and node.has_method("play") and node.has_method("sample")


static func _model_pose(pose: String) -> String:
	return MODEL_POSES.get(pose, pose)


## Whether the art has `pose` (a sprite animation, or a model clip).
static func has_pose(node: Node, pose: String) -> bool:
	var sprite := sprite_of(node)
	if sprite:
		return sprite.sprite_frames.has_animation(pose)
	if is_model(node):
		var player: AnimationPlayer = node.get("player")
		return player != null and player.has_animation(_model_pose(pose))
	return false


## Plays `pose` (falls back to "attack" for an action, "idle" otherwise).
static func play(node: Node, pose: String, fallback := "attack") -> void:
	var sprite := sprite_of(node)
	if sprite:
		sprite.play(pose if sprite.sprite_frames.has_animation(pose) else fallback)
	elif is_model(node):
		node.play(_model_pose(pose) if has_pose(node, pose) else fallback)


## The pose it shows now.
static func current(node: Node) -> String:
	var sprite := sprite_of(node)
	if sprite:
		return sprite.animation
	if is_model(node):
		return str(node.get("current_pose"))
	return ""


## Follows the effects setting (still poses when off).
static func set_motion(node: Node, enabled: bool) -> void:
	if is_model(node):
		node.set_motion(enabled)


## Turns a model to face `target` (sprites face the camera by themselves).
static func face(node: Node3D, target: Vector3) -> void:
	if not is_model(node) or not node.is_inside_tree():
		return
	var flat := Vector3(target.x, node.global_position.y, target.z)
	if flat.distance_to(node.global_position) > 0.01:
		node.look_at(flat, Vector3.UP, true)  # local +Z toward the target


## On the dark battle stage: draw the model over the fog sheet, with a
## depth pre-pass so it still hides its own far side. Call after the node
## is in the tree (the model sets its material in _ready).
static func raise_model(node: Node) -> void:
	if not is_model(node):
		return
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var source: Material = mesh.material_override if mesh.material_override else mesh.get_active_material(0)
		if not source is BaseMaterial3D:
			continue
		var material: BaseMaterial3D = source.duplicate()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		material.render_priority = STAGE_PRIORITY
		mesh.material_override = material


## Its height in metres, for tags and framing.
static func height(node: Node) -> float:
	return float(node.get_meta("visual_height", 1.0)) if node else 1.0


## A fade: sprites fade out; models play their fall and lie still.
static func fade_time(node: Node) -> float:
	if is_model(node):
		var player: AnimationPlayer = node.get("player")
		if player and player.has_animation("fall"):
			return player.get_animation("fall").length + 0.5
	return 0.4
