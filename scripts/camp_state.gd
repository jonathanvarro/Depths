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

const GearModel := preload("res://scripts/gear_model.gd")
const Quests := preload("res://scripts/quests.gd")
const Supplies := preload("res://scripts/supplies.gd")
const Recruits := preload("res://scripts/recruits.gd")
const Progression := preload("res://scripts/progression.gd")
const TORCH := preload("res://data/items/torch.tres")
## Gold (#42): the lantern upgrade, and what the merchant pays for gear.
const LANTERN_PRICE := 40
const GEAR_RESALE := 0.5  # was 0.3; finds are worth selling (owner, 2026-10-31)
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
	preload("res://data/items/votive_candle.tres"),  # a Mage's cast back (#170)
	preload("res://data/items/touchstone.tres"),  # reads an unidentified piece (2026-11-03)
	preload("res://data/items/calming_herbs.tres"),  # keeps panic in check (2026-11-08)
]
## The nurse lifts a bane for this much (#133).
const LIFT_BANE_PRICE := 20
## The smith reads an unidentified piece for this much, by its border
## (owner, 2026-11-03).
const IDENTIFY_PRICE := {"magic": 10, "rare": 20}
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
	# Shields can be bought (owner, 2026-11-12, #219); worn on the back.
	preload("res://data/gear/buckler.tres"),
	# The back row's weapons (owner, 2026-11-17, #260): slings and bows that
	# learn, and a Mage's staff or wand, which their prayers grow with.
	preload("res://data/gear/sling.tres"),
	preload("res://data/gear/short_bow.tres"),
	preload("res://data/gear/wand.tres"),
	preload("res://data/gear/oak_staff.tres"),
]
## Contracts the king's camp posts, one a day (#42).
const CONTRACTS := [
	{"enemy": "Goblin", "plural": "goblins", "count": 3, "reward": 15},
	{"enemy": "Spider", "plural": "spiders", "count": 3, "reward": 8},
	{"enemy": "Rat", "plural": "rats", "count": 4, "reward": 5},
]
## How many recruits wait at the fire (#41).
const CANDIDATES := 3
## Roles that stand in the front row.
const FRONT_ROLES := ["Melee"]  # the classes (#179); older Wardens and Brawlers count too

var day := 1
## Story-controlled physical sites (#108). Missing keys preserve today's
## availability and old saves. New story starts opt into #80's arrival sequence.
var site_presence: Dictionary = {}
## The caravan can be physically present before its shop opens (#80).
## False by default preserves established camps in existing saves.
var merchant_unloading := false
## Zero means no pending arrival (including older saves).
var smith_arrival_day := 0
## Pending nurse arrival from older saves. New campaigns bring her supplies.
var traders_arrival_day := 0
## When the merchant, nurse and smith arrived on older stories (by day).
## New stories earn them (owner, 2026-11-17, #238): the merchant after the
## first report, the nurse after the bitter moss (Story.on_return), the
## smith after a return from this floor.
const ARRIVAL_DAY := 3
const SMITH_AFTER_FLOOR := 2
## A pending smith: he comes after a return from this deep (0 = none).
var smith_after_floor := 0
const SITE_IDS := ["supplies", "treatment", "rest", "smith", "fire", "cave", "trainer"]
const TRAINER_LESSONS := {"bulwark": 12, "steady_hands": 12, "steel_nerves": 12, "iron_hide": 24}
## Items and gear left in the tent; they survive a party wipe.
var stash = Supplies.new()
## Companion -> the day they're fit again after treatment.
var recovering := {}
## Recruits waiting at the fire; each new day one leaves, one arrives (#41).
var candidates: Array[Companion] = []
## The named cast who have come to camp (#180), by id.
var named_met: Array[String] = []
## Companions whose bodies the party carried home (#180, owner 2026-11-17):
## the nurse can try to bring them back.
var fallen: Array[Companion] = []
const REVIVE_PRICE := 40
## Bodies left below by a full wipe (#180, owner 2026-11-18): [{hero, depth}].
## Only the main hero wakes at camp; a later trip can find the others on
## the floor where they fell and carry them home.
var lost_bodies: Array = []
## Bodies the party has picked up this trip, on their way home.
var carried: Array[Companion] = []
## What coming back costs them for good: maximum health.
const REVIVE_SCAR := 3
## Heroes recovering in the nurse's tent while the others are down below.
var left_behind: Array[Companion] = []
var rng := RandomNumberGenerator.new()
## Today's contract: enemy, plural, count, reward, done, paid.
var contract := {}
var _charity_on := 0
## True once someone has gone down today: the cave they mapped is lost if
## the party rests (#85).
var explored_today := false
## The first-days guide (#235) points at your tent until you've looked in.
var tent_seen := false
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
## The monster journal (#176): name -> what the party knows. See bestiary.gd.
var bestiary := {}
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
	if id == "trainer":
		return bool(site_presence.get("trainer", false)) or bounty_paid
	return id in SITE_IDS and bool(site_presence.get(id, true))


