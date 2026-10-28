extends RefCounted
## The first story slice's rules (docs/first-slice-plan.md): who has
## something to say at camp, and what follows a conversation. Quest state
## lives in quests.gd; conversation text in data/conversations/*.tres.
## Static helpers only (no static variables: see #100).

const Quests := preload("res://scripts/quests.gd")
const DIR := "res://data/conversations/"
const CAMP_BLADE := "res://data/gear/camp_forged_blade.tres"


## The conversation waiting at a camp site, by ID, or "".
static func camp_talk(camp, site: String) -> String:
	var S := Quests.Stage
	match site:
		"cave":  # the commander keeps his post by the cave path
			if Quests.is_active(camp, "left_behind"):
				return "commander_report" if Quests.has_flag(camp, "left_behind", "found") else "commander_waiting"
			if Quests.has_flag(camp, "lower_gate", "seen") and Quests.stage(camp, "dry_passage") == S.UNKNOWN:
				return "commander_galleries"  # slice 2
			if Quests.has_flag(camp, "reservoir", "diverted") and not Quests.has_flag(camp, "reservoir", "reported"):
				return "commander_reservoir"  # slice 2's ending
		"smith":
			if not camp.site_present("smith"):
				return ""
			if Quests.stage(camp, "iron_sample") in [S.UNKNOWN, S.OFFERED]:
				return "smith_offer"
			if Quests.is_active(camp, "iron_sample") and Quests.has_flag(camp, "iron_sample", "have_ore"):
				return "smith_deliver"
			if Quests.has_flag(camp, "lower_gate", "seen") and Quests.stage(camp, "the_arrow") == S.UNKNOWN:
				return "smith_arrow"  # slice 2
		"fire":
			if Quests.has_flag(camp, "three_knocks", "miner_at_camp") and not Quests.has_flag(camp, "three_knocks", "thanked"):
				return "miner_thanks"
			if Quests.has_flag(camp, "keeper", "helped") and not Quests.has_flag(camp, "keeper", "talked"):
				return "fire_keeper"  # slice 2: the party argues over her
	return ""


static func conversation(id: String) -> Conversation:
	var path := DIR + id + ".tres"
	return load(path) if id != "" and ResourceLoader.exists(path) else null


## What a finished conversation changes beyond its replies' quest steps.
static func after_talk(camp, id: String) -> void:
	var S := Quests.Stage
	match id:
		"commander_report":
			Quests.set_stage(camp, "left_behind", S.RESOLVED)
			Quests.set_stage(camp, "lower_gate", S.ACTIVE)
			Quests.set_stage(camp, "queen_claim", S.ACTIVE)
		"smith_deliver":
			Quests.set_stage(camp, "iron_sample", S.RESOLVED)
			if CAMP_BLADE not in camp.smith_unlocks:
				camp.smith_unlocks.append(CAMP_BLADE)
		"commander_galleries":
			Quests.set_stage(camp, "dry_passage", S.ACTIVE)
		"commander_reservoir":
			Quests.set_flag(camp, "reservoir", "reported")
			Quests.set_stage(camp, "reservoir", S.RESOLVED)
		"smith_arrow":
			Quests.set_stage(camp, "the_arrow", S.ACTIVE)
		"fire_keeper":
			Quests.set_flag(camp, "keeper", "talked")
			Quests.set_stage(camp, "the_arrow", S.RESOLVED)
		"miner_thanks":
			Quests.set_flag(camp, "three_knocks", "thanked")
			Quests.set_stage(camp, "three_knocks", S.RESOLVED)
			Quests.set_flag(camp, "iron_sample", "seam_told")
	camp.changed.emit()


## A camp return: news that arrives after an expedition (the miner's crew).
static func on_return(camp) -> void:
	if Quests.has_flag(camp, "three_knocks", "crew_sent") and not Quests.has_flag(camp, "three_knocks", "miner_at_camp"):
		Quests.set_flag(camp, "three_knocks", "miner_at_camp")
