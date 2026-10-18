extends RefCounted
## The campsite between expeditions (#40): the day, the tent's stash,
## heroes recovering in the nurse's tent, and the merchant's daily top-up.
## No visuals; camp_screen.gd shows it and tests can drive it directly.
##
## Owner decisions (#40): camp is safe - resting fully restores health and
## strain at no supply cost but moves the day on by one, and a new day
## brings a re-randomized cave (main.gd listens for `day_passed`). The
## nurse treats injuries for free until there's gold; a treated hero is out
## of play for the injury's recovery days. Treatment is optional.

## A new day began (rest): the cave re-randomizes, the merchant restocks.
signal day_passed(day: int)
signal changed

const Supplies := preload("res://scripts/supplies.gd")

var day := 1
## Items and gear left in the tent; they survive a party wipe.
var stash = Supplies.new()
## Companion -> the day they're fit again after treatment.
var recovering := {}
var _restocked_on := 0


## Rest until tomorrow: everyone recovers fully, and the day moves on.
func rest(party) -> void:
	for hero: Companion in party.living_members():
		hero.complete_pending_effects()
		hero.hunger = 0
		hero.change_strain(-hero.strain)
		hero.change_health(hero.effective_max_health())
	day += 1
	for hero in recovering.keys():
		if recovering[hero] <= day:
			recovering.erase(hero)
	day_passed.emit(day)
	changed.emit()


## Days the nurse needs for `hero` (the longest of their injuries).
func treatment_days(hero: Companion) -> int:
	var days := 0
	for injury in hero.injuries:
		days = maxi(days, injury.recovery_days)
	return days


## The nurse treats every injury; the hero is out of play meanwhile.
func treat(hero: Companion) -> void:
	var days := treatment_days(hero)
	if days <= 0:
		return
	hero.treat_injuries()
	recovering[hero] = day + days
	changed.emit()


func is_recovering(hero: Companion) -> bool:
	return recovering.get(hero, 0) > day


## The day `hero` is fit again (or today).
func ready_on(hero: Companion) -> int:
	return maxi(day, recovering.get(hero, day))


## Heroes fit to go into the cave.
func available(party) -> Array[Companion]:
	return party.living_members().filter(func(h: Companion): return not is_recovering(h))


func can_restock() -> bool:
	return _restocked_on < day


## What the merchant would add to bring the pack up to `wanted`.
func restock_preview(party, wanted: Dictionary) -> Dictionary:
	var missing := {}
	for item in wanted:
		var short: int = wanted[item] - party.supplies.count(item)
		if short > 0:
			missing[item] = short
	return missing


## Tops the pack up to `wanted`, once a day (free until gold exists, #42).
func restock(party, wanted: Dictionary) -> Dictionary:
	if not can_restock():
		return {}
	var given := restock_preview(party, wanted)
	for item in given:
		party.supplies.add(item, given[item])
	_restocked_on = day
	changed.emit()
	return given


func store(party, item: SupplyItem) -> void:
	if party.supplies.take(item):
		stash.add(item)
		changed.emit()


func withdraw(party, item: SupplyItem) -> void:
	if stash.take(item):
		party.supplies.add(item)
		changed.emit()


func store_gear(party, item: Equipment) -> void:
	if item in party.supplies.gear:
		party.supplies.gear.erase(item)
		stash.gear.append(item)
		party.supplies.changed.emit()
		changed.emit()


func withdraw_gear(party, item: Equipment) -> void:
	if item in stash.gear:
		stash.gear.erase(item)
		party.supplies.gear.append(item)
		party.supplies.changed.emit()
		changed.emit()
