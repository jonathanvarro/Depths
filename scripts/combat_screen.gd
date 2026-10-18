extends Control
## The combat screen (#14): turn text and a short log (top-left), a tag over
## each enemy that you tap to target it, and the action panel (bottom-right,
## in place of the movement pad). Runs the fight with combat_state.gd and
## animates what happens. Layout follows ChatGPT's combat study
## (art/expedition-v1/combat-*.png).

signal finished(result: int)  # combat_state.gd Result
## After each enemy turn (the opening reacts to the spider's poison, #59).
signal enemy_acted(foe, outcome: Dictionary)
signal _action_chosen(action: Dictionary)

const CombatState := preload("res://scripts/combat_state.gd")
const COLOR_TEXT := Color("e8d9b0")
const COLOR_DIM_TEXT := Color(0.85, 0.8, 0.7, 0.75)
const ENEMY_PAUSE := 0.45
const LOG_LINES := 3
const TAG_HEIGHT := 0.9  # metres above an enemy's feet

var content: MarginContainer  # main.gd keeps this inside the safe area

var _state  # combat_state.gd
var _cards: Array = []  # party_card.gd, to mark whose turn it is
var _target  # CombatState.Foe
var _turn_label: Label
var _log_label: Label
var _log: PackedStringArray = []
var _target_label: Label
var _actions: Control
var _action_buttons: HBoxContainer
var _item_buttons: HBoxContainer
var _tags := {}  # Foe -> Button


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


## Runs a whole fight; emits `finished` with the result when it's over.
func run(state, cards: Array) -> void:
	_state = state
	_cards = cards
	_log.clear()
	for tag in _tags.values():
		tag.queue_free()
	_tags.clear()
	for foe in state.foes:
		var tag := Button.new()
		tag.focus_mode = Control.FOCUS_NONE
		tag.custom_minimum_size = Vector2(110, 44)
		tag.add_theme_font_size_override("font_size", 18)
		tag.pressed.connect(_select_target.bind(foe))
		add_child(tag)
		_tags[foe] = tag
	_select_target(state.living_foes()[0])
	var names := ", ".join(PackedStringArray(state.foes.map(func(f): return f.name.to_lower())))
	_add_log("Something stirs: %s!" % names)
	var hinted := {}
	for foe in state.foes:
		if foe.type.intro != "" and not hinted.has(foe.type):
			hinted[foe.type] = true
			_add_log(foe.type.intro)  # a hint at how it fights (#15)
	visible = true

	while state.result == CombatState.Result.ONGOING:
		var actor = state.current_actor()
		_refresh()
		if actor is Companion:
			_mark_turn(actor)
			_show_actions(true)
			var action: Dictionary = await _action_chosen
			_show_actions(false)
			await _hero_action(actor, action)
		else:
			_mark_turn(null)
			_turn_label.text = "Round %d · the %s acts" % [state.round, actor.name.to_lower()]
			await get_tree().create_timer(ENEMY_PAUSE).timeout
			await _enemy_action(actor)
		if state.result != CombatState.Result.ONGOING:
			break
		state.advance()
		for event in state.events:
			_add_log(event)
		state.events.clear()
		if _target == null or not _target.is_alive():
			var living: Array = state.living_foes()
			if not living.is_empty():
				_select_target(living[0])

	_mark_turn(null)
	_refresh()
	await get_tree().create_timer(0.8).timeout
	visible = false
	finished.emit(state.result)


func _hero_action(hero: Companion, action: Dictionary) -> void:
	match action["kind"]:
		"attack":
			var target = _target
			var outcome: Dictionary = _state.hero_attack(hero, target)
			_add_log(outcome["text"])
			if outcome["hit"]:
				await _play(target, "hurt", 0.35)
				if outcome["killed"]:
					await _fade_out(target)
		"defend":
			_add_log(_state.hero_defend(hero))
		"item":
			_add_log(_state.hero_use_item(action["item"]))
		"retreat":
			_add_log(_state.retreat())
		"throw":
			var target = _target
			_add_log(_state.hero_throw_torch(hero, target))
			await _fade_out(target)
	await get_tree().create_timer(0.25).timeout


func _enemy_action(foe) -> void:
	var outcome: Dictionary = _state.enemy_act(foe)
	_add_log(outcome.get("text", ""))
	enemy_acted.emit(foe, outcome)
	if outcome.get("fled", false):
		await _fade_out(foe)
		return
	_play(foe, "attack", 0.4)
	await get_tree().create_timer(0.5).timeout


func _play(foe, animation: String, seconds: float) -> void:
	var sprite: AnimatedSprite3D = foe.node.get_node_or_null("Sprite") if foe.node else null
	if sprite == null:
		return
	sprite.play(animation)
	await get_tree().create_timer(seconds).timeout
	if is_instance_valid(sprite):
		sprite.play("idle")


