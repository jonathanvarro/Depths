extends RefCounted
## Quests (#123, docs/first-slice-plan.md): each has a stage and a few
## flags, kept on the camp (camp_state.quests: id -> {"stage", "flags"}).
## Saved with the campaign and keyed by quest ID, never by floor seed or
## cell, so the cave changing each day doesn't forget them. Static helpers
## only (no static variables: see #100).

enum Stage { UNKNOWN, OFFERED, ACTIVE, RESOLVED }

## Title, who gave it, and floor (for the log). Hidden quests appear in the
## log only once found (stage OFFERED or later).
const INFO := {
	"left_behind": {"title": "Those Left Behind", "giver": "Commander Vael", "floor": 1, "hidden": false},
	"three_knocks": {"title": "Three Knocks", "giver": "", "floor": 1, "hidden": true},
	"iron_sample": {"title": "Iron for the Apprentice", "giver": "the smith", "floor": 1, "hidden": false},
	"lower_gate": {"title": "The Way Down", "giver": "Commander Vael", "floor": 4, "hidden": false},
	"queen_claim": {"title": "The Queen's Claim", "giver": "Commander Vael", "floor": 4, "hidden": false},
}


static func _entry(camp, id: String) -> Dictionary:
	if not camp.quests.has(id):
		camp.quests[id] = {"stage": Stage.UNKNOWN, "flags": []}
	return camp.quests[id]


static func stage(camp, id: String) -> int:
	return camp.quests.get(id, {}).get("stage", Stage.UNKNOWN)


static func set_stage(camp, id: String, to: int) -> void:
	var entry := _entry(camp, id)
	if to > entry["stage"]:  # quests only move forward
		entry["stage"] = to
		camp.changed.emit()


static func has_flag(camp, id: String, flag: String) -> bool:
	return flag in camp.quests.get(id, {}).get("flags", [])


static func set_flag(camp, id: String, flag: String) -> void:
	var entry := _entry(camp, id)
	if flag not in entry["flags"]:
		entry["flags"].append(flag)
		camp.changed.emit()


static func is_active(camp, id: String) -> bool:
	return stage(camp, id) == Stage.ACTIVE


## Quests to show in the log, in INFO order: [id, ...].
static func in_log(camp) -> Array:
	return INFO.keys().filter(func(id): return stage(camp, id) in [Stage.OFFERED, Stage.ACTIVE, Stage.RESOLVED])


## What to do next, in a few words, for the log.
static func next_step(camp, id: String) -> String:
	var s := stage(camp, id)
	if s == Stage.RESOLVED:
		return "Done."
	match id:
		"left_behind":
			if has_flag(camp, id, "found"):
				return "Report to Commander Vael at camp."
			return "Find where your party fell, on floor 1."
		"three_knocks":
			if has_flag(camp, id, "crew_sent"):
				return "A camp crew will bring the miner back after your next return."
			return "Someone is tapping behind the rubble. Get them out, or mark it for a crew."
		"iron_sample":
			if has_flag(camp, id, "have_ore"):
				return "Bring the iron ore to the smith."
			return "Take an iron sample from a seam in the cave."
		"lower_gate":
			return "Find a way past the fortress to the water below, on floor 4."
		"queen_claim":
			return "Optional: the goblin queen holds the fortress hall on floor 4."
	return ""
