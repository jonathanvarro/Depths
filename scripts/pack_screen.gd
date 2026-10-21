extends Control
## Backpack screen (#10): lantern oil, time spent, and supplies with Use
## buttons. Supplies live here rather than on the HUD, to keep the view
## quiet. Opening and browsing spend nothing; using an item spends its time.

signal closed
## Save the game and go back to the title (#45).
signal save_and_exit
signal open_settings
signal open_quests  # the quest log (#123)
## An item was used; `message` describes what happened.
signal used(message: String)

const Supplies := preload("res://scripts/supplies.gd")
const StrainRules := preload("res://scripts/strain.gd")
const Trinkets := preload("res://scripts/trinkets.gd")
const Quality := preload("res://scripts/quality.gd")
const COLOR_TEXT := Color("e8d9b0")
const COLOR_DIM_TEXT := Color(0.85, 0.8, 0.7, 0.65)
const COLOR_OIL := Color("e8a84a")
const LANTERN_ICON := preload("res://art/items/refined-v2/lantern.png")
const UNLIT_LANTERN_ICON := preload("res://art/items/refined-v2/lantern-unlit.png")
const TORCH_ICON := preload("res://art/items/refined-v2/torch.png")
const COIN_ICON := preload("res://art/symbols/crest-v1/currency-coin.svg")
const SETTINGS_ICON := preload("res://art/ui/controls-v1/settings.svg")
const CLOSE_ICON := preload("res://art/ui/controls-v1/close.svg")
const JOURNAL_ICON := preload("res://art/ui/controls-v1/journal.svg")

var content: MarginContainer  # main.gd keeps this inside the safe area

var _party  # party_state.gd
var _time_label: Label
var _lantern_bar: ProgressBar
var _lantern_label: Label
var _light_title: Label
var _light_note: Label
var _light_icon: TextureRect
var _list: VBoxContainer
var _injuries: VBoxContainer
var _inventory_scroll: ScrollContainer


func setup(party_state) -> void:
	_party = party_state
	_build()
	party_state.changed.connect(refresh)
	party_state.supplies.changed.connect(refresh)
	refresh()


