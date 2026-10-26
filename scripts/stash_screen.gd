extends "res://scripts/kit_exchange.gd"
## The tent's stash (owner, 2026-10-25): what stays safe at camp, beside
## the pack, on the shared Field kit exchange. One tap moves one item (or
## all the gold) across; a full pack says so.
const COIN_ICON:=preload("res://art/symbols/crest-v1/currency-coin.svg")
const Sounds:=preload("res://scripts/sounds.gd")
var _camp
var _party
var _pending:=false

func _init() -> void:
	super()
	_take_all.visible=false
	_extra.visible=false
	requested.connect(_move)
	visible=false

func open(camp,party) -> void:
	if _camp and _camp.changed.is_connected(_request_refresh):_camp.changed.disconnect(_request_refresh)
	if _party and _party.supplies.changed.is_connected(_request_refresh):_party.supplies.changed.disconnect(_request_refresh)
	_camp=camp;_party=party
	_camp.changed.connect(_request_refresh);_party.supplies.changed.connect(_request_refresh)
	_portrait.visible=false
	_bag_page=0;clear_inspection();visible=true;refresh()

func _request_refresh() -> void:
	if not _pending:_pending=true;refresh.call_deferred()

func refresh() -> void:
	_pending=false
	if not visible or _party==null or _camp==null:return
	var supplies=_party.supplies
	var stash=_camp.stash
	_title.text="Stash"
	_left_title.text="Safe at camp"
	_empty.text="Nothing stored yet."
	var left:Array[Dictionary]=[]
	if stash.gold>0:
		left.append({"key":"stash_gold","item":null,"name":"Gold","icon":COIN_ICON,"count":stash.gold,"kind":"take","action":"Take all gold","description":"Stored gold is safe, whatever happens down there."})
	for item:SupplyItem in stash.items:
		if stash.count(item)>0:
			left.append({"key":item,"item":item,"count":stash.count(item),"kind":"take","action":"Take 1","reason":"" if supplies.room_for(item)>0 else "Your pack is full"})
	for gear:Equipment in stash.gear:
		left.append({"key":gear,"item":gear,"count":1,"kind":"take","action":"Take","reason":"" if supplies.has_room_for_gear() else "Your pack is full"})
	var bag:=inventory(supplies)
	for entry in bag:
		entry.kind="store"
		entry.action="Store 1" if entry.item is SupplyItem else "Store"
		entry.reason="An open flask stays with the lantern" if entry.get("open_flask",false) else ""
	if supplies.gold>0:
		bag.insert(0,{"key":"pack_gold","item":null,"name":"Gold","icon":COIN_ICON,"count":supplies.gold,"kind":"store","action":"Store all gold","description":"Gold carried is lost if everyone falls. Stored gold is safe."})
	set_view(left,bag,supplies.slots_used(),supplies.capacity,supplies.gold)

func _move(entry:Dictionary,side:String) -> void:
	var key=entry.get("key")
	if key is String:
		if key=="stash_gold":_camp.take_gold(_party)
		elif key=="pack_gold":_camp.store_gold(_party)
	elif side=="left":
		if key is Equipment:_camp.withdraw_gear(_party,key)
		else:_camp.withdraw(_party,key)
	elif not entry.get("open_flask",false):
		if key is Equipment:_camp.store_gear(_party,key)
		else:_camp.store(_party,key)
	Sounds.play(self,"ui",-10.0,0.0)
	refresh()
