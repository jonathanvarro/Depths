extends SceneTree
## Audits the live 3D models' clips (owner, 2026-11-21: smooth the
## animations). For every clip: the biggest one-step jump of any bone
## (sampled at 30 fps), and for looping clips the seam between the last and
## first frame. Prints one line per clip, worst first.
##   Godot --headless --path . --script tools/animation_audit.gd

const FOLDERS := ["res://art/enemies/combat-roster-3d-v1", "res://art/enemies/early-creatures-3d-v1",
	"res://art/enemies/creatures-refined-v2", "res://art/enemies/field-creatures-3d-v1", "res://art/enemies/fortress-goblins-3d-v1",
	"res://art/enemies/goblin-elites-3d-v1", "res://art/enemies/rat-3d-v1"]
const LOOPS := ["idle", "walk", "run"]
const STEP := 1.0 / 30.0


func _rot(anim: Animation, t: int, time: float) -> Quaternion:
	return anim.rotation_track_interpolate(t, time)


## Degrees between two rotations.
func _angle(a: Quaternion, b: Quaternion) -> float:
	return rad_to_deg(a.normalized().angle_to(b.normalized()))


func _initialize() -> void:
	var rows := []
	for folder in FOLDERS:
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".tscn"):
				continue
			var scene: Node = load(folder + "/" + file).instantiate()
			var player := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if player == null:
				scene.free()
				continue
			var held: Array = Array(scene.get("held_poses")) if scene.get("held_poses") != null else []
			for name in player.get_animation_list():
				var anim := player.get_animation(name)
				var worst := 0.0
				var worst_at := ""
				var seam := 0.0
				var seam_at := ""
				var loops: bool = name in LOOPS or name in held
				for t in anim.get_track_count():
					if anim.track_get_type(t) != Animation.TYPE_ROTATION_3D or anim.track_get_key_count(t) < 2:
						continue
					var bone := str(anim.track_get_path(t)).get_slice(":", 1)
					var time := 0.0
					var before := _rot(anim, t, 0.0)
					while time < anim.length:
						time = minf(time + STEP, anim.length)
						var now := _rot(anim, t, time)
						var step := _angle(before, now)
						if step > worst:
							worst = step
							worst_at = "%s @%.2fs" % [bone, time]
						before = now
					if loops:
						var gap := _angle(_rot(anim, t, anim.length), _rot(anim, t, 0.0))
						if gap > seam:
							seam = gap
							seam_at = bone
				rows.append({"line": "%-28s %-10s len %.2fs  biggest step %5.1f deg (%s)%s" % [file.get_basename(), name, anim.length, worst, worst_at,
						("  loop seam %5.1f deg (%s)" % [seam, seam_at]) if loops else ""], "score": maxf(worst, seam * 1.5)})
			scene.free()
	rows.sort_custom(func(a, b): return a["score"] > b["score"])
	for row in rows:
		print(row["line"])
	quit()
