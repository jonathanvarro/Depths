extends SceneTree
## The quartermaster's issue (owner, 2026-11-22): every return tops the pack
## up to a baseline, raised for good by paying gold and mine materials. And
## the bigger mine floors with smaller rooms that make the baseline matter.

const CampState := preload("res://scripts/camp_state.gd")
const PartyState := preload("res://scripts/party_state.gd")
const SaveGame := preload("res://scripts/save_game.gd")
const FloorGenerator := preload("res://scripts/floor_generator.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var torch: SupplyItem = load("res://data/items/torch.tres")
	var ration: SupplyItem = load("res://data/items/ration.tres")
	var coal: SupplyItem = load("res://data/items/coal.tres")
	var camp = CampState.new()
	var party = PartyState.new()
	party.add_member(load("res://data/companions/mara.tres"))
	check("the baseline: three torches, free", camp.top_up_torches(party) == 3 and party.supplies.count(torch) == 3 and party.supplies.count(ration) == 0)
	check("no gold, no better issue", not camp.can_raise_issue(party) and not camp.raise_issue(party))
	party.supplies.gold = 35
	check("30 gold buys the field issue", camp.raise_issue(party) and camp.issue_level == 1 and party.supplies.gold == 5)
	camp.top_up_torches(party)
	check("...and every return now tops up four torches and a ration", party.supplies.count(torch) == 4 and party.supplies.count(ration) == 1, camp.issue_text())
	# No piling issued supplies in the stash for a fresh set each return
	# (owner, 2026-11-23): what's stored counts toward the issue.
	camp.store(party, torch)
	camp.store(party, torch)
	camp.top_up_torches(party)
	check("stored issue torches count: no fresh set to pile up", party.supplies.count(torch) + camp.stash.count(torch) == 4, [party.supplies.count(torch), camp.stash.count(torch)])
	camp.withdraw(party, torch)
	camp.withdraw(party, torch)
	var merchant_sells_supplies: bool = camp.sell(party, torch)
	check("...and the merchant won't buy supplies back", not merchant_sells_supplies and party.supplies.count(torch) == 4)
	party.supplies.gold = 100
	check("the next needs coal from the mine as well", not camp.can_raise_issue(party), camp.next_issue_price())
	party.supplies.add(coal, 1)
	camp.stash.add(coal, 2)
	check("...counted from the pack and the stash", camp.raise_issue(party) and party.supplies.count(coal) == 0 and camp.stash.count(coal) == 0 and party.supplies.gold == 40)
	var packed: Dictionary = SaveGame.pack_object(camp, ["stash", "candidates", "left_behind", "recovering", "rng", "fallen", "lost_bodies", "carried"])
	var again = CampState.new()
	SaveGame.unpack_into(again, packed)
	check("a save keeps the issue", again.issue_level == 2, again.issue_level)

	# The camp offers it at the mine path.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	root.add_child(main)
	await create_timer(0.5).timeout
	main._party_state.supplies.gold = 50
	main._end_expedition(main.Expedition.Ending.RETURNED)
	await process_frame
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout
	main._camp._close_activity()
	main._camp._buttons["cave"].pressed.emit()
	await create_timer(0.2).timeout
	var buttons: Array = main._camp.find_children("*", "Button", true, false).filter(func(b): return b.text.begins_with("Field issue"))
	check("the mine path offers the field issue", buttons.size() == 1, buttons.size())
	# The button works with the gold in the tent, and says so (2026-11-24).
	var camp_state = main._camp_state
	var pack_gold: int = main._party_state.supplies.gold
	camp_state.stash.gold += 40
	main._party_state.supplies.gold = 0
	main._camp._refresh_activity()
	await process_frame
	buttons = main._camp.find_children("*", "Button", true, false).filter(func(b): return b.text.begins_with("Field issue"))
	check("...and gold in the tent's stash pays for it", buttons.size() == 1 and not buttons[0].disabled)
	var level: int = camp_state.issue_level
	buttons[0].pressed.emit()
	await process_frame
	var texts: Array = main._camp.find_children("*", "Label", true, false).map(func(l): return l.text)
	check("pressing it raises the issue and says so", camp_state.issue_level == level + 1 and texts.any(func(t): return t.begins_with("Paid.")), [camp_state.issue_level, camp_state.stash.gold])
	main._party_state.supplies.gold = pack_gold
	check("not enough gold names what's missing", camp_state.issue_shortfall(main._party_state).contains("more"), camp_state.issue_shortfall(main._party_state))

	# Bigger floors, smaller rooms (owner, 2026-11-22).
	var cells := 0
	var biggest := 0
	for s in 100:
		var map = DungeonMap.new(FloorGenerator.generate(s * 31 + 3, true, 1), 1)
		cells += map.walking_distances(map.find_content(DungeonMap.Content.STAIRS_UP)).size()
	check("floor 1 is bigger: about 340 walkable cells (was about 240)", cells / 100 > 300, cells / 100)
	check("rooms are at most 5 across", FloorGenerator.ROOM_MAX <= 5)
	print("fails=", fails)
	quit()
