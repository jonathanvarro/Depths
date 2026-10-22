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

const Quests := preload("res://scripts/quests.gd")
const Supplies := preload("res://scripts/supplies.gd")
const Recruits := preload("res://scripts/recruits.gd")
const Progression := preload("res://scripts/progression.gd")
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
	# For the mine's shrines, wells and rockfalls (#133).
	preload("res://data/items/antidote.tres"),
	preload("res://data/items/holy_water.tres"),
	preload("res://data/items/spade.tres"),
	preload("res://data/items/pick.tres"),
]
## The nurse lifts a bane for this much (#133).
const LIFT_BANE_PRICE := 20
const SMITH_STOCK: Array[Equipment] = [
	preload("res://data/gear/plain_knife.tres"),
	preload("res://data/gear/wooden_club.tres"),
	preload("res://data/gear/simple_spear.tres"),
	preload("res://data/gear/woodcutters_axe.tres"),
	preload("res://data/gear/iron_sword.tres"),
	preload("res://data/gear/padded_coat.tres"),
	preload("res://data/gear/leather_jerkin.tres"),
	# Worn on the back (owner, 2026-10-21).
	preload("res://data/gear/satchel.tres"),
	preload("res://data/gear/frame_pack.tres"),
	preload("res://data/gear/oilcloth_cloak.tres"),
	preload("res://data/gear/wool_cape.tres"),
]
## Not for sale until shields have rules.
const SMITH_COMING := ["a rough wooden shield (16g)"]
## Contracts the king's camp posts, one a day (#42).
const CONTRACTS := [
	{"enemy": "Goblin", "plural": "goblins", "count": 3, "reward": 15},
	{"enemy": "Spider", "plural": "spiders", "count": 3, "reward": 8},
	{"enemy": "Rat", "plural": "rats", "count": 4, "reward": 5},
]
## How many recruits wait at the fire (#41).
const CANDIDATES := 3
## Roles that stand in the front row.
const FRONT_ROLES := ["Warden", "Brawler"]

var day := 1
## Story-controlled physical sites (#108). Missing keys preserve today's
## availability and old saves. New story starts opt into #80's arrival sequence.
var site_presence: Dictionary = {}
## The caravan can be physically present before its shop opens (#80).
## False by default preserves established camps in existing saves.
var merchant_unloading := false
## Zero means no pending arrival (including older saves).
var smith_arrival_day := 0
const SITE_IDS := ["supplies", "treatment", "rest", "smith", "fire", "cave"]
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
## True once someone has gone down today: the cave they mapped is lost if
## the party rests (#85).
var explored_today := false
## The goblin fortress (#44): lasting progress that survives the cave
## shifting each day.
var gate_broken := false
var queen_defeated := false
var bounty_paid := false
const QUEEN_BOUNTY := 50
## The scouts' routes (#79; owner 2026-10-20): once the party has reached
## a floor on this many expeditions, the king's scouts will take them
## straight down to it - each floor its own route, dearer the deeper it goes.
const ROUTE_AFTER := 2
const ROUTE_PRICES := {2: 20, 3: 35, 4: 50}
var floors_reached := {}  # depth -> expeditions that got at least that deep
var floor2_reached := 0  # older saves' count, from when only floor 2 had a route
## Experience (#47): fight XP each floor can still teach this campaign, and
## the highest level any hero has taken (recruits join one below it).
var xp_left := Progression.FLOOR_XP_LIMIT.duplicate()
var best_level := 1
## Quests and story flags (#123): id -> {"stage", "flags"}; see quests.gd.
var quests := {}
## Smith work unlocked by quests (resource paths), sold after SMITH_STOCK.
var smith_unlocks: Array[String] = []
## A proper forge (2026-10-22): after the iron project, the party can pay
## the apprentice to build one; then he also sells fine versions of his
## weapons and armour - one of each a day - at the fine price.
const FORGE_PRICE := 60
var forge_built := false
var fine_stock: Array[Equipment] = []
var fine_stock_day := -1
var _used_names: Array = []  # each name comes by once before any repeats


func site_present(id: String) -> bool:
	return id in SITE_IDS and bool(site_presence.get(id, true))


