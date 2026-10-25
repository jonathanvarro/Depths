extends Control
## The live Field kit: hero equipment/status left, shared physical bag right.
## Browsing is presentation only; explicit actions use the existing party model.
signal closed
signal save_and_exit
signal open_settings
signal open_quests
signal used(message: String)

const Supplies := preload("res://scripts/supplies.gd")
const StrainRules := preload("res://scripts/strain.gd")
const Trinkets := preload("res://scripts/trinkets.gd")
const Quality := preload("res://scripts/quality.gd")
const FieldKit := preload("res://art/ui/field-kit-v1/style.gd")
const PortraitView := preload("res://scripts/portrait_view.gd")
const BagView := preload("res://scripts/kit_bag.gd")
const ROLL := preload("res://art/ui/physical-kit-v1/roll.png")
const LANTERN_ICON := preload("res://art/items/refined-v2/lantern.png")
const UNLIT_LANTERN_ICON := preload("res://art/items/refined-v2/lantern-unlit.png")
const TORCH_ICON := preload("res://art/items/refined-v2/torch.png")
const COIN_ICON := preload("res://art/symbols/crest-v1/currency-coin.svg")
const SETTINGS_ICON := preload("res://art/ui/controls-v1/settings.svg")
const CLOSE_ICON := preload("res://art/ui/controls-v1/close.svg")
const JOURNAL_ICON := preload("res://art/ui/controls-v1/journal.svg")
const SLOT_NAMES := {"weapon":"Weapon", "body":"Armour", "back":"Back", "trinket":"Trinket"}
const PAGE_SIZE := 12
const EMPTY_ICONS := {"weapon":preload("res://art/ui/physical-kit-v1/weapon.svg"),"body":preload("res://art/ui/physical-kit-v1/armour.svg"),"back":preload("res://art/ui/controls-v1/backpack.svg"),"trinket":preload("res://art/ui/physical-kit-v1/trinket.svg")}

var content: MarginContainer
var _party
var _selected_hero: Companion
var _selection: Resource
var _from_slot := ""
var _pinned := false
var _serial := 0
var _page := 0
var _status := false
var _refresh_pending := false
var _entries: Array[Dictionary] = []
var _hero_row: HBoxContainer
var _hero_summary: Label
var _equip_tab: Button
var _status_tab: Button
var _equipment: Control
var _equipment_slots: GridContainer
var _slot_buttons: Dictionary = {}
var _status_scroll: ScrollContainer
var _status_content: VBoxContainer
var _bag: Control
var _pages: HBoxContainer
var _capacity: Label
var _details: PanelContainer
var _detail_icon: TextureRect
var _detail_text: VBoxContainer
var _detail_actions: HBoxContainer
var _close: Button
var _time_label: Label
var _light_title: Label
var _light_note: Label
var _light_icon: TextureRect
var _lantern_bar: ProgressBar
var _lantern_label: Label
# Review helpers point at the real controls, not a hidden legacy list.
var _list: Control
var _inventory_scroll: ScrollContainer
var _injuries: VBoxContainer

func setup(party_state) -> void:
	_party = party_state
	_build()
	_party.changed.connect(_request_refresh)
	_party.supplies.changed.connect(_request_refresh)
	visibility_changed.connect(_on_visibility)
	refresh()

func _on_visibility() -> void:
	if visible:
		_status = false
		clear_inspection()
		refresh()
		_close.grab_focus.call_deferred()
	else:
		clear_inspection()

func _request_refresh() -> void:
	if not _refresh_pending:
		_refresh_pending = true
		refresh.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		if _selection!=null:
			clear_inspection()
		else:
			closed.emit()
		get_viewport().set_input_as_handled()

