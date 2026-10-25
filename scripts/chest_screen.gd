extends "res://scripts/kit_exchange.gd"
## Loot left, the real physical backpack right; explicit moves and drag transfer.
signal took(item,quantity:int)
var contents:Dictionary={}
var _party
var _chest_grid:GridContainer
var _pack_grid:Control
var _pack_panel:Control
var _pack_heading:Label

func _init() -> void:
	super()
	_chest_grid=_left_grid;_pack_grid=_bag;_pack_panel=_bag_panel;_pack_heading=_space
	requested.connect(func(entry:Dictionary,side:String):
		if side=="left":take(entry.item)
		else:put_back(entry.item))
	take_all_requested.connect(take_all)
	visible=false

func open(title:String,items:Dictionary,party_state) -> void:
	if _party and _party.supplies.changed.is_connected(_request_refresh):
		_party.supplies.changed.disconnect(_request_refresh)
	_party=party_state
	_party.supplies.changed.connect(_request_refresh)
	contents=items.duplicate()
	_title.text=title
	_left_title.text="Contents";_empty.text="Empty"
	_bag_page=0;clear_inspection()
	visible=true;refresh()

func _request_refresh() -> void:
	refresh.call_deferred()

func is_empty() -> bool:
	return contents.values().all(func(n):return n<=0)

func take(item) -> void:
	var quantity:int=contents.get(item,0)
	if quantity<=0:return
	if item is Equipment:
		var fits:=0
		while fits<quantity and _party.supplies.has_room_for_gear():
			_party.supplies.gear.append(item);fits+=1
		if fits==0:return
		if fits==quantity:contents.erase(item)
		else:contents[item]=quantity-fits
		_party.supplies.changed.emit()
		took.emit(item,fits)
	else:
		var fits:int=_party.supplies.add_what_fits(item,quantity)
		if fits>=quantity:contents.erase(item)
		else:contents[item]=quantity-fits
		if fits>0:took.emit(item,fits)
	refresh()

func put_back(item) -> void:
	if item is Equipment:
		if item in _party.supplies.gear:
			_party.supplies.gear.erase(item)
			_party.supplies.changed.emit()
			contents[item]=contents.get(item,0)+1
	else:
		var held:int=_party.supplies.count(item)
		var stack:int=item.stack_size()
		var dropped:int=_party.supplies.drop(item,held%stack if held%stack!=0 else stack)
		if dropped>0:contents[item]=contents.get(item,0)+dropped
	refresh()

func take_all() -> void:
	for item in contents.keys():take(item)

func refresh() -> void:
	if _party==null or not visible:return
	var supplies=_party.supplies
	var left:Array[Dictionary]=[]
	for item in contents:
		var count:int=contents[item]
		if count<=0:continue
		var fits:int=mini(count,maxi(0,supplies.capacity-supplies.slots_used())) if item is Equipment and supplies.is_limited() else (count if item is Equipment else mini(count,supplies.room_for(item)))
		left.append({"key":item,"item":item,"count":count,"action":"Take %d" % fits if fits>1 else "Take","kind":"take","reason":"Your pack is full" if fits<=0 else "","info":"%d available · %d fit" % [count,fits] if fits>0 and fits<count else ""})
	var bag:=inventory(supplies)
	for entry in bag:
		var item:Resource=entry.item
		var held:int=supplies.count(item) if item is SupplyItem else 1
		var count:int=(held%item.stack_size() if held%item.stack_size()!=0 else item.stack_size()) if item is SupplyItem else 1
		entry.action="Leave %d" % count if count>1 else "Leave"
		entry.kind="leave"
		entry.reason="The open flask stays with the lantern" if entry.get("open_flask",false) else ""
		entry.info="Leaves the part-full stack first" if item is SupplyItem and held>item.stack_size() and held%item.stack_size()!=0 else ""
	set_view(left,bag,supplies.slots_used(),supplies.capacity,supplies.gold)
	_take_all.disabled=not left.any(func(e):return e.reason=="")
	for button:Button in _left_grid.get_children():
		var item:Resource=button.get_meta("item")
		button.set_drag_forwarding(func(_at):return _start_drag(item),Callable(),Callable())
	_bag_panel.set_drag_forwarding(Callable(),_can_drop_on_pack,_drop_on_pack)
	_bag.set_drag_forwarding(Callable(),_can_drop_on_pack,_drop_on_pack)
	for button:Button in _bag.slots:
		button.set_drag_forwarding(Callable(),_can_drop_on_pack,_drop_on_pack)

func _start_drag(item:Resource) -> Variant:
	if contents.get(item,0)<=0:return null
	var preview:=_icon(item.icon,Vector2(72,72));preview.modulate.a=0.85
	set_drag_preview(preview)
	return {"chest_item":item}

func _can_drop_on_pack(_at:Vector2,data:Variant) -> bool:
	return data is Dictionary and data.has("chest_item") and contents.get(data.chest_item,0)>0

func _drop_on_pack(at:Vector2,data:Variant) -> void:
	if _can_drop_on_pack(at,data):take(data.chest_item)
