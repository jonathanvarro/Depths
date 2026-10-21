extends Control
## The campsite (#40/#108): layered terrain, independent sites and lights.
## Six places to tap - merchant, nurse, cave path, your tent, apprentice smith
## and the recruitment fire. Each opens an activity view with Back. The
## rules live in camp_state.gd; this only shows them and passes choices on.
##
## Opening, looking and leaving cost nothing; anything that does (resting
## moves the day on) says so on its button first.

## The player chose to head back down (cave path).
signal cave_chosen(start_depth: int)
## Save and go back to the title (#45).
signal save_and_exit
signal open_settings

const DIR := "res://art/camp/highres-v4/"
const PORTRAIT_DIR := DIR
const HEADING := preload("res://art/fonts/heading-cinzel.tres")
const BODY := preload("res://art/fonts/body-source-sans.tres")
const ACTION := preload("res://art/fonts/action-source-sans.tres")
const TEXT := Color("e6dac1")
const MUTED := Color("b3a78f")
const AMBER := Color("dbb477")
const CANVAS := Vector2(640, 360)
const COIN_ICON := preload("res://art/symbols/crest-v1/currency-coin.svg")
const SETTINGS_ICON := preload("res://art/ui/controls-v1/settings.svg")
const BACK_ICON := preload("res://art/ui/controls-v1/back.svg")
const LANTERN_ICON := preload("res://art/items/refined-v2/lantern-unlit.png")
## The apprentice's starter stock, shown until there's gold (#42).
const CampState := preload("res://scripts/camp_state.gd")
const Story := preload("res://scripts/story.gd")
const NEWS_ICON := preload("res://art/ui/controls-v1/news.svg")
const Quests := preload("res://scripts/quests.gd")
const Progression := preload("res://scripts/progression.gd")

var content: Control  # main.gd keeps this inside the safe area

var _camp  # camp_state.gd
var _party  # party_state.gd
var _note: Label  # a passing announcement over the clearing
var _note_tween: Tween
var _canvas: Control
var _buttons := {}  # site id -> Button
var _sites := {}  # site id -> layout entry
var _site_art := {}  # site id -> registered art node
## The conversation screen (set by main.gd): people at camp with news (#123).
var conversation: Control
var _dressing: Node2D
var _day_label: Label
var _activity: Panel
var _activity_title: Label
var _portrait: TextureRect
var _scroll: ScrollContainer
var _body: VBoxContainer
var _back: Button
var _current := ""
var _last_site := ""
var _save_button: Button
var _settings_button: Button
## Presentation toggle for a still review or reduced-motion integration.
var animate_lights := true:
	set(value):
		animate_lights=value
		for site in _site_art.values():site.animate_lights=value
		if _dressing:_dressing.animate_lights=value


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var backdrop := ColorRect.new()
	backdrop.color = Color("101715")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	content = Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	_canvas = Control.new()
	_canvas.size = CANVAS
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_canvas)
	var scenery := TextureRect.new()
	scenery.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	scenery.texture = load(DIR + "terrain.png")
	scenery.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	scenery.size = CANVAS
	scenery.light_mask = 2
	scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(scenery)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "layout.json"))
	for site in layout["sites"]:
		_add_site(site)
	_dressing=preload("res://art/camp/highres-v4/dressing.gd").new()
	_canvas.add_child(_dressing)
	_canvas.move_child(_dressing,_site_art.fire.get_index()+1)
	_dressing.setup(_canvas,_site_art.fire)
	var title := _label("Relief camp", HEADING, 18, TEXT)
	title.position = Vector2(20, 8)
	_canvas.add_child(title)
	_day_label = _label("", HEADING, 16, AMBER)
	_day_label.position = Vector2(400, 10)
	_day_label.size = Vector2(204, 24)
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_canvas.add_child(_day_label)
	var coin := TextureRect.new()
	coin.texture = COIN_ICON
	coin.position = Vector2(610,13)
	coin.size = Vector2(14,14)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(coin)
	var save := _button("Save & exit")
	_save_button=save
	save.position = Vector2(440, 326)
	save.size = Vector2(104, 30)
	save.add_theme_font_size_override("font_size", 11)
	save.pressed.connect(func(): save_and_exit.emit())
	_canvas.add_child(save)
	var gear := _button("")
	gear.icon=SETTINGS_ICON
	gear.expand_icon=true
	gear.add_theme_constant_override("icon_max_width",18)
	gear.tooltip_text="Settings"
	gear.accessibility_name="Settings"
	_settings_button=gear
	gear.position = Vector2(550, 326)
	gear.size = Vector2(74, 30)
	gear.add_theme_font_size_override("font_size", 11)
	gear.pressed.connect(func(): open_settings.emit())
	_canvas.add_child(gear)
	_build_activity()
	_note = _label("", ACTION, 14, AMBER)
	_note.position = Vector2(0, 150)
	_note.size = Vector2(CANVAS.x, 24)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.modulate.a = 0.0
	_canvas.add_child(_note)
	content.resized.connect(_fit)
	visible = false