func refresh() -> void:
	if not visible or _party == null:
		return
	var supplies = _party.supplies
	_time_label.text = str(supplies.gold)
	_time_label.tooltip_text = "Gold · %d time spent this expedition" % _party.time_elapsed
	match supplies.source:
		Supplies.Source.TORCH:
			_light_icon.texture = TORCH_ICON
			_light_title.text = "Torch"
			_lantern_bar.max_value = Supplies.TORCH_BURN_TIME
			_lantern_bar.value = supplies.torch_left
			_lantern_label.text = "Burning  ·  %d time left" % ceili(supplies.torch_left) if supplies.torch_burns else "Burning"
			_light_note.text = "In a fight, Item > Throw torch scares an enemy away, but the torch is gone."
		Supplies.Source.NONE:
			_light_icon.texture = UNLIT_LANTERN_ICON if supplies.has_lantern else null
			_light_title.text = "No light"
			_lantern_bar.value = 0
			_lantern_label.text = "Darkness"
			_light_note.text = ""
		_:
			_light_icon.texture = LANTERN_ICON if supplies.oil > 0 else UNLIT_LANTERN_ICON
			_light_title.text = "Lantern"
			_lantern_bar.max_value = Supplies.LANTERN_CAPACITY
			_lantern_bar.value = supplies.oil
			var flask_note := "  ·  part-used flask: %d" % roundi(supplies.open_flask) if supplies.open_flask > 0.0 else ""
			_lantern_label.text = "%s  ·  %d/%d oil%s" % [
				Supplies.LIGHT_NAMES[supplies.light_band()], roundi(supplies.oil), int(Supplies.LANTERN_CAPACITY),
				flask_note]
			_light_note.text = "A fuller lantern lights farther but burns faster."
	# Keep the fuel bar and amount in view; secondary help belongs to the light.
	_light_icon.tooltip_text = _light_note.text
	_light_title.tooltip_text = _light_note.text
	_lantern_label.tooltip_text = "Burns %.1f oil per step" % supplies.burn_rate() if supplies.source == Supplies.Source.LANTERN else _light_note.text

	for child in _injuries.get_children():
		child.queue_free()
	var any_injury := false
	for member: Companion in _party.members:
		var hunger := "  ·  hungry" if member.is_hungry() else ""
		_injuries.add_child(_label("%s: %s (strain %d)%s" % [
			member.display_name, StrainRules.NAMES[member.strain_state()], roundi(member.strain),
			hunger], 17, COLOR_TEXT))
		if member.is_alive() and member.effectiveness() < 1.0:
			# Why their numbers are down (#67).
			_injuries.add_child(_label("    Hit chance and damage reduced to %d%%. Light, food and rest ease strain." % [
				roundi(member.effectiveness() * 100)], 16, COLOR_DIM_TEXT))
		for injury in member.injuries:
			any_injury = true
			var state := "dressed until camp" if injury in member.dressed else "untreated"
			var line := _label("    %s (%s). %s" % [injury.display_name, state, injury.description], 17, COLOR_DIM_TEXT)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if _party.can_field_bind(member) and not injury in member.dressed:
				var medic: Companion = _party.living_members().filter(func(m: Companion): return m.trait_id == "field_medic")[0]
				var bind := _small_button("%s binds it" % medic.display_name.split(" ")[-1])
				bind.custom_minimum_size = Vector2(170, 44)
				bind.tooltip_text = "Field medic: once a trip, without a dressing"
				var patient := member
				bind.pressed.connect(func():
					_party.field_bind(patient)
					used.emit("%s binds %s's wound without a dressing." % [medic.display_name, patient.display_name])
					refresh())
				_injuries.add_child(bind)
			_injuries.add_child(line)
	if not any_injury:
		_injuries.add_child(_label("No injuries.", 17, COLOR_DIM_TEXT))

	for child in _list.get_children():
		child.queue_free()
	# Pack space (#133): slots used of the pack's size.
	if supplies.is_limited():
		var space := _label("Pack space: %d of %d" % [supplies.slots_used(), supplies.capacity], 18, COLOR_DIM_TEXT if supplies.slots_used() < supplies.capacity else COLOR_TEXT)
		space.tooltip_text = "Each hero adds %d slots. A slot holds a stack of one kind of supply, or one piece of spare gear." % _party.PACK_SLOTS_PER_HERO
		_list.add_child(space)
	_add_gear_rows()
	for item: SupplyItem in supplies.items:
		if supplies.count(item) > 0:
			_list.add_child(_item_row(item))


