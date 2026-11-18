extends SceneTree
## Camp services earned through the story (#238, owner 2026-11-17): the
## nurse's quest (healing moss from floor 2), her arrival, and the smith's
## arrival talk. Writes data/conversations, data/events and data/packages.
## Rerun to rebuild:
##   Godot --headless --path . --script tools/story/build_camp_services.gd

const Quests := preload("res://scripts/quests.gd")
const MERCHANT := "res://art/camp/highres-v4/merchant.png"
const NURSE := "res://art/camp/highres-v4/nurse.png"
const SMITH := "res://art/camp/highres-v4/apprentice.png"


func _reply(label: String, next := -1, quest := "", stage := -1, flag := "", said_by := {}, accepts := "") -> ConversationReply:
	var r := ConversationReply.new()
	r.label = label
	r.said_by = said_by
	r.accepts = accepts
	r.next = next
	r.quest = quest
	r.stage = stage
	r.flag = flag
	return r


func _page(text: String, replies: Array = []) -> ConversationPage:
	var p := ConversationPage.new()
	p.text = text
	p.replies.assign(replies)
	return p


func _save(name: String, speaker: String, portrait: String, pages: Array) -> void:
	var talk := Conversation.new()
	talk.speaker = speaker
	talk.portrait = load(portrait)
	talk.pages.assign(pages)
	var path := "res://data/conversations/%s.tres" % name
	print(path, " ", "ok" if ResourceSaver.save(talk, path) == OK else "FAILED")


func _initialize() -> void:
	var A := Quests.Stage.ACTIVE
	var O := Quests.Stage.OFFERED
	_save("merchant_nurse", "The merchant", MERCHANT, [
		_page("The merchant watches your party limp past his stall. \"You need a proper nurse up here, not my bandages. I know one - she'll come with my next wagon. But she won't set foot in a camp without bitter moss for her salves, and I can't get it.\"", [
			_reply("Where does it grow?", 1, "", -1, "", {
				"Mara": "\"Bitter moss. Where does it grow?\"",
				"Corin": "\"A nurse would be worth a walk. Where does it grow?\"",
				"Sister Alwen": "\"I know the stuff. Where does it grow down here?\""})]),
		_page("\"In the damp caverns, the second floor down - pale stuff on the wet rock, smells like old pennies. Bring me a good handful and I'll send word to her.\"", [
			_reply("I'll find it", -1, "healing_moss", A, "", {
				"Mara": "\"I'll find it.\"",
				"Corin": "\"I'll bring you a handful. Send for her.\"",
				"Sister Alwen": "\"I'll gather it myself. She'll be needed.\""}, "healing_moss"),
			_reply("Not now", -1, "healing_moss", O, "", {
				"Mara": "\"Not now.\"",
				"Corin": "\"Later. We've other business down there.\"",
				"Sister Alwen": "\"Not yet. Ask me again.\""}),
		])])
	_save("nurse_arrival", "The nurse", NURSE, [
		_page("A woman in a patched apron is unpacking jars beside the far tent, sorting the bitter moss into neat bundles. \"You're the ones who brought this? Good. It's fresh.\"", [
			_reply("Go on", 1)]),
		_page("\"I can dress what the mine does to you - the deep cuts, the bad legs. Some of it takes days to mend, and you'll go down without them while it does. Bring me your wounded.\"")])
	_save("smith_arrival", "The apprentice smith", SMITH, [
		_page("A thin young man is hammering a bent rail flat on a borrowed anvil. \"The quartermaster sent me with the last wagon. Apprentice smith. I've knives, clubs, a spear or two - plain things.\" He looks at your gear. \"Bring me something worth working, and I'll do better.\"")])

	# The moss: a patch on the wet rock of floor 2.
	var moss := RoomEvent.new()
	moss.title = "Bitter moss"
	moss.clue = "Pale moss carpets the wet rock here, thick as a fleece. It smells sharp, like old coins."
	moss.kind = 4
	moss.min_depth = 99  # only ever placed by its package
	moss.max_depth = 99
	var gather := EventChoice.new()
	gather.label = "Gather a good handful"
	gather.time_cost = 2
	var got := EventOutcome.new()
	got.text = "You scrape a dripping handful into a cloth and wrap it tight. The merchant will send for his nurse."
	got.quest = "healing_moss"
	got.quest_flag = "have_moss"
	gather.outcomes.assign([got])
	moss.choices.assign([gather])
	moss.prop = load("res://art/dressing/cave-growth-3d-v1/mushroom-clump.tscn")
	var path := "res://data/events/quest_healing_moss.tres"
	print(path, " ", "ok" if ResourceSaver.save(moss, path) == OK else "FAILED")
	var p := QuestPackage.new()
	p.id = "healing_moss"
	p.min_depth = 2
	p.max_depth = 2
	p.quest = "healing_moss"
	p.stages.assign([A])
	p.unless_flags = PackedStringArray(["have_moss"])
	p.rows = PackedStringArray(["#####", "#,1,#", "#,,,#", "##.##"])
	p.events.assign([load(path)])
	var pack_path := "res://data/packages/healing_moss.tres"
	print(pack_path, " ", "ok" if ResourceSaver.save(p, pack_path) == OK else "FAILED")
	quit()