## Shows the clearing.
func open(camp, party) -> void:
	if _camp and _camp.changed.is_connected(_on_camp_changed):
		_camp.changed.disconnect(_on_camp_changed)
	_camp = camp
	_party = party
	_camp.changed.connect(_on_camp_changed)
	_update_site_art()
	visible = true
	_close_activity()
	_fit()
	_focus_available.call_deferred("cave")


func _on_camp_changed() -> void:
	_update_site_art()
	_day_label.text=_status()
	if _current!="" and not _camp.site_present(_current):_close_activity()
	elif _current=="supplies":_refresh_activity()


func _focus_available(preferred: String) -> void:
	if _buttons.has(preferred) and _buttons[preferred].visible and not _buttons[preferred].disabled:
		_buttons[preferred].grab_focus()
		return
	for button in _buttons.values():
		if button.visible and not button.disabled:
			button.grab_focus()
			return


## A short message over the clearing (e.g. a contract paid).
func announce(text: String) -> void:
	_note.text = text
	_note.modulate.a = 1.0
	_day_label.text = _status()
	if _note_tween:
		_note_tween.kill()
	_note_tween = create_tween()
	_note_tween.tween_interval(3.0)
	_note_tween.tween_property(_note, "modulate:a", 0.0, 0.8)


func is_open(id: String) -> bool:
	return _current == id


func _add_site(site: Dictionary) -> void:
	var id: String = site["id"]
	_sites[id] = site
	var r: Array = site["rect"]
	var rect := Rect2(r[0], r[1], r[2], r[3])
	var art: Node2D = load(DIR + id + ".tscn").instantiate()
	# Textures retain registered positions on the common landscape canvas.
	art.animate_lights=animate_lights
	_canvas.add_child(art)
	_site_art[id]=art
	if id=="supplies":
		art.add_child(load(DIR + "caravan-unloading.tscn").instantiate())
	# The whole site and its label are one target (keyboard, mouse, touch).
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = site["label"]
	button.add_theme_font_override("font", ACTION)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color",Color("101513"))
	button.add_theme_constant_override("outline_size",3)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.content_margin_top = rect.size.y - 21
	button.add_theme_stylebox_override("normal", normal)
	for state in ["hover", "pressed", "focus"]:
		var highlight := normal.duplicate() as StyleBoxFlat
		button.add_theme_stylebox_override(state, highlight)
	button.mouse_entered.connect(_highlight_site.bind(id))
	button.mouse_exited.connect(_highlight_site.bind(id))
	button.focus_entered.connect(_highlight_site.bind(id))
	button.focus_exited.connect(_highlight_site.bind(id))
	button.pressed.connect(open_activity.bind(id))
	_canvas.add_child(button)
	_buttons[id] = button
	# Put all controls above artwork even where the terrain groups overlap.
	for target in _buttons.values():_canvas.move_child(target,-1)


func _highlight_site(id: String) -> void:
	var button: Button=_buttons[id]
	var active: bool=button.is_hovered() or button.has_focus()
	_site_art[id].modulate=Color(1.14,1.10,1.02) if active else Color.WHITE
	button.add_theme_color_override("font_color",AMBER if active else TEXT)


