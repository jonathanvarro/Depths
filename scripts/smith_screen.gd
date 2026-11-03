extends "res://scripts/kit_exchange.gd"
## The apprentice smith (owner, 2026-10-31): the same Field kit exchange as
## the merchant. Today's wares on the left - a few pieces, no scrolling, new
## each day (CampState.smith_wares) - and the pack on the right, where the
## smith buys gear back. The forge offer is the extra button.
const CampState:=preload("res://scripts/camp_state.gd")
const Sounds:=preload("res://scripts/sounds.gd")
var _camp
var _party
var _pending:=false
var _temper_menu:PopupMenu
var _temper_choices:Array=[]  # [item, option id] by menu index
var _identify:Button  # reading unidentified pieces (owner, 2026-11-03)
var _identify_menu:PopupMenu
var _identify_choices:Array=[]  # item by menu index
var _read_note:Label  # what the last piece turned out to be

func _init() -> void:
	super()
	_take_all.visible=false
	requested.connect(_trade)
	extra_requested.connect(func():
		if _camp and _camp.forge_offered():_camp.build_forge(_party)
		elif _camp:_show_temper()
		refresh())
	_temper_menu=PopupMenu.new()
	_temper_menu.id_pressed.connect(_on_temper)
	add_child(_temper_menu)
	_identify=_button("")
	_identify.tooltip_text="The smith reads what a found piece hides: its properties, and any curse."
	_identify.pressed.connect(_show_identify)
	_extra.add_sibling(_identify)
	_identify_menu=PopupMenu.new()
	_identify_menu.id_pressed.connect(_on_identify)
	add_child(_identify_menu)
	_read_note=_wrapped("",17,FieldKit.AMBER);_read_note.visible=false
	_extra.get_parent().add_sibling(_read_note)
	visible=false

func open(camp,party) -> void:
	if _camp and _camp.changed.is_connected(_request_refresh):_camp.changed.disconnect(_request_refresh)
	if _party and _party.supplies.changed.is_connected(_request_refresh):_party.supplies.changed.disconnect(_request_refresh)
	_camp=camp;_party=party
	_camp.changed.connect(_request_refresh);_party.supplies.changed.connect(_request_refresh)
	_portrait.texture=load("res://art/camp/highres-v4/apprentice.png");_portrait.visible=true
	_portrait.tooltip_text="It's not much. But it'll hold."
	_bag_page=0;clear_inspection();_read_note.visible=false;visible=true;refresh()

func _request_refresh() -> void:
	if not _pending:_pending=true;refresh.call_deferred()

func refresh() -> void:
	_pending=false
	if not visible or _party==null or _camp==null:return
	var supplies=_party.supplies
	_title.text="Smith · the forge" if _camp.forge_built else "Apprentice smith"
	_left_title.text="Today's work"
	_empty.text="Sold out for today.\nNew work tomorrow."
	var ready:=_ready_to_temper()
	if _camp.forge_offered():
		_extra.text="Build a forge · %d"%CampState.FORGE_PRICE
		_extra.visible=true
		_extra.disabled=supplies.gold<CampState.FORGE_PRICE
		_extra.tooltip_text="With proper iron, he could build a forge: finer work, and pieces with something extra."
	else:
		# Tempering (#173): gear at mastery 3 or 6, worn or carried.
		_extra.text="Temper (%d ready)"%ready.size()
		_extra.visible=not ready.is_empty()
		_extra.disabled=false
		_extra.tooltip_text="The smith turns mastery into one chosen improvement, for gold and the piece's own region's material."
	var unread:Array=_party.unidentified()
	_identify.text="Identify (%d)"%unread.size()
	_identify.visible=not unread.is_empty()
	var stock:Array[Dictionary]=[]
	for item:Equipment in _camp.smith_wares():
		var price:int=CampState.price_for(_party,item.price)
		stock.append({"key":item,"item":item,"price":price,"kind":"buy","action":"Buy · %d"%price,"reason":_buy_reason(price),"info":_summary(item)})
	var bag:=inventory(supplies)
	for entry in bag:
		var item:Resource=entry.item
		entry.kind="sell"
		entry.action="Sell"
		entry.reason="" if item is Equipment else "The smith only buys weapons and armour"
		if item is Equipment:
			entry.price=CampState.sell_price(_party,item)
			entry.action="Sell · %d"%entry.price
	set_view(stock,bag,supplies.slots_used(),supplies.capacity,supplies.gold)