func _fade_out(foe) -> void:
	var sprite: AnimatedSprite3D = foe.node.get_node_or_null("Sprite") if foe.node else null
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
		await tween.finished
		foe.node.visible = false


func _process(_delta: float) -> void:
	if not visible or _state == null:
		return
	var camera := get_viewport().get_camera_3d()
	for foe in _tags:
		var tag: Button = _tags[foe]
		tag.visible = foe.is_alive() and foe.node != null and not camera.is_position_behind(foe.node.global_position)
		if tag.visible:
			var screen := camera.unproject_position(foe.node.global_position + Vector3(0, TAG_HEIGHT, 0))
			tag.text = "%s %d/%d%s" % [foe.name, foe.health, foe.type.max_health, "  [shield]" if foe.shielded else ""]
			tag.position = screen - tag.size / 2.0
			tag.modulate = Color.WHITE if foe == _target else Color(1, 1, 1, 0.65)


func _select_target(foe) -> void:
	_target = foe
	_target_label.text = "Target: %s" % foe.name


func _refresh() -> void:
	_log_label.text = "\n".join(_log)


func _mark_turn(hero: Companion) -> void:
	for card in _cards:
		card.set_active(hero != null and card.companion == hero)
	if hero:
		var odds := roundi(_state.hero_hit_chance(hero) * 100)
		var status := PackedStringArray()
		if _state.is_webbed(hero):
			status.append("webbed")
		if _state.venom_turns(hero) > 0:
			status.append("poisoned")
		var extra := (", " + ", ".join(status)) if not status.is_empty() else ""
		_turn_label.text = "Round %d · %s's turn (%d%% to hit%s)" % [_state.round, hero.display_name, odds, extra]


func _add_log(text: String) -> void:
	if text == "":
		return
	_log.append(text)
	while _log.size() > LOG_LINES:
		_log.remove_at(0)
	_refresh()


func _show_actions(shown: bool) -> void:
	_actions.visible = shown
	_action_buttons.visible = true
	_item_buttons.visible = false


func _show_items() -> void:
	for child in _item_buttons.get_children():
		child.queue_free()
	if _state.party.supplies.torch_lit():
		# Throw the burning torch: the target flees the flames (#59).
		var throw := _button("Throw torch")
		throw.pressed.connect(func(): _action_chosen.emit({"kind": "throw"}))
		_item_buttons.add_child(throw)
	for item: SupplyItem in _state.party.supplies.items:
		if not item.usable_in_combat:
			continue
		var reason: String = _state.party.cannot_use_reason(item, true)
		var button := _button("%s ×%d" % [item.display_name, _state.party.supplies.count(item)] if reason == "" else reason)
		button.disabled = reason != ""
		button.pressed.connect(func(): _action_chosen.emit({"kind": "item", "item": item}))
		_item_buttons.add_child(button)
	var back := _button("Back")
	back.pressed.connect(func():
		_action_buttons.visible = true
		_item_buttons.visible = false)
	_item_buttons.add_child(back)
	_action_buttons.visible = false
	_item_buttons.visible = true


func _build() -> void:
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "top", "right", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 16)
	add_child(content)
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(layer)

	var top_left := VBoxContainer.new()
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(top_left)
	_turn_label = _label("", 22, COLOR_TEXT)
	top_left.add_child(_turn_label)
	_log_label = _label("", 18, COLOR_DIM_TEXT)
	_log_label.custom_minimum_size = Vector2(520, 0)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_left.add_child(_log_label)

	_target_label = _label("", 20, COLOR_TEXT)
	_target_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_target_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_target_label.position.y = 230  # below the minimap and Pack button
	layer.add_child(_target_label)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.05, 0.85)
	style.border_color = Color(0.35, 0.27, 0.18, 0.9)
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	_actions = panel
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	rows.add_child(_label("Action", 20, COLOR_TEXT))
	_action_buttons = HBoxContainer.new()
	_action_buttons.add_theme_constant_override("separation", 8)
	rows.add_child(_action_buttons)
	for spec in [["Attack", "attack"], ["Defend", "defend"], ["Item", ""], ["Retreat", "retreat"]]:
		var button := _button(spec[0])
		var kind: String = spec[1]
		if kind == "":
			button.pressed.connect(_show_items)
		else:
			button.pressed.connect(func(): _action_chosen.emit({"kind": kind}))
		_action_buttons.add_child(button)
	_item_buttons = HBoxContainer.new()
	_item_buttons.add_theme_constant_override("separation", 8)
	_item_buttons.visible = false
	rows.add_child(_item_buttons)
	_actions.visible = false
	visible = false


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(112, 56)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	return button


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	return label