## Registered site variants follow actual contracts and recovery state.
func _update_site_art() -> void:
	if _camp==null:return
	_save_button.visible=_current==""
	_settings_button.visible=_current==""
	_dressing.refresh(_camp)
	for id in _site_art:
		var present: bool=_camp.site_present(id)
		_site_art[id].visible=present
		_buttons[id].disabled=not present
		_buttons[id].visible=present and _current==""
	var unloading: bool=_camp.merchant_unloading
	_site_art.supplies.get_node("Base").visible=not unloading
	_site_art.supplies.get_node("Unloading").visible=unloading
	_site_art.supplies.get_node("Lantern0").visible=not unloading
	_buttons.supplies.text="Merchant · Unloading" if unloading else _sites.supplies.label
	var has_contract: bool = _camp.contract.has("enemy") and not _camp.queen_defeated
	_site_art["cave"].get_node("Notice").visible=has_contract
	var occupied: bool = _camp.recovering.keys().any(func(hero):return _camp.is_recovering(hero))
	_site_art["treatment"].get_node("OccupiedCot").visible=occupied
	# News follows the same story availability as the site's conversation.
	for id in _buttons:
		if id != "supplies" and _sites.has(id):
			var news: bool = Story.camp_talk(_camp, id) != ""
			_buttons[id].text = _sites[id].label
			_buttons[id].icon = NEWS_ICON if news else null
			_buttons[id].icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_buttons[id].expand_icon = true
			_buttons[id].add_theme_constant_override("icon_max_width", 14)
			_buttons[id].tooltip_text = "Someone here has news" if news else ""
			_buttons[id].accessibility_name = _sites[id].label + (", new conversation" if news else "")


## Scales the 640 x 360 scene to fit the safe area, centred.
func _fit() -> void:
	var room := content.size
	if room.x <= 0.0 or room.y <= 0.0:
		return
	var ratio := minf(room.x / CANVAS.x, room.y / CANVAS.y)
	_canvas.scale = Vector2.ONE * ratio
	_canvas.position = (room - CANVAS * ratio) / 2.0
	# Keep global/activity controls comfortably tappable at Larger UI scale.
	var height:=maxf(30.0,44.0/ratio)
	for button in [_save_button,_settings_button,_back]:
		if button:
			button.custom_minimum_size.y=height
			button.size.y=height
	if _save_button:
		_save_button.size.x=104
		_settings_button.size.x=height
		_settings_button.position.x=CANVAS.x-height-16
		_save_button.position.x=_settings_button.position.x-114
		_save_button.position.y=CANVAS.y-height-4
		_settings_button.position.y=CANVAS.y-height-4
	for button in _body.find_children("*","Button",true,false):button.custom_minimum_size.y=height


func _build_activity() -> void:
	_activity = Panel.new()
	_activity.position = Vector2(36, 24)
	_activity.size = Vector2(568, 316)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2421")
	style.border_color = Color("938263")
	style.set_border_width_all(1)
	_activity.add_theme_stylebox_override("panel", style)
	_canvas.add_child(_activity)
	_activity_title = _label("", HEADING, 20, TEXT)
	_activity_title.position = Vector2(18, 10)
	_activity.add_child(_activity_title)
	_back = _button("")
	_back.icon=BACK_ICON
	_back.expand_icon=true
	_back.add_theme_constant_override("icon_max_width",18)
	_back.tooltip_text="Back to camp"
	_back.accessibility_name="Back to camp"
	_back.position = Vector2(516, 10)
	_back.size = Vector2(40, 30)
	_back.pressed.connect(_close_activity)
	_activity.add_child(_back)
	_portrait = TextureRect.new()
	_portrait.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	_portrait.position = Vector2(10, 56)
	_portrait.size = Vector2(200, 200)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_activity.add_child(_portrait)
	_scroll = ScrollContainer.new()
	_scroll.follow_focus = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_activity.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	_scroll.add_child(_body)
	_activity.visible = false


func open_activity(id: String) -> void:
	if not _sites.has(id) or _camp==null or not _camp.site_present(id):return
	_current = id
	if _note_tween:
		_note_tween.kill()
	_note.modulate.a = 0.0  # announcements belong to the clearing
	_last_site = id
	for button in _buttons.values():
		button.visible = false
	var site: Dictionary = _sites[id]
	_activity_title.text = site["label"]
	var npc: String = site["npc"]
	_portrait.texture = load(PORTRAIT_DIR + npc + ".png") if npc != "" else null
	var left := 222.0 if npc != "" else 18.0
	_scroll.position = Vector2(left, 50)
	_scroll.size = Vector2(_activity.size.x - left - 14, _activity.size.y - 62)
	_activity.visible = true
	_refresh_activity()
	_back.grab_focus()


