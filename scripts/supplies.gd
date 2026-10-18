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

## What the party sees by: the lantern (oil), a torch in hand (burns down),
## or nothing at all (#59). The opening has no lantern.
enum Source { NONE, LANTERN, TORCH }

enum Light { OUT, DIM, STEADY, BRIGHT }

const LANTERN_CAPACITY := 100.0
## Oil burned per time unit, at an empty and a full lantern. In between it
## scales with the oil level; a full tank lasts about 110 time units.
const BURN_AT_EMPTY := 0.5
const BURN_AT_FULL := 1.5
const LIGHT_NAMES := {Light.OUT: "Out", Light.DIM: "Dim", Light.STEADY: "Steady", Light.BRIGHT: "Bright"}
## Time units a torch burns. It gives steady light, dimming near the end.
const TORCH_BURN_TIME := 50.0
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
## Oil left in a flask that was only partly poured (used first next refill).
var open_flask := 0.0
var items: Array[SupplyItem] = []  # kinds carried, in pack order
var _counts := {}  # SupplyItem -> int


func add(item: SupplyItem, quantity := 1) -> void:
	if not _counts.has(item):
		items.append(item)
		_counts[item] = 0
	_counts[item] += quantity
	changed.emit()


func count(item: SupplyItem) -> int:
	return _counts.get(item, 0)


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


func burn(units: int) -> void:
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
			oil = maxf(0.0, oil - burn_rate())
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
