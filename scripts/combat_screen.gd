extends Control
## The combat screen (#14): the round (top-left), a tag over each enemy that
## you tap to target it, and the action panel (bottom-right, in place of the
## movement pad). Runs the fight with combat_state.gd and shows what happens
## as slashes, claw marks, numbers and icons rather than sentences (#105).
## Layout follows ChatGPT's combat study (art/expedition-v1/combat-*.png).

signal finished(result: int)  # combat_state.gd Result
## After each enemy turn (the opening reacts to the spider's poison, #59).
signal enemy_acted(foe, outcome: Dictionary)
signal _action_chosen(action: Dictionary)

const CombatState := preload("res://scripts/combat_state.gd")
const Glyphs := preload("res://art/ui/backlog96-v1/glyphs.gd")
const CombatFx := preload("res://scripts/combat_fx.gd")
const Sounds := preload("res://scripts/sounds.gd")
const COLOR_TEXT := Color("e8d9b0")
const COLOR_DIM_TEXT := Color(0.85, 0.8, 0.7, 0.75)
const ENEMY_PAUSE := 0.45
const TAG_HEIGHT := 0.9  # metres above an enemy's feet
const TAG_ICON := 30
## Native 32px glyphs matching the #96 interface art (#105).
const MARKS := {
	"rush": preload("res://art/ui/visual105-v1/rush.png"),
	"recover": preload("res://art/ui/visual105-v1/recover.png"),
	"beat": preload("res://art/ui/visual105-v1/beat.png"),
	"webbed": preload("res://art/ui/visual105-v1/webbed.png"),
	"venom": preload("res://art/ui/visual105-v1/venom.png"),
	"guard": preload("res://art/ui/visual105-v1/guard.png"),
	"armour": preload("res://art/ui/visual105-v1/armour.png"),
	"drummed": preload("res://art/ui/visual105-v1/drummed.png"),
	"miss": preload("res://art/ui/visual105-v1/miss.png"),
}
const TORCH := preload("res://data/items/torch.tres")

var content: MarginContainer  # main.gd keeps this inside the safe area

var _state  # combat_state.gd
var _cards: Array = []  # party_card.gd, to mark whose turn it is
var _target  # CombatState.Foe
var _turn_label: Label
## The selected enemy's next move in words (#116): an icon and a short line
## on the action panel, so touch and keyboard players needn't hover.
var _intent_icon_rect: TextureRect
var _intent_label: Label
var _fx: Control  # combat_fx.gd
var _health_seen := {}  # Companion -> health, to show each change as a number
var _last_number := {}  # Companion -> msec of their last number, to stagger the next
var _actions: Control
var _action_buttons: HBoxContainer
var _item_buttons: HBoxContainer
var _tags := {}  # Foe -> Button
## "" allows every action; "throw" allows only Item > Throw torch (the
## opening forces the throw when Mara is nearly down, #69).
var only_action := ""
var _hero: Companion  # whose turn it is (rows decide who they can reach, #72)
## The coin flip overlay (coin_flip.gd), set by main.gd (#77).
var coin: Control
## No running away (the queen's hall, #44).
var no_retreat := false
## Places a foe that joins mid-fight in the world (set by main.gd).
var place_foe := Callable()
## Emitted after each hero action (the opening reacts to glancing blows).
signal hero_acted(hero: Companion, action: Dictionary, outcome: Dictionary)


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


## Runs a whole fight; emits `finished` with the result when it's over.
func run(state, cards: Array) -> void:
	_state = state
	_cards = cards
	_note_health()
	for tag in _tags.values():
		tag.queue_free()
	_tags.clear()
	for foe in state.foes:
		_add_tag(foe)
	state.foe_joined.connect(func(foe):
		if place_foe.is_valid():
			place_foe.call(foe)
		_add_tag(foe))
	_select_target(state.living_foes()[0])
	visible = true

	while state.result == CombatState.Result.ONGOING:
		var actor = state.current_actor()
		_refresh()
		if actor is Companion:
			_hero = actor
			var reachable: Array = state.targets_for(actor)
			if not reachable.is_empty() and not state.can_hit(actor, _target):
				_select_target(reachable[0])
			_mark_turn(actor)
			_show_actions(true)
			var action: Dictionary = await _action_chosen
			_show_actions(false)
			await _hero_action(actor, action)
		else:
			_mark_turn(null)
			await get_tree().create_timer(ENEMY_PAUSE).timeout
			await _enemy_action(actor)
		if state.result != CombatState.Result.ONGOING:
			break
		state.advance()
		if not state.events.is_empty():
			_show_health_changes(MARKS["venom"])  # venom ticking
		state.events.clear()
		if _target == null or not _target.is_alive():
			var living: Array = state.living_foes()
			if not living.is_empty():
				_select_target(living[0])

	_mark_turn(null)
	_hero = null
	_refresh()
	await get_tree().create_timer(0.8).timeout
	visible = false
	finished.emit(state.result)