func _close_activity() -> void:
	_current = ""
	_activity.visible = false
	_update_site_art()
	_day_label.text = _status() if _camp else ""
	if visible:_focus_available.call_deferred(_last_site)


func _refresh_activity() -> void:
	if _current!="" and not _camp.site_present(_current):
		_close_activity()
		return
	_update_site_art()
	if _current=="supplies":
		_activity_title.text="Merchant caravan · Unloading" if _camp.merchant_unloading else _sites.supplies.label
	_day_label.text = _status()
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_talk_row()
	match _current:
		"supplies": _merchant()
		"smith": _smith()
		"treatment": _nurse()
		"rest": _tent()
		"fire": _fire()
		"cave": _cave_path()
	_fit()


## Someone here has something to say (#123): a talk button at the top.
func _talk_row() -> void:
	var id := Story.camp_talk(_camp, _current)
	var talk := Story.conversation(id)
	if talk == null:
		return
	var button := _button("Talk to %s" % talk.speaker)
	button.add_theme_color_override("font_color", AMBER)
	button.pressed.connect(func():
		if conversation:
			var heroes: Array = _party.members.filter(func(h): return h.founder or h.main_hero)
			await conversation.play(talk, heroes[0] if not heroes.is_empty() else (_party.members[0] if not _party.members.is_empty() else null), _camp, _party.members)
		Story.after_talk(_camp, id)
		_refresh_activity())
	_body.add_child(button)


## The merchant (#42): buy supplies and the lantern, sell treasure and gear.
func _merchant() -> void:
	if _camp.merchant_unloading:
		_text("\"Careful with that chest! The shop opens when I've finished unloading.\"")
		_text("Caravan unloading. Trading is not available yet.", AMBER)
	else:
		_text("\"Back again, and still breathing. Good for business. What'll it be?\"")
	if _camp.needs_charity(_party):
		_text("He looks at your empty hands and sighs. \"Two torches. On account.\"", AMBER)
		var charity := _button("Take two torches")
		charity.pressed.connect(func():
			_camp.give_charity(_party)
			_refresh_activity())
		_body.add_child(charity)
	# Existing emergency torches remain possible; these are not a trade.
	if _camp.merchant_unloading:return
	_body.add_child(_label("Buy", HEADING, 16, TEXT))
	if not _party.supplies.has_lantern:
		_shop_row("Lantern: brighter than a torch, burns oil. Yours to keep.", CampState.LANTERN_PRICE, func(): _camp.buy_lantern(_party), LANTERN_ICON)
	for item: SupplyItem in CampState.MERCHANT_STOCK:
		if item.effect == SupplyItem.Effect.REFILL_LANTERN and not _party.supplies.has_lantern:
			continue  # oil is for lantern owners
		var held: int = _party.supplies.count(item)
		_shop_row("%s (you have %d)" % [item.display_name, held], item.price, _camp.buy.bind(_party, item), item.icon, _party.supplies.room_for(item) > 0)
	var selling := false
	for item: SupplyItem in _party.supplies.items:
		if item.effect == SupplyItem.Effect.TREASURE and _party.supplies.count(item) > 0:
			if not selling:
				_body.add_child(_label("Sell", HEADING, 16, TEXT))
				selling = true
			_sell_row("%s ×%d" % [item.display_name, _party.supplies.count(item)], CampState.sale_price(item), _camp.sell.bind(_party, item), item.icon)
	for item: Equipment in _party.supplies.gear:
		if not selling:
			_body.add_child(_label("Sell", HEADING, 16, TEXT))
			selling = true
		_sell_row(item.display_name, CampState.sale_price(item), _camp.sell_gear.bind(_party, item), item.icon)


