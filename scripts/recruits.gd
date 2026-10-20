extends RefCounted
## Recruits waiting at the campfire (#41): a role, one strength and one
## weakness each, so they differ a little without random stat soup.
##
## Owner decisions (#41): roles Warden (protector), Scout (quick) and
## Brawler (damage); 2-3 candidates, one leaving and one arriving each day;
## free until gold exists. Faces come from ChatGPT's recruit roster (#82):
## three animated faces per role; a role silhouette if none is free.
## All numbers are first guesses to tune.

const FACES := "res://art/portraits/recruit-roster-v1/catalog.json"
const Progression := preload("res://scripts/progression.gd")

const ROLES := {
	"Warden": {
		"about": "A protector. Tough, and when defending takes only a quarter of a blow.",
		"stats": [2, 1, 3, 2], "aim": 0.74, "speed": 10, "hp": 0, "attack": Vector2i(2, 3),
		"guard_factor": 0.25, "toughness": 0, "weapon": "res://data/gear/wooden_club.tres",
		"portrait": "res://art/portraits/recruit-silhouettes-v1/warden.png",
	},
	"Scout": {
		"about": "Quick and sharp, with a sling: fights from the back row. Acts early and hits often, but can't take much.",
		"stats": [1, 3, 1, 2], "aim": 0.81, "speed": 11, "hp": 0, "attack": Vector2i(2, 3),
		"guard_factor": 0.5, "toughness": 0, "row": "back", "reach": true,
		"portrait": "res://art/portraits/recruit-silhouettes-v1/scout.png",
	},
	"Brawler": {
		"about": "Hits hard. Careless with it: misses more and takes an extra point from every blow.",
		"stats": [3, 2, 3, 1], "aim": 0.65, "speed": 9, "hp": -2, "attack": Vector2i(2, 4),
		"guard_factor": 0.5, "toughness": -1, "weapon": "res://data/gear/woodcutters_axe.tres",
		"portrait": "res://art/portraits/recruit-silhouettes-v1/brawler.png",
	},
}
## One of each per recruit; never a strength and weakness on the same stat.
const STRENGTHS := [
	{"name": "Sharp-eyed", "text": "+8% to hit", "stat": "aim_base", "amount": 0.08},
	{"name": "Sturdy", "text": "+4 health", "stat": "hp_bonus", "amount": 4},
	{"name": "Quick", "text": "acts sooner", "stat": "speed_base", "amount": 3},
	{"name": "Strong arm", "text": "+1 damage", "stat": "damage_max_mod", "amount": 1},
	{"name": "Lucky", "text": "better odds when a coin is flipped", "stat": "luck", "amount": 0.1},
]
const WEAKNESSES := [
	{"name": "Clumsy", "text": "-8% to hit", "stat": "aim_base", "amount": -0.08},
	{"name": "Frail", "text": "-4 health", "stat": "hp_bonus", "amount": -4},
	{"name": "Slow", "text": "acts later", "stat": "speed_base", "amount": -3},
	{"name": "Weak grip", "text": "-1 damage", "stat": "damage_max_mod", "amount": -1},
]
const NAMES := [
	"Aldric", "Bryn", "Cass", "Dorran", "Edda", "Fenn", "Garet", "Hild", "Ivo", "Jessa",
	"Kell", "Liane", "Maro", "Nell", "Osric", "Pell", "Quinn", "Rhosyn", "Sef", "Tamsin",
	"Ulla", "Varn", "Wren", "Yorick",
]


## What a hero says: their own lines, or (for a recruit saved before
## recruits could talk) their role's (#118).
static func lines_for(hero: Companion) -> DialogueLines:
	if hero.dialogue:
		return hero.dialogue
	if ROLES.has(hero.role):
		return load(_lines_path(hero.role))
	return null


static func _lines_path(role: String) -> String:
	return "res://data/dialogue/recruit_%s.tres" % role.to_lower()


## Faces for a role from the roster catalog: [{id, portrait, portrait_set}].
static func faces_for(role: String) -> Array:
	if not FileAccess.file_exists(FACES):
		return []
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FACES))
	return catalog["portraits"].filter(func(p): return p["role"] == role and ResourceLoader.exists(p["portrait_set"]))


## A new recruit, drawn with `rng`. `taken` names and `faces_in_use`
## (portrait set paths) are avoided where possible.
static func make(rng: RandomNumberGenerator, taken: Array = [], faces_in_use: Array = [], level := 1, role := "") -> Companion:
	if role == "":
		role = ROLES.keys()[rng.randi_range(0, ROLES.size() - 1)]
	var spec: Dictionary = ROLES[role]
	var hero := Companion.new()
	var free_names := NAMES.filter(func(n): return n not in taken)
	hero.display_name = free_names[rng.randi_range(0, free_names.size() - 1)] if not free_names.is_empty() else "Recruit"
	hero.role = role
	# Attributes and role offsets (#47): max health, accuracy and speed are
	# derived, matching the role's earlier fixed numbers at level 1.
	hero.uses_stats = true
	var stats: Array = spec["stats"]
	hero.stat_str = stats[0]
	hero.stat_dex = stats[1]
	hero.stat_vit = stats[2]
	hero.stat_res = stats[3]
	hero.aim_base = spec["aim"]
	hero.speed_base = spec["speed"]
	hero.hp_bonus = spec["hp"]
	hero.attack_min = spec["attack"].x
	hero.attack_max = spec["attack"].y
	hero.guard_factor = spec["guard_factor"]
	hero.toughness = spec["toughness"]
	hero.row = spec.get("row", "front")  # Scouts start at the back with a sling (#72)
	hero.reach = spec.get("reach", false)
	# They arrive with their role's plain weapon (balance report, owner
	# 2026-10-19); Scouts keep their sling.
	if spec.has("weapon"):
		hero.weapon = load(spec["weapon"])
	hero.portrait = load(spec["portrait"])
	var faces := faces_for(role)
	var free_faces := faces.filter(func(f): return f["portrait_set"] not in faces_in_use)
	if not free_faces.is_empty():
		faces = free_faces
	if not faces.is_empty():
		var face: Dictionary = faces[rng.randi_range(0, faces.size() - 1)]
		hero.portrait_set = load(face["portrait_set"])
		if ResourceLoader.exists(face["portrait"]):
			hero.portrait = load(face["portrait"])
	var strength: Dictionary = STRENGTHS[rng.randi_range(0, STRENGTHS.size() - 1)]
	var weaknesses := WEAKNESSES.filter(func(w): return w["stat"] != strength["stat"])
	var weakness: Dictionary = weaknesses[rng.randi_range(0, weaknesses.size() - 1)]
	for mod in [strength, weakness]:
		hero.set(mod["stat"], hero.get(mod["stat"]) + mod["amount"])
	hero.strength = "%s (%s)" % [strength["name"], strength["text"]]
	hero.weakness = "%s (%s)" % [weakness["name"], weakness["text"]]
	hero.personality = spec["about"]
	hero.dialogue = load(_lines_path(role))  # a few lines in the role's voice (#118)
	hero.refresh_stats()
	# Joining part-way up (#47): one level behind the campaign's best.
	hero.xp = Progression.THRESHOLDS[level] if level > 1 else 0
	Progression.auto_advance(hero)
	hero.health = hero.max_health
	hero.strain = 10.0
	return hero
