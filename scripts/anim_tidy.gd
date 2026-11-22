extends RefCounted
## Smoother 3D model animation (owner, 2026-11-21). Presentation only: the
## model actors call these, and the clips' timing and poses stay the art's.
## - Moves blend into each other instead of snapping (BLEND seconds; hurt is
##   quicker so a hit still lands at once).
## - Bone flips (a bone turning faster than MAX_SPEED in one key step, as
##   in the goblins' fall) are spread over the neighbouring keys along the
##   shortest turn, so a fall no longer snaps the spine or leg round.
## Static helpers only (no static variables: see #100).

const BLEND := 0.14
const QUICK := {"hurt": 0.06}
## Degrees per second one key step may turn a bone before it reads as a pop.
const MAX_SPEED := 1300.0
const MIN_STEP := 35.0


static func blend_for(pose: String) -> float:
	return QUICK.get(pose, BLEND)


## Plays `pose` on `player`, blending from what was showing. The same
## one-shot pose asked for again starts over.
static func play(player: AnimationPlayer, pose: String) -> void:
	if player.current_animation == pose and player.is_playing() \
			and player.get_animation(pose).loop_mode == Animation.LOOP_NONE:
		player.seek(0.0, true)
		return
	player.play(pose, blend_for(pose))


## Evens out bone flips in every clip on `player`, once per clip.
static func tidy(player: AnimationPlayer) -> void:
	for name in player.get_animation_list():
		var anim := player.get_animation(name)
		if anim.has_meta("tidied"):
			continue
		anim.set_meta("tidied", true)
		for t in anim.get_track_count():
			if anim.track_get_type(t) == Animation.TYPE_ROTATION_3D:
				_ease_flips(anim, t)


static func _too_fast(anim: Animation, t: int, k: int) -> bool:
	var dt: float = anim.track_get_key_time(t, k) - anim.track_get_key_time(t, k - 1)
	var turn := rad_to_deg(Quaternion(anim.track_get_key_value(t, k - 1)).angle_to(anim.track_get_key_value(t, k)))
	return turn > MIN_STEP and turn / maxf(dt, 0.001) > MAX_SPEED


## Each run of too-fast steps is re-keyed as one even turn from the key
## before it to the key after it, widened a key each side until it's slow
## enough (or the clip's ends are reached).
static func _ease_flips(anim: Animation, t: int) -> void:
	var count := anim.track_get_key_count(t)
	var k := 1
	while k < count:
		if not _too_fast(anim, t, k):
			k += 1
			continue
		var last := k
		while last + 1 < count and _too_fast(anim, t, last + 1):
			last += 1
		var a := maxi(0, k - 2)
		var b := mini(count - 1, last + 1)
		for widen in 3:
			if _even_speed(anim, t, a, b) <= MAX_SPEED:
				break
			a = maxi(0, a - 1)
			b = mini(count - 1, b + 1)
		var from: Quaternion = Quaternion(anim.track_get_key_value(t, a)).normalized()
		var to: Quaternion = Quaternion(anim.track_get_key_value(t, b)).normalized()
		var t0: float = anim.track_get_key_time(t, a)
		var t1: float = anim.track_get_key_time(t, b)
		for i in range(a + 1, b):
			var w: float = (anim.track_get_key_time(t, i) - t0) / maxf(t1 - t0, 0.001)
			w = w * w * (3.0 - 2.0 * w)  # ease in and out
			anim.track_set_key_value(t, i, from.slerp(to, w))
		k = b + 1


static func _even_speed(anim: Animation, t: int, a: int, b: int) -> float:
	var turn := rad_to_deg(Quaternion(anim.track_get_key_value(t, a)).angle_to(anim.track_get_key_value(t, b)))
	return turn / maxf(anim.track_get_key_time(t, b) - anim.track_get_key_time(t, a), 0.001)