func refresh() -> void:
	_refresh_pending = false
	if not visible or _party == null:
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_id: String = focused.get_meta("kit_focus","") if is_instance_valid(focused) else ""
	if _selected_hero not in _party.members:
		_selected_hero = _party.members[0] if not _party.members.is_empty() else null
		clear_inspection()
	if _selection != null and not _selection_available():
		clear_inspection()
	_refresh_light()
	_refresh_heroes()
	_refresh_equipment()
	_refresh_status()
	_refresh_bag()
	_refresh_details()
	if focus_id != "":
		_restore_focus.call_deferred(focus_id)

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _restore_focus(id: String) -> void:
	if not visible:
		return
	for button in find_children("*","Button",true,false):
		if button.get_meta("kit_focus","") == id and button.is_visible_in_tree() and not button.disabled:
			button.grab_focus()
			return

func select_hero(hero: Companion) -> void:
	if hero not in _party.members:
		return
	_selected_hero = hero
	clear_inspection()
	refresh()

func set_status(show_status: bool) -> void:
	_status = show_status
	_equipment.visible = not _status
	_status_scroll.visible = _status
	_equip_tab.button_pressed = not _status
	_status_tab.button_pressed = _status

func clear_inspection() -> void:
	_selection = null
	_from_slot = ""
	_pinned = false
	_serial += 1
	if is_instance_valid(_detail_text):
		_refresh_details()
		_highlight_slots()

func inspect_item(item: Resource, pin := true, worn_slot := "") -> void:
	if item == null or (not pin and _pinned):
		return
	_selection = item
	_from_slot = worn_slot
	_pinned = pin
	_serial += 1
	_refresh_details()
	_highlight_slots()

func inspect_item_by_name(item_name: String) -> bool:
	for entry in _entries:
		if entry.item.display_name.begins_with(item_name):
			inspect_item(entry.item)
			return true
	return false

func show_page(page: int) -> void:
	_page = clampi(page,0,_page_count()-1)
	_refresh_bag()
	clear_inspection()

func _page_count() -> int:
	return maxi(1,ceili(float(maxi(_entries.size(),_party.supplies.capacity))/PAGE_SIZE))

func _selection_available() -> bool:
	if _from_slot != "":
		return _selected_hero != null and _selected_hero.get(_from_slot) == _selection
	if _selection is Equipment:
		return _selection in _party.supplies.gear
	if _selection is SupplyItem:
		return _party.supplies.count(_selection)>0 or (_selection.effect==SupplyItem.Effect.REFILL_LANTERN and _party.supplies.open_flask>0)
	return false

func _refresh_light() -> void:
	var s = _party.supplies
	_time_label.text = str(s.gold)
	_time_label.tooltip_text = "Gold · %d time spent this expedition" % _party.time_elapsed
	_light_note.text = ""
	match s.source:
		Supplies.Source.TORCH:
			_light_icon.texture=TORCH_ICON
			_light_title.text="Torch"
			_lantern_bar.max_value=Supplies.TORCH_BURN_TIME
			_lantern_bar.value=s.torch_left
			_lantern_label.text="%d time" % ceili(s.torch_left) if s.torch_burns else "Burning"
		Supplies.Source.NONE:
			_light_icon.texture=UNLIT_LANTERN_ICON if s.has_lantern else TORCH_ICON
			_light_title.text="No light"
			_lantern_bar.value=0
			_lantern_label.text="Dark"
		_:
			_light_icon.texture=LANTERN_ICON if s.oil>0 else UNLIT_LANTERN_ICON
			_light_title.text="Lantern"
			_lantern_bar.max_value=Supplies.LANTERN_CAPACITY
			_lantern_bar.value=s.oil
			_lantern_label.text="%d/%d oil" % [roundi(s.oil),int(Supplies.LANTERN_CAPACITY)]
			_light_note.text="Burns %.1f oil per step. Part-used flask: %d oil." % [s.burn_rate(),roundi(s.open_flask)]
	_light_icon.tooltip_text=_light_title.text+" · "+_lantern_label.text+" "+_light_note.text
	_lantern_label.tooltip_text=_light_note.text

