extends RefCounted
## Recruits waiting at the campfire (#41): a role, one strength and one
## weakness each, so they differ a little without random stat soup.
##
## Owner decisions (#41): roles Warden (protector), Scout (quick) and
## Brawler (damage); 2-3 candidates, one leaving and one arriving each day;
## free until gold exists. Portraits are role silhouettes until ChatGPT's
## recruit portraits land (#82). All numbers are first guesses to tune.

const ROLES := {
	"Warden": {
		"about": "A protector. Tough, and when defending takes only a quarter of a blow.",
		"max_health": 24, "attack": Vector2i(2, 3), "accuracy": 0.7, "initiative": 8,
		"guard_factor": 0.25, "toughness": 0,
		"portrait": "res://art/portraits/recruit-silhouettes-v1/warden.png",
	},
	"Scout": {
		"about": "Quick and sharp. Acts early and hits often, but can't take much.",
		"max_health": 16, "attack": Vector2i(2, 3), "accuracy": 0.85, "initiative": 13,
		"guard_factor": 0.5, "toughness": 0,
		"portrait": "res://art/portraits/recruit-silhouettes-v1/scout.png",
	},
	"Brawler": {
		"about": "Hits hard. Careless with it: misses more and takes an extra point from every blow.",
		"max_health": 22, "attack": Vector2i(3, 5), "accuracy": 0.65, "initiative": 9,
		"guard_factor": 0.5, "toughness": -1,
		"portrait": "res://art/portraits/recruit-silhouettes-v1/brawler.png",
	},
}
## One of each per recruit; never a strength and weakness on the same stat.
const STRENGTHS := [
	{"name": "Sharp-eyed", "text": "+8% to hit", "stat": "accuracy", "amount": 0.08},
	{"name": "Sturdy", "text": "+4 health", "stat": "max_health", "amount": 4},
	{"name": "Quick", "text": "acts sooner", "stat": "initiative", "amount": 3},
	{"name": "Strong arm", "text": "+1 damage", "stat": "attack_max", "amount": 1},
]
const WEAKNESSES := [
	{"name": "Clumsy", "text": "-8% to hit", "stat": "accuracy", "amount": -0.08},
	{"name": "Frail", "text": "-4 health", "stat": "max_health", "amount": -4},
	{"name": "Slow", "text": "acts later", "stat": "initiative", "amount": -3},
	{"name": "Weak grip", "text": "-1 damage", "stat": "attack_max", "amount": -1},
]
const NAMES := [
	"Aldric", "Bryn", "Cass", "Dorran", "Edda", "Fenn", "Garet", "Hild", "Ivo", "Jessa",
	"Kell", "Liane", "Maro", "Nell", "Osric", "Pell", "Quinn", "Rhosyn", "Sef", "Tamsin",
	"Ulla", "Varn", "Wren", "Yorick",
]


## A new recruit, drawn with `rng`. `taken` names are avoided.
static func make(rng: RandomNumberGenerator, taken: Array = []) -> Companion:
	var role: String = ROLES.keys()[rng.randi_range(0, ROLES.size() - 1)]
	var spec: Dictionary = ROLES[role]
	var hero := Companion.new()
	var free_names := NAMES.filter(func(n): return n not in taken)
	hero.display_name = free_names[rng.randi_range(0, free_names.size() - 1)] if not free_names.is_empty() else "Recruit"
	hero.role = role
	hero.max_health = spec["max_health"]
	hero.attack_min = spec["attack"].x
	hero.attack_max = spec["attack"].y
	hero.accuracy = spec["accuracy"]
	hero.initiative = spec["initiative"]
	hero.guard_factor = spec["guard_factor"]
	hero.toughness = spec["toughness"]
	hero.portrait = load(spec["portrait"])
	var strength: Dictionary = STRENGTHS[rng.randi_range(0, STRENGTHS.size() - 1)]
	var weaknesses := WEAKNESSES.filter(func(w): return w["stat"] != strength["stat"])
	var weakness: Dictionary = weaknesses[rng.randi_range(0, weaknesses.size() - 1)]
	for mod in [strength, weakness]:
		hero.set(mod["stat"], hero.get(mod["stat"]) + mod["amount"])
	hero.attack_max = maxi(hero.attack_min, hero.attack_max)
	hero.strength = "%s (%s)" % [strength["name"], strength["text"]]
	hero.weakness = "%s (%s)" % [weakness["name"], weakness["text"]]
	hero.personality = spec["about"]
	hero.health = hero.max_health
	hero.strain = 10.0
	return hero