## No schedule is invented here; story code decides when a site arrives.
func set_site_present(id: String, present: bool) -> void:
	if id not in SITE_IDS or site_present(id) == present:
		return
	site_presence[id] = present
	changed.emit()


## Owner's starting composition; story entry calls this once, not on rest.
func begin_arrivals() -> void:
	site_presence = {"smith": false}
	merchant_unloading = true
	smith_arrival_day = day + 1
	changed.emit()


func set_merchant_unloading(unloading: bool) -> void:
	if merchant_unloading == unloading:
		return
	merchant_unloading = unloading
	changed.emit()


func can_trade() -> bool:
	return site_present("supplies") and not merchant_unloading


## The tutorial escape does not count; Main calls this for later returns.
func expedition_returned() -> void:
	set_merchant_unloading(false)


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
		# At least one of the three can hold the front (balance report).
		var role := ""
		if candidates.size() == CANDIDATES - 1 and not candidates.any(func(c: Companion): return c.role in FRONT_ROLES):
			role = FRONT_ROLES[rng.randi_range(0, FRONT_ROLES.size() - 1)]
		var recruit: Companion = Recruits.make(rng, _used_names, faces, maxi(1, best_level - 1), role)
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
	explored_today = true
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
	party.update_capacity()
	party.changed.emit()


## Rest until tomorrow: everyone recovers fully, and the day moves on.
func rest(party) -> void:
	for hero: Companion in party.members.filter(func(h: Companion): return h.is_with_party()):
		hero.complete_pending_effects()
		hero.hunger = 0
		hero.change_strain(-hero.strain)
		hero.change_health(hero.effective_max_health())
	day += 1
	if smith_arrival_day > 0 and day >= smith_arrival_day:
		site_presence["smith"] = true
		smith_arrival_day = 0
	explored_today = false
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
## The nurse lifts one bane for a price (#133). Returns it, or null.
func lift_bane(party, hero: Companion) -> Boon:
	if not hero.has_bane() or party.supplies.gold < LIFT_BANE_PRICE:
		return null
	party.supplies.gold -= LIFT_BANE_PRICE
	party.supplies.changed.emit()
	changed.emit()
	return hero.lift_bane()


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


## An expedition got down to `deepest`: it counts toward every route on the way.
func record_depth(deepest: int) -> void:
	for depth in ROUTE_PRICES:
		if deepest >= depth:
			floors_reached[depth] = times_reached(depth) + 1


## How many expeditions have reached `depth`.
func times_reached(depth: int) -> int:
	return maxi(floors_reached.get(depth, 0), floor2_reached if depth == 2 else 0)


func route_open(depth := 2) -> bool:
	return ROUTE_PRICES.has(depth) and times_reached(depth) >= ROUTE_AFTER


## The floors the scouts will take the party to, shallowest first.
func open_routes() -> Array:
	var depths := ROUTE_PRICES.keys().filter(func(d): return route_open(d))
	depths.sort()
	return depths


func route_price(depth: int) -> int:
	return ROUTE_PRICES.get(depth, 0)


## Pays for the route to `depth`. Returns false if it's not open or too dear.
func buy_route(party, depth := 2) -> bool:
	if not route_open(depth) or party.supplies.gold < route_price(depth):
		return false
	party.supplies.gold -= route_price(depth)
	party.supplies.changed.emit()
	changed.emit()
	return true


## What the smith sells now: his stock plus anything quests unlocked.
func smith_stock() -> Array[Equipment]:
	var stock: Array[Equipment] = SMITH_STOCK.duplicate()
	for path in smith_unlocks:
		if ResourceLoader.exists(path):
			stock.append(load(path))
	return stock


## Whether the forge can be paid for: the iron project done, not yet built.
func forge_offered() -> bool:
	return not forge_built and Quests.stage(self, "iron_sample") == Quests.Stage.RESOLVED


func build_forge(party) -> bool:
	if not forge_offered() or party.supplies.gold < FORGE_PRICE:
		return false
	party.supplies.gold -= FORGE_PRICE
	party.supplies.changed.emit()
	forge_built = true
	changed.emit()
	return true


