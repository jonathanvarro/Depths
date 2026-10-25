extends Control
## Shared Field kit presentation for loot and trade; controllers own the rules.
signal closed
signal requested(entry: Dictionary, side: String)
signal take_all_requested
signal extra_requested

const BagView:=preload("res://scripts/kit_bag.gd")
const Quality:=preload("res://scripts/quality.gd")
const FieldKit:=preload("res://art/ui/field-kit-v1/style.gd")
const ROLL:=preload("res://art/ui/physical-kit-v1/roll.png")
const COIN:=preload("res://art/symbols/crest-v1/currency-coin.svg")
const CLOSE:=preload("res://art/ui/controls-v1/close.svg")
const TAKE_ALL:=preload("res://art/ui/physical-kit-v1/take-all.svg")

var content: MarginContainer
var _left_entries:Array[Dictionary]=[]
var _bag_entries:Array[Dictionary]=[]
var _capacity_value:=-1
var _bag_page:=0
var _key:Variant=null
var _side:=""
var _pinned:=false
var _serial:=0
var _title:Label
var _portrait:TextureRect
var _gold:Label
var _close:Button
var _left_title:Label
var _left_scroll:ScrollContainer
var _left_grid:GridContainer
var _empty:Label
var _bag:Control
var _bag_panel:Control
var _space:Label
var _pages:HBoxContainer
var _details:PanelContainer
var _detail_text:VBoxContainer
var _detail_icon:TextureRect
var _detail_actions:HBoxContainer
var _primary:Button
var _take_all:Button
var _extra:Button

static func inventory(supplies) -> Array[Dictionary]:
	var entries:Array[Dictionary]=[]
	for item:SupplyItem in supplies.items:
		var left:int=supplies.count(item)
		while left>0:
			var count:=mini(left,item.stack_size())
			entries.append({"key":item,"item":item,"count":count})
			left-=count
	if supplies.open_flask>0:
		var oil:SupplyItem=load("res://data/items/oil_flask.tres")
		if not entries.any(func(e):return e.item==oil):entries.append({"key":oil,"item":oil,"count":0,"open_flask":true})
	for item:Equipment in supplies.gear:entries.append({"key":item,"item":item,"count":1})
	return entries

func _init() -> void:
	_build()
	visibility_changed.connect(func():
		if visible:_close.grab_focus.call_deferred()
		else:clear_inspection())