func teach(party, hero: Companion, lesson: String) -> bool:
	if not site_present("trainer") or hero == null or hero not in party.living_members() or not hero.uses_stats:
		return false
	if not TRAINER_LESSONS.has(lesson) or lesson in hero.talents or (lesson == "iron_hide" and not bounty_paid):
		return false
	var price: int = TRAINER_LESSONS[lesson]
	if not can_afford(party, price):
		return false
	party.supplies.gold -= price
	Progression.learn(hero, lesson)
	party.supplies.changed.emit()
	changed.emit()
	return true


## No schedule is invented here; story code decides when a site arrives.
func set_site_present(id: String, present: bool) -> void:
	if id not in SITE_IDS or site_present(id) == present:
		return
	site_presence[id] = present
	changed.emit()


## Owner's starting composition; story entry calls this once, not on rest.
func begin_arrivals() -> void:
	site_presence = {"smith": false, "supplies": false, "treatment": false}
	merchant_unloading = false
	smith_arrival_day = 0  # no longer by the day (#238)
	traders_arrival_day = 0
	smith_after_floor = SMITH_AFTER_FLOOR
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
	while candidates.size() < candidate_count(party):
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
		if candidates.size() == candidate_count(party) - 1 and not candidates.any(func(c: Companion): return load("res://scripts/classes.gd").of(c.role) in FRONT_ROLES):
			role = FRONT_ROLES[rng.randi_range(0, FRONT_ROLES.size() - 1)]
		var recruit: Companion = Recruits.make(rng, _used_names, faces, 1, role)  # levels start each expedition (#172)
		_used_names.append(recruit.display_name)
		candidates.append(recruit)


## Free while there's no gold (#42). Returns false if the party is full.
func hire(party, recruit: Companion) -> bool:
	if recruit not in candidates or not party.add_member(recruit):
		return false
	candidates.erase(recruit)
	changed.emit()
	return true


## Invites `recruit` into the party's `row` ("front"/"back"), or in their
## own row when "" (owner, 2026-11-21: the fire's party lineup).
func hire_into(party, recruit: Companion, row := "") -> bool:
	if not hire(party, recruit):
		return false
	if row != "":
		party.members[-1].row = row
	return true


## Swaps `out` for `recruit` in the same row; `out` goes back to wait by
## the fire. The founder stays.
func swap(party, out: Companion, recruit: Companion) -> bool:
	if out.founder or out not in party.members or recruit not in candidates:
		return false
	var row: String = out.row
	party.remove_member(out)
	recovering.erase(out)
	if not hire(party, recruit):
		party.members.append(out)
		party.update_capacity()
		return false
	party.members[-1].row = row
	candidates.push_front(out)
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
	if traders_arrival_day > 0 and day >= traders_arrival_day:
		site_presence["treatment"] = true
		traders_arrival_day = 0
	explored_today = false
	if not candidates.is_empty():
		var leaving: Array = candidates.filter(func(c: Companion): return c.named_id == "")
		if not leaving.is_empty():
			candidates.erase(leaving[0])  # the longest-waiting moves on; the named cast wait (#180)
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


## The party carried `hero`'s body home (#180).
func carry_home(hero: Companion) -> void:
	if hero not in fallen:
		fallen.append(hero)
		changed.emit()


## A full wipe left `hero` lying on floor `depth` (#180).
func leave_body(hero: Companion, depth: int) -> void:
	if bodies_on(depth).has(hero) or hero in fallen:
		return
	carried.erase(hero)
	lost_bodies.append({"hero": hero, "depth": depth})
	changed.emit()


## Who lies on floor `depth`.
func bodies_on(depth: int) -> Array:
	return lost_bodies.filter(func(b): return b["depth"] == depth).map(func(b): return b["hero"])


## The party found `hero`'s body and carries it.
func pick_up(hero: Companion) -> void:
	lost_bodies = lost_bodies.filter(func(b): return b["hero"] != hero)
	if hero not in carried:
		carried.append(hero)
	changed.emit()


## Home with them: the carried bodies go to the nurse's tent.
func bring_home() -> void:
	for hero in carried:
		carry_home(hero)
	carried.clear()


## Wiped again while carrying: they lie on this floor now.
func drop_carried(depth: int) -> void:
	for hero in carried.duplicate():
		leave_body(hero, depth)
	carried.clear()