## Everything the party holds that's due a temper.
func _ready_to_temper() -> Array:
	var GearModel:=load("res://scripts/gear_model.gd")
	return GearModel.owned_by(_party).filter(func(i):return GearModel.temper_due(i)>0)

func _show_temper() -> void:
	var GearModel:=load("res://scripts/gear_model.gd")
	_temper_menu.clear();_temper_choices.clear()
	for item:Equipment in _ready_to_temper():
		var owner:=""
		for hero in _party.members:
			if item in [hero.weapon,hero.body,hero.back]:owner=hero.display_name+"'s "
		var cost:Dictionary=GearModel.temper_cost(item)
		var material:SupplyItem=load("res://data/items/%s.tres"%cost["material_id"])
		var label:String=item.display_name.to_lower() if owner!="" else item.display_name
		for option in GearModel.temper_options(item):
			_temper_menu.add_item("%s%s: %s (%dg, %d %s)"%[owner,label,option["text"],CampState.price_for(_party,cost["gold"]),cost["material"],material.display_name.to_lower()],_temper_choices.size())
			_temper_choices.append([item,option["id"]])
	_temper_menu.reset_size()
	_temper_menu.popup_centered()

func _show_identify() -> void:
	_identify_menu.clear();_identify_choices.clear()
	for item:Equipment in _party.unidentified():
		var owner:=""
		for hero in _party.members:
			if item in [hero.weapon,hero.body,hero.back]:owner=hero.display_name+"'s "
		_identify_menu.add_item("%s%s (%dg)"%[owner,item.display_name.to_lower() if owner!="" else item.display_name,_camp.identify_price(_party,item)],_identify_choices.size())
		_identify_choices.append(item)
	_identify_menu.reset_size()
	_identify_menu.popup_centered()

func _on_identify(id:int) -> void:
	var item:Equipment=_identify_choices[id]
	var text:String=_camp.identify(_party,item)
	if text.begins_with("Identified"):Sounds.play(self,"purchase",-7.0)
	_read_note.text=text;_read_note.visible=true
	refresh()
	if item in _party.supplies.gear:select_item(item,"right",true)  # its card, read

func _on_temper(id:int) -> void:
	var choice:Array=_temper_choices[id]
	var why:String=_camp.temper(_party,choice[0],choice[1])
	if why=="":Sounds.play(self,"purchase",-7.0)
	else:_extra.tooltip_text=why;_empty.text=why
	refresh()

## The numbers that matter, in a line.
func _summary(item:Equipment) -> String:
	match item.slot:
		"weapon":
			var acc:="" if is_zero_approx(item.accuracy_bonus) else ", %+d%% to hit"%roundi(item.accuracy_bonus*100)
			return "%d-%d damage%s"%[item.attack_min,item.attack_max,acc]
		"body":
			return "armour %d%s"%[item.armour,", slower by %d"%item.initiative_penalty if item.initiative_penalty>0 else ""]
	return Equipment.back_text(item)

func _buy_reason(price:int) -> String:
	if not _party.supplies.has_room_for_gear():return "Your pack is full"
	if _party.supplies.gold<price:return "Need %d more gold"%(price-_party.supplies.gold)
	return ""

func _trade(entry:Dictionary,side:String) -> void:
	var before:int=_party.supplies.gold
	if side=="left" and entry.get("item") is Equipment:
		_camp.buy_gear(_party,entry.item)
	elif side=="right" and entry.get("item") is Equipment:
		_camp.sell_gear(_party,entry.item,true)
	if _party.supplies.gold<before:Sounds.play(self,"purchase",-7.0)
	elif _party.supplies.gold>before:Sounds.play(self,"coins",-7.0)
	refresh()