## An enemy's tag (#105): its next move as an icon, its name, a health bar,
## and small marks (shield, drum). The words live in the tooltip.
func _add_tag(foe) -> void:
	var tag := Button.new()
	tag.focus_mode = Control.FOCUS_NONE
	tag.custom_minimum_size = Vector2(110, 48)
	tag.add_theme_font_size_override("font_size", 15)
	tag.expand_icon = false
	tag.add_theme_constant_override("icon_max_width", TAG_ICON)
	tag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tag.pressed.connect(_select_target.bind(foe))
	var bar := ProgressBar.new()
	bar.name = "Health"
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -7
	bar.offset_bottom = -3
	bar.offset_left = 6
	bar.offset_right = -6
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.12, 0.08, 0.07)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("c0392b")
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	tag.add_child(bar)
	var marks := HBoxContainer.new()
	marks.name = "Marks"
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marks.add_theme_constant_override("separation", 1)
	marks.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	marks.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	marks.position.y = -10
	tag.add_child(marks)
	var odds := Label.new()  # the current hero's chance to hit, on the target
	odds.name = "Odds"
	odds.add_theme_font_size_override("font_size", 14)
	odds.add_theme_color_override("font_color", Color("f2d27a"))
	odds.add_theme_color_override("font_outline_color", Color.BLACK)
	odds.add_theme_constant_override("outline_size", 5)
	odds.position = Vector2(2, -12)
	odds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_child(odds)
	add_child(tag)
	move_child(_fx, -1)  # effects stay on top
	_tags[foe] = tag


func _hero_action(hero: Companion, action: Dictionary) -> void:
	var outcome := {}
	_note_health()
	match action["kind"]:
		"attack":
			var target = _target
			outcome = _state.hero_attack(hero, target)
			var at := _foe_point(target)
			if not outcome["hit"]:
				_fx.number(at, "miss", CombatFx.COLOR_DULL, 34)
			elif outcome.get("glanced", false):
				Sounds.play(self, "block")
				_fx.slash(at)
				_fx.icon(at + Vector2(0, -30), MARKS["armour"])  # its hard legs turn the blade
				_fx.number(at + Vector2(60, -40), str(outcome["damage"]), CombatFx.COLOR_DULL, 34, 0.12)
			else:
				_fx.slash(at, outcome["damage"] >= 5)
				Sounds.play(self, "block" if target.shielded else "hit")
				if target.shielded:
					_fx.icon(at + Vector2(-50, -20), MARKS["guard"], 34.0)
				# The slash lands, then the number follows it (#105).
				_fx.number(at + Vector2(70, -50), str(outcome["damage"]), CombatFx.COLOR_DAMAGE, 72 if outcome["killed"] else CombatFx.NUMBER_SIZE, 0.12)
				await _play(target, "hurt", 0.35)
				if outcome["killed"]:
					await _fade_out(target)
		"defend":
			_state.hero_defend(hero)
			Sounds.play(self, "block", -10.0)
			_fx.icon(_card_point(hero), MARKS["guard"], 56.0)
		"move":
			_state.hero_move(hero)
		"item":
			_state.hero_use_item(action["item"])
			_fx.icon(_card_point(hero) + Vector2(0, -40), action["item"].icon, 48.0)
		"retreat":
			_state.retreat()
		"throw":
			var target = _target
			outcome = _state.hero_throw_torch(hero, target)
			var at := _foe_point(target)
			_fx.icon(at, TORCH.icon, 64.0)
			if outcome["fled"]:
				await _fade_out(target)  # beasts flee the flames (#115)
			else:  # goblins are burned but hold their ground
				_fx.number(at + Vector2(60, -40), str(outcome["damage"]), Color("ff9a3c"), CombatFx.NUMBER_SIZE, 0.12)
				await _play(target, "hurt", 0.35)
				if outcome["killed"]:
					await _fade_out(target)
	_show_health_changes()
	_refresh()
	hero_acted.emit(hero, action, outcome)
	await get_tree().create_timer(0.25).timeout


