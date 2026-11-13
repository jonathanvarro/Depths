extends CenterContainer
## Shows a room event (#16): its clue, its choices and "Leave it". Each
## choice spends time and shows what happened; investigations add to the
## clue and keep the event open. Emits `finished` when the player is done.
const UiTheme := preload("res://scripts/ui_theme.gd")

## {"left": bool, "ambush": Array[EnemyType]}
signal finished(result: Dictionary)

const Sounds := preload("res://scripts/sounds.gd")
const COLOR_TEXT := Color("e6dac1")
const COLOR_DIM_TEXT := Color(0.85, 0.8, 0.7, 0.85)

var _rules  # room_events.gd
var _party  # party_state.gd
var _flags: Array = []  # this room's preparation so far (#114)
var _event: RoomEvent
var _title: Label
var _body: Label
var _chips: HFlowContainer  # what changed, as icons and numbers (#105)
var _buttons: VBoxContainer
var _used := {}  # investigations already tried
## Finds that didn't fit in the pack (#133, #136): handed on with the result
## so main.gd can offer them beside the pack.
var _no_room := {}


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = UiTheme.overlay_colour(0.94)
	style.border_color = UiTheme.EDGE
	style.set_border_width_all(1)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	_title = _label(26, COLOR_TEXT)
	_title.theme_type_variation = "PageTitle"  # Cinzel heading (#51)
	column.add_child(_title)
	_body = _label(19, COLOR_DIM_TEXT)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(520, 0)
	column.add_child(_body)
	_chips = HFlowContainer.new()
	_chips.add_theme_constant_override("h_separation", 10)
	_chips.add_theme_constant_override("v_separation", 6)
	column.add_child(_chips)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 8)
	column.add_child(_buttons)
	visible = false


## The coin flip overlay (coin_flip.gd), set by main.gd (#77).
var coin: Control


## `flags`: the room's remembered preparation (main.gd keeps it per cell).
## A sprung trap's own sound (#217); a hollow floor drops, others stumble.
func _trap_sound() -> String:
	var id := _event.resource_path.get_file().get_basename()
	var own: String = {"trap_dart": "trap_dart", "trap_snare": "trap_snare", "trap_bell_wire": "trap_alarm_bell", "trap_tripwire": "trap_tripwire"}.get(id, "")
	if own != "":
		return own
	return "fall" if _event.prop and _event.prop.resource_path.contains("hollow-floor") else "stumble"


func show_event(event: RoomEvent, party_state, rules, flags: Array = []) -> void:
	_flags = flags
	_event = event
	_party = party_state
	_rules = rules
	_used.clear()
	_no_room = {}
	_title.text = event.title
	_body.text = event.clue
	_clear_chips()
	_show_choices()
	visible = true


func _show_choices() -> void:
	_clear_buttons()
	for choice in _event.choices:
		if _used.has(choice):
			continue
		var label := choice.label
		if choice.time_cost > 0 and not label.contains("time"):
			label += "  (%d time)" % choice.time_cost
		var missing: String = choice.missing(_party)
		if missing != "":
			label = "%s  (%s)" % [choice.label, missing]
		_add_button(label, _choose.bind(choice)).disabled = missing != ""
	_add_button("Leave it", func(): _finish({"left": true, "ambush": [] as Array[EnemyType]}))


func _choose(choice: EventChoice) -> void:
	var forced := -1
	if choice.coin_flip and coin:
		# No turning it down once chosen (#77); luck bends the odds.
		_clear_buttons()
		var luck: Array = _party.luck()
		var chance: float = minf(0.5 + luck[0], 0.85)
		var note: String = "%s's luck" % luck[1] if luck[1] != "" else ""
		visible = false  # the coin has the screen to itself
		var heads: bool = await coin.flip(_event.title, choice.heads_text, choice.tails_text, chance, note)
		visible = true
		forced = 0 if heads else 1
	var was_drained: bool = _rules.drained
	var was_alarmed: bool = _rules.alarm_raised
	var result: Dictionary = _rules.resolve(_party, choice, forced, _flags)
	if _rules.drained and not was_drained:
		Sounds.play(self, "sluice", -5.0, 0.0)
	for item in result.get("no_room", {}):
		_no_room[item] = _no_room.get(item, 0) + result["no_room"][item]
	if choice.investigation and result["ambush"].is_empty():
		_used[choice] = true
		_body.text += "\n\n" + result["story"]
		_add_chips(result["changes"])
		_show_choices()
		return
	_body.text = result["story"]
	if _event.kind == 2:  # DungeonMap.Content.CHEST: the lid comes up (#54)
		Sounds.play(self, "chest")
	elif _event.kind == 3 and (result["changes"].any(func(change): return not change["good"]) or (_rules.alarm_raised and not was_alarmed)):
		Sounds.play(self, _trap_sound(), -6.0)
	_clear_chips()
	_add_chips(result["changes"])
	_clear_buttons()
	var fired: bool = _event.kind == 3 and (result["changes"].any(func(change): return not change["good"]) or (_rules.alarm_raised and not was_alarmed))
	var picked: int = _event.choices.find(choice)
	_add_button("Continue", func(): _finish({"left": false, "ambush": result["ambush"], "choice": picked, "fired": fired}))


func _finish(result: Dictionary) -> void:
	visible = false
	result["no_room"] = _no_room.duplicate()
	finished.emit(result)


func _clear_chips() -> void:
	for child in _chips.get_children():
		_chips.remove_child(child)
		child.queue_free()


## One chip per change: an icon and its number, green for good, red for bad.
func _add_chips(changes: Array) -> void:
	for change in changes:
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", UiTheme.chip(change["good"]))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		chip.add_child(row)
		if change["icon"]:
			var icon := TextureRect.new()
			icon.texture = change["icon"]
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.custom_minimum_size = Vector2(32, 32)
			row.add_child(icon)
		if change["text"] != "":
			var label := _label(22, Color("bfe3a8") if change["good"] else Color("f0a090"))
			label.text = change["text"]
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.size_flags_vertical = Control.SIZE_FILL
			row.add_child(label)
		_chips.add_child(chip)


func _clear_buttons() -> void:
	for child in _buttons.get_children():
		child.queue_free()


func _add_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 52)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(func(): Sounds.play(self, "ui", -12.0, 0.0))
	button.pressed.connect(action)
	_buttons.add_child(button)
	return button


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
