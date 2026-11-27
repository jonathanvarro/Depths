extends RefCounted
## Areas as challenge families (#305, owner 2026-11-26). Each area leans on
## a kind of problem, so the party you build at the fire suits some areas
## better than others. No area ever needs a class: every obstacle has a
## cheap or safe way for the right class and a costlier way (time, light,
## health, nerves) for the rest.
##
## First pass ("build order" in DESIGN.md): the existing obstacles weighted
## by area. Class- and formation-specific challenges come later.
##
## - Abandoned Mines: rubble (a Sapper clears it free).
## - Damp Caves: traps, shut passages and deep water (a Scout spots traps and
##   finds the shallows: wading costs half the nerves and no time).
## - Cavern / Goblin Fortress / Execution Halls: fights and patrols (Soldier).
## - Jail: locks and cells (Sapper).
## - Fungal Hollows / Grove: spores fray nerves faster and few wall lights
##   (an Acolyte with the party keeps the spores off).
## - Drowned Galleries / Black Reservoir: water, traps, gates (Sapper and Scout).
##
## Static helpers only (no static variables: see #100). Numbers are first
## guesses, to tune in playtests.

## Per area:
## - leans: the classes (role ids: Melee, Scout, Fixer = Sapper, Mage =
##   Acolyte) the area favours.
## - hint: the arrival card's line about the area's character.
## - content: added to the floor generator's room-content weights.
## - blocked / closed: rubble and shut-passage chances per doorway (the
##   generator's defaults when absent).
## - puzzles: Puzzles.place chances (its defaults when absent).
## - lights: how many of the usual wall lights the area keeps.
## - spores: strain gains are scaled by this unless an Acolyte stands with
##   the party.
## - wander: wandering packs' quiet spell on arrival is scaled by this.
const AREAS := {
	"mines": {"leans": ["Fixer"], "hint": "Rubble and old workings: Sapper ground.",
		"blocked": 0.24},  # puzzle odds stay usual: floor 1 holds the first story site
	"damp": {"leans": ["Scout"], "hint": "Deep water, hidden traps and shut passages: Scout ground.",
		"content": {"T": 2}, "closed": 0.42},
	"cavern": {"leans": ["Melee"], "hint": "Open halls and packs on the move: Soldier ground.",
		"content": {"E": 2, "T": -1}, "blocked": 0.04, "wander": 0.6},
	"fortress": {"leans": ["Melee"], "hint": "Gates, guards and the goblins' hall: Soldier ground.",
		"content": {"E": 1}},
	"jail": {"leans": ["Fixer"], "hint": "Locks, cells and keys: Sapper ground.",
		"closed": 0.45},
	"execution": {"leans": ["Melee"], "hint": "One brute and its guards: Soldier ground."},
	"hollows": {"leans": ["Mage"], "hint": "Spores fray the nerves and few lights burn: an Acolyte steadies the party.",
		"spores": 1.35, "lights": 0.4},
	"grove": {"leans": ["Mage"], "hint": "Thick spores and rot: an Acolyte steadies the party.",
		"spores": 1.5, "lights": 0.0},
	"galleries": {"leans": ["Fixer", "Scout"], "hint": "Floods, sluices and gates: Sapper and Scout ground.",
		"content": {"T": 1}, "puzzles": {"oneway": 0.6, "key": 0.5, "lever": 0.8}},
	"reservoir": {"leans": ["Fixer", "Scout"], "hint": "Black water and old gates: Sapper and Scout ground.",
		"content": {"T": 1}, "puzzles": {"oneway": 0.6, "key": 0.5, "lever": 0.8}},
}

## Class names for players (classes.gd's NAMES; kept here so this stays a
## plain table).
const CLASS_NAMES := {"Melee": "Soldier", "Scout": "Scout", "Fixer": "Sapper", "Mage": "Acolyte"}

## A Scout in the party finds the shallows: wading costs this much of the
## usual nerves, and no extra time (the time is rounded down).
const SCOUT_WADE := 0.5


static func info(area: String) -> Dictionary:
	return AREAS.get(area, {})


static func leans(area: String) -> Array:
	return info(area).get("leans", [])


static func hint(area: String) -> String:
	return info(area).get("hint", "")


## The room-content weights for `area`, from the generator's `base`.
static func content_weights(area: String, base: Dictionary) -> Dictionary:
	var out := base.duplicate()
	var bias: Dictionary = info(area).get("content", {})
	for symbol in bias:
		out[symbol] = maxi(0, int(out.get(symbol, 0)) + int(bias[symbol]))
	return out


static func blocked_chance(area: String, default: float) -> float:
	return info(area).get("blocked", default)


static func closed_chance(area: String, default: float) -> float:
	return info(area).get("closed", default)


static func puzzle_chances(area: String, default: Dictionary) -> Dictionary:
	return info(area).get("puzzles", default)


static func light_share(area: String) -> float:
	return info(area).get("lights", 1.0)


static func wander_pace(area: String) -> float:
	return info(area).get("wander", 1.0)


## Strain is scaled by this in `area` for `party`: spores, unless an
## Acolyte stands with them.
static func strain_factor(area: String, party) -> float:
	var spores: float = info(area).get("spores", 1.0)
	if spores == 1.0 or party == null:
		return 1.0
	if party.living_members().any(func(h: Companion): return h.role == "Mage"):
		return 1.0
	return spores


## Wading costs this share of the usual time and nerves for `party`.
static func wade_share(party) -> float:
	if party != null and party.living_members().any(func(h: Companion): return h.role == "Scout"):
		return SCOUT_WADE
	return 1.0


## The arrival card: "Damp Caves · Deep water ...: Scout ground." plus, if
## the party has none of the classes it leans on, a warning.
static func arrival_line(area: String, party) -> String:
	var line := hint(area)
	if line == "":
		return ""
	var wanted := leans(area)
	if party != null and not wanted.is_empty() and not party.living_members().any(func(h: Companion): return h.role in wanted):
		line += " You have no %s with you: it will cost you." % " or ".join(wanted.map(func(r): return CLASS_NAMES.get(r, r)))
	return line


## The areas in `seen` (ids) that favour a class among `heroes`, in AREAS
## order: for the fire and the preparation screen.
static func suited(heroes: Array, seen: Dictionary) -> Array[String]:
	var roles := {}
	for hero: Companion in heroes:
		roles[hero.role] = true
	var out: Array[String] = []
	for area: String in AREAS:
		if seen.has(area) and leans(area).any(func(r): return roles.has(r)):
			out.append(area)
	return out
