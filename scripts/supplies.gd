extends RefCounted
## What the party carries: lantern oil and consumable supplies (#10).
##
## The lantern burns faster the fuller it is (owner decision): bright light
## is an advantage but costs more oil per time unit; a low lantern lasts
## longer but lights less. Numbers start from ChatGPT's economy research
## (docs/starter-cave-economy-research.md) and are meant to be tuned.

signal changed
signal light_band_changed(band: Light)

enum Light { OUT, DIM, STEADY, BRIGHT }

const LANTERN_CAPACITY := 100.0
## Oil burned per time unit, at an empty and a full lantern. In between it
## scales with the oil level; a full tank lasts about 110 time units.
const BURN_AT_EMPTY := 0.5
const BURN_AT_FULL := 1.5
const LIGHT_NAMES := {Light.OUT: "Out", Light.DIM: "Dim", Light.STEADY: "Steady", Light.BRIGHT: "Bright"}

var oil := LANTERN_CAPACITY
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
	if oil <= 0.0:
		return 0.0
	return BURN_AT_EMPTY + (BURN_AT_FULL - BURN_AT_EMPTY) * oil / LANTERN_CAPACITY


func burn(units: int) -> void:
	var band_before := light_band()
	for i in units:
		oil = maxf(0.0, oil - burn_rate())
	if light_band() != band_before:
		light_band_changed.emit(light_band())
	changed.emit()


## 0 (out) to 1 (full): how strong the light is. Combat can read this as
## the lantern's advantage later.
func light_fraction() -> float:
	return oil / LANTERN_CAPACITY


func light_band() -> Light:
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