## The apprentice smith (#42): plain gear into the pack (equip it there).
func _smith() -> void:
	_text("The apprentice wipes his hands. \"It's not much. But it'll hold.\"")
	for item: Equipment in _camp.smith_stock():  # with quest unlocks (#123)
		if item.slot == "body":  # armour (#93)
			var slower := ", slower by %d" % item.initiative_penalty if item.initiative_penalty > 0 else ""
			_shop_row("%s: armour %d%s" % [item.display_name, item.armour, slower], item.price, _camp.buy_gear.bind(_party, item), item.icon, _party.supplies.has_room_for_gear())
			continue
		var accuracy := "" if is_zero_approx(item.accuracy_bonus) else ", %+d%% to hit" % roundi(item.accuracy_bonus * 100)
		_shop_row("%s: %d-%d damage%s" % [item.display_name, item.attack_min, item.attack_max, accuracy], item.price, _camp.buy_gear.bind(_party, item), item.icon, _party.supplies.has_room_for_gear())
	_text("Coming once there are rules for them: %s." % ", ".join(PackedStringArray(CampState.SMITH_COMING)), MUTED)
	_text("Bought gear goes in your pack; equip it from there.", MUTED)


## Level-ups (#47): each hero's level, XP and attributes; anyone ready
## chooses a talent (levels 2 and 4) or an attribute point (level 3).
func _training() -> void:
	_body.add_child(_label("Training", HEADING, 16, TEXT))
	for hero: Companion in _party.members:
		if not hero.uses_stats:
			continue
		var next: int = Progression.xp_for_next(hero)
		var progress := "%d / %d XP" % [hero.xp, next] if next > 0 else "%d XP (the mine's best)" % hero.xp
		var talents := ", ".join(PackedStringArray(hero.talents.map(func(t): return Progression.talent_name(t))))
		_text("%s · level %d · %s · STR %d DEX %d VIT %d RES %d%s" % [hero.display_name, hero.level, progress, hero.stat_str, hero.stat_dex, hero.stat_vit, hero.stat_res, (" · " + talents) if talents != "" else ""], MUTED)
		if Progression.ready_to_advance(hero):
			_text("%s is ready for level %d. Choose one:" % [hero.display_name, hero.level + 1], AMBER)
			var row := HFlowContainer.new()
			row.add_theme_constant_override("h_separation", 8)
			for option in Progression.choices(hero):
				var pick := _button("%s: %s" % [option[1], option[2]])
				var id: String = option[0]
				pick.pressed.connect(func():
					_camp.advance(hero, id)
					_refresh_activity())
				row.add_child(pick)
			_body.add_child(row)


## What the camp says about the goblin queen (#44).
func _rumour() -> String:
	if _camp.queen_defeated:
		return "The camp still toasts the goblin queen's death."
	if _camp.gate_broken:
		return "Word has spread: the fortress gate is broken. Only the queen's hall remains."
	return "Soldiers swap stories of a goblin queen and her fortress, four floors down, behind a barred gate."


## Top-right: the day and the purse.
func _status() -> String:
	return "Day %d · %d" % [_camp.day, _party.supplies.gold]


## `room` false: the pack has no space for it (#133).
func _shop_row(text: String, price: int, on_buy: Callable, icon: Texture2D = null, room := true) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_item_icon(row,icon)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	var name := _label(text, BODY, 12, TEXT)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(name)
	if _party.supplies.gold < price:
		details.add_child(_label("Need %dg more" % (price-_party.supplies.gold),BODY,11,MUTED))
	var buy := _button("Buy %dg" % price)
	buy.custom_minimum_size = Vector2(78, 30)
	_price_icon(buy)
	buy.disabled = _party.supplies.gold < price or not room
	buy.tooltip_text = "Your pack is full" if not room else ("Need %dg more gold" % (price-_party.supplies.gold) if buy.disabled else "Buy for %dg" % price)
	if not room:
		details.add_child(_label("No room in your pack", BODY, 11, MUTED))
	buy.pressed.connect(func():
		on_buy.call()
		_refresh_activity())
	row.add_child(buy)
	_body.add_child(row)


func _sell_row(text: String, price: int, on_sell: Callable, icon: Texture2D = null) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_item_icon(row,icon)
	var name := _label(text, BODY, 12, TEXT)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(name)
	var sell := _button("Sell %dg" % price)
	sell.custom_minimum_size = Vector2(78, 30)
	_price_icon(sell)
	sell.pressed.connect(func():
		on_sell.call()
		_refresh_activity())
	row.add_child(sell)
	_body.add_child(row)


func _item_icon(row: Control, texture: Texture2D) -> void:
	if texture == null:return
	var icon := TextureRect.new()
	icon.texture = texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.custom_minimum_size = Vector2(28,28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)