## What each hero wields, and carried gear with Equip / Drop (#58). Each
## carried weapon shows, per hero, what it would change (#67).
func _add_gear_rows() -> void:
	var living: Array[Companion] = _party.living_members()
	if living.is_empty():
		return
	_list.add_child(_label("Gear", 20, COLOR_TEXT))
	for hero in living:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var held := "%s (%s)" % [hero.weapon.display_name, _numbers(hero, hero.weapon)] if hero.weapon else "their own weapon (%s)" % _numbers(hero, null)
		var worn := " · wears %s (armour %d)" % [hero.body.display_name.to_lower(), hero.body.armour] if hero.body else ""
		var subject := "%s wields " % hero.display_name if living.size() > 1 else "Wields "
		var line := _label("%s%s%s" % [subject, held, worn], 18, COLOR_TEXT)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(line)
		if hero.weapon and not hero.founder:  # recruits can go back to their own kit
			var away := _small_button("Put away")
			away.pressed.connect(func():
				_party.supplies.gear.append(hero.weapon)
				hero.weapon = null
				hero.emit_changed()
				_party.supplies.changed.emit()
				refresh())
			row.add_child(away)
		_list.add_child(row)
		# On the back (owner, 2026-10-21): a backpack, cloak or cape.
		if hero.back:
			var back_row := HBoxContainer.new()
			back_row.add_theme_constant_override("separation", 12)
			var carried := _label("    On the back: %s (%s)" % [hero.back.display_name.to_lower(), Equipment.back_text(hero.back)], 16, COLOR_DIM_TEXT)
			carried.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			carried.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			back_row.add_child(carried)
			var unstrap := _small_button("Take off")
			unstrap.tooltip_text = "Into the pack"
			unstrap.pressed.connect(func():
				_party.take_off_back(hero)
				refresh())
			back_row.add_child(unstrap)
			_list.add_child(back_row)
		# Trinkets (#135): what it does, and taking it off (not if cursed).
		if hero.trinket:
			var charm_row := HBoxContainer.new()
			charm_row.add_theme_constant_override("separation", 12)
			var curse := ""
			if hero.is_cursed():
				curse = "  ·  cursed: %s, %s" % [hero.trinket.curse.display_name.to_lower(), hero.trinket.curse.effects_text()]
			var charm := _label("    Wears the %s: %s%s" % [hero.trinket.display_name.to_lower(), hero.trinket.effect.effects_text(), curse], 16, COLOR_DIM_TEXT)
			charm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			charm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			charm_row.add_child(charm)
			var off := _small_button("Take off" if not hero.is_cursed() else "Cursed")
			off.disabled = hero.is_cursed()
			off.tooltip_text = "Holy water or the nurse can lift the curse" if hero.is_cursed() else "Back into the pack"
			off.pressed.connect(func():
				_party.take_off_trinket(hero)
				refresh())
			charm_row.add_child(off)
			_list.add_child(charm_row)
	for item: Equipment in _party.supplies.gear:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		if item.icon:
			row.add_child(Quality.framed(item.icon, Quality.tier_of(item), Vector2(40, 40)))  # its quality's border
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var summary := "armour %d%s" % [item.armour, (", slower by %d" % item.initiative_penalty) if item.initiative_penalty > 0 else ""] if item.slot == "body" else "%d-%d" % [item.attack_min, item.attack_max]
		if item.slot == "trinket":
			summary = "%s trinket" % item.tier
		elif item.tier != "common":
			summary = "%s, %s" % [item.tier, summary]
		elif item.slot == "back":
			summary = "worn on the back"
		text.add_child(_label("%s  (%s)" % [item.display_name, summary], 22, COLOR_TEXT))
		var about := _label(item.description, 17, COLOR_DIM_TEXT)
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(about)
		if item.slot == "trinket":
			text.add_child(_label("Worn: " + item.effect.effects_text(), 16, COLOR_DIM_TEXT))
		elif item.effect:  # a magic or rare weapon or armour
			text.add_child(_label("%s: %s" % [item.tier.capitalize(), item.effect.effects_text()], 16, COLOR_DIM_TEXT))
		elif item.slot == "back":
			text.add_child(_label("Worn: " + Equipment.back_text(item), 16, COLOR_DIM_TEXT))
		for hero in living:
			if item.slot in ["trinket", "back"]:
				break
			var now := _numbers(hero, hero.weapon) if item.slot != "body" else _armour(hero, hero.body)
			var then := _numbers(hero, item) if item.slot != "body" else _armour(hero, item)
			var subject := "%s: " % hero.display_name if living.size() > 1 else ""
			text.add_child(_label("%s%s  ->  %s" % [subject, now, then], 16, COLOR_DIM_TEXT))
		row.add_child(text)
		var buttons := VBoxContainer.new()
		for hero in living:
			var equip := _small_button("Equip" if living.size() == 1 else "Equip: %s" % hero.display_name)
			if living.size() > 1:
				equip.custom_minimum_size = Vector2(150, 44)
			if item.slot == "trinket":
				equip.text = "Wear" if living.size() == 1 else "Wear: %s" % hero.display_name
				equip.disabled = hero.is_cursed()
			equip.pressed.connect(func():
				if item.slot == "trinket":
					used.emit(_party.wear(hero, item))
				else:
					_party.equip(hero, item)
					used.emit("%s takes up the %s." % [hero.display_name, item.display_name.to_lower()])
				refresh())
			buttons.add_child(equip)
		var drop := _small_button("Drop")
		drop.pressed.connect(func():
			_party.drop(item)
			used.emit("You drop the %s. It's gone." % item.display_name.to_lower())
			refresh())
		buttons.add_child(drop)
		row.add_child(buttons)
		_list.add_child(row)