func _refresh_heroes() -> void:
	_clear(_hero_row)
	for hero: Companion in _party.members:
		var button:=_button("",Vector2(80,56))
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.toggle_mode=true
		button.button_pressed=hero==_selected_hero
		button.accessibility_name="Inspect "+hero.display_name
		button.tooltip_text=hero.display_name
		button.set_meta("kit_focus","hero:"+str(hero.get_instance_id()))
		_hero_row.add_child(button)
		var row:=HBoxContainer.new()
		row.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left=4;row.offset_right=-4;row.offset_top=4;row.offset_bottom=-4
		row.add_theme_constant_override("separation",4)
		button.add_child(row)
		var portrait:=PortraitView.new()
		portrait.custom_minimum_size=Vector2(40,40)
		row.add_child(portrait)
		portrait.show_portrait(hero.portrait_set,hero.portrait)
		portrait.set_animated(hero.is_alive())
		portrait.modulate=Color.WHITE if hero.is_alive() else Color(0.45,0.45,0.45)
		portrait.set_condition("pallor",hero.is_alive() and hero.strain_state()>=StrainRules.State.SHAKEN)
		for condition in hero.appearance:portrait.set_condition(condition,true)
		for injury in hero.injuries:
			portrait.set_condition(injury.portrait_condition,injury not in hero.dressed)
			portrait.set_condition(injury.dressed_portrait_condition,injury in hero.dressed)
		var name_label:=_label(hero.display_name,16)
		name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		name_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		row.add_child(name_label)
		button.pressed.connect(select_hero.bind(hero))
	if _selected_hero:
		var h:=_selected_hero
		var state: String=StrainRules.NAMES[h.strain_state()] if h.is_alive() else ("Unconscious" if h.is_unconscious() else "Fallen")
		_hero_summary.text="%s · %d/%d · %s" % [h.role,h.health,h.effective_max_health(),state]
	else:
		_hero_summary.text=""
	set_status(_status)

func _refresh_equipment() -> void:
	_clear(_equipment_slots)
	_slot_buttons.clear()
	for slot: String in SLOT_NAMES:
		var box:=VBoxContainer.new()
		box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		box.size_flags_vertical=Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation",0)
		_equipment_slots.add_child(box)
		var caption:=_label(SLOT_NAMES[slot],14,FieldKit.MUTED)
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(caption)
		var item: Equipment=_selected_hero.get(slot) if _selected_hero else null
		var button:=_button("",Vector2(60,44))
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.size_flags_vertical=Control.SIZE_EXPAND_FILL
		button.set_meta("kit_focus","slot:"+slot)
		button.accessibility_name=SLOT_NAMES[slot]+": "+(item.display_name if item else "Empty")
		button.tooltip_text=button.accessibility_name
		box.add_child(button)
		_slot_buttons[slot]=button
		if item:
			_add_icon(button,item.icon,Quality.tier_of(item,_selected_hero),Vector2(40,40))
			_bind_inspection(button,item,slot)
		else:
			_add_icon(button,EMPTY_ICONS[slot],"common",Vector2(32,32))
			button.get_child(0).modulate.a=0.45
			button.disabled=true
	_highlight_slots()

func _highlight_slots() -> void:
	var receiving: String=_selection.slot if _selection is Equipment else ""
	if _selection is SupplyItem and Trinkets.for_treasure(_selection)!=null:
		receiving="trinket"
	for slot: String in _slot_buttons:
		var button:Button=_slot_buttons[slot]
		var active:=slot==receiving and _from_slot==""
		var edge:=FieldKit.AMBER if active else Color.TRANSPARENT
		var box:=FieldKit.plate(Color(0.04,0.045,0.03,0.25) if active else Color.TRANSPARENT,edge,3)
		button.add_theme_stylebox_override("normal",box)
		button.add_theme_stylebox_override("disabled",box)

