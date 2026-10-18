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
const Recruits := preload("res://scripts/recruits.gd")
const TORCH := preload("res://data/items/torch.tres")
## Gold (#42): the lantern upgrade, and what the merchant pays for gear.
const LANTERN_PRICE := 40
const GEAR_RESALE := 0.3
## What the merchant and the smith sell.
const MERCHANT_STOCK: Array[SupplyItem] = [
	preload("res://data/items/torch.tres"),
	preload("res://data/items/ration.tres"),
	preload("res://data/items/dressing.tres"),
	preload("res://data/items/restorative_draught.tres"),
	preload("res://data/items/oil_flask.tres"),
]
const SMITH_STOCK: Array[Equipment] = [
	preload("res://data/gear/plain_knife.tres"),
	preload("res://data/gear/wooden_club.tres"),
	preload("res://data/gear/simple_spear.tres"),
	preload("res://data/gear/woodcutters_axe.tres"),
	preload("res://data/gear/iron_sword.tres"),
]
## Not for sale until armour and shields have rules.
const SMITH_COMING := ["a rough wooden shield (16g)", "a padded coat (28g)"]
## Contracts the king's camp posts, one a day (#42).
const CONTRACTS := [
	{"enemy": "Goblin", "plural": "goblins", "count": 3, "reward": 15},
	{"enemy": "Spider", "plural": "spiders", "count": 3, "reward": 8},
	{"enemy": "Rat", "plural": "rats", "count": 4, "reward": 5},
]
## How many recruits wait at the fire (#41).
const CANDIDATES := 3

var day := 1
## Items and gear left in the tent; they survive a party wipe.
var stash = Supplies.new()
## Companion -> the day they're fit again after treatment.
var recovering := {}
## Recruits waiting at the fire; each new day one leaves, one arrives (#41).
var candidates: Array[Companion] = []
## Heroes recovering in the nurse's tent while the others are down below.
var left_behind: Array[Companion] = []
var rng := RandomNumberGenerator.new()
## Today's contract: enemy, plural, count, reward, done, paid.
var contract := {}
var _charity_on := 0
var _used_names: Array = []  # each name comes by once before any repeats


## Seeds the camp and puts the first recruits by the fire.
func start(seed_value: int, party = null) -> void:
	rng.seed = seed_value
	_fill_fire(party)
	post_contract()


func _fill_fire(party = null) -> void:
	while candidates.size() < CANDIDATES:
		if _used_names.size() >= Recruits.NAMES.size():
			_used_names.clear()  # everyone's been by once; names may repeat
		var faces := []  # no two people by the fire or in the party share a face
		var people: Array = candidates.duplicate()
		if party:
			people.append_array(party.members)
		people.append_array(left_behind)
		for person in people:
			if person.portrait_set:
				faces.append(person.portrait_set.resource_path)
		var recruit: Companion = Recruits.make(rng, _used_names, faces)
		_used_names.append(recruit.display_name)
		candidates.append(recruit)


## Free while there's no gold (#42). Returns false if the party is full.
func hire(party, recruit: Companion) -> bool:
	if recruit not in candidates or not party.add_member(recruit):
		return false
	candidates.erase(recruit)
	changed.emit()
	return true


## Sends a recruit away for good. The founder (Mara) stays.
func dismiss(party, hero: Companion) -> bool:
	if hero.founder or hero not in party.members:
		return false
	party.remove_member(hero)
	recovering.erase(hero)
	changed.emit()
	return true


## Heading down: heroes still recovering stay in the nurse's tent.
func leave_behind(party) -> void:
	for hero: Companion in party.members.duplicate():
		if is_recovering(hero):
			party.remove_member(hero)
			left_behind.append(hero)


## Back at camp: they rejoin the party (a wipe below doesn't touch them).
func rejoin(party) -> void:
	for hero in left_behind:
		if party.members.size() < party.MAX_MEMBERS:
			party.members.append(hero)
	left_behind.clear()
	party.changed.emit()