## Today's fine pieces from the forge (empty without one): each of the
## smith's weapons and armour, made fine, seeded by the day.
func smith_fine_stock() -> Array[Equipment]:
	if not forge_built:
		return []
	if fine_stock_day != day:
		fine_stock.clear()
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(["forge", day])
		var gear_gen = load("res://scripts/gear_gen.gd")  # loaded here: it preloads this script
		for base in gear_gen.bases():
			fine_stock.append(gear_gen.make(base, "fine", rng))
		fine_stock_day = day
	return fine_stock


## Fight XP from `depth`, limited by what that floor can still teach.
func take_floor_xp(depth: int, amount: int) -> int:
	var left: int = xp_left.get(depth, 0)
	var given := mini(amount, left)
	xp_left[depth] = left - given
	return given


## Takes a level-up chosen at camp and keeps track of the best level.
func advance(hero: Companion, choice: String) -> bool:
	if not Progression.advance(hero, choice):
		return false
	best_level = maxi(best_level, hero.level)
	changed.emit()
	return true


## Heroes fit to go into the cave.
func available(party) -> Array[Companion]:
	return party.living_members().filter(func(h: Companion): return not is_recovering(h))


## The merchant (#42): sells supplies and the lantern, buys treasure and
## gear (gear at 30%). The basic kit after the opening is free (main.gd).
func can_afford(party, price: int) -> bool:
	return party.supplies.gold >= price


func buy(party, item: SupplyItem) -> bool:
	if not can_trade() or not can_afford(party, item.price) or party.supplies.room_for(item) <= 0:
		return false
	party.supplies.gold -= item.price
	party.supplies.add(item)
	changed.emit()
	return true


func buy_lantern(party) -> bool:
	var supplies = party.supplies
	if not can_trade() or supplies.has_lantern or not can_afford(party, LANTERN_PRICE):
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
	if not can_trade() or item.effect != SupplyItem.Effect.TREASURE or not party.supplies.take(item):
		return false
	party.supplies.gold += sale_price(item)
	party.supplies.changed.emit()
	changed.emit()
	return true


func sell_gear(party, item: Equipment) -> bool:
	if not can_trade() or item not in party.supplies.gear:
		return false
	party.supplies.gear.erase(item)
	party.supplies.gold += sale_price(item)
	party.supplies.changed.emit()
	changed.emit()
	return true


## The smith's stock (#42): plain gear into the pack, to equip there.
func buy_gear(party, item: Equipment) -> bool:
	if not site_present("smith") or not can_afford(party, item.price) or not party.supplies.has_room_for_gear():
		return false
	party.supplies.gold -= item.price
	party.supplies.gear.append(item)
	fine_stock.erase(item)  # one of each fine piece a day
	party.supplies.changed.emit()
	changed.emit()
	return true


## No light and no money: the merchant fronts two torches, once a day, so
## the party is never stuck at camp (#41's "always a viable party").
func needs_charity(party) -> bool:
	var supplies = party.supplies
	# Torches and gold in the stash count too, so it can't be farmed (#86).
	var torches: int = supplies.count(TORCH) + stash.count(TORCH)
	return not supplies.has_lantern and torches == 0 and supplies.gold + stash.gold < TORCH.price and _charity_on < day


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
	if queen_defeated:  # the fortress is broken: no more contracts
		contract = {}
		return
	var offer: Dictionary = CONTRACTS[rng.randi_range(0, CONTRACTS.size() - 1)]
	contract = offer.duplicate()
	contract["done"] = 0
	contract["paid"] = false
	changed.emit()


func count_kill(enemy_name: String) -> void:
	if not contract.is_empty() and not contract.get("paid", true) and enemy_name == contract["enemy"]:
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
	if party.supplies.room_for(item) > 0 and stash.take(item):
		party.supplies.add(item)
		changed.emit()


func store_gear(party, item: Equipment) -> void:
	if item in party.supplies.gear:
		party.supplies.gear.erase(item)
		stash.gear.append(item)
		party.supplies.changed.emit()
		changed.emit()


func withdraw_gear(party, item: Equipment) -> void:
	if item in stash.gear and party.supplies.has_room_for_gear():
		stash.gear.erase(item)
		party.supplies.gear.append(item)
		party.supplies.changed.emit()
		changed.emit()