func _refresh_status() -> void:
	_clear(_status_content)
	var h:=_selected_hero
	if h==null:
		return
	_status_content.add_child(_label("Level %d · %d XP" % [h.level,h.xp],18))
	if h.uses_stats:
		var stats:=GridContainer.new();stats.columns=2
		stats.add_theme_constant_override("h_separation",16)
		_status_content.add_child(stats)
		for pair in [["Strength",h.stat_str],["Dexterity",h.stat_dex],["Vitality",h.stat_vit],["Resolve",h.stat_res]]:
			stats.add_child(_label("%s  %d" % pair,17))
	_status_content.add_child(_wrapped(_numbers(h,h.weapon)+" · armour %d · speed %d" % [h.damage_reduction(),h.effective_initiative()],17))
	_status_content.add_child(_label("Strain %d · %s" % [roundi(h.strain),StrainRules.NAMES[h.strain_state()]],18))
	var strain:=ProgressBar.new();strain.max_value=100;strain.value=h.strain
	strain.show_percentage=false;strain.custom_minimum_size.y=8
	strain.tooltip_text="Strain";_status_content.add_child(strain)
	if h.effectiveness()<1:
		_status_content.add_child(_wrapped("Hit chance and damage reduced to %d%%. Light, food and rest ease strain." % roundi(h.effectiveness()*100),17))
	if h.is_hungry():_status_content.add_child(_label("Hungry",18,Color("e7ad83")))
	if h.bleeding:_status_content.add_child(_label("Bleeding",18,Color("e7ad83")))
	for effect in h.pending_effects:
		_status_content.add_child(_wrapped("Healing: %d time remaining" % effect.units_left,17))
	for injury in h.injuries:
		_status_content.add_child(_wrapped("%s · %s. %s" % [injury.display_name,"dressed until camp" if injury in h.dressed else "untreated",injury.description],17))
	if _party.can_field_bind(h):
		var bind:=_button("Bind wound",Vector2(120,44))
		bind.tooltip_text="Field medic: without a dressing"
		bind.pressed.connect(func():
			if _party.can_field_bind(h) and _party.field_bind(h):
				used.emit("The field medic binds the wound without a dressing.")
				_request_refresh())
		_status_content.add_child(bind)
	for entry in h.boons:
		var boon:Boon=entry.boon
		_status_content.add_child(_wrapped("%s · %s\n%s" % [boon.display_name,boon.duration_text(entry.fights_left),boon.effects_text()],17))
	for slot in ["weapon","body","back","trinket"]:
		var item:Equipment=h.get(slot)
		if item and item.effect:_status_content.add_child(_wrapped(item.display_name+": "+item.effect.effects_text(),17))
		if item and item.curse:_status_content.add_child(_wrapped("Cursed: "+item.curse.display_name+" · "+item.curse.effects_text(),17,Color("c39ed5")))
	if h.trait_name!="":_status_content.add_child(_wrapped(h.trait_name+": "+h.trait_text,17))
	for text: String in [h.strength,h.weakness,h.backstory]:
		if text!="":_status_content.add_child(_wrapped(text,17,FieldKit.MUTED))

