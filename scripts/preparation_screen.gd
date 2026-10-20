extends Control
## Preparation before heading back into the cave (#18): who's going, how
## they are, the lantern and the pack. The very first expedition skips it —
## Mara wakes alone in the deep with nothing to prepare (#8, #30).
## Buying, recruiting and the stash come with the campsite (#22, #26).

signal entered

const PartyCard := preload("res://scripts/party_card.gd")
const Supplies := preload("res://scripts/supplies.gd")
const StrainRules := preload("res://scripts/strain.gd")
const HEADING := preload("res://art/fonts/heading-cinzel.tres")
const ACTION := preload("res://art/fonts/action-source-sans.tres")
const BODY := preload("res://art/fonts/body-source-sans.tres")
const TEXT := Color("e6dac1")
const MUTED := Color("b3a78f")
const AMBER := Color("dbb477")

var content: MarginContainer  # main.gd keeps this inside the safe area

var _title: Label
var _cards: HBoxContainer
var _supplies: VBoxContainer
var _enter: Button


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.035, 0.03, 1.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 32)
	add_child(content)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	content.add_child(column)
	_title = _label("", HEADING, 32, TEXT)
	column.add_child(_title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	var party_column := VBoxContainer.new()
	party_column.add_theme_constant_override("separation", 10)
	row.add_child(party_column)
	party_column.add_child(_label("Party", HEADING, 24, TEXT))
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 8)
	party_column.add_child(_cards)
	var pack_column := VBoxContainer.new()
	pack_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_column.add_theme_constant_override("separation", 6)
	row.add_child(pack_column)
	pack_column.add_child(_label("Pack", HEADING, 24, TEXT))
	var inventory_scroll := ScrollContainer.new()
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pack_column.add_child(inventory_scroll)
	_supplies = VBoxContainer.new()
	_supplies.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_supplies.add_theme_constant_override("separation", 4)
	inventory_scroll.add_child(_supplies)

	_enter = Button.new()
	_enter.text = "Enter the cave"
	_enter.custom_minimum_size = Vector2(280, 64)
	_enter.size_flags_horizontal = Control.SIZE_SHRINK_END
	_enter.add_theme_font_override("font", ACTION)
	_enter.add_theme_font_size_override("font_size", 24)
	_enter.add_theme_color_override("font_color", AMBER)
	_enter.pressed.connect(func():
		visible = false
		entered.emit())
	column.add_child(_enter)
	visible = false


func show_for(expedition_number: int, party) -> void:
	_title.text = "Expedition %d" % expedition_number
	for child in _cards.get_children():
		child.queue_free()
	for i in party.MAX_MEMBERS:
		var hero_column := VBoxContainer.new()
		hero_column.add_theme_constant_override("separation", 6)
		_cards.add_child(hero_column)
		var card := PartyCard.new()
		hero_column.add_child(card)
		if i < party.members.size():
			var hero: Companion = party.members[i]
			card.show_companion(hero)
			# The portrait already shows identity, health, strain and condition icons.
			# Only lasting injury care needs a separate preparation note.
			if not hero.hindering_injuries().is_empty():
				var care := _label("Needs the nurse", BODY, 17, AMBER)
				care.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				care.custom_minimum_size = Vector2(100, 0)
				hero_column.add_child(care)
		else:
			card.show_empty()

	for child in _supplies.get_children():
		child.queue_free()
	var supplies = party.supplies
	_supplies.add_child(_label(_light_line(supplies), ACTION, 20, TEXT))
	for item: SupplyItem in supplies.items:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		if item.icon:
			var icon := TextureRect.new()
			icon.texture = item.icon
			icon.custom_minimum_size = Vector2(32, 32)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			line.add_child(icon)
		line.add_child(_label("%s ×%d" % [item.display_name, supplies.count(item)], BODY, 20, TEXT if supplies.count(item) > 0 else MUTED))
		_supplies.add_child(line)
	visible = true
	_enter.grab_focus()


## What lights the way: the lantern if the party has one, else torches.
func _light_line(supplies) -> String:
	if supplies.has_lantern:
		return "Lantern: %d/%d oil (%s)" % [roundi(supplies.oil), int(Supplies.LANTERN_CAPACITY), Supplies.LIGHT_NAMES[supplies.light_band()].to_lower()]
	if supplies.torch_lit():
		return "Torch: burning, %d time left" % ceili(supplies.torch_left)
	var torch_count := 0
	for item: SupplyItem in supplies.items:
		if item.effect == SupplyItem.Effect.LIGHT_TORCH:
			torch_count += supplies.count(item)
	if torch_count > 0:
		return "Torches: %d (one is lit as you go in)" % torch_count
	return "No light! Get torches from the merchant."


func _label(text: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
