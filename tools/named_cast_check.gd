extends SceneTree
## The named cast and bringing back the dead (#180/#201, owner 2026-11-17):
## Branna, Rook, Nessa and Maelin come to the fire at their story points and
## wait there; a companion who falls while the others get home is carried
## out, and the nurse can bring them back for gold and a lasting scar.
## Args: tag, screenshot dir.

const NamedCast := preload("res://scripts/named_cast.gd")
const Quests := preload("res://scripts/quests.gd")
const Story := preload("res://scripts/story.gd")
const CampState := preload("res://scripts/camp_state.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _names(camp) -> Array:
	return camp.candidates.map(func(c): return c.display_name)


func _initialize() -> void:
	var camp = CampState.new()
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres"))
	camp.start(7, party)
	camp.begin_arrivals()
	check("no one named by the fire at the start", not _names(camp).any(func(n): return n in ["Branna", "Rook", "Nessa", "Maelin"]))
	Quests.set_stage(camp, "left_behind", Quests.Stage.ACTIVE)
	Quests.set_flag(camp, "left_behind", "found")
	Story.after_talk(camp, "commander_report")
	check("the report brings Branna to the fire", "Branna" in _names(camp))
	var branna: Companion = camp.candidates.filter(func(c): return c.display_name == "Branna")[0]
	check("...a Melee with her own face and introduction", branna.role == "Melee" and branna.named_id == "branna" and branna.portrait != null and branna.personality.contains("rescue"))
	Story.after_talk(camp, "merchant_arrival")
	check("meeting the merchant brings Rook, on the Fixer face", "Rook" in _names(camp) and camp.candidates.filter(func(c): return c.display_name == "Rook")[0].portrait_set != null)
	camp.record_depth(2)
	check("a first floor-2 return brings Nessa", "Nessa" in _names(camp))
	Quests.set_flag(camp, "healing_moss", "have_moss")
	Story.on_return(camp)
	check("the bitter moss brings Maelin (and the nurse)", "Maelin" in _names(camp) and camp.site_present("treatment"))
	var count: int = _names(camp).filter(func(n): return n == "Branna").size()
	Story.on_return(camp)
	check("each comes once", _names(camp).filter(func(n): return n == "Branna").size() == count)
	for i in 6:
		camp.rest(party)
	check("the named cast wait by the fire while others come and go", ["Branna", "Rook", "Nessa", "Maelin"].all(func(n): return n in _names(camp)), _names(camp))

	# Bringing back the dead.
	check("Branna joins", camp.hire(party, branna))
	var hired: Companion = party.members.filter(func(h): return h.display_name == "Branna")[0]
	hired.health = 0
	camp.carry_home(hired)
	party.remove_member(hired)
	check("her body is carried home", hired in camp.fallen)
	party.supplies.gold = 10
	check("the nurse can't without the gold", not camp.revive(party, hired))
	party.supplies.gold = 100
	var before: int = hired.max_health
	check("with it, she brings Branna back", camp.revive(party, hired) and hired not in camp.fallen and hired in camp.candidates)
	check("...scarred for good, but on her feet", hired.max_health == before - CampState.REVIVE_SCAR and hired.health == hired.effective_max_health() and hired.health > 0 and party.supplies.gold == 100 - CampState.REVIVE_PRICE)

	# Saves keep the fallen and who's named.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	root.add_child(main)
	await create_timer(0.5).timeout
	var ghost: Companion = NamedCast.make(main._camp_state, "nessa")
	main._camp_state.fallen.append(ghost)
	var data: Dictionary = main._save_data()
	main._camp_state.fallen.clear()
	main._restore(data)
	check("a save keeps the body at camp, and who it was", main._camp_state.fallen.size() == 1 and main._camp_state.fallen[0].named_id == "nessa" and main._camp_state.fallen[0].display_name == "Nessa")
	print("fails=", fails)
	quit()
