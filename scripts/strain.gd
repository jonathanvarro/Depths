extends RefCounted
## Strain rules (#12): how pressure builds on a hero and what it does.
##
## Owner decision (#236, 2026-11-06): panic comes from what happens and
## what the party chooses - traps, forcing through barriers and webs without
## the proper equipment, shrines and curses, and blows taken in a fight -
## not from the clock. Darkness and hunger (choices about light and food)
## still wear on everyone; time, missing health and old injuries no longer
## do. High strain causes panic and lost effectiveness. Relief comes from
## bright light, food and rest. All numbers are first guesses to tune.

const Supplies := preload("res://scripts/supplies.gd")

enum State { STEADY, UNEASY, SHAKEN, PANICKING }

const MAX := 100.0
## Strain at which each state begins.
const THRESHOLDS := {State.UNEASY: 25.0, State.SHAKEN: 50.0, State.PANICKING: 75.0}
const NAMES := {State.STEADY: "Steady", State.UNEASY: "Uneasy", State.SHAKEN: "Shaken", State.PANICKING: "Panicking"}
## How well a hero performs (combat will use this, #14).
const EFFECTIVENESS := {State.STEADY: 1.0, State.UNEASY: 0.9, State.SHAKEN: 0.75, State.PANICKING: 0.6}
## Chance per move that a panicking hero bolts the wrong way.
const PANIC_BOLT_CHANCE := 0.15

## Per time unit:
const TIME := 0.0  # was 0.08: the clock alone no longer frays nerves (#236)
const DARKNESS := {Supplies.Light.BRIGHT: -0.12, Supplies.Light.STEADY: 0.0, Supplies.Light.DIM: 0.2, Supplies.Light.OUT: 0.5}
const MISSING_HEALTH := 0.0  # was 0.25 (#236): the blow itself is the shock
const PER_INJURY := 0.0  # was 0.08 (#236): NEW_INJURY is the shock
const HUNGRY_AFTER := 80  # time units since the last meal
const STARVING_AFTER := 160
const HUNGRY := 0.15
const STARVING := 0.35

## One-off events:
const DAMAGE_PER_HEALTH := 1.5  # strain per point of health lost
const NEW_INJURY := 10.0
const EATING := -5.0
const RESTING := -20.0
## Shocks (#236): what the party runs into, or chooses.
const STRUCK := 3.0  # each blow taken in a fight, on top of the damage
const TRAP := 12.0  # caught by a trap (the one caught; the rest half)
const WEB_BARE := 6.0  # tearing a web by hand, with no torch to burn it
const FORCED := 10.0  # forcing a blocked passage without a spade or pick
const BANE := 15.0  # a curse settles on you (a shrine, a fouled well)
## A gain at least this big counts towards Steel nerves (#233).
const SHOCK_DEED := 6.0


static func state_for(strain: float) -> State:
	if strain >= THRESHOLDS[State.PANICKING]:
		return State.PANICKING
	if strain >= THRESHOLDS[State.SHAKEN]:
		return State.SHAKEN
	if strain >= THRESHOLDS[State.UNEASY]:
		return State.UNEASY
	return State.STEADY


## Strain gained by one hero over one time unit at this light level.
static func per_time_unit(hero: Companion, light: Supplies.Light) -> float:
	var gain: float = TIME + DARKNESS[light]
	gain += MISSING_HEALTH * (1.0 - float(hero.health) / hero.max_health)
	gain += PER_INJURY * hero.hindering_injuries().size()
	if hero.hunger >= STARVING_AFTER:
		gain += STARVING
	elif hero.hunger >= HUNGRY_AFTER:
		gain += HUNGRY
	return gain