func _enemy_action(foe) -> void:
	if foe.intent in [CombatState.Intent.KILLING_BLOW, CombatState.Intent.CLEAVER] and coin:
		# The coin decides (#77): shown in the open, no turning it down.
		var target: Companion = _state.prepare_killing_blow(foe)
		if target:
			var notes := PackedStringArray()
			if _state.is_defending(target):
				notes.append("%s is defending" % target.display_name)
			var luck: Array = _state.party.luck()
			if luck[1] != "":
				notes.append("%s's luck" % luck[1])
			var title := "The queen raises her cleaver over %s!" % target.display_name if foe.intent == CombatState.Intent.CLEAVER else "The %s lunges for %s's throat!" % [foe.name.to_lower(), target.display_name]
			var heads: bool = await coin.flip(title,
					"the blow whistles past", "a crushing hit and a lasting injury",
					_state.killing_blow_odds(target), ", ".join(notes))
			_state.coin = 1 if heads else 0
	_note_health()
	var intent: int = foe.intent
	var was_webbed := {}
	for hero in _state.party.members:
		was_webbed[hero] = _state.is_webbed(hero)
	var outcome: Dictionary = _state.enemy_act(foe)
	enemy_acted.emit(foe, outcome)
	if outcome.get("fled", false):
		await _fade_out(foe)
		return
	_play(foe, "attack", 0.4)
	_show_enemy_outcome(foe, intent, outcome, was_webbed)
	_refresh()
	await get_tree().create_timer(0.5).timeout


## What an enemy's turn did, drawn over the heroes' cards and the enemies.
func _show_enemy_outcome(foe, intent: int, outcome: Dictionary, was_webbed: Dictionary) -> void:
	var target: Companion = outcome.get("target")
	var at := _foe_point(foe)
	match intent:
		CombatState.Intent.SHIELD, CombatState.Intent.BRACE:
			Sounds.play(self, "block", -10.0)
			_fx.icon(at, MARKS["guard"], 56.0)
		CombatState.Intent.RECOVER:
			_fx.icon(at, MARKS["recover"], 56.0)
		CombatState.Intent.BEAT:
			_fx.icon(at, MARKS["beat"], 56.0)
			for other in _state.living_foes():
				if other != foe:
					_fx.icon(_foe_point(other), MARKS["drummed"], 40.0)
		CombatState.Intent.CALL, CombatState.Intent.SCREECH:
			_fx.icon(at, _intent_icon(intent), 64.0)
		CombatState.Intent.WEB:
			if target:
				var stuck: bool = _state.is_webbed(target) and not was_webbed.get(target, false)
				_fx.icon(_card_point(target), MARKS["webbed"] if stuck else MARKS["miss"], 64.0)
			return
	if target == null:
		_show_health_changes()
		return
	var card_at := _card_point(target)
	if outcome.get("hit", false):
		Sounds.play(self, "hit", -2.0)
		_fx.claw(card_at)
		if target.body and target.body.armour > 0:
			_fx.icon(card_at + Vector2(40, 30), MARKS["armour"], 30.0)
		if _state.venom_turns(target) > 0 and foe.type.venomous and foe.type.tactic == EnemyType.Tactic.WEB_AND_VENOM:
			_fx.icon(card_at + Vector2(-40, 30), MARKS["venom"], 34.0)
		if outcome.get("injury"):
			var injury: Injury = outcome["injury"]
			_fx.icon(card_at + Vector2(0, 40), Glyphs.STATUS["limp" if injury.icon_kind == "limp" else "deep-wound"], 40.0)
	elif _state.is_defending(target):
		Sounds.play(self, "block")
		_fx.icon(card_at, MARKS["guard"], 56.0)  # braced and turned aside
	else:
		_fx.number(card_at, "miss", CombatFx.COLOR_DULL, 34)
	_show_health_changes()


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
		if foe.node and foe.node.has_method("set_combat_state"):
			foe.node.set_combat_state(foe.enraged,foe.shielded)
		var tag: Button = _tags[foe]
		tag.visible = foe.is_alive() and foe.node != null and not camera.is_position_behind(foe.node.global_position)
		if tag.visible:
			# Back-row tags sit higher, so a row behind doesn't hide the row in front (#72).
			# Neighbours alternate heights too, so tags don't collide.
			var lift: float = float(foe.node.get_meta("visual_height",TAG_HEIGHT)) + 0.12 + (0.6 if not _state.foe_in_front(foe) else 0.0) + 0.25 * (foe.node.scale.y - 1.0) + 0.35 * (_state.foes.find(foe) % 2)
			var screen := camera.unproject_position(foe.node.global_position + Vector3(0, lift, 0))
			# What it does next as an icon (#60, #105); the words on hover.
			tag.icon = _intent_icon(foe.intent)
			tag.text = foe.name
			tag.tooltip_text = "%s: %s" % [foe.name, CombatState.intent_text(foe)]
			var bar: ProgressBar = tag.get_node("Health")
			bar.visible = not foe.glancing  # no health to whittle down (#69)
			bar.max_value = foe.type.max_health
			bar.value = foe.health
			var marks := []
			if foe.shielded:
				marks.append(MARKS["guard"])
			if _state._drummed.has(foe):
				marks.append(MARKS["drummed"])
			_set_marks(tag.get_node("Marks"), marks)
			var odds: Label = tag.get_node("Odds")
			odds.visible = foe == _target and _hero != null and _state.can_hit(_hero, foe)
			if odds.visible:
				odds.text = "%d%%" % roundi(_state.hero_hit_chance(_hero) * 100)
			tag.position = screen - tag.size / 2.0
			var reachable: bool = _hero == null or _state.can_hit(_hero, foe)
			tag.modulate = Color.WHITE if foe == _target else Color(1, 1, 1, 0.65 if reachable else 0.35)