func _refresh_bag() -> void:
	_entries.clear()
	var s=_party.supplies
	for item: SupplyItem in s.items:
		var left:int=s.count(item)
		while left>0:
			var amount:=mini(left,item.stack_size())
			_entries.append({"item":item,"count":amount})
			left-=amount
	if s.open_flask>0:
		var oil:SupplyItem=load("res://data/items/oil_flask.tres")
		if not _entries.any(func(e):return e.item==oil):
			_entries.append({"item":oil,"count":0})
	for item: Equipment in s.gear:_entries.append({"item":item,"count":1})
	var pages:=_page_count()
	_page=clampi(_page,0,pages-1)
	_bag.clear_slots()
	for cell in PAGE_SIZE:
		var index:=_page*PAGE_SIZE+cell
		var button:=_button("",Vector2(44,44))
		button.set_meta("kit_focus","bag:"+str(index))
		for state in ["normal","disabled"]:
			button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover",FieldKit.plate(Color(0.3,0.24,0.13,0.32),FieldKit.AMBER,2))
		if index<_entries.size():
			var entry:=_entries[index]
			var item:Resource=entry.item
			button.accessibility_name=item.display_name+(" ×%d" % entry.count if entry.count>1 else "")
			button.tooltip_text=button.accessibility_name
			button.set_meta("item",item)
			_add_icon(button,item.icon,Quality.tier_of(item),Vector2(36,36))
			_bind_inspection(button,item)
			if entry.count!=1:
				var badge:=_label("×%d" % entry.count if entry.count>0 else "≈",15,FieldKit.AMBER)
				badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
				badge.offset_left=-35;badge.offset_top=-21;badge.offset_right=-3;badge.offset_bottom=-1
				badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
				badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
				button.add_child(badge)
		else:
			button.disabled=true
			button.accessibility_name="Empty compartment" if not s.is_limited() or index<s.capacity else "Beyond pack capacity"
			if s.is_limited() and index>=s.capacity:button.text="·";button.modulate.a=0.35
		_bag.add_slot(button)
	_capacity.text="%d / %d" % [s.slots_used(),s.capacity] if s.is_limited() else str(s.slots_used())
	_capacity.tooltip_text="Pack space"+(" · %d lost to a limp" % _party.pack_lost() if _party.pack_lost()>0 else "")
	_capacity.add_theme_color_override("font_color",Color("e7ad83") if s.is_limited() and s.slots_used()>s.capacity else FieldKit.MUTED)
	_clear(_pages)
	if pages>1:
		var previous:=_button("‹",Vector2(44,44));previous.disabled=_page==0
		previous.accessibility_name="Previous pack page";previous.pressed.connect(show_page.bind(_page-1));_pages.add_child(previous)
		_pages.add_child(_label("%d / %d" % [_page+1,pages],16))
		var next:=_button("›",Vector2(44,44));next.disabled=_page==pages-1
		next.accessibility_name="Next pack page";next.pressed.connect(show_page.bind(_page+1));_pages.add_child(next)
	_bag._fit()

func _bind_inspection(button: Button,item: Resource,slot := "") -> void:
	button.pressed.connect(inspect_item.bind(item,true,slot))
	button.mouse_entered.connect(inspect_item.bind(item,false,slot))
	button.focus_entered.connect(inspect_item.bind(item,false,slot))

func _add_icon(button: Button,texture: Texture2D,tier: String,extent: Vector2) -> void:
	var icon:=Quality.framed(texture,tier,extent)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left=5;icon.offset_right=-5;icon.offset_top=4;icon.offset_bottom=-4
	button.add_child(icon)

func _refresh_details() -> void:
	_clear(_detail_text)
	_clear(_detail_actions)
	_detail_icon.texture=null
	if _selection==null:
		return
	var item:=_selection
	_detail_icon.texture=item.icon
	var tier:=Quality.tier_of(item,_selected_hero if _from_slot!="" else null)
	_detail_text.add_child(_wrapped(("" if tier=="common" else tier.capitalize()+" · ")+item.display_name,21))
	var description:=_wrapped(item.description,17,FieldKit.MUTED)
	_detail_text.add_child(description)
	if _from_slot!="":
		if item is Equipment:
			if item.slot=="back":_detail_text.add_child(_wrapped(Equipment.back_text(item),17))
			elif item.effect:_detail_text.add_child(_wrapped(item.effect.effects_text(),17))
			if item.curse:_detail_text.add_child(_wrapped("Cursed: "+item.curse.effects_text()+". Holy water or the nurse can lift it.",17))
		_action("Take off","unequip",_unequip_reason())
		_detail_text.move_child(description,_detail_text.get_child_count()-1)
		return
	if item is Equipment:
		var now:Equipment=_selected_hero.get(item.slot) if _selected_hero else null
		var comparison:=""
		if _selected_hero:
			if item.slot=="weapon":comparison=_numbers(_selected_hero,now)+" → "+_numbers(_selected_hero,item)
			elif item.slot=="body":comparison=_armour(_selected_hero,now)+" → "+_armour(_selected_hero,item)
		if comparison!="":_detail_text.add_child(_wrapped(comparison,17))
		if now:_detail_text.add_child(_wrapped("Replaces "+now.display_name,17))
		if item.slot=="back":_detail_text.add_child(_wrapped("Worn: "+Equipment.back_text(item),17))
		elif item.effect:_detail_text.add_child(_wrapped("Worn: "+item.effect.effects_text(),17))
		_action("Wear" if item.slot=="trinket" else "Equip","equip",_equip_reason(item.slot))
	else:
		var charm:Equipment=Trinkets.for_treasure(item) if item.effect==SupplyItem.Effect.TREASURE else null
		if charm:
			_detail_text.add_child(_wrapped("Worn: "+charm.effect.effects_text(),17))
			_action("Wear","wear",_equip_reason("trinket"))
		else:
			var reason:String=_party.cannot_use_reason(item)
			var target:=_use_target(item)
			if target!="":_detail_text.add_child(_wrapped(target,17))
			_action("Use · %d time" % item.use_time,"use",reason)
	_action("Drop","drop")
	_detail_text.move_child(description,_detail_text.get_child_count()-1)