## Rest until tomorrow: everyone recovers fully, and the day moves on.
func rest(party) -> void:
	for hero: Companion in party.living_members():
		hero.complete_pending_effects()
		hero.hunger = 0
		hero.change_strain(-hero.strain)
		hero.change_health(hero.effective_max_health())
	day += 1
	if not candidates.is_empty():
		candidates.pop_front()  # the longest-waiting moves on
	_fill_fire(party)
	post_contract()
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


## The merchant (#42): sells supplies and the lantern, buys treasure and
## gear (gear at 30%). The basic kit after the opening is free (main.gd).
func can_afford(party, price: int) -> bool:
	return party.supplies.gold >= price


func buy(party, item: SupplyItem) -> bool:
	if not can_afford(party, item.price):
		return false
	party.supplies.gold -= item.price
	party.supplies.add(item)
	changed.emit()
	return true


func buy_lantern(party) -> bool:
	var supplies = party.supplies
	if supplies.has_lantern or not can_afford(party, LANTERN_PRICE):
		return false
	supplies.gold -= LANTERN_PRICE
	supplies.has_lantern = true
	supplies.oil = Supplies.LANTERN_CAPACITY
	supplies.source = Supplies.Source.LANTERN
	supplies.torch_left = 0.0
	supplies.changed.emit()
	changed.emit()
	return true


static func sale_price(item) -> int:
	if item is Equipment:
		return floori(item.price * GEAR_RESALE)
	return item.price


func sell(party, item: SupplyItem) -> bool:
	if item.effect != SupplyItem.Effect.TREASURE or not party.supplies.take(item):
		return false
	party.supplies.gold += sale_price(item)
	party.supplies.changed.emit()
	changed.emit()
	return true


func sell_gear(party, item: Equipment) -> bool:
	if item not in party.supplies.gear:
		return false
	party.supplies.gear.erase(item)
	party.supplies.gold += sale_price(item)
	party.supplies.changed.emit()
	changed.emit()
	return true


## The smith's stock (#42): plain gear into the pack, to equip there.
func buy_gear(party, item: Equipment) -> bool:
	if not can_afford(party, item.price):
		return false
	party.supplies.gold -= item.price
	party.supplies.gear.append(item)
	party.supplies.changed.emit()
	changed.emit()
	return true


## No light and no money: the merchant fronts two torches, once a day, so
## the party is never stuck at camp (#41's "always a viable party").
func needs_charity(party) -> bool:
	var supplies = party.supplies
	return not supplies.has_lantern and supplies.count(TORCH) == 0 and supplies.gold < TORCH.price and _charity_on < day


func give_charity(party) -> bool:
	if not needs_charity(party):
		return false
	party.supplies.add(TORCH, 2)
	_charity_on = day
	changed.emit()
	return true


## Gold moves between the pack and the stash all at once.
func store_gold(party) -> void:
	stash.gold += party.supplies.gold
	party.supplies.gold = 0
	party.supplies.changed.emit()
	changed.emit()


func take_gold(party) -> void:
	party.supplies.gold += stash.gold
	stash.gold = 0
	party.supplies.changed.emit()
	changed.emit()


## Today's posted contract from the king's camp (#42): beat so many of one
## kind of enemy for a lump sum, paid back at camp. A new one each day.
func post_contract() -> void:
	var offer: Dictionary = CONTRACTS[rng.randi_range(0, CONTRACTS.size() - 1)]
	contract = offer.duplicate()
	contract["done"] = 0
	contract["paid"] = false
	changed.emit()


func count_kill(enemy_name: String) -> void:
	if not contract.is_empty() and not contract["paid"] and enemy_name == contract["enemy"]:
		contract["done"] = mini(contract["done"] + 1, contract["count"])


## Pays a completed contract into the pack. Returns the reward (0 if none).
func collect_contract(party) -> int:
	if contract.is_empty() or contract["paid"] or contract["done"] < contract["count"]:
		return 0
	contract["paid"] = true
	party.supplies.gold += contract["reward"]
	party.supplies.changed.emit()
	changed.emit()
	return contract["reward"]


static func contract_text(offer: Dictionary) -> String:
	return "Beat %d %s: %d gold" % [offer["count"], offer["plural"], offer["reward"]]


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
