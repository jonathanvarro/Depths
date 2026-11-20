extends RefCounted
## The named cast (#180/#201, owner 2026-11-17): companions with a name, a
## face and a reason to be here, who come to the fire at points in the
## story and wait there until hired. Random recruits still fill the gaps.
## Static helpers only (no static variables: see #100).

const Recruits := preload("res://scripts/recruits.gd")
const Quests := preload("res://scripts/quests.gd")

## id -> who they are, and when they come (see due()). Faces: the reviewed
## likenesses (#197-#199) and the Fixer-a rig for Rook (#200).
const CAST := {
	"branna": {"name": "Branna", "role": "Melee", "portrait": "res://art/portraits/named-cast-v1/branna.png", "portrait_set": "res://data/portraits/named-cast-v1/branna.tres",
		"intro": "Mine rescue worker. Came up to sort the dead miners' belongings, and stayed to see who killed them.", "when": "report"},
	"rook": {"name": "Rook", "role": "Fixer", "portrait_set": "res://data/portraits/fixer-v1/fixer-a.tres",
		"intro": "Expedition broker. Has already sold the merchant two crates he didn't know he needed.", "when": "merchant"},
	"nessa": {"name": "Nessa", "role": "Scout", "portrait": "res://art/portraits/named-cast-v1/nessa.png", "portrait_set": "res://data/portraits/named-cast-v1/nessa.tres",
		"intro": "Survey assistant. Says the old survey of the second floor is wrong, and wants to see for herself.", "when": "floor2"},
	"maelin": {"name": "Maelin", "role": "Mage", "portrait": "res://art/portraits/named-cast-v1/maelin.png", "portrait_set": "res://data/portraits/named-cast-v1/maelin.tres",
		"intro": "Unlicensed scholar. Wants to know why the bitter moss grows where it does, and what else does.", "when": "moss"},
}


## The story point that brings `id`.
static func due(camp, id: String) -> bool:
	match CAST[id]["when"]:
		"report": return Quests.stage(camp, "left_behind") == Quests.Stage.RESOLVED
		"merchant": return Quests.has_flag(camp, "story", "merchant_met")
		"floor2": return camp.times_reached(2) > 0
		"moss": return Quests.stage(camp, "healing_moss") == Quests.Stage.RESOLVED
	return false


## Brings anyone now due to the fire. Returns who came.
static func arrive(camp) -> Array:
	var came := []
	for id: String in CAST:
		if id in camp.named_met or not due(camp, id):
			continue
		camp.named_met.append(id)
		var hero := make(camp, id)
		camp.candidates.push_front(hero)
		came.append(hero)
	if not came.is_empty():
		camp.changed.emit()
	return came


## A named companion, built like a recruit of their class.
static func make(camp, id: String) -> Companion:
	var who: Dictionary = CAST[id]
	var hero: Companion = Recruits.make(camp.rng, [], [], 1, who["role"])
	hero.display_name = who["name"]
	hero.named_id = id
	hero.personality = who["intro"]
	_second_strength(camp.rng, hero)
	apply_portrait(hero)
	return hero


static func apply_portrait(hero: Companion) -> void:
	if not CAST.has(hero.named_id):
		return
	var who: Dictionary = CAST[hero.named_id]
	if who.has("portrait_set"):
		hero.portrait_set = load(who["portrait_set"])
	if who.has("portrait"):
		hero.portrait = load(who["portrait"])


## Named companions carry two strengths beside their weakness; random
## recruits one of each (#180, owner 2026-11-18: random soldiers are the
## lesser hires). Never on the stat of the first strength or the weakness.
static func _second_strength(rng: RandomNumberGenerator, hero: Companion) -> void:
	var taken := []
	for mod in Recruits.STRENGTHS + Recruits.WEAKNESSES:
		if hero.strength.begins_with(mod["name"] + " ") or hero.weakness.begins_with(mod["name"] + " "):
			taken.append(mod["stat"])
	var free: Array = Recruits.STRENGTHS.filter(func(m): return m["stat"] not in taken)
	if free.is_empty():
		return
	var extra: Dictionary = free[rng.randi_range(0, free.size() - 1)]
	hero.set(extra["stat"], hero.get(extra["stat"]) + extra["amount"])
	hero.strength += "; %s (%s)" % [extra["name"], extra["text"]]
	hero.refresh_stats()
	hero.health = hero.max_health