func _price_icon(button: Button) -> void:
	button.icon = COIN_ICON
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width",12)


func _nurse() -> void:
	# Banes that outlasted the trip (#133).
	for hero: Companion in _party.living_members():
		if not hero.has_bane():
			continue
		var bane: Boon = hero.boons.filter(func(b): return b["boon"].bane)[0]["boon"]
		_text("%s still carries %s: %s" % [hero.display_name, bane.display_name.to_lower(), bane.description], AMBER)
		var lift := _button("Lift it (%dg)" % CampState.LIFT_BANE_PRICE)
		lift.disabled = _party.supplies.gold < CampState.LIFT_BANE_PRICE
		lift.pressed.connect(func():
			var lifted: Boon = _camp.lift_bane(_party, hero)
			_refresh_activity()
			if lifted:
				_text("The nurse mutters over %s and burns something bitter. %s lifts." % [hero.display_name, lifted.display_name], AMBER))
		_body.add_child(lift)
	for hero: Companion in _party.living_members():
		if _camp.is_recovering(hero):
			_text("%s is resting here until day %d." % [hero.display_name, _camp.ready_on(hero)])
		elif hero.injuries.is_empty():
			_text("%s has no lasting injuries." % hero.display_name, MUTED)
		else:
			var names := ", ".join(PackedStringArray(hero.injuries.map(func(i: Injury): return i.display_name.to_lower())))
			var days: int = _camp.treatment_days(hero)
			_text("%s: %s. Untreated, %s can still go back in." % [hero.display_name, names, hero.display_name])
			# Who's left to go down meanwhile (#88).
			var others: int = _camp.available(_party).filter(func(h): return h != hero).size()
			if others == 0:
				_text("Treated, %s is out until day %d - and no one else is fit, so nobody goes down until then." % [hero.display_name, _camp.day + days], AMBER)
			else:
				_text("%d days of recovery · back on day %d. The others can travel." % [days, _camp.day + days], MUTED)
			var treat := _button("Treat %s (back on day %d)" % [hero.display_name, _camp.day + days])
			treat.pressed.connect(func():
				_camp.treat(hero)
				_refresh_activity())
			_body.add_child(treat)


func _tent() -> void:
	_training()
	# What a night's rest does, and doesn't (#85, #88).
	_text("Rest until tomorrow: health and strain fully restored. Lasting injuries remain - only the nurse treats those.")
	var injured: Array = _party.living_members().filter(func(h): return not h.injuries.is_empty() and not _camp.is_recovering(h))
	if not injured.is_empty():
		_text("Still injured after resting: %s." % ", ".join(PackedStringArray(injured.map(func(h): return h.display_name))), MUTED)
	var healed: Array = _party.living_members().filter(func(h): return _camp.is_recovering(h) and _camp.ready_on(h) == _camp.day + 1)
	if not healed.is_empty():
		_text("Fit again tomorrow: %s." % ", ".join(PackedStringArray(healed.map(func(h): return h.display_name))), MUTED)
	if _camp.explored_today:
		_text("By morning the mine will have shifted: new passages and fresh enemies. The ways you found today will be gone.", AMBER)
	else:
		_text("By morning the mine will have shifted: new passages and fresh enemies.", MUTED)
	var rest := _button("Rest until day %d" % (_camp.day + 1))
	rest.pressed.connect(func():
		_camp.rest(_party)
		_refresh_activity()
		_text("A night's rest. It's day %d." % _camp.day, AMBER))
	_body.add_child(rest)
	_body.add_child(_label("Stash", HEADING, 16, TEXT))
	_text("Stored items and gold stay here, whatever happens down there.", MUTED)
	var gold_row := HBoxContainer.new()
	gold_row.add_theme_constant_override("separation", 8)
	var gold_text := _label("Gold: %d carried · %d in the stash" % [_party.supplies.gold, _camp.stash.gold], BODY, 12, AMBER)
	gold_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gold_row.add_child(gold_text)
	for spec in [["Store gold", _camp.store_gold, _party.supplies.gold > 0], ["Take gold", _camp.take_gold, _camp.stash.gold > 0]]:
		var button := _button(spec[0])
		button.disabled = not spec[2]
		var action: Callable = spec[1]
		button.pressed.connect(func():
			action.call(_party)
			_refresh_activity())
		gold_row.add_child(button)
	_body.add_child(gold_row)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	_body.add_child(columns)
	var pack := _column(columns, "In your pack (%d/%d)" % [_party.supplies.slots_used(), _party.supplies.capacity])
	var stash := _column(columns, "In the stash")
	for item: SupplyItem in _party.supplies.items:
		if _party.supplies.count(item) > 0:
			_row(pack, "%s ×%d" % [item.display_name, _party.supplies.count(item)], "Store", _camp.store.bind(_party, item))
	for item: Equipment in _party.supplies.gear:
		_row(pack, item.display_name, "Store", _camp.store_gear.bind(_party, item))
	for item: SupplyItem in _camp.stash.items:
		if _camp.stash.count(item) > 0:
			_row(stash, "%s ×%d" % [item.display_name, _camp.stash.count(item)], "Take", _camp.withdraw.bind(_party, item), _party.supplies.room_for(item) > 0)
	for item: Equipment in _camp.stash.gear:
		_row(stash, item.display_name, "Take", _camp.withdraw_gear.bind(_party, item), _party.supplies.has_room_for_gear())
	if pack.get_child_count() == 1:
		pack.add_child(_label("Empty.", BODY, 12, MUTED))
	if stash.get_child_count() == 1:
		stash.add_child(_label("Empty.", BODY, 12, MUTED))


