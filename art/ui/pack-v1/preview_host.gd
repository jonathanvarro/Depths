extends Control
## Isolated design preview. Never binds the live expedition's party or saves.
const View := preload("res://art/ui/pack-v1/pack_view.gd")
const PartyState := preload("res://scripts/party_state.gd")
var phone := false
var party
var pack
var reopen: Button

func _ready() -> void:
	var backdrop := TextureRect.new()
	backdrop.texture = preload("res://art/title/title-v1/background.png")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	party = PartyState.new()
	party.add_member(load("res://data/companions/mara.tres"))
	var hero: Companion = party.members[0]
	hero.add_injury(load("res://data/injuries/deep_wound.tres"))
	hero.health = 9
	party.time_elapsed = 18
	party.supplies.oil = 62.0
	for row in [["oil_flask",3],["ration",2],["restorative_draught",1],["dressing",2]]:
		party.supplies.add(load("res://data/items/"+row[0]+".tres"),row[1])
	reopen = Button.new()
	reopen.text = "Open Pack"
	reopen.theme = preload("res://art/ui/field-kit-v1/style.gd").make_theme()
	reopen.position = Vector2(100,80)
	reopen.custom_minimum_size = Vector2(200,72)
	reopen.visible = false
	add_child(reopen)
	pack = View.new()
	add_child(pack)
	pack.setup(party,phone)
	pack.closed.connect(func():
		pack.hide()
		reopen.show()
		reopen.grab_focus())
	reopen.pressed.connect(func():
		reopen.hide()
		pack.show()
		pack.back_button.grab_focus())