func _use_target(item: SupplyItem) -> String:
	match item.effect:
		SupplyItem.Effect.HEAL_ONE:
			var patient:Companion=_party.most_hurt()
			return "Treats "+patient.display_name+" (most hurt)" if patient else ""
		SupplyItem.Effect.DRESS_INJURY:
			var patient:Companion=_party.first_undressed_injured()
			return "Binds "+patient.display_name+"'s injury" if patient else ""
		SupplyItem.Effect.FEED_PARTY:return "Feeds the party"
		SupplyItem.Effect.REFILL_LANTERN:return "Refills the shared lantern"+(" · %d oil in the open flask" % roundi(_party.supplies.open_flask) if _party.supplies.open_flask>0 else "")
		SupplyItem.Effect.LIFT_BANE:
			for hero in _party.living_members():
				if hero.has_bane():return "Lifts a curse from "+hero.display_name
	return ""

func _equip_reason(slot: String) -> String:
	if _selected_hero==null or not _selected_hero.is_alive():return "Needs a conscious hero"
	var held:Equipment=_selected_hero.get(slot)
	if held and held.curse:return "Cursed · holy water or the nurse can lift it"
	return ""

func _unequip_reason() -> String:
	if _selected_hero==null or not _selected_hero.is_alive():return "Needs a conscious hero"
	var held:Equipment=_selected_hero.get(_from_slot)
	if held==null:return "Nothing worn"
	if held.curse:return "Cursed · holy water or the nurse can lift it"
	if _from_slot=="weapon" and _selected_hero.founder:return "Replace this weapon from the pack"
	return ""

func _action(title: String,kind: String,reason := "") -> void:
	var button:=_button(title,Vector2(76,44))
	button.set_meta("kit_focus","action:"+kind)
	button.accessibility_name=title
	button.disabled=reason!=""
	button.tooltip_text=reason
	var serial:=_serial
	var hero:=_selected_hero
	button.pressed.connect(func():
		if serial==_serial and hero==_selected_hero and reason=="":
			_perform(kind))
	_detail_actions.add_child(button)
	if reason!="":_detail_text.add_child(_wrapped(reason,17,FieldKit.MUTED))

func _perform(kind: String) -> void:
	if _selection==null or not _selection_available():return
	var item:=_selection
	var h:=_selected_hero
	match kind:
		"use":
			var message:String=_party.use_item(item)
			if message!="":used.emit(message)
		"wear":
			if _equip_reason("trinket")=="":used.emit(_party.wear_treasure(h,item))
		"equip":
			if _equip_reason(item.slot)!="":return
			if item.slot=="trinket":used.emit(_party.wear(h,item))
			else:
				_party.equip(h,item)
				if item.curse:
					used.emit("The %s bites into %s's hand. Cursed with %s — it won't come off." % [item.display_name.to_lower(),h.display_name,item.curse.display_name.to_lower()])
				else:
					used.emit(h.display_name+" equips "+item.display_name+".")
		"drop":
			if item is Equipment:_party.drop(item)
			else:_party.supplies.drop(item,1)
			used.emit("Left behind: "+item.display_name+".")
		"unequip":
			if _unequip_reason()!="":return
			if _from_slot=="trinket":_party.take_off_trinket(h)
			elif _from_slot=="back":_party.take_off_back(h)
			else:
				_party.supplies.gear.append(item)
				h.set(_from_slot,null)
				h.health=mini(h.health,h.effective_max_health())
				h.emit_changed()
				_party.supplies.changed.emit()
				_party.changed.emit()
			clear_inspection()
	_request_refresh()