func _unhandled_input(event:InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		if _key!=null:clear_inspection()
		else:closed.emit()
		get_viewport().set_input_as_handled()

func clear_inspection() -> void:
	_key=null;_side="";_pinned=false;_serial+=1
	if _detail_text:_show_details();_mark_selection()

func select_item(key:Variant,side:String,pin:=true) -> void:
	if not pin and _pinned:return
	_key=key;_side=side;_pinned=pin;_serial+=1
	_show_details();_mark_selection()

func _mark_selection() -> void:
	for button:Button in _left_grid.get_children()+_bag.slots:
		if button.has_meta("exchange_key"):
			var key=button.get_meta("exchange_key")
			button.set_pressed_no_signal(typeof(key)==typeof(_key) and key==_key and button.get_meta("exchange_side")==_side)

func selected_entry() -> Dictionary:
	for entry in (_left_entries if _side=="left" else _bag_entries):
		if typeof(entry.key)==typeof(_key) and entry.key==_key:return entry
	return {}

func show_page(page:int) -> void:
	_bag_page=clampi(page,0,_page_count()-1)
	clear_inspection();_render_bag()

func _page_count() -> int:
	return maxi(1,ceili(float(maxi(_bag_entries.size(),_capacity_value))/12.0))

func set_view(left:Array[Dictionary],bag:Array[Dictionary],used_slots:int,capacity:int,gold:int) -> void:
	var action_focused:bool=is_instance_valid(_primary) and _primary.has_focus()
	_left_entries=left;_bag_entries=bag;_capacity_value=capacity
	_serial+=1
	if _key!=null and selected_entry().is_empty():clear_inspection()
	_gold.text=str(gold)
	_space.text="%d / %d" % [used_slots,capacity] if capacity>=0 else str(used_slots)
	_space.tooltip_text="Pack space"
	_space.add_theme_color_override("font_color",Color("e7ad83") if capacity>=0 and used_slots>capacity else FieldKit.MUTED)
	_render_left();_render_bag();_show_details();_mark_selection()
	if action_focused:_restore_action_focus.call_deferred()

func _restore_action_focus() -> void:
	if not is_visible_in_tree():return
	if _primary and _primary.is_inside_tree():_primary.grab_focus()
	else:_close.grab_focus()

func _clear(node:Node) -> void:
	for child in node.get_children():node.remove_child(child);child.queue_free()

func _name(entry:Dictionary) -> String:
	return entry.get("name",entry.item.display_name if entry.get("item") else "")

func _description(entry:Dictionary) -> String:
	return entry.get("description",entry.item.description if entry.get("item") else "")

func _texture(entry:Dictionary) -> Texture2D:
	return entry.get("icon",entry.item.icon if entry.get("item") else null)

func _tier(entry:Dictionary) -> String:
	return Quality.tier_of(entry.item) if entry.get("item") else "common"

func _properties(entry:Dictionary) -> String:
	var item:Resource=entry.get("item")
	if not item is Equipment:return ""
	var parts:=PackedStringArray()
	if item.slot=="weapon":
		parts.append("Base damage %d–%d · accuracy %+.0f%%"%[item.attack_min,item.attack_max,item.accuracy_bonus*100])
		if item.reach:parts.append("Reaches the back row")
	elif item.slot=="body":parts.append("Armour %d · speed −%d"%[item.armour,item.initiative_penalty])
	elif item.slot=="back":parts.append(Equipment.back_text(item))
	if item.effect and item.slot!="back":parts.append(item.effect.effects_text())
	return " · ".join(parts)

func _render_left() -> void:
	_clear(_left_grid)
	_empty.visible=_left_entries.is_empty()
	_left_scroll.visible=not _left_entries.is_empty()
	for entry in _left_entries:_left_grid.add_child(_tile(entry,"left"))
	_fit_stock()

func _fit_stock() -> void:
	_left_grid.columns=clampi(floori((_left_scroll.size.x+6)/70),1,4)
	var height:=floorf(clampf((_left_scroll.size.x-6*(_left_grid.columns-1))/_left_grid.columns,64,104))
	for button:Button in _left_grid.get_children():button.custom_minimum_size.y=height

func _render_bag() -> void:
	_bag.clear_slots();_clear(_pages)
	_bag_page=clampi(_bag_page,0,_page_count()-1)
	for cell in 12:
		var index:=_bag_page*12+cell
		var button:Button
		if index<_bag_entries.size():button=_tile(_bag_entries[index],"right")
		else:
			button=_button("",Vector2(44,44));button.disabled=true
			button.accessibility_name="Empty compartment" if _capacity_value<0 or index<_capacity_value else "Beyond pack capacity"
			button.add_theme_stylebox_override("disabled",StyleBoxEmpty.new())
			if _capacity_value>=0 and index>=_capacity_value:button.text="·";button.modulate.a=0.35
		_bag.add_slot(button)
	if _page_count()>1:
		var prev:=_button("‹",Vector2(44,44));prev.disabled=_bag_page==0
		prev.accessibility_name="Previous pack page";prev.pressed.connect(show_page.bind(_bag_page-1));_pages.add_child(prev)
		_pages.add_child(_label("%d / %d" % [_bag_page+1,_page_count()],16))
		var next:=_button("›",Vector2(44,44));next.disabled=_bag_page==_page_count()-1
		next.accessibility_name="Next pack page";next.pressed.connect(show_page.bind(_bag_page+1));_pages.add_child(next)
	_bag._fit()

func _tile(entry:Dictionary,side:String) -> Button:
	var button:=_button("",Vector2(64,64) if side=="left" else Vector2(44,44))
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.accessibility_name=_name(entry)
	button.toggle_mode=true
	button.tooltip_text=button.accessibility_name
	button.set_meta("exchange_key",entry.key);button.set_meta("exchange_side",side)
	button.set_meta("item",entry.get("item"))
	button.add_theme_stylebox_override("normal",FieldKit.plate(Color(0.04,0.045,0.03,0.20),Color(0.39,0.32,0.23,0.4),2) if side=="left" else StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover",FieldKit.plate(Color(0.30,0.24,0.13,0.3),FieldKit.AMBER,2))
	var icon:=Quality.framed(_texture(entry),_tier(entry),Vector2(32,32))
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left=5;icon.offset_right=-5;icon.offset_top=4;icon.offset_bottom=-5
	if side=="left" and entry.has("price"):icon.offset_bottom=-22
	button.add_child(icon)
	var count:int=entry.get("count",1)
	if count!=1 and not (side=="left" and entry.has("price")):
		var badge:=_label("×%d" % count if count>0 else "≈",15,FieldKit.AMBER)
		badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		badge.offset_left=-35;badge.offset_top=-21;badge.offset_right=-3;badge.offset_bottom=-1
		badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;button.add_child(badge)
	if side=="left" and entry.has("price"):
		var price:=HBoxContainer.new();price.mouse_filter=Control.MOUSE_FILTER_IGNORE
		price.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);price.offset_top=-22
		price.alignment=BoxContainer.ALIGNMENT_CENTER
		price.add_child(_icon(COIN,Vector2(14,14)))
		price.add_child(_label(str(entry.price),15,FieldKit.AMBER))
		button.add_child(price)
	button.pressed.connect(select_item.bind(entry.key,side,true))
	button.mouse_entered.connect(select_item.bind(entry.key,side,false))
	button.focus_entered.connect(select_item.bind(entry.key,side,false))
	return button

func _show_details() -> void:
	_clear(_detail_text);_clear(_detail_actions);_detail_icon.texture=null;_primary=null
	var entry:=selected_entry()
	if _key==null or entry.is_empty():return
	_detail_icon.texture=_texture(entry)
	var tier:=_tier(entry)
	_detail_text.add_child(_wrapped((tier.capitalize()+" · " if tier!="common" else "")+_name(entry),21))
	var properties:=_properties(entry)
	if properties!="":_detail_text.add_child(_wrapped(properties,17))
	if entry.get("info","")!="":_detail_text.add_child(_wrapped(entry.info,17))
	var reason:String=entry.get("reason","")
	if reason!="":_detail_text.add_child(_wrapped(reason,17,FieldKit.MUTED))
	_detail_text.add_child(_wrapped(_description(entry),17,FieldKit.MUTED))
	_primary=_button(entry.get("action","Take"),Vector2(120,44))
	_primary.disabled=reason!="";_primary.tooltip_text=reason
	_primary.set_meta("exchange_action",entry.get("kind","take"))
	if entry.has("price"):_primary.icon=COIN;_primary.expand_icon=true;_primary.add_theme_constant_override("icon_max_width",16)
	var serial:=_serial;var side:=_side
	_primary.pressed.connect(func():
		if serial==_serial and reason=="" and not selected_entry().is_empty():requested.emit(entry,side))
	_detail_actions.add_child(_primary)

func _button(text:String,minimum:=Vector2(44,44)) -> Button:
	var button:=Button.new();button.text=text;button.custom_minimum_size=minimum
	button.focus_mode=Control.FOCUS_ALL;button.add_theme_font_size_override("font_size",18)
	for state in ["normal","hover","pressed","disabled"]:
		var box:=button.get_theme_stylebox(state).duplicate();box.set_content_margin_all(6)
		button.add_theme_stylebox_override(state,box)
	return button

func _label(text:String,font_size:=18,color:=FieldKit.TEXT) -> Label:
	var label:=Label.new();label.text=text
	label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",color)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

func _wrapped(text:String,font_size:=18,color:=FieldKit.TEXT) -> Label:
	var label:=_label(text,font_size,color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label

func _icon(texture:Texture2D,minimum:Vector2) -> TextureRect:
	var icon:=TextureRect.new();icon.texture=texture;icon.custom_minimum_size=minimum
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return icon

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	var shade:=ColorRect.new();shade.color=Color("10140f");shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
	content=MarginContainer.new();content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","top","right","bottom"]:content.add_theme_constant_override("margin_"+side,12)
	add_child(content)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);content.add_child(column)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",8);column.add_child(header)
	_portrait=_icon(null,Vector2(48,48));_portrait.visible=false;_portrait.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;header.add_child(_portrait)
	_title=_label("Finds",26);_title.theme_type_variation="PageTitle";_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_title.size_flags_vertical=Control.SIZE_SHRINK_CENTER;header.add_child(_title)
	header.add_child(_icon(COIN,Vector2(20,20)))
	_gold=_label("0");_gold.size_flags_vertical=Control.SIZE_SHRINK_CENTER;header.add_child(_gold)
	_extra=_button("");_extra.visible=false;_extra.pressed.connect(func():extra_requested.emit());header.add_child(_extra)
	_take_all=_button("");_take_all.icon=TAKE_ALL;_take_all.expand_icon=true
	_take_all.add_theme_constant_override("icon_max_width",28);_take_all.accessibility_name="Take everything that fits"
	_take_all.tooltip_text="Take everything that fits";_take_all.pressed.connect(func():take_all_requested.emit());header.add_child(_take_all)
	_close=_button("");_close.icon=CLOSE;_close.expand_icon=true;_close.add_theme_constant_override("icon_max_width",22)
	_close.accessibility_name="Close";_close.tooltip_text="Close";_close.pressed.connect(func():closed.emit());header.add_child(_close)
	var workspace:=HBoxContainer.new();workspace.size_flags_vertical=Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation",20);column.add_child(workspace)
	var left:=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.size_flags_stretch_ratio=1
	left.add_theme_constant_override("separation",6);workspace.add_child(left)
	_left_title=_label("Contents",19,FieldKit.MUTED);left.add_child(_left_title)
	var display:=Control.new();display.size_flags_vertical=Control.SIZE_EXPAND_FILL;left.add_child(display)
	var roll:=_icon(ROLL,Vector2.ZERO);roll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	roll.stretch_mode=TextureRect.STRETCH_SCALE;roll.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;display.add_child(roll)
	_left_scroll=ScrollContainer.new();_left_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_left_scroll.anchor_left=0.17;_left_scroll.anchor_right=0.9;_left_scroll.anchor_top=0.22;_left_scroll.anchor_bottom=0.84
	_left_scroll.resized.connect(_fit_stock)
	_left_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_left_scroll.follow_focus=true;display.add_child(_left_scroll)
	_left_grid=GridContainer.new();_left_grid.columns=4;_left_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_left_grid.add_theme_constant_override("h_separation",6);_left_grid.add_theme_constant_override("v_separation",6)
	_left_scroll.add_child(_left_grid)
	_empty=_label("Empty",22,FieldKit.MUTED);_empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	display.add_child(_empty)
	_bag_panel=Control.new();_bag_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_bag_panel.size_flags_stretch_ratio=1
	workspace.add_child(_bag_panel)
	_bag=BagView.new();_bag.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_bag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_bag_panel.add_child(_bag)
	var lower:=HBoxContainer.new();lower.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);lower.offset_top=-44
	_bag_panel.add_child(lower)
	_space=_label("",17,FieldKit.MUTED);_space.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_space.size_flags_vertical=Control.SIZE_SHRINK_CENTER;lower.add_child(_space)
	_pages=HBoxContainer.new();lower.add_child(_pages)
	_details=PanelContainer.new();_details.custom_minimum_size=Vector2(0,100)
	_details.add_theme_stylebox_override("panel",FieldKit.plate(Color("191d17"),FieldKit.EDGE,8));column.add_child(_details)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);_details.add_child(row)
	_detail_icon=_icon(null,Vector2(56,56));row.add_child(_detail_icon)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.follow_focus=true;row.add_child(scroll)
	_detail_text=VBoxContainer.new();_detail_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_detail_text.add_theme_constant_override("separation",3);scroll.add_child(_detail_text)
	_detail_actions=HBoxContainer.new();_detail_actions.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(_detail_actions)
