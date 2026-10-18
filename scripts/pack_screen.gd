extends Control
## Backpack screen (#10): lantern oil, time spent, and supplies with Use
## buttons. Supplies live here rather than on the HUD, to keep the view
## quiet. Opening and browsing spend nothing; using an item spends its time.

signal closed
## Save the game and go back to the title (#45).
signal save_and_exit
## An item was used; `message` describes what happened.
signal used(message: String)

const Supplies := preload("res://scripts/supplies.gd")
const StrainRules := preload("res://scripts/strain.gd")
const COLOR_TEXT := Color("e8d9b0")
const COLOR_DIM_TEXT := Color(0.85, 0.8, 0.7, 0.65)
const COLOR_OIL := Color("e8a84a")

var content: MarginContainer  # main.gd keeps this inside the safe area

var _party  # party_state.gd
var _time_label: Label
var _lantern_bar: ProgressBar
var _lantern_label: Label
var _light_title: Label
var _light_note: Label
var _list: VBoxContainer
var _injuries: VBoxContainer


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
	_time_label.text = "%d gold  ·  Time spent: %d" % [supplies.gold, _party.time_elapsed]
	match supplies.source:
		Supplies.Source.TORCH:
			_light_title.text = "Torch"
			_lantern_bar.max_value = Supplies.TORCH_BURN_TIME
			_lantern_bar.value = supplies.torch_left
			_lantern_label.text = "Burning  ·  %d time left" % ceili(supplies.torch_left) if supplies.torch_burns else "Burning"
			_light_note.text = "In a fight, Item > Throw torch scares an enemy away, but the torch is gone."
		Supplies.Source.NONE:
			_light_title.text = "No light"
			_lantern_bar.value = 0
			_lantern_label.text = "Darkness. Light a torch, if you have one."
			_light_note.text = ""
		_:
			_light_title.text = "Lantern"
			_lantern_bar.max_value = Supplies.LANTERN_CAPACITY
			_lantern_bar.value = supplies.oil
			var flask_note := "  ·  part-used flask: %d" % roundi(supplies.open_flask) if supplies.open_flask > 0.0 else ""
			_lantern_label.text = "%s  ·  %d/%d oil  ·  burns %.1f per step%s" % [
				Supplies.LIGHT_NAMES[supplies.light_band()], roundi(supplies.oil), int(Supplies.LANTERN_CAPACITY),
				supplies.burn_rate(), flask_note]
			_light_note.text = "A fuller lantern lights farther but burns faster."

	for child in _injuries.get_children():
		child.queue_free()
	var any_injury := false
	for member: Companion in _party.members:
		var hunger := "  ·  hungry" if member.is_hungry() else ""
		_injuries.add_child(_label("%s: %s (strain %d)  ·  effectiveness %d%%%s" % [
			member.display_name, StrainRules.NAMES[member.strain_state()], roundi(member.strain),
			roundi(member.effectiveness() * 100), hunger], 17, COLOR_TEXT))
		if member.is_alive() and member.effectiveness() < 1.0:
			# Why their numbers are down (#67).
			_injuries.add_child(_label("    Strain cuts %s's hit chance and damage to %d%%. Light, food and rest ease it." % [
				member.display_name, roundi(member.effectiveness() * 100)], 16, COLOR_DIM_TEXT))
		for injury in member.injuries:
			any_injury = true
			var state := "dressed until camp" if injury in member.dressed else "untreated"
			var line := _label("%s: %s (%s). %s" % [member.display_name, injury.display_name, state, injury.description], 17, COLOR_DIM_TEXT)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_injuries.add_child(line)
	if not any_injury:
		_injuries.add_child(_label("No injuries.", 17, COLOR_DIM_TEXT))

	for child in _list.get_children():
		child.queue_free()
	_add_gear_rows()
	for item: SupplyItem in supplies.items:
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
		var line := _label("%s wields %s" % [hero.display_name, held], 18, COLOR_TEXT)
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
	for item: Equipment in _party.supplies.gear:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		if item.icon:
			var icon := TextureRect.new()
			icon.texture = item.icon
			icon.custom_minimum_size = Vector2(40, 40)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(_label("%s  (%d-%d)" % [item.display_name, item.attack_min, item.attack_max], 22, COLOR_TEXT))
		var about := _label(item.description, 17, COLOR_DIM_TEXT)
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(about)
		for hero in living:
			var now := _numbers(hero, hero.weapon)
			var then := _numbers(hero, item)
			text.add_child(_label("%s: %s  ->  %s" % [hero.display_name, now, then], 16, COLOR_DIM_TEXT))
		row.add_child(text)
		var buttons := VBoxContainer.new()
		for hero in living:
			var equip := _small_button("Equip" if living.size() == 1 else "Equip: %s" % hero.display_name)
			if living.size() > 1:
				equip.custom_minimum_size = Vector2(150, 44)
			equip.pressed.connect(func():
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


## "3-5 dmg, 85% to hit" for `hero` holding `weapon` (null: their own),
## before strain - the comparison is about the gear (#67).
func _numbers(hero: Companion, weapon: Equipment) -> String:
	var low: int = weapon.attack_min if weapon else hero.attack_min
	var high: int = weapon.attack_max if weapon else hero.attack_max
	var hit: float = clampf(hero.accuracy + (weapon.accuracy_bonus if weapon else 0.0), 0.1, 0.95)
	var damage := str(low) if low == high else "%d-%d" % [low, high]
	return "%s dmg, %d%% to hit" % [damage, roundi(hit * 100)]


func _small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110, 56)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return button


func _item_row(item: SupplyItem) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	if item.icon:
		var icon := TextureRect.new()
		icon.texture = item.icon
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var title := _label("%s  ×%d" % [item.display_name, _party.supplies.count(item)], 22, COLOR_TEXT)
	text.add_child(title)
	var about := _label(item.description, 17, COLOR_DIM_TEXT)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(about)

	var reason: String = _party.cannot_use_reason(item)
	var button := Button.new()
	button.text = "Use" if reason == "" else reason
	button.disabled = reason != ""
	button.custom_minimum_size = Vector2(170, 56)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func():
		var message: String = _party.use_item(item)
		if message != "":
			used.emit(message)
		refresh())
	row.add_child(button)
	return row


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.03, 0.03, 0.96)
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
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_time_label = _label("", 20, COLOR_DIM_TEXT)
	_time_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_time_label)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(120, 52)
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(func(): closed.emit())
	var save := Button.new()
	save.text = "Save & exit"
	save.custom_minimum_size = Vector2(150, 52)
	save.focus_mode = Control.FOCUS_NONE
	save.add_theme_font_size_override("font_size", 20)
	save.pressed.connect(func(): save_and_exit.emit())
	header.add_child(save)
	header.move_child(save, header.get_child_count() - 2)
	header.add_child(close)

	_light_title = _label("Lantern", 22, COLOR_TEXT)
	column.add_child(_light_title)
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
	column.add_child(_light_note)

	column.add_child(_label("Condition", 22, COLOR_TEXT))
	_injuries = VBoxContainer.new()
	column.add_child(_injuries)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 14)
	scroll.add_child(_list)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
