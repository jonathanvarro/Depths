extends SceneTree
## Writes the first slice's conversations (docs/first-slice-plan.md) as
## data/conversations/*.tres. Edit the text here or in the .tres files;
## rerun to rebuild:  Godot --headless --path . --script tools/story/build_conversations.gd

const Quests := preload("res://scripts/quests.gd")
## Placeholder until ChatGPT's commander portrait lands.
const COMMANDER_PORTRAIT := "res://art/portraits/recruit-silhouettes-v1/warden.png"


func _reply(label: String, next := -1, quest := "", stage := -1, flag := "") -> ConversationReply:
	var r := ConversationReply.new()
	r.label = label
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
	talk.portrait = load(portrait) if portrait != "" else null
	talk.pages.assign(pages)
	var path := "res://data/conversations/%s.tres" % name
	var error := ResourceSaver.save(talk, path)
	print(path, " ", "ok" if error == OK else "FAILED %d" % error)


func _initialize() -> void:
	var A := Quests.Stage.ACTIVE
	# After the escape: the king's forces are waiting at the cave mouth.
	_save("commander_first", "Commander Edric Vael", COMMANDER_PORTRAIT, [
		_page("Soldiers in the king's colours stand at the cave mouth. Their commander steps forward: grey at the temples, armour scrubbed clean, eyes that miss nothing.\n\n\"Edric Vael, commander of this expedition. You went down with the survey party. Tell me - did you find it?\"", [
			_reply("\"We were ambushed.\"", 1, "story", -1, "told_ambush"),
			_reply("\"Not yet.\"", 2, "story", -1, "told_not_yet"),
			_reply("\"Find what? They never told me.\"", 3, "story", -1, "asked_what"),
		]),
		_page("\"Ambushed.\" He weighs the word. \"Rats bite. Spiders wait. Goblins raid - but an ambush means someone knew where you'd be.\" He glances at his officers, then back to you. \"Then I want to know who.\"", [
			_reply("Go on", 4)]),
		_page("\"Not yet.\" Something tightens at the corner of his mouth. \"Then the king's patience is the only thing in this valley that isn't running out.\"", [
			_reply("Go on", 4)]),
		_page("\"They didn't tell you.\" A pause - not surprise, exactly. \"Good. Fewer tongues. You'll learn what you need when you need it, {hero}.\"", [
			_reply("Go on", 4)]),
		_page("\"Your party is still down there. Rest at the camp tonight. Then go back to the first floor, find where they fell, and bring me whatever they carried - every map, every scrap. Their families will want to know. So will I.\"", [
			_reply("\"I'll find them.\"", -1, "left_behind", A),
		]),
	])
	quit()
