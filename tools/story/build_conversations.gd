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
	var R := Quests.Stage.RESOLVED
	_save("commander_waiting", "Commander Edric Vael", COMMANDER_PORTRAIT, [
		_page("\"Floor one, {hero}. Where your party fell. Every map, every scrap - and their names, if you can read them.\"")])
	_save("commander_report", "Commander Edric Vael", COMMANDER_PORTRAIT, [
		_page("You set the survey map on his table, and beside it the arrow.

He unrolls the map first. Your party's route is there in the surveyor's neat hand - and over it, someone else's: marks at the very turns where you were caught. He is quiet for a long moment.

\"None of your people drew these.\"", [
			_reply("Show him the arrow", 1)]),
		_page("He turns the arrow in his fingers. Goblin-made shaft. The fletching is black and glossy, cut from no bird you know.

\"Goblins fletch with crow, if they bother at all.\" He lays it down very carefully. \"Say nothing of this at the fire. Not yet.\"", [
			_reply("\"What happens now?\"", 2)]),
		_page("\"Now we go deeper. Below the fortress the old water channels run down to - \" he stops himself. \"To where my orders point. The goblins hold the way. There is a bounty on their queen, if you want it. But I need a way past that fortress, with her or without her.\"", [
			_reply("\"I'll find a way down.\"", -1, "story", -1, "reported")]),
	])
	_save("smith_offer", "The apprentice smith", "res://art/camp/highres-v4/smith.png", [
		_page("The apprentice turns a bent nail over in his fingers. \"Everything they sent me is scrap. If I had real iron - even a fist-sized lump from a good seam - I could make you something better than what you're carrying.\"", [
			_reply("\"I'll bring you iron.\"", -1, "iron_sample", Quests.Stage.ACTIVE),
			_reply("\"Maybe later.\"", -1, "iron_sample", Quests.Stage.OFFERED),
		])])
	_save("smith_deliver", "The apprentice smith", "res://art/camp/highres-v4/smith.png", [
		_page("He weighs the ore in both hands and grins for the first time since he arrived. \"Good iron. Proper iron.\" Two days of hammering later, a blade lies on his anvil, bright and light. \"It's yours to buy - I still have to eat.\"")])
	_save("miner_thanks", "Hask, a miner", "res://art/portraits/recruit-silhouettes-v1/brawler.png", [
		_page("The miner you found behind the rubble is sitting at the fire, a blanket round his shoulders. \"They said it was you who heard me. I'd have died in there.\"

He leans in. \"There's good iron on the first floor - a dark seam with rust-red streaks, where the old workings end. The smith'd want it.\"")])
	quit()