## The nurse brings a fallen companion back (#180): for a price, and a
## lasting scar. They wait by the fire to be asked again.
func revive(party, hero: Companion) -> bool:
	if hero not in fallen or not site_present("treatment") or party.supplies.gold < REVIVE_PRICE:
		return false
	party.supplies.gold -= REVIVE_PRICE
	party.supplies.changed.emit()
	fallen.erase(hero)
	hero.hp_bonus -= REVIVE_SCAR
	hero.injuries.clear()
	hero.dressed.clear()
	hero.refresh_stats()
	hero.health = hero.effective_max_health()
	hero.strain = 40.0  # they remember dying
	candidates.push_front(hero)
	changed.emit()
	return true


## An expedition got down to `deepest`: it counts toward every route on the way.
func record_depth(deepest: int, returned_alive := true) -> void:
	if deepest >= 3 and returned_alive:
		set_site_present("trainer", true)
	if smith_after_floor > 0 and deepest >= smith_after_floor:  # the apprentice comes up with the wagon (#238)
		smith_after_floor = 0
		site_presence["smith"] = true
		load("res://scripts/quests.gd").set_flag(self, "story", "smith_due")
		changed.emit()
	for depth in ROUTE_PRICES:
		if deepest >= depth:
			floors_reached[depth] = times_reached(depth) + 1
	load("res://scripts/named_cast.gd").arrive(self)  # a first floor-2 return brings Nessa (#180)


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


## The smith's work for the day (owner, 2026-10-31): a few pieces, new each
## day, rolled by the equipment tables (#192) from the regions the party has
## reached. Before the forge: plain, rough work with nothing extra. After
## it: anything up to exceptional, with modifiers. Quest unlocks (the
## camp-forged blade) are always there. Shields wait for their rules.
const SMITH_WARES := 8
var wares: Array[Equipment] = []
var wares_day := -1

func smith_wares() -> Array[Equipment]:
	if wares_day != day:
		wares.clear()
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(["smith", day, forge_built])
		var deepest := 1
		for depth in floors_reached:
			if int(floors_reached[depth]) > 0:
				deepest = maxi(deepest, int(depth))
		var region := GearModel.region_of(deepest)
		var pool: Array = GearModel.tables()["bases"]["bases"].filter(func(b): return int(b["region"]) <= region 				and not b.get("no_drop", false) and b.get("kind", "") != "shield")
		for path in smith_unlocks:
			if ResourceLoader.exists(path):
				wares.append(GearModel.ensure_instance(load(path)))
		while wares.size() < SMITH_WARES and not pool.is_empty():
			var b: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
			var quality := ""
			if not forge_built:
				quality = ["cracked", "bent", "ordinary", "ordinary", "ordinary"][rng.randi_range(0, 4)]
			var item := GearModel.generate(rng, b["id"], quality)
			if not forge_built and not item.mods.is_empty():
				item.mods = PackedStringArray()
				GearModel.apply(item)
			wares.append(item)
		wares_day = day
	return wares


## Tempering (#173; owner 2026-10-31): the smith turns mastery 3 or 6 into
## one chosen improvement, for gold and a piece of the item's own region's
## material (copper ore, goblin-forged scrap, black ore), from the pack or
## the stash. Returns why not, or "" when it's done.
## What the smith asks to read `item`.
func identify_price(party, item: Equipment) -> int:
	return price_for(party, IDENTIFY_PRICE.get(item.tier, IDENTIFY_PRICE["rare"]))


## The smith reads an unidentified piece, worn or carried. Returns what it
## turned out to be, or why not ("" never: a reason starts with no "Identified").
func identify(party, item: Equipment) -> String:
	if not site_present("smith"):
		return "The smith is away"
	if item == null or item.identified:
		return "Nothing to read"
	var price := identify_price(party, item)
	if party.supplies.gold < price:
		return "Need %d gold" % price
	party.supplies.gold -= price
	var text := GearModel.identify(item)
	party.supplies.changed.emit()
	party.changed.emit()
	changed.emit()
	return text