func _set_marks(row: HBoxContainer, textures: Array) -> void:
	var shown: Array = row.get_children().map(func(c): return c.texture)
	if shown == textures:
		return
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for texture in textures:
		var mark := TextureRect.new()
		mark.texture = texture
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mark.custom_minimum_size = Vector2(20, 20)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(mark)


## The #96 intention glyphs, with placeholders for the newer moves.
func _intent_icon(intent: int) -> Texture2D:
	match intent:
		CombatState.Intent.RUSH: return MARKS["rush"]
		CombatState.Intent.RECOVER: return MARKS["recover"]
		CombatState.Intent.BEAT: return MARKS["beat"]
	return Glyphs.intention(intent)


## Where an enemy is on screen (for slashes and numbers).
func _foe_point(foe) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if foe == null or foe.node == null or camera == null:
		return get_viewport_rect().size / 2.0
	var scale_y: float = foe.node.scale.y
	return camera.unproject_position(foe.node.global_position + Vector3(0, 0.45 * scale_y, 0))


## The middle of a hero's portrait card.
func _card_point(hero: Companion) -> Vector2:
	for card in _cards:
		if card.companion == hero:
			return card.global_position + Vector2(card.size.x / 2.0, card.size.y * 0.4)
	return get_viewport_rect().size / 2.0


func _note_health() -> void:
	_health_seen.clear()
	if _state == null:
		return
	for hero in _state.party.members:
		_health_seen[hero] = hero.health


## Every hero whose health changed since the last note gets a number on
## their card: red for a loss, green for a gain.
func _show_health_changes(extra_icon: Texture2D = null) -> void:
	for hero in _health_seen:
		var change: int = hero.health - _health_seen[hero]
		if change == 0:
			continue
		var at := _card_point(hero)
		var now := Time.get_ticks_msec()
		if now - _last_number.get(hero, -10000) < 700:
			at += Vector2(34, 26)  # don't land on the number still rising
		_last_number[hero] = now
		if change < 0:
			_fx.number(at + Vector2(0, -20), str(change), CombatFx.COLOR_HURT, CombatFx.NUMBER_SIZE, 0.1)
			if extra_icon:
				_fx.icon(at + Vector2(-40, 30), extra_icon, 34.0)
		else:
			_fx.number(at + Vector2(0, -20), "+%d" % change, CombatFx.COLOR_HEAL)
	_note_health()