func _numbers(hero: Companion,weapon: Equipment) -> String:
	var held:=hero.weapon
	hero.weapon=weapon
	var span:=hero.attack_range()
	var hit:=clampf(hero.hit_accuracy(),0.1,0.95)
	hero.weapon=held
	return "%s dmg, %d%% to hit" % [str(span.x) if span.x==span.y else "%d–%d" % [span.x,span.y],roundi(hit*100)]

func _armour(hero: Companion,armour: Equipment) -> String:
	return "armour %d, speed %d" % [armour.armour if armour else 0,hero.initiative-(armour.initiative_penalty if armour else 0)-(hero.back.initiative_penalty if hero.back else 0)]

func _button(title: String,minimum := Vector2(44,44)) -> Button:
	var button:=Button.new()
	button.text=title
	button.custom_minimum_size=minimum
	button.focus_mode=Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size",18)
	for state in ["normal","hover","pressed","disabled"]:
		var box:=button.get_theme_stylebox(state).duplicate()
		box.set_content_margin_all(6)
		button.add_theme_stylebox_override(state,box)
	return button

func _label(text: String,font_size:=18,color:=FieldKit.TEXT) -> Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

func _wrapped(text: String,font_size:=18,color:=FieldKit.TEXT) -> Label:
	var label:=_label(text,font_size,color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label

func _icon(texture: Texture2D,minimum: Vector2) -> TextureRect:
	var icon:=TextureRect.new()
	icon.texture=texture
	icon.custom_minimum_size=minimum
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return icon

func _header_icon(texture: Texture2D,title: String,callback: Callable) -> Button:
	var button:=_button("")
	button.icon=texture;button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",22)
	button.accessibility_name=title;button.tooltip_text=title
	button.pressed.connect(callback)
	return button

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var shade:=ColorRect.new()
	shade.color=Color("10140f")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	content=MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","top","right","bottom"]:content.add_theme_constant_override("margin_"+side,12)
	add_child(content)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	content.add_child(column)
	var header:=HBoxContainer.new()
	header.add_theme_constant_override("separation",8)
	column.add_child(header)
	var title:=_label("Field kit",26)
	title.theme_type_variation="PageTitle"
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	header.add_child(title)
	header.add_child(_icon(COIN_ICON,Vector2(20,20)))
	_time_label=_label("");_time_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	header.add_child(_time_label)
	_light_icon=_icon(LANTERN_ICON,Vector2(30,36));header.add_child(_light_icon)
	var light:=VBoxContainer.new();light.size_flags_vertical=Control.SIZE_SHRINK_CENTER;header.add_child(light)
	_light_title=_label("");_light_title.visible=false;light.add_child(_light_title)
	_lantern_label=_label("",16);light.add_child(_lantern_label)
	_lantern_bar=ProgressBar.new();_lantern_bar.show_percentage=false;_lantern_bar.custom_minimum_size=Vector2(98,8)
	light.add_child(_lantern_bar)
	_light_note=_label("");_light_note.visible=false;light.add_child(_light_note)
	var save:=_button("Save & exit",Vector2(102,44));save.pressed.connect(func():save_and_exit.emit());header.add_child(save)
	header.add_child(_header_icon(JOURNAL_ICON,"Quest journal",func():open_quests.emit()))
	header.add_child(_header_icon(SETTINGS_ICON,"Settings",func():open_settings.emit()))
	_close=_header_icon(CLOSE_ICON,"Close pack",func():closed.emit());header.add_child(_close)
	var workspace:=HBoxContainer.new();workspace.size_flags_vertical=Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation",20);column.add_child(workspace)
	var left:=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.size_flags_stretch_ratio=1.0
	left.add_theme_constant_override("separation",4);workspace.add_child(left)
	_hero_row=HBoxContainer.new();_hero_row.add_theme_constant_override("separation",6);left.add_child(_hero_row)
	_hero_summary=_label("",17,FieldKit.MUTED);left.add_child(_hero_summary)
	var tabs:=HBoxContainer.new();left.add_child(tabs)
	_equip_tab=_button("Equipment");_equip_tab.toggle_mode=true;_equip_tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_equip_tab.pressed.connect(set_status.bind(false));tabs.add_child(_equip_tab)
	_status_tab=_button("Status");_status_tab.toggle_mode=true;_status_tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_status_tab.pressed.connect(set_status.bind(true));tabs.add_child(_status_tab)
	var panel:=Control.new();panel.size_flags_vertical=Control.SIZE_EXPAND_FILL;left.add_child(panel)
	_equipment=Control.new();_equipment.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_child(_equipment)
	_equipment.resized.connect(func():
		if is_instance_valid(_equipment_slots):_equipment_slots.columns=2 if _equipment.size.y>=145 else 4)
	var roll:=_icon(ROLL,Vector2.ZERO);roll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_equipment.add_child(roll)
	roll.stretch_mode=TextureRect.STRETCH_SCALE
	roll.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_equipment_slots=GridContainer.new();_equipment_slots.columns=2
	_equipment_slots.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_equipment_slots.anchor_left=0.02;_equipment_slots.anchor_right=0.98
	_equipment_slots.anchor_top=0.06;_equipment_slots.anchor_bottom=0.94
	_equipment_slots.offset_top=0;_equipment_slots.offset_bottom=0
	_equipment_slots.add_theme_constant_override("h_separation",6)
	_equipment_slots.add_theme_constant_override("v_separation",4)
	_equipment.add_child(_equipment_slots)
	_status_scroll=ScrollContainer.new();_status_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_status_scroll.follow_focus=true;panel.add_child(_status_scroll)
	_status_content=VBoxContainer.new();_status_content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_status_content.add_theme_constant_override("separation",8);_status_scroll.add_child(_status_content)
	_inventory_scroll=_status_scroll;_injuries=_status_content
	var right:=Control.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.size_flags_stretch_ratio=1.0;workspace.add_child(right)
	_bag=BagView.new();_bag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);right.add_child(_bag)
	_bag.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var lower:=HBoxContainer.new();lower.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);lower.offset_top=-44
	lower.add_theme_constant_override("separation",8);right.add_child(lower)
	_capacity=_label("",17);_capacity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_capacity.size_flags_vertical=Control.SIZE_SHRINK_CENTER;lower.add_child(_capacity)
	_pages=HBoxContainer.new();lower.add_child(_pages)
	_details=PanelContainer.new();_details.custom_minimum_size=Vector2(0,116)
	_details.add_theme_stylebox_override("panel",FieldKit.plate(Color("191d17"),FieldKit.EDGE,8))
	column.add_child(_details)
	var detail_row:=HBoxContainer.new();detail_row.add_theme_constant_override("separation",12);_details.add_child(detail_row)
	_detail_icon=_icon(null,Vector2(56,56));detail_row.add_child(_detail_icon)
	var detail_scroll:=ScrollContainer.new();detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;detail_scroll.follow_focus=true
	detail_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail_row.add_child(detail_scroll)
	_detail_text=VBoxContainer.new();_detail_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_detail_text.add_theme_constant_override("separation",3);detail_scroll.add_child(_detail_text)
	_detail_actions=HBoxContainer.new();_detail_actions.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	_detail_actions.add_theme_constant_override("separation",6);detail_row.add_child(_detail_actions)
	_list=self
