extends SceneTree
## Smoother 3D model animation (owner, 2026-11-21; scripts/anim_tidy.gd):
## no bone flips left in any live model's clips, moves blend into each other,
## a repeated blow starts over, and still mode keeps its exact frames.
## Args: tag, screenshot dir.

const AnimTidy := preload("res://scripts/anim_tidy.gd")
const FOLDERS := ["res://art/enemies/combat-roster-3d-v1", "res://art/enemies/early-creatures-3d-v1",
	"res://art/enemies/creatures-refined-v2", "res://art/enemies/creatures-predatory-v3", "res://art/enemies/field-creatures-3d-v1", "res://art/enemies/fortress-goblins-3d-v1",
	"res://art/enemies/goblin-elites-3d-v1", "res://art/enemies/rat-3d-v1"]

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var models := 0
	var flips := []
	var restart_ok := true
	var still_ok := true
	var blended := 0
	for folder in FOLDERS:
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".tscn"):
				continue
			var actor: Node3D = load(folder + "/" + file).instantiate()
			if not actor.has_method("sample"):
				actor.free()
				continue
			root.add_child(actor)
			await process_frame
			models += 1
			var player: AnimationPlayer = actor.player
			for name in player.get_animation_list():
				var anim := player.get_animation(name)
				for t in anim.get_track_count():
					if anim.track_get_type(t) != Animation.TYPE_ROTATION_3D:
						continue
					for k in range(1, anim.track_get_key_count(t)):
						if AnimTidy._too_fast(anim, t, k):
							var dt: float = anim.track_get_key_time(t, k) - anim.track_get_key_time(t, k - 1)
							var turn := rad_to_deg(Quaternion(anim.track_get_key_value(t, k - 1)).angle_to(anim.track_get_key_value(t, k)))
							if turn / dt > AnimTidy.MAX_SPEED * 1.6:  # smoothstep peaks at 1.5x the even speed
								flips.append("%s %s %s %.0f deg/s" % [file.get_basename(), name, str(anim.track_get_path(t)).get_slice(":", 1), turn / dt])
			if player.has_animation("attack"):
				actor.play("idle")
				player.advance(0.3)
				actor.play("attack")
				player.advance(0.05)
				if player.current_animation == "attack":
					blended += 1
				player.advance(0.2)
				actor.play("attack")
				if player.current_animation_position > 0.05:
					restart_ok = false
				actor.set_motion(false)
				actor.play("attack")
				var want: float = float(actor.STATIC_TIME.get("attack", 0.0))
				if actor.has_method("get") and actor.get("KING_STILL") != null and actor.KING_STILL.has("attack"):
					want = actor.KING_STILL["attack"]
				if absf(player.current_animation_position - minf(want, player.get_animation("attack").length)) > 0.01 or player.is_playing():
					still_ok = false
			actor.queue_free()
	check("every live model loads its clips", models >= 25, models)
	check("no bone flips left (no bone turns faster than %d deg/s in a key step)" % int(AnimTidy.MAX_SPEED * 1.6), flips.is_empty(), flips.slice(0, 8))
	check("moves blend: the attack takes over from idle", blended >= 25, blended)
	check("the same blow again starts over", restart_ok)
	check("still mode keeps its exact frame", still_ok)
	print("fails=", fails)
	quit()
