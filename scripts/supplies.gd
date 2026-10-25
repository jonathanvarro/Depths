extends RefCounted
## What the party carries: lantern oil and consumable supplies (#10).
##
## The lantern burns faster the fuller it is (owner decision): bright light
## is an advantage but costs more oil per time unit; a low lantern lasts
## longer but lights less. Numbers start from ChatGPT's economy research
## (docs/starter-cave-economy-research.md) and are meant to be tuned.

signal changed
signal light_band_changed(band: Light)
## A held torch burned down to nothing (#59).
signal torch_burnt_out
signal torch_flared  # a fresh torch is lit (the sound, #54)

## What the party sees by: the lantern (oil), a torch in hand (burns down),
## or nothing at all (#59). The opening has no lantern.
enum Source { NONE, LANTERN, TORCH }

enum Light { OUT, DIM, STEADY, BRIGHT }

const LANTERN_CAPACITY := 100.0
## Oil burned per time unit, at an empty and a full lantern. In between it
## scales with the oil level; a full tank lasts about 120 time units.
## Loosened slightly (owner, 2026-10-25): the bot spent a third of its steps
## in the dark. Was 0.5 and 1.5.
const BURN_AT_EMPTY := 0.45
const BURN_AT_FULL := 1.35
const LIGHT_NAMES := {Light.OUT: "Out", Light.DIM: "Dim", Light.STEADY: "Steady", Light.BRIGHT: "Bright"}
## Time units a torch burns. It gives steady light, dimming near the end.
## Was 50 until the same loosening (2026-10-25).
const TORCH_BURN_TIME := 58.0
const TORCH_DIM_BELOW := 10.0
## How strong a torch's light is, against a full lantern's 1.0.
const TORCH_LIGHT := 0.55

var oil := LANTERN_CAPACITY
var has_lantern := true
var source := Source.LANTERN
var torch_left := 0.0
## False: a lit torch doesn't burn down (the opening, where it's lost by
## tripping instead, #69).
var torch_burns := true
## Gear carried in the pack (not wielded), e.g. a spare weapon (#58).
var gear: Array[Equipment] = []
## Carried gold (#42). Lost in a party wipe; the camp stash keeps its own.
var gold := 0
## Oil left in a flask that was only partly poured (used first next refill).
var open_flask := 0.0
var items: Array[SupplyItem] = []  # kinds carried, in pack order
var _counts := {}  # SupplyItem -> int
## Pack space (owner, 2026-10-21, #133): how many slots the pack has. A slot
## holds up to an item's stack size; a piece of spare gear fills one. Gold,
## the lantern, a lit torch and what heroes wear don't take space. -1: no
## limit (the camp stash). party_state.gd sets it from the party's size.
var capacity := -1


func add(item: SupplyItem, quantity := 1) -> void:
	if not _counts.has(item):
		items.append(item)
		_counts[item] = 0
	_counts[item] += quantity
	changed.emit()


func count(item: SupplyItem) -> int:
	return _counts.get(item, 0)


## Slots in use: each kind's stacks, plus one per piece of spare gear.
func slots_used() -> int:
	var used := gear.size()
	for item: SupplyItem in _counts:
		used += ceili(float(_counts[item]) / item.stack_size())
	return used


func is_limited() -> bool:
	return capacity >= 0


## How many more of `item` fit: room left in its last stack, plus free slots.
func room_for(item: SupplyItem) -> int:
	if not is_limited():
		return 1 << 30
	var stack := item.stack_size()
	var held := count(item)
	var top_up := (stack - held % stack) % stack
	return top_up + maxi(0, capacity - slots_used()) * stack


func has_room_for_gear() -> bool:
	return not is_limited() or slots_used() < capacity


## Adds as many of `item` as fit (up to `quantity`); returns how many.
func add_what_fits(item: SupplyItem, quantity := 1) -> int:
	var fits := mini(quantity, room_for(item))
	if fits > 0:
		add(item, fits)
	return fits


