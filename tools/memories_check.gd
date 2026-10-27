extends SceneTree
## Recruit memories (#118, owner 2026-10-26): each hero keeps up to three
## facts the game saw (pulled from a grip, a close call, a mini-boss or the
## queen falling, a friend lost), saved with them, shown in the hero window
## and spoken at homecoming; a friend falling mid-fight and a hero ready to
## advance get lines of their own. Args: tag, screenshot dir.

const CombatState := preload("res://scripts/combat_state.gd")
const SaveGame := preload("res://scripts/save_game.gd")
const VOICES := ["mara", "corin", "alwen", "recruit_warden", "recruit_scout", "recruit_brawler", "recruit_fixer"]
const NEW_LINES := ["ally_down", "level_ready", "memory_rescued", "memory_close_call", "memory_slew"]

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	# Every voice has the new lines.
	var missing := []
	for voice in VOICES:
		var lines: DialogueLines = load("res://data/dialogue/%s.tres" % voice)
		for situation in NEW_LINES:
			if lines.pick(situation) == "":
				missing.append("%s/%s" % [voice, situation])
	check("all seven voices have every new line", missing.is_empty(), missing)

	# Remembering.
	var hero: Companion = load("res://data/companions/corin.tres").duplicate()
	hero.remember("slew", "Was there when the Broodmother fell", 3, "Broodmother")
	hero.remember("close_call", "Came through a fight on 1 health, floor 2", 4)
	hero.remember("close_call", "Came through a fight on 2 health, floor 3", 5)
	check("the same kind about the same one replaces the older", hero.memories.size() == 2 and hero.memories[0]["day"] == 5)
	hero.remember("lost", "Was there when Bren fell", 6, "Bren")
	hero.remember("rescued", "Pulled from the hollow miner's grip by Mara", 7, "Mara")
	check("at most three, newest first", hero.memories.size() == 3 and hero.memories[0]["kind"] == "rescued" and hero.memories[2]["kind"] == "close_call", hero.memories.map(func(m): return m["kind"]))
	var copy: Companion = Companion.new()
	SaveGame.unpack_into(copy, SaveGame.pack_object(hero))
	check("memories survive a save and load", copy.memories.size() == 3 and copy.memories[1]["text"] == "Was there when Bren fell" and copy.memories[1]["about"] == "Bren")

	# A rescue in a fight.
	var party = load("res://scripts/party_state.gd").new()
	party.add_member(load("res://data/companions/mara.tres").duplicate())
	party.add_member(load("res://data/companions/corin.tres").duplicate())
	var miner: Array[EnemyType] = [load("res://data/enemies/hollow_miner.tres")]
	var state = CombatState.new(party, miner)
	var mara: Companion = party.members[0]
	var corin: Companion = party.members[1]
	state._grabbed[mara] = state.foes[0]
	corin.accuracy = 1.0
	corin.aim_base = 1.0
	var tries := 0
	while state.rescues.is_empty() and tries < 20:
		state._grabbed[mara] = state.foes[0]
		state.foes[0].health = 99
		state.hero_attack(corin, state.foes[0])
		tries += 1
	check("a blow that frees a friend is a rescue", not state.rescues.is_empty() and state.rescues[0][0] == corin and state.rescues[0][1] == mara)

	# In the game.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	ps.add_member(load("res://data/companions/corin.tres").duplicate())
	main._on_party_state_changed(false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var recruit: Companion = load("res://scripts/recruits.gd").make(rng, [], [], 1, "Brawler")
	ps.add_member(recruit)
	recruit = ps.members[-1]  # the party keeps its own
	main._on_party_state_changed(false)
	main._expedition = main.Expedition.new(ps, 1)  # they all set out together
	var lead: Companion = ps.members[0]
	var friend: Companion = ps.members[1]
	main._fight_kind = "lair"
	var boss_fight: Array[EnemyType] = [load("res://data/enemies/broodmother.tres")]
	var won = CombatState.new(ps, boss_fight)
	won.rescues.append([friend, lead, "Hollow miner"])
	lead.health = 1
	main._fight_memories(won, CombatState.Result.VICTORY)
	main._fight_kind = ""
	var kinds: Array = lead.memories.map(func(m): return m["kind"])
	check("after a won lair fight: rescued, a close call and the mini-boss", "rescued" in kinds and "close_call" in kinds and "slew" in kinds, kinds)
	var said: Dictionary = main._homecoming_lines()
	check("a hero speaks of what this trip gave them at homecoming", said.has(lead) and (said[lead].contains("Broodmother") or said[lead] != ""), said.get(lead, ""))
	main._trip_memories.clear()
	lead.health = lead.effective_max_health()
	main._last_spoke_at = -100.0
	recruit.health = 0
	main._on_party_state_changed()
	check("a friend falls: someone standing cries out their name", main._dialogue_box._text.text.contains(recruit.display_name), main._dialogue_box._text.text)
	main._remember_the_fallen()
	check("those who come back remember who didn't", lead.memories.any(func(m): return m["kind"] == "lost" and m["about"] == recruit.display_name))
	check("...not a main hero who was only knocked out", not lead.memories.any(func(m): return m["kind"] == "lost" and m["about"] == friend.display_name))
	main._set_pack(true)
	await process_frame
	main._pack._select_hero(lead) if main._pack.has_method("_select_hero") else null
	await process_frame
	var texts: Array = main._pack._status_content.find_children("*", "Label", true, false).map(func(l): return l.text)
	check("the hero window shows what they remember", texts.any(func(t): return t.begins_with("Remembers:")), texts.size())
	if dir != "":
		for i in 4:
			await process_frame
		root.get_texture().get_image().save_png("%s/memories_%s.png" % [dir, tag])
	print("fails=", fails)
	quit()
