extends "res://scripts/kit_exchange.gd"
## The actual merchant economy on the Field kit exchange presentation.
const CampState:=preload("res://scripts/camp_state.gd")
const Sounds:=preload("res://scripts/sounds.gd")
const LANTERN:=preload("res://art/items/refined-v2/lantern-unlit.png")
var _camp
var _party
var _pending:=false

func _init() -> void:
	super()
	_take_all.visible=false
	requested.connect(_trade)
	extra_requested.connect(func():
		if _camp and _camp.needs_charity(_party):_camp.give_charity(_party)
		refresh())
	visible=false

func open(camp,party) -> void:
	if _camp and _camp.changed.is_connected(_request_refresh):_camp.changed.disconnect(_request_refresh)
	if _party and _party.supplies.changed.is_connected(_request_refresh):_party.supplies.changed.disconnect(_request_refresh)
	_camp=camp;_party=party
	_camp.changed.connect(_request_refresh);_party.supplies.changed.connect(_request_refresh)
	_portrait.texture=load("res://art/camp/highres-v4/merchant.png");_portrait.visible=true
	_portrait.tooltip_text="Back again, and still breathing. Good for business."
	_bag_page=0;clear_inspection();visible=true;refresh()

func _request_refresh() -> void:
	if not _pending:_pending=true;refresh.call_deferred()

func refresh() -> void:
	_pending=false
	if not visible or _party==null or _camp==null:return
	var supplies=_party.supplies
	var trading:bool=_camp.can_trade()
	_title.text="Merchant caravan" if not _camp.merchant_unloading else "Merchant · Unloading"
	_left_title.text="Stock"
	_empty.text="Unloading\nTrading is not available yet." if _camp.merchant_unloading else "The merchant is away"
	_extra.text="Take two torches";_extra.visible=_camp.needs_charity(_party)
	var stock:Array[Dictionary]=[]
	if trading:
		if not supplies.has_lantern:
			var lantern_price:int=CampState.price_for(_party,CampState.LANTERN_PRICE)  # a Fixer haggles (#101)
			stock.append({"key":"lantern","item":null,"name":"Lantern","icon":LANTERN,"description":"Brighter than a torch, burns oil. Yours to keep.","price":lantern_price,"kind":"lantern","action":"Buy · %d"%lantern_price,"reason":_buy_reason(lantern_price,true)})
		for item:SupplyItem in CampState.MERCHANT_STOCK:
			if item.effect==SupplyItem.Effect.REFILL_LANTERN and not supplies.has_lantern:continue
			var price:int=CampState.price_for(_party,item.price)
			stock.append({"key":item,"item":item,"price":price,"kind":"buy","action":"Buy 1 · %d"%price,"reason":_buy_reason(price,supplies.room_for(item)>0),"info":"Carrying %d"%supplies.count(item)})
	var bag:=inventory(supplies)
	for entry in bag:
		var item:Resource=entry.item
		var sellable:bool=item is Equipment or (item is SupplyItem and item.effect==SupplyItem.Effect.TREASURE)
		entry.kind="sell"
		if entry.get("open_flask",false):sellable=false
		entry.action="Sell"
		entry.reason="Trading is not available yet" if not trading else ("The merchant does not buy this supply" if not sellable else "")
		if sellable:
			entry.price=CampState.sell_price(_party,item)
			entry.action=("Sell 1 · %d" if item is SupplyItem else "Sell · %d")%entry.price
			entry.info="Sells one item" if item is SupplyItem else ""
	set_view(stock,bag,supplies.slots_used(),supplies.capacity,supplies.gold)

func _buy_reason(price:int,room:bool) -> String:
	if not _camp.can_trade():return "Trading is not available yet"
	if not room:return "Your pack is full"
	if _party.supplies.gold<price:return "Need %d more gold"%(price-_party.supplies.gold)
	return ""

func _trade(entry:Dictionary,side:String) -> void:
	if not _camp.can_trade():refresh();return
	var before:int=_party.supplies.gold
	if side=="left":
		if entry.key is String and entry.key=="lantern":_camp.buy_lantern(_party)
		elif entry.get("item") in CampState.MERCHANT_STOCK:_camp.buy(_party,entry.item)
	elif entry.get("item"):
		if entry.item is Equipment:_camp.sell_gear(_party,entry.item)
		elif not entry.get("open_flask",false):_camp.sell(_party,entry.item)
	if _party.supplies.gold<before:Sounds.play(self,"purchase",-7.0)
	elif _party.supplies.gold>before:Sounds.play(self,"coins",-7.0)
	refresh()
