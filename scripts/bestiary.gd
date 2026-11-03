extends RefCounted
## The monster journal (#176, owner 2026-10-30): what the party has learned
## about each kind of monster, kept for the whole campaign (it's the player's
## knowledge). Meeting one writes its brief; each move it makes is noted
## (the rest stay "?"); killing one shows its weaknesses and what it shrugs
## off. Kept in CampState.bestiary, keyed by the monster's name.

const CombatState := preload("res://scripts/combat_state.gd")


## After a fight: who was met, what they did, who fell.
static func record(camp, state, depth: int) -> void:
	for foe in state.foes:
		var key: String = foe.type.display_name
		var entry: Dictionary = camp.bestiary.get(key, {"met": 0, "killed": 0, "deepest": 0, "moves": [], "facts": {}})
		entry["met"] = int(entry["met"]) + 1
		entry["deepest"] = maxi(int(entry["deepest"]), depth)
		for move in state.seen_moves.get(foe, []):
			if move not in entry["moves"]:
				entry["moves"].append(move)
		if foe.health <= 0:
			entry["killed"] = int(entry["killed"]) + 1
		if key in state.studied:
			entry["studied"] = true
		entry["facts"] = _facts(foe.type)
		camp.bestiary[key] = entry


static func _facts(type: EnemyType) -> Dictionary:
	var flare := "dazzle" if type.fears_fire else "squint"
	if type.tactic == EnemyType.Tactic.DRAINER:
		flare = "drink"
	elif type.tactic == EnemyType.Tactic.BLOAT:
		flare = "none"
	return {"id": type.resource_path.get_file().get_basename(), "flare": flare, "brief": type.intro, "armour": type.armour, "fears_fire": type.fears_fire, "slow": type.slow,
		"back": type.row == "back", "reach_back": type.reach_back, "family": type.family,
		"venom": type.venomous and type.tactic in [EnemyType.Tactic.WEB_AND_VENOM, EnemyType.Tactic.BROOD]}


const ART := "res://art/ui/expedition-v1/"
## Moves worth bracing for, or stepping off the marked tile.
const BIG_BLOWS := [CombatState.Intent.HEAVY, CombatState.Intent.KILLING_BLOW, CombatState.Intent.CLEAVER, CombatState.Intent.REACH]


## The monster's silhouette for its page (#178): ChatGPT's thumbnails, by
## enemy file. Older saves lack the id: found by name. Null if none.
static func thumbnail(camp, key: String) -> Texture2D:
	var id: String = camp.bestiary.get(key, {}).get("facts", {}).get("id", "")
	if id == "":
		for file in DirAccess.get_files_at("res://data/enemies/"):
			if file.ends_with(".tres") and load("res://data/enemies/" + file).display_name == key:
				id = file.get_basename()
	var path := ART + "thumbnails/%s.png" % id
	return load(path) if id != "" and ResourceLoader.exists(path) else null


## The page's marks (#178), only for what the party has learned: [mark,
## frame ("weak", "immune" or ""), words]. Frames sit round a smaller mark.
## A big blow it has been seen winding up shows at once; the rest after a
## kill or a study, like the weaknesses.
static func marks(camp, key: String) -> Array:
	var e: Dictionary = camp.bestiary.get(key, {})
	if e.is_empty():
		return []
	var out := []
	if e["moves"].any(func(m): return int(m) in BIG_BLOWS):
		out.append([ART + "journal/brace.png", "", "Winds up big blows: brace, or step aside"])
	if int(e["killed"]) == 0 and not e.get("studied", false):
		return out
	var f: Dictionary = e["facts"]
	if f.get("fears_fire", false):
		out.append([ART + "journal/fire.png", "weak", "Weak to fire"])
		out.append([ART + "journal/thrown-torch.png", "", "A thrown torch drives it off"])
	else:
		out.append([ART + "journal/fire.png", "immune", "Not troubled by fire"])
	if f.get("back", false):
		out.append([ART + "journal/reach.png", "", "Keeps to the back row: reach it"])
	if f.get("venom", false):
		out.append([ART + "journal/poison.png", "", "Venomous bite"])
	match f.get("flare", ""):
		"dazzle": out.append([ART + "journal/flare.png", "weak", "A flare blinds it"])
		"squint": out.append([ART + "journal/flare.png", "", "A flare only makes it squint"])
		"drink", "none": out.append([ART + "journal/flare.png", "immune", "A flare does it no harm" if f["flare"] == "none" else "It drinks a flare's light"])
	return out


## Names in the order first met is lost to dictionaries; alphabetical reads
## fine and stays put.
static func names(camp) -> Array:
	var out: Array = camp.bestiary.keys()
	out.sort()
	return out


## The page for one monster: [heading, line, line...].
static func page(camp, key: String) -> PackedStringArray:
	var e: Dictionary = camp.bestiary.get(key, {})
	var lines := PackedStringArray()
	if e.is_empty():
		return lines
	var f: Dictionary = e["facts"]
	lines.append("Met %d %s · killed %d · as deep as floor %d" % [e["met"], "time" if int(e["met"]) == 1 else "times", e["killed"], e["deepest"]])
	if str(f.get("brief", "")) != "":
		lines.append(f["brief"])
	var moves := PackedStringArray()
	for move in e["moves"]:
		moves.append(CombatState.INTENT_TEXT.get(int(move), "?"))
	moves.append("?")  # what it hasn't shown yet
	lines.append("Moves seen: " + ", ".join(moves))
	if int(e["killed"]) == 0 and not e.get("studied", false):
		lines.append("Weaknesses: ? (kill one to learn more)")
		return lines
	var weak := PackedStringArray()
	var shrugs := PackedStringArray()
	if int(f.get("armour", 0)) > 0:
		weak.append("blunt weapons (armour %d turns blades)" % f["armour"])
	else:
		weak.append("blades (no armour)")
	if f.get("fears_fire", false):
		weak.append("fire: a thrown torch drives it off")
	else:
		shrugs.append("fire and thrown torches")
	if f.get("slow", false):
		weak.append("it's slow: outpace it on the map")
	if f.get("back", false):
		lines.append("Keeps to the back row: a long weapon or a thrown one reaches it.")
	lines.append("Weak to: " + ", ".join(weak))
	if not shrugs.is_empty():
		lines.append("Not troubled by: " + ", ".join(shrugs))
	if f.get("reach_back", false):
		lines.append("Reaches your back row.")
	if f.get("venom", false):
		lines.append("Its bite is venomous.")
	return lines