func _select_target(foe) -> void:
	_target = foe
	_update_attack()
	_update_intent_line()


## "Goblin: winding up a heavy blow" for the selected enemy (#116).
func _update_intent_line() -> void:
	if _intent_label == null or _target == null:
		return
	_intent_icon_rect.texture = _intent_icon(_target.intent)
	_intent_label.text = "%s: %s" % [_target.name, CombatState.intent_text(_target)]


## Keyboard (#116): Tab, or the turn keys (A/D, ←/→), pick the next or
## previous enemy while choosing an action.
func _unhandled_input(event: InputEvent) -> void:
	if not visible or _state == null or not _actions.visible or not event.is_pressed() or event.is_echo():
		return
	var step := 0
	if event.is_action("ui_focus_next") or event.is_action("turn_right"):
		step = 1
	elif event.is_action("ui_focus_prev") or event.is_action("turn_left"):
		step = -1
	if step == 0:
		return
	var living: Array = _state.living_foes()
	if living.is_empty():
		return
	var i: int = living.find(_target)
	_select_target(living[(i + step + living.size()) % living.size()])
	get_viewport().set_input_as_handled()


## Attack only when the current hero can reach the target (#72).
func _update_attack() -> void:
	if _action_buttons == null or _state == null or _hero == null:
		return
	for button: Button in _action_buttons.get_children():
		if button.text == "Attack":
			button.disabled = only_action != "" or not _state.can_hit(_hero, _target)
		elif button.text == "Move":
			button.visible = _state.party.living_members().size() > 1
			button.disabled = only_action != ""
		elif button.text == "Retreat":
			button.disabled = only_action != "" or no_retreat


## The round, and each hero's fight conditions as icons on their card.
func _refresh() -> void:
	_turn_label.text = "Round %d" % _state.round
	var ongoing: bool = _state.result == CombatState.Result.ONGOING
	for card in _cards:
		var hero: Companion = card.companion
		if hero == null:
			continue
		var marks := []
		if ongoing and _state.is_webbed(hero):
			marks.append([MARKS["webbed"], "Webbed: their next move is clumsy"])
		if ongoing and _state.venom_turns(hero) > 0:
			marks.append([MARKS["venom"], "Venom: loses health each turn"])
		if ongoing and _state.is_defending(hero):
			marks.append([MARKS["guard"], "Defending: takes less damage"])
		card.set_marks(marks)


func _mark_turn(hero: Companion) -> void:
	for card in _cards:
		card.set_active(hero != null and card.companion == hero)


func _show_actions(shown: bool) -> void:
	_actions.visible = shown
	_action_buttons.visible = true
	_item_buttons.visible = false
	for button: Button in _action_buttons.get_children():
		button.disabled = only_action != "" and button.text != "Item"
	_update_attack()
	_update_intent_line()  # its intention may have changed since it acted
	if shown and only_action == "throw":
		_show_items()


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
		button.disabled = reason != "" or only_action != ""
		button.pressed.connect(func(): _action_chosen.emit({"kind": "item", "item": item}))
		_item_buttons.add_child(button)
	var back := _button("Back")
	back.disabled = only_action != ""
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

	_turn_label = _label("", 22, COLOR_TEXT)
	layer.add_child(_turn_label)

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
	var intent_row := HBoxContainer.new()
	intent_row.add_theme_constant_override("separation", 8)
	_intent_icon_rect = TextureRect.new()
	_intent_icon_rect.custom_minimum_size = Vector2(28, 28)
	_intent_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_intent_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_intent_icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	intent_row.add_child(_intent_icon_rect)
	_intent_label = _label("", 18, COLOR_TEXT)
	intent_row.add_child(_intent_label)
	rows.add_child(intent_row)
	_action_buttons = HBoxContainer.new()
	_action_buttons.add_theme_constant_override("separation", 8)
	rows.add_child(_action_buttons)
	for spec in [["Attack", "attack"], ["Defend", "defend"], ["Move", "move"], ["Item", ""], ["Retreat", "retreat"]]:
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
	_fx = CombatFx.new()  # above everything else on the fight screen
	add_child(_fx)
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
