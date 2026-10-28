extends RefCounted
## Wandering monsters (owner, 2026-10-26): linger on a floor and something
## comes looking. After a quiet spell, each unit of time may stir a group,
## likelier the longer the party stays; deeper floors stir sooner and more
## often. Once stirred, they arrive a few steps later, so a warning sound
## gives the player time to reach the stairs or make ready. Noisy events (a
## rung bell, falling stones) stir them at once. Taking the stairs resets
## the clock; after a wanderer there's a breather. The fortress (floor 4)
## has none.
##
## Shared by main.gd and the campaign playtest, so both follow one rule.

## Depth -> [quiet time on arrival, chance per time unit at first, at most].
const WANDER := {
	1: [60, 0.02, 0.06],
	2: [50, 0.03, 0.08],
	3: [40, 0.04, 0.10],
	5: [40, 0.04, 0.10],  # the Drowned Galleries (slice 2)
	6: [35, 0.05, 0.12],  # the Black Reservoir
}
## The chance rises this much for every RISE_EVERY time lingered past quiet.
const RISE := 0.01
const RISE_EVERY := 20
## Quiet time after a wanderer has found you.
const BREATHER := 40
## Steps between hearing them and their arrival.
const WARNING_STEPS := 3

var depth := 0
var since := 0  # party time the clock last reset
var quiet := 0  # quiet time from then
var checked := 0  # party time at the last roll
var coming := -1  # steps until they arrive; -1 when none are coming


static func roams(at_depth: int) -> bool:
	return WANDER.has(at_depth)


## Chance per time unit after lingering `lingered` past the quiet spell.
static func chance(at_depth: int, lingered: int) -> float:
	var row: Array = WANDER.get(at_depth, [])
	if row.is_empty() or lingered < 0:
		return 0.0
	return minf(row[1] + RISE * (lingered / RISE_EVERY), row[2])


## A new floor (or a load): the clock starts over.
func arrive_on(at_depth: int, now: int) -> void:
	depth = at_depth
	_reset(now, WANDER.get(at_depth, [0])[0])


func _reset(now: int, quiet_time: int) -> void:
	since = now
	checked = now
	quiet = quiet_time
	coming = -1


## A step, at party time `now`: "stir" when a group is heard, "arrive" when
## one reaches the party, else "". `can_arrive` false (a room's content, a
## fight's room) holds them off a step.
func step(now: int, rng: RandomNumberGenerator, can_arrive := true) -> String:
	if not roams(depth):
		return ""
	if coming > 0:
		coming -= 1
		if coming > 0:
			return ""
		if not can_arrive:
			coming = 1
			return ""
		_reset(now, BREATHER)
		return "arrive"
	var units := now - checked
	checked = now
	var c := chance(depth, now - since - quiet)
	if c > 0.0 and units > 0 and rng.randf() < 1.0 - pow(1.0 - c, units):
		coming = WARNING_STEPS
		return "stir"
	return ""


## A noise: they're coming now, whatever the clock says. False if nothing
## roams here or they're already on their way.
func stir() -> bool:
	if not roams(depth) or coming > 0:
		return false
	coming = WARNING_STEPS
	return true