func temper(party, item: Equipment, option_id: String) -> String:
	if not site_present("smith"):
		return "The smith is away"
	if GearModel.temper_due(item) == 0:
		return "Not ready: mastery 3, then 6"
	if not GearModel.temper_options(item).any(func(o): return o["id"] == option_id):
		return "Not a choice for this piece"
	var cost := GearModel.temper_cost(item)
	var material: SupplyItem = load("res://data/items/%s.tres" % cost["material_id"])
	var have: int = party.supplies.count(material) + stash.count(material)
	if party.supplies.gold < price_for(party, cost["gold"]):
		return "Need %d gold" % price_for(party, cost["gold"])
	if have < cost["material"]:
		return "Needs %d %s" % [cost["material"], material.display_name.to_lower()]
	party.supplies.gold -= price_for(party, cost["gold"])
	for i in cost["material"]:
		if not party.supplies.take(material):
			stash.take(material)
	item.tempers.append(option_id)
	GearModel.apply(item)
	party.supplies.changed.emit()
	changed.emit()
	return ""


## Whether the forge can be paid for: the iron project done, not yet built.
func forge_offered() -> bool:
	return not forge_built and Quests.stage(self, "iron_sample") == Quests.Stage.RESOLVED


func build_forge(party) -> bool:
	if not forge_offered() or party.supplies.gold < FORGE_PRICE:
		return false
	party.supplies.gold -= FORGE_PRICE
	party.supplies.changed.emit()
	forge_built = true
	wares_day = -1  # the forge's first work, today
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


## A Fixer's eye for value (#101): treasure sells for more, and the
## merchant knocks something off.
const FIXER_SALE := 1.25
const FIXER_DISCOUNT := 0.9

static func has_fixer(party) -> bool:
	return party != null and party.members.any(func(h): return h.role == "Fixer" and h.is_alive())


## What the merchant asks of this party.
static func price_for(party, price: int) -> int:
	return ceili(price * FIXER_DISCOUNT) if has_fixer(party) else price


## What the merchant pays this party for `item`.
static func sell_price(party, item) -> int:
	var price := sale_price(item)
	if item is SupplyItem and item.effect == SupplyItem.Effect.TREASURE and has_fixer(party):
		price = roundi(price * FIXER_SALE)
	return price


## How many recruits wait by the fire: one more with a Fixer.
func candidate_count(party = null) -> int:
	return CANDIDATES + (1 if has_fixer(party) else 0)


func buy(party, item: SupplyItem) -> bool:
	var price := price_for(party, item.price)
	if not can_trade() or not can_afford(party, price) or party.supplies.room_for(item) <= 0:
		return false
	party.supplies.gold -= price
	party.supplies.add(item)
	changed.emit()
	return true


func buy_lantern(party) -> bool:
	var supplies = party.supplies
	var price := price_for(party, LANTERN_PRICE)
	if not can_trade() or supplies.has_lantern or not can_afford(party, price):
		return false
	supplies.gold -= price
	supplies.has_lantern = true
	supplies.oil = Supplies.LANTERN_CAPACITY
	supplies.source = Supplies.Source.LANTERN
	supplies.torch_left = 0.0
	supplies.changed.emit()
	changed.emit()
	return true


static func sale_price(item) -> int:
	if item is Equipment:  # unidentified: what it shows, a plain piece; mastery adds a little (2026-11-03)
		return floori(GearModel.known(item).price * GEAR_RESALE * (1.0 + GearModel.mastery_value(item)))
	return item.price


func sell(party, item: SupplyItem) -> bool:
	if not can_trade() or item.effect != SupplyItem.Effect.TREASURE or not party.supplies.take(item):
		return false
	party.supplies.gold += sell_price(party, item)
	party.supplies.changed.emit()
	changed.emit()
	return true


func sell_gear(party, item: Equipment, at_smith := false) -> bool:
	if not (can_trade() or (at_smith and site_present("smith"))) or item not in party.supplies.gear:
		return false
	party.supplies.gear.erase(item)
	party.supplies.gold += sale_price(item)
	party.supplies.changed.emit()
	changed.emit()
	return true


## The smith's stock (#42): plain gear into the pack, to equip there.
func buy_gear(party, item: Equipment) -> bool:
	var price := price_for(party, item.price)  # a Fixer haggles here too (#101)
	if not site_present("smith") or not can_afford(party, price) or not party.supplies.has_room_for_gear():
		return false
	party.supplies.gold -= price
	party.supplies.gear.append(GearModel.ensure_instance(item))  # your own piece, from now on (#192)
	fine_stock.erase(item)
	wares.erase(item)  # one of each a day  # one of each fine piece a day
	party.supplies.changed.emit()
	changed.emit()
	return true


## The quartermaster's torches (owner playtest, 2026-10-25): every return
## to camp tops the party up to this many, free. Gold was too scarce to keep
## buying them, and a party without light can't get anywhere.
const FREE_TORCHES := 3