## Leaves `quantity` of `item` behind to make room.
func drop(item: SupplyItem, quantity := 1) -> int:
	var dropped := mini(quantity, count(item))
	if dropped > 0:
		_counts[item] -= dropped
		changed.emit()
	return dropped


func take(item: SupplyItem) -> bool:
	if count(item) <= 0:
		return false
	_counts[item] -= 1
	changed.emit()
	return true


func burn_rate() -> float:
	if source != Source.LANTERN or oil <= 0.0:
		return 0.0
	return BURN_AT_EMPTY + (BURN_AT_FULL - BURN_AT_EMPTY) * oil / LANTERN_CAPACITY


## `rate`: boons and banes can make the lantern burn slower or faster (#133).
func burn(units: int, rate := 1.0) -> void:
	var band_before := light_band()
	if source == Source.TORCH:
		if not torch_burns:
			return
		torch_left = maxf(0.0, torch_left - units)
		if torch_left <= 0.0:
			source = Source.LANTERN if has_lantern else Source.NONE
			torch_burnt_out.emit()
	else:
		for i in units:
			oil = maxf(0.0, oil - burn_rate() * rate)
	if light_band() != band_before:
		light_band_changed.emit(light_band())
	changed.emit()


## Lights a torch from the pack and holds it (it replaces the lantern's
## light while it burns).
func light_torch(torch: SupplyItem) -> bool:
	if source == Source.TORCH or not take(torch):
		return false
	var band_before := light_band()
	source = Source.TORCH
	torch_left = TORCH_BURN_TIME
	if light_band() != band_before:
		light_band_changed.emit(light_band())
	torch_flared.emit()
	changed.emit()
	return true


## The held torch is thrown (or dropped): back to the lantern, or darkness.
func lose_torch() -> void:
	if source != Source.TORCH:
		return
	var band_before := light_band()
	torch_left = 0.0
	source = Source.LANTERN if has_lantern else Source.NONE
	if light_band() != band_before:
		light_band_changed.emit(light_band())
	changed.emit()


## A party wipe (#41): everything carried is lost, lantern included.
func lose_everything() -> void:
	items.clear()
	_counts.clear()
	gear.clear()
	gold = 0
	open_flask = 0.0
	oil = 0.0
	has_lantern = false
	source = Source.NONE
	torch_left = 0.0
	changed.emit()


func torch_lit() -> bool:
	return source == Source.TORCH and torch_left > 0.0


## 0 (out) to 1 (full): how strong the light is. Combat can read this as
## the lantern's advantage later.
func light_fraction() -> float:
	match source:
		Source.TORCH:
			return TORCH_LIGHT * (0.6 if torch_left < TORCH_DIM_BELOW else 1.0)
		Source.NONE:
			return 0.0
	return oil / LANTERN_CAPACITY


func light_band() -> Light:
	match source:
		Source.NONE:
			return Light.OUT
		Source.TORCH:
			return Light.DIM if torch_left < TORCH_DIM_BELOW else Light.STEADY
	if oil <= 0.0:
		return Light.OUT
	if oil < LANTERN_CAPACITY / 3.0:
		return Light.DIM
	if oil < LANTERN_CAPACITY * 2.0 / 3.0:
		return Light.STEADY
	return Light.BRIGHT


func lantern_is_full() -> bool:
	return oil >= LANTERN_CAPACITY - 0.5


## Pours oil into the lantern: the open flask first, then a fresh `flask`
## if there's still room. Nothing is wasted; leftovers stay in the open
## flask. Returns the amount poured.
func refill(flask: SupplyItem) -> float:
	var band_before := light_band()
	var poured := 0.0
	var space := LANTERN_CAPACITY - oil
	if open_flask > 0.0:
		var from_open := minf(open_flask, space)
		open_flask -= from_open
		poured += from_open
		space -= from_open
	if space >= 0.5 and take(flask):
		var from_new := minf(float(flask.amount), space)
		open_flask = flask.amount - from_new
		poured += from_new
	oil += poured
	if light_band() != band_before:
		light_band_changed.emit(light_band())
	changed.emit()
	return poured