## Recruits by the fire (#41): who they are, their strength and weakness,
## and Invite; then the party, where recruits can be sent away.
func _fire() -> void:
	var full: bool = _party.free_slots() <= 0
	if _camp.candidates.is_empty():
		_text("No one is by the fire today.", MUTED)
	else:
		_text("Others who made it to the camp sit by the fire. Any of them would join you - for now, for nothing.")
	_text(_rumour(), MUTED)
	for recruit: Companion in _camp.candidates:
		_recruit_row(recruit, full)
	_body.add_child(_label("Your party", HEADING, 16, TEXT))
	if _party.members.is_empty():
		_text("No one. Invite someone to go down with you.", AMBER)
	for hero: Companion in _party.members:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var about := _label("%s · %s · %d/%d health" % [hero.display_name, hero.role, hero.health, hero.effective_max_health()], BODY, 12, TEXT)
		about.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(about)
		if hero.founder:
			row.add_child(_label("Stays", ACTION, 12, MUTED))
		else:
			var dismiss := _button("Dismiss")
			dismiss.pressed.connect(func():
				_camp.dismiss(_party, hero)
				_refresh_activity())
			row.add_child(dismiss)
		_body.add_child(row)


func _recruit_row(recruit: Companion, full: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var face := TextureRect.new()
	face.texture = recruit.portrait
	face.custom_minimum_size = Vector2(56, 56)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(face)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	info.add_child(_label("%s · %s" % [recruit.display_name, recruit.role], ACTION, 14, TEXT))
	var traits := _label("Strength: %s · Weakness: %s" % [recruit.strength, recruit.weakness], BODY, 11, AMBER)
	traits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(traits)
	var damage := str(recruit.attack_min) if recruit.attack_min == recruit.attack_max else "%d-%d" % [recruit.attack_min, recruit.attack_max]
	var numbers := _label("%d health · %s damage · %d%% to hit · speed %d" % [recruit.max_health, damage, roundi(recruit.accuracy * 100), recruit.initiative], BODY, 11, MUTED)
	info.add_child(numbers)
	var about := _label(recruit.personality, BODY, 11, MUTED)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(about)
	row.add_child(info)
	var invite := _button("Party full" if full else "Invite")
	invite.disabled = full
	invite.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	invite.pressed.connect(func():
		_camp.hire(_party, recruit)
		_refresh_activity())
	row.add_child(invite)
	_body.add_child(row)


func _cave_path() -> void:
	# Current orders (#123): the quest log in brief.
	for id in Quests.in_log(_camp):
		if Quests.stage(_camp, id) != Quests.Stage.RESOLVED:
			_text("%s - %s" % [Quests.INFO[id]["title"], Quests.next_step(_camp, id)], AMBER)
	var going: Array[Companion] = _camp.available(_party)
	for hero: Companion in _party.living_members():
		if _camp.is_recovering(hero):
			_text("%s is recovering with the nurse until day %d." % [hero.display_name, _camp.ready_on(hero)], MUTED)
		else:
			var hurt := " · untreated: " + ", ".join(PackedStringArray(hero.injuries.map(func(i: Injury): return i.display_name.to_lower()))) if not hero.injuries.is_empty() else ""
			_text("%s: %d/%d health%s" % [hero.display_name, hero.health, hero.effective_max_health(), hurt])
	if _party.members.is_empty():
		_text("Your party is gone. Find companions at the fire.", AMBER)
		return
	if going.is_empty():
		_text("No one is fit to go. Rest in your tent to pass the days.", AMBER)
		return
	# The roster that actually leaves (#87).
	var staying: Array = _party.living_members().filter(func(h): return h not in going)
	_text("Going down: %s." % ", ".join(PackedStringArray(going.map(func(h): return h.display_name))), AMBER)
	if not staying.is_empty():
		_text("Staying with the nurse: %s." % ", ".join(PackedStringArray(staying.map(func(h): return "%s (fit on day %d)" % [h.display_name, _camp.ready_on(h)]))), MUTED)
	_text("The mine is as you left it today." if _camp.explored_today else "The mine has shifted since anyone was last inside.", MUTED)
	_text(_rumour(), MUTED)
	if not _camp.contract.is_empty():
		var c: Dictionary = _camp.contract
		var state := "paid" if c["paid"] else "%d of %d" % [c["done"], c["count"]]
		_text("Posted on the trail post, by order of the king: %s (%s)." % [CampState.contract_text(c), state], AMBER)
	var down := _button("Head back down")
	down.pressed.connect(func(): cave_chosen.emit(1))
	_body.add_child(down)
	# The scouts' routes (#79): straight down to any floor they've marked,
	# dearer the deeper it goes.
	for depth: int in _camp.open_routes():
		var price: int = _camp.route_price(depth)
		var route := _button("Scouts' route to floor %d (%dg)" % [depth, price])
		route.disabled = _party.supplies.gold < price
		route.pressed.connect(func():
			if _camp.buy_route(_party, depth):
				cave_chosen.emit(depth))
		_body.add_child(route)
	# The next route they'd mark.
	for depth: int in CampState.ROUTE_PRICES:
		if not _camp.route_open(depth) and (depth == 2 or _camp.times_reached(depth) > 0):
			_text("The king's scouts say: reach floor %d twice, and they'll mark a safe way down to it - for a price. (%d of %d)" % [depth, _camp.times_reached(depth), CampState.ROUTE_AFTER], MUTED)
			break


func _unhandled_input(event: InputEvent) -> void:
	if visible and _current != "" and event.is_action_pressed("ui_cancel"):
		_close_activity()
		get_viewport().set_input_as_handled()


func _column(parent: Control, heading: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	column.add_child(_label(heading, ACTION, 13, AMBER))
	parent.add_child(column)
	return column


## `enabled` false: e.g. no room in the pack to take it (#133).
func _row(column: VBoxContainer, text: String, action: String, on_press: Callable, enabled := true) -> void:
	var row := HBoxContainer.new()
	var name := _label(text, BODY, 12, TEXT)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(name)
	var button := _button(action)
	button.custom_minimum_size = Vector2(52, 30)
	button.disabled = not enabled
	if not enabled:
		button.tooltip_text = "Your pack is full"
	button.pressed.connect(func():
		on_press.call()
		_refresh_activity())
	row.add_child(button)
	column.add_child(row)


func _text(text: String, color := TEXT) -> void:
	var label := _label(text, BODY, 13, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(_scroll.size.x - 8, 0)
	_body.add_child(label)


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 30)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_override("font", ACTION)
	button.add_theme_font_size_override("font_size", 13)
	# This entire camp uses a scaled 640px canvas. Keep the shared theme's
	# colours/focus, but do not double-scale its screen-sized 12px padding.
	for state in ["normal","hover","pressed","disabled"]:
		var compact:=button.get_theme_stylebox(state).duplicate() as StyleBox
		compact.content_margin_left=8
		compact.content_margin_right=8
		compact.content_margin_top=4
		compact.content_margin_bottom=4
		button.add_theme_stylebox_override(state,compact)
	return button


func _label(text: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