## The quartermaster's issue (owner, 2026-11-22): what every return tops
## the pack back up to, free. The first is the baseline; each next one is
## paid for once, in gold and things brought up from the mine (from the pack
## or the stash), and lasts.
const ISSUE := [
	{"name": "Basic issue", "items": {"torch": 3}},
	{"name": "Field issue", "items": {"torch": 4, "ration": 1}, "gold": 30, "materials": {}},
	{"name": "Full issue", "items": {"torch": 5, "ration": 1, "dressing": 1}, "gold": 60, "materials": {"coal": 3}},
	{"name": "Expedition issue", "items": {"torch": 5, "ration": 2, "dressing": 2, "oil_flask": 1}, "gold": 100, "materials": {"copper_ore": 2}},
]
const ISSUE_ITEM := "res://data/items/%s.tres"
var issue_level := 0


## What the issue hands over now: {SupplyItem: count}.
func issue_items(level := -1) -> Dictionary:
	var out := {}
	var spec: Dictionary = ISSUE[clampi(issue_level if level < 0 else level, 0, ISSUE.size() - 1)]
	for id: String in spec["items"]:
		out[load(ISSUE_ITEM % id)] = int(spec["items"][id])
	return out


## The next issue up and what it costs, or {} at the top.
func next_issue() -> Dictionary:
	return ISSUE[issue_level + 1] if issue_level + 1 < ISSUE.size() else {}


func can_raise_issue(party) -> bool:
	var next := next_issue()
	# Gold in the tent's stash counts too (owner, 2026-11-24: the button
	# seemed dead with the gold put away).
	if next.is_empty() or party.supplies.gold + stash.gold < int(next["gold"]):
		return false
	for id: String in next["materials"]:
		var item: SupplyItem = load(ISSUE_ITEM % id)
		if party.supplies.count(item) + stash.count(item) < int(next["materials"][id]):
			return false
	return true


## What's still missing for the next issue, in words ("" if nothing).
func issue_shortfall(party) -> String:
	var next := next_issue()
	if next.is_empty():
		return ""
	var missing: Array[String] = []
	var gold: int = party.supplies.gold + stash.gold
	if gold < int(next["gold"]):
		missing.append("%d more gold" % (int(next["gold"]) - gold))
	for id: String in next["materials"]:
		var item: SupplyItem = load(ISSUE_ITEM % id)
		var have: int = party.supplies.count(item) + stash.count(item)
		if have < int(next["materials"][id]):
			missing.append("%d more %s" % [int(next["materials"][id]) - have, item.display_name.to_lower()])
	return "Still needed: %s." % ", ".join(missing) if not missing.is_empty() else ""


## Pays for the next issue (gold and materials from the pack first, then the stash).
func raise_issue(party) -> bool:
	if not can_raise_issue(party):
		return false
	var next := next_issue()
	var from_pack := mini(party.supplies.gold, int(next["gold"]))
	party.supplies.gold -= from_pack
	stash.gold -= int(next["gold"]) - from_pack
	for id: String in next["materials"]:
		var item: SupplyItem = load(ISSUE_ITEM % id)
		var owed: int = int(next["materials"][id]) - party.supplies.drop(item, int(next["materials"][id]))
		if owed > 0:
			stash.drop(item, owed)
	issue_level += 1
	party.supplies.changed.emit()
	changed.emit()
	return true


## "3 torches, a ration" for the issue at `level` (now by default).
func issue_text(level := -1) -> String:
	var parts := []
	var items := issue_items(level)
	for item: SupplyItem in items:
		var n: int = items[item]
		var name := item.display_name.to_lower()
		parts.append(("a %s" % name) if n == 1 else "%s ×%d" % [name, n])
	return ", ".join(PackedStringArray(parts))


## "30 gold, 3 coal" for the next issue.
func next_issue_price() -> String:
	var next := next_issue()
	if next.is_empty():
		return ""
	var parts := ["%d gold" % int(next["gold"])]
	for id: String in next["materials"]:
		parts.append("%s ×%d" % [load(ISSUE_ITEM % id).display_name.to_lower(), int(next["materials"][id])])
	return ", ".join(PackedStringArray(parts))


## Tops the pack up to the issue (FREE_TORCHES torches at the start).
## Returns how many torches were handed over.
func top_up_torches(party) -> int:
	var torches := 0
	var wanted := issue_items()
	for item: SupplyItem in wanted:
		# What's in the stash counts too, so issued supplies can't be piled
		# up there trip after trip (owner, 2026-11-23: no profit from the
		# camp's supplies; the merchant never buys supplies either).
		var short: int = wanted[item] - party.supplies.count(item) - stash.count(item)
		if short > 0:
			var given: int = party.supplies.add_what_fits(item, short)
			if item == TORCH:
				torches = given
	changed.emit()
	return torches


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
