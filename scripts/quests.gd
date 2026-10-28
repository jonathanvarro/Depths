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
	"three_knocks": {"title": "Three Knocks", "giver": "", "floor": 2, "hidden": true},
	"iron_sample": {"title": "Iron for the Apprentice", "giver": "the smith", "floor": 1, "hidden": false},
	"lower_gate": {"title": "The Way Down", "giver": "Commander Vael", "floor": 4, "hidden": false},
	"queen_claim": {"title": "The Queen's Claim", "giver": "Commander Vael", "floor": 4, "hidden": false},
	# Slice 2, the Drowned Galleries (docs/story-slice-2-plan.md).
	"dry_passage": {"title": "The Dry Passage", "giver": "Commander Vael", "floor": 5, "hidden": false},
	"the_arrow": {"title": "The Black Fletching", "giver": "the smith", "floor": 5, "hidden": false},
	"keeper": {"title": "The Wounded Keeper", "giver": "", "floor": 5, "hidden": true},
	"reservoir": {"title": "The Black Reservoir", "giver": "Commander Vael", "floor": 6, "hidden": false},
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
## A very short brief for the mine path's reminder card (owner, 2026-10-25).
static func brief(camp, id: String) -> String:
	match id:
		"left_behind":
			return "Report back to camp." if has_flag(camp, id, "found") else "Find where your party fell."
		"three_knocks":
			return "Free the trapped miner."
		"iron_sample":
			return "Give the smith the ore." if has_flag(camp, id, "have_ore") else "Bring back iron ore."
		"lower_gate":
			return "Find the way down."
		"queen_claim":
			return "Optional: the goblin queen."
		"dry_passage":
			return "Open the main sluice."
		"the_arrow":
			return "Ask who fletches in black." if has_flag(camp, "keeper", "helped") else "Find who fletches in black."
		"keeper":
			return "Help the wounded elf."
		"reservoir":
			return "Report to the commander." if has_flag(camp, id, "diverted") else "Divert the reservoir's flow."
	return ""


## Who gave it, as a picture to show in silhouette ("" if no one).
const GIVER_ART := {
	"Commander Vael": "res://art/portraits/story-slice-v1/commander-edric.png",
	"the smith": "res://art/camp/highres-v4/smith.png",
}


## The quest the mine path should remind the party of: the first open one
## that isn't optional or hidden, else the first open one at all; "" if none.
static func current(camp) -> String:
	var open: Array = in_log(camp).filter(func(id): return stage(camp, id) != Stage.RESOLVED)
	for id in open:
		if id != "queen_claim" and not INFO[id]["hidden"]:
			return id
	return open[0] if not open.is_empty() else ""


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
			return "Take an iron sample from a seam in the mine."
		"lower_gate":
			return "Find a way past the fortress to the water below, on floor 4."
		"queen_claim":
			return "Optional: the goblin queen holds the fortress hall on floor 4."
		"dry_passage":
			return "Find the main sluice in the Drowned Galleries, floor 5, and open it."
		"the_arrow":
			return "Whoever fletched that arrow came from below. Look for them on floor 5."
		"keeper":
			return "A wounded dark elf waits among the pools on floor 5. Help her, or leave her."
		"reservoir":
			if has_flag(camp, id, "diverted"):
				return "Tell Commander Vael what the reservoir was hiding."
			return "Find the flow gate in the Black Reservoir, floor 6, and divert the water."
	return ""