## "armour 1, speed 9" for `hero` wearing `armour` (null: nothing), #93.
func _armour(hero: Companion, armour: Equipment) -> String:
	var points: int = armour.armour if armour else 0
	var penalty: int = armour.initiative_penalty if armour else 0
	return "armour %d, speed %d" % [points, hero.initiative - penalty]


## "3-5 dmg, 85% to hit" for `hero` holding `weapon` (null: their own),
## before strain - the comparison is about the gear (#67).
func _numbers(hero: Companion, weapon: Equipment) -> String:
	var held: Equipment = hero.weapon
	hero.weapon = weapon
	var span: Vector2i = hero.attack_range()  # Strength and talents included (#47)
	hero.weapon = held
	var low: int = span.x
	var high: int = span.y
	hero.weapon = weapon
	var hit: float = clampf(hero.hit_accuracy(), 0.1, 0.95)  # a magic weapon's aim too
	hero.weapon = held
	var damage := str(low) if low == high else "%d-%d" % [low, high]
	return "%s dmg, %d%% to hit" % [damage, roundi(hit * 100)]


func _small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110, 56)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 20)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return button


func _item_row(item: SupplyItem) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	if item.icon:
		row.add_child(Quality.framed(item.icon, Quality.tier_of(item), Vector2(40, 40)))  # its quality's border
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var title := _label("%s  ×%d" % [item.display_name, _party.supplies.count(item)], 22, COLOR_TEXT)
	text.add_child(title)
	var about := _label(item.description, 17, COLOR_DIM_TEXT)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(about)
	# Jewellery can be worn as a trinket, or sold (#135).
	var trinket: Equipment = Trinkets.for_treasure(item) if item.effect == SupplyItem.Effect.TREASURE else null
	if trinket:
		text.add_child(_label("Worn (%s): %s" % [trinket.tier, trinket.effect.effects_text()], 16, COLOR_DIM_TEXT))
		var wearers := VBoxContainer.new()
		wearers.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var living: Array[Companion] = _party.living_members()
		for hero in living:
			var wear := _small_button("Wear" if living.size() == 1 else "Wear: %s" % hero.display_name)
			wear.custom_minimum_size = Vector2(150, 44)
			wear.disabled = hero.is_cursed()
			wear.pressed.connect(func():
				used.emit(_party.wear_treasure(hero, item))
				refresh())
			wearers.add_child(wear)
		row.add_child(wearers)

	var reason: String = _party.cannot_use_reason(item)
	var button := Button.new()
	button.text = "Use · %d time" % item.use_time if reason == "" else reason
	button.disabled = reason != ""
	button.custom_minimum_size = Vector2(170, 56)
	button.focus_mode = Control.FOCUS_ALL
	button.tooltip_text = reason if reason != "" else item.description
	button.add_theme_font_size_override("font_size", 20)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func():
		var message: String = _party.use_item(item)
		if message != "":
			used.emit(message)
		refresh())
	row.add_child(button)
	# Leave one behind, to make room (#133).
	var drop := _small_button("Drop")
	drop.tooltip_text = "Leave one %s here" % item.display_name.to_lower()
	drop.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	drop.pressed.connect(func():
		_party.supplies.drop(item, 1)
		used.emit("Left behind: %s." % item.display_name.to_lower())
		refresh())
	row.add_child(drop)
	return row


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.03, 0.03, 1.0)
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

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label("Pack", 30, COLOR_TEXT)
	title.theme_type_variation = "PageTitle"  # Cinzel heading (#51)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_time_label = _label("", 20, COLOR_DIM_TEXT)
	_time_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_time_label)
	var coin := TextureRect.new()
	coin.texture = COIN_ICON
	coin.custom_minimum_size = Vector2(20,20)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(coin)
	var close := Button.new()
	close.icon = CLOSE_ICON
	close.expand_icon = true
	close.add_theme_constant_override("icon_max_width", 24)
	close.tooltip_text = "Close pack"
	close.accessibility_name = "Close pack"
	close.custom_minimum_size = Vector2(52, 52)
	close.focus_mode = Control.FOCUS_ALL
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(func(): closed.emit())
	var save := Button.new()
	save.text = "Save & exit"
	save.custom_minimum_size = Vector2(150, 52)
	save.focus_mode = Control.FOCUS_ALL
	save.add_theme_font_size_override("font_size", 20)
	save.pressed.connect(func(): save_and_exit.emit())
	header.add_child(save)
	header.move_child(save, header.get_child_count() - 2)
	var quests := Button.new()
	quests.icon = JOURNAL_ICON
	quests.expand_icon = true
	quests.add_theme_constant_override("icon_max_width", 26)
	quests.tooltip_text = "Quest journal"
	quests.accessibility_name = "Quest journal"
	quests.custom_minimum_size = Vector2(52, 52)
	quests.focus_mode = Control.FOCUS_ALL
	quests.add_theme_font_size_override("font_size", 20)
	quests.pressed.connect(func(): open_quests.emit())
	header.add_child(quests)
	header.move_child(quests, header.get_child_count() - 2)
	var gear := Button.new()
	gear.icon = SETTINGS_ICON
	gear.expand_icon = true
	gear.add_theme_constant_override("icon_max_width", 24)
	gear.tooltip_text = "Settings"
	gear.accessibility_name = "Settings"
	gear.custom_minimum_size = Vector2(52, 52)
	gear.focus_mode = Control.FOCUS_ALL
	gear.add_theme_font_size_override("font_size", 20)
	gear.pressed.connect(func(): open_settings.emit())
	header.add_child(gear)
	header.move_child(gear, header.get_child_count() - 2)
	header.add_child(close)
	header.move_child(coin, 1)
	header.move_child(save, header.get_child_count()-2)
	visibility_changed.connect(func():
		if visible: close.grab_focus())

	var light_row := HBoxContainer.new()
	light_row.add_theme_constant_override("separation",8)
	column.add_child(light_row)
	_light_icon = TextureRect.new()
	_light_icon.custom_minimum_size = Vector2(28,28)
	_light_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_light_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_light_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_light_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	light_row.add_child(_light_icon)
	_light_title = _label("Lantern", 22, COLOR_TEXT)
	_light_title.theme_type_variation = "ItemTitle"  # Cinzel heading (#51)
	light_row.add_child(_light_title)
	_lantern_bar = ProgressBar.new()
	_lantern_bar.max_value = Supplies.LANTERN_CAPACITY
	_lantern_bar.show_percentage = false
	_lantern_bar.custom_minimum_size = Vector2(0, 18)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.12, 0.09, 0.05)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COLOR_OIL
	_lantern_bar.add_theme_stylebox_override("background", back)
	_lantern_bar.add_theme_stylebox_override("fill", fill)
	column.add_child(_lantern_bar)
	_lantern_label = _label("", 17, COLOR_DIM_TEXT)
	column.add_child(_lantern_label)
	_light_note = _label("", 17, COLOR_DIM_TEXT)
	_light_note.visible = false
	column.add_child(_light_note)

	var scroll := ScrollContainer.new()
	_inventory_scroll = scroll
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var inventory := VBoxContainer.new()
	inventory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory.add_theme_constant_override("separation",14)
	scroll.add_child(inventory)
	inventory.add_child(_label("Condition", 22, COLOR_TEXT))
	_injuries = VBoxContainer.new()
	inventory.add_child(_injuries)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 14)
	inventory.add_child(_list)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
