extends SceneTree
## Full-campaign playtest (#119, #49): plays whole campaigns, from the camp
## after the opening escape until the queen is dead and the first story
## slice's lower gate is reached, many times over for each starting hero,
## and reports how they went. It follows the story too: the commander's
## orders, quest packages and camp conversations (docs/first-slice-plan.md).
##
## It plays by the game's own rules - PartyState, CombatState, CampState,
## RoomEvents, Progression, FloorGenerator, Fortress and main.gd's
## encounter tables - without drawing anything, so dozens of campaigns run
## in minutes. The UI is covered by the other checks; this measures pacing
## and balance. The bot plays sensibly but plainly (see _hero_turn, _camp).
##
##   Godot --headless --path . --script tools/campaign_playtest.gd -- [runs per hero] [max days] [json out]

const PS := preload("res://scripts/party_state.gd")
const CS := preload("res://scripts/combat_state.gd")
const CampState := preload("res://scripts/camp_state.gd")
const Progression := preload("res://scripts/progression.gd")
const RoomEvents := preload("res://scripts/room_events.gd")
const DungeonMap := preload("res://scripts/dungeon_map.gd")
const FloorGenerator := preload("res://scripts/floor_generator.gd")
const Fortress := preload("res://scripts/fortress.gd")
const Supplies := preload("res://scripts/supplies.gd")
const StrainRules := preload("res://scripts/strain.gd")
const Quests := preload("res://scripts/quests.gd")
const Story := preload("res://scripts/story.gd")
const Packages := preload("res://scripts/packages.gd")

const TORCH := preload("res://data/items/torch.tres")
const RATION := preload("res://data/items/ration.tres")
const DRESSING := preload("res://data/items/dressing.tres")
const DRAUGHT := preload("res://data/items/restorative_draught.tres")
const OIL := preload("res://data/items/oil_flask.tres")
const IRON_SWORD := preload("res://data/gear/iron_sword.tres")
const ANTIDOTE := preload("res://data/items/antidote.tres")
const HOLY_WATER := preload("res://data/items/holy_water.tres")
const SPADE := preload("res://data/items/spade.tres")
const Trinkets := preload("res://scripts/trinkets.gd")
const GearGen := preload("res://scripts/gear_gen.gd")
const DEEP_WOUND := preload("res://data/injuries/deep_wound.tres")

const HEROES := {
	"mara": "res://data/companions/mara.tres",
	"corin": "res://data/companions/corin.tres",
	"alwen": "res://data/companions/alwen.tres",
}
const C := DungeonMap.Content
const FORTRESS_DEPTH := 4
const FLOORS := 4
## The bot turns for home when the party's health falls below this...
const HOME_BELOW := 0.45
## ...and only takes on the queen above this (and the gate above GATE_ABOVE).
const QUEEN_ABOVE := 0.75
const GATE_ABOVE := 0.6
const STEP_LIMIT := 4000  # per expedition: a soft-lock guard

var Main  # main.gd, for its encounter tables and constants
var events_rules  # room_events.gd

# One campaign's state.
var party
var camp
var floors := {}  # depth -> DungeonMap (kept until a day passes, as in game)
var first_seed := 0
var depth := 0
var cell := Vector2i.ZERO
var stats := {}
var steps := 0
var trinket_rng := RandomNumberGenerator.new()  # trinket drops (#135)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var runs: int = int(args[0]) if args.size() > 0 else 30
	var max_days: int = int(args[1]) if args.size() > 1 else 45
	var out_path: String = args[2] if args.size() > 2 else ""
	Main = load("res://scripts/main.gd")
	events_rules = RoomEvents.new()
	var all := {}
	var started := Time.get_ticks_msec()
	for hero in HEROES:
		all[hero] = []
		for i in runs:
			var run_seed := 1000 + i * 7919 + HEROES.keys().find(hero) * 104729
			var result := _campaign(HEROES[hero], run_seed, max_days)
			result["hero"] = hero
			result["seed"] = run_seed
			all[hero].append(result)
			print("%s #%d seed %d: %s in %d days, %d expeditions, %d wipes%s" % [hero, i + 1, run_seed,
					"queen dead" if result["won"] else "gave up", result["days"], result["expeditions"], result["wipes"],
					"  STUCK: " + result["stuck"] if result["stuck"] != "" else ""])
	print("played %d campaigns in %.0fs" % [runs * HEROES.size(), (Time.get_ticks_msec() - started) / 1000.0])
	_summarise(all)
	if out_path != "":
		var file := FileAccess.open(out_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(all, "  "))
	quit()


# --- A campaign --------------------------------------------------------

func _campaign(hero_path: String, run_seed: int, max_days: int) -> Dictionary:
	seed(run_seed)
	events_rules.rng.seed = run_seed
	first_seed = run_seed
	floors.clear()
	stats = {
		"won": false, "days": 0, "expeditions": 0, "wipes": 0, "returns": 0, "fight_retreats": 0,
		"fights": 0, "fights_won": 0, "events": 0, "injuries": 0, "stuck": "",
		"damage_by_floor": {1: 0, 2: 0, 3: 0, 4: 0}, "visits_by_floor": {1: 0, 2: 0, 3: 0, 4: 0},
		"wipes_by_floor": {1: 0, 2: 0, 3: 0, 4: 0}, "first_arrival": {},
		"gold_found": 0, "gold_contracts": 0, "gold_sold": 0, "gold_spent": 0, "bounty": 0,
		"gate_tries": 0, "gate_day": 0, "queen_tries": 0, "queen_rounds": 0, "queen_day": 0,
		"route_bought": 0, "lantern_day": 0, "boons": 0, "banes": 0, "banes_lifted": 0, "trinkets_found": 0, "trinkets_worn": 0, "gear_found": 0, "gear_equipped": 0,
		# Light (owner question, 2026-10-25): steps by light band, trips cut
		# short for want of light, and light used.
		"steps_bright": 0, "steps_steady": 0, "steps_dim": 0, "steps_out": 0,
		"home_no_light": 0, "torches_lit": 0, "flasks_used": 0, "xp_spent_out_day": {}, "levels_at_end": [],
		"treated": 0, "recruits_hired": 0, "quest_days": {}, "queen_attempts": [], "gate_attempts": [],
	}
	party = PS.new()
	party.add_member(load(hero_path))
	var lead: Companion = party.members[0]
	lead.weapon = lead.companion_weapon if lead.companion_weapon else IRON_SWORD  # taken in the opening
	lead.refresh_stats()
	lead.health = lead.effective_max_health()
	# Restocked at camp after the opening (#69), with service arrivals (#80).
	party.supplies.add(TORCH, 4)
	party.supplies.add(RATION, 2)
	party.supplies.add(DRAUGHT, 1)
	party.supplies.add(DRESSING, 2)
	camp = CampState.new()
	camp.start(run_seed, party)
	events_rules.camp = camp
	# The commander's order after the escape (first story slice).
	Quests.set_stage(camp, "left_behind", Quests.Stage.ACTIVE)
	camp.day_passed.connect(func(day): floors.clear())
	camp.begin_arrivals()
	while camp.day <= max_days:
		_talk_at_camp()
		var start_depth := _camp_day()
		if start_depth < 0:
			continue  # rested or waited a day
		stats["expeditions"] += 1
		var ending := _expedition(start_depth)
		_back_at_camp(ending)
		if stats["stuck"] != "":
			break
		_note_quests()
		if camp.queen_defeated and Quests.stage(camp, "lower_gate") == Quests.Stage.RESOLVED:
			stats["won"] = true
			break
	stats["days"] = camp.day
	stats["levels_at_end"] = party.members.map(func(h): return h.level)
	return stats


# --- Camp ---------------------------------------------------------------

## People at camp with news (first slice): the bot listens, answering with
## the first reply each time, as the conversation screen would apply it.
func _talk_at_camp() -> void:
	for site in ["cave", "smith", "fire"]:
		var id := Story.camp_talk(camp, site)
		var talk := Story.conversation(id)
		if talk == null:
			continue
		var page := 0
		var guard := 0
		while page >= 0 and page < talk.pages.size() and guard < 20:
			guard += 1
			var replies: Array = talk.pages[page].replies
			var reply = replies[0] if not replies.is_empty() else null
			if reply and reply.quest != "":
				if reply.stage >= 0:
					Quests.set_stage(camp, reply.quest, reply.stage)
				if reply.flag != "":
					Quests.set_flag(camp, reply.quest, reply.flag)
			page = reply.next if reply else -1
		Story.after_talk(camp, id)


## The day each quest first resolved, for the report.
func _note_quests() -> void:
	for id in Quests.INFO:
		if Quests.stage(camp, id) == Quests.Stage.RESOLVED and not stats["quest_days"].has(id):
			stats["quest_days"][id] = camp.day


## One visit to camp. Returns the depth to head down to, or -1 if the day
## was spent resting or waiting.
func _camp_day() -> int:
	# Level-ups first (#47): the first talent, or the best attribute.
	for hero: Companion in party.members:
		while Progression.ready_to_advance(hero):
			var options := Progression.choices(hero)
			var pick: String = options[0][0] if not options.is_empty() else ""
			if hero.level + 1 == 3:
				for key in Progression.ATTRIBUTES:
					if hero.get(key) < Progression.ATTRIBUTE_CAP and (pick == "" or pick not in Progression.ATTRIBUTES or hero.get(key) > hero.get(pick)):
						pick = key
			if not camp.advance(hero, pick):
				break
	# Lasting injuries go to the nurse (#43).
	for hero: Companion in party.members:
		if not hero.hindering_injuries().is_empty() and not camp.is_recovering(hero):
			camp.treat(hero)
			stats["treated"] += 1
	# Fill the party from the fire (#41).
	while party.members.size() < PS.MAX_MEMBERS and not camp.candidates.is_empty():
		if camp.hire(party, camp.candidates[0]):
			stats["recruits_hired"] += 1
		else:
			break
	_shop()
	var fit: Array = camp.available(party)
	var hurt: bool = party.members.any(func(h: Companion): return h.is_with_party() and (h.health < h.effective_max_health() or h.strain > 30.0 or h.hunger > 40))
	# Rest when hurt, when nobody is fit, or after every trip (as players do;
	# it also refreshes the cave and the contract).
	camp.top_up_torches(party)  # free on every return (owner, 2026-10-25)
	if fit.is_empty() or hurt or camp.explored_today:
		camp.rest(party)
		camp.give_charity(party)
		return -1
	camp.give_charity(party)
	var start := 1
	# The deepest route the party is ready for and can afford with gold to spare.
	for depth: int in camp.open_routes():
		if _gold() >= camp.route_price(depth) + 20 and _mean_level() >= depth - 0.5:
			start = depth
	if start > 1:
		camp.take_gold(party)
		if camp.buy_route(party, start):
			stats["gold_spent"] += camp.route_price(start)
			stats["route_bought"] += 1
		else:
			start = 1
	camp.store_gold(party)  # nothing carried is safe from a wipe
	camp.leave_behind(party)
	return start


func _gold() -> int:
	return party.supplies.gold + camp.stash.gold


func _shop() -> void:
	camp.take_gold(party)
	_wear_trinkets()
	if camp.can_trade():
		for item in party.supplies.items.duplicate():
			while item.effect == SupplyItem.Effect.TREASURE and party.supplies.count(item) > 0:
				var price := CampState.sale_price(item)
				if not camp.sell(party, item):
					break
				stats["gold_sold"] += price
		if not party.supplies.has_lantern and party.supplies.gold >= CampState.LANTERN_PRICE + 25:
			if camp.buy_lantern(party):
				stats["gold_spent"] += CampState.LANTERN_PRICE
				stats["lantern_day"] = camp.day
		var size: int = maxi(1, party.members.size())
		var wants := {TORCH: 2 if party.supplies.has_lantern else 4, OIL: 2 if party.supplies.has_lantern else 0,
				RATION: size, DRAUGHT: 2, DRESSING: 2}
		for item in wants:
			while party.supplies.count(item) < wants[item] and party.supplies.gold >= item.price:
				if not camp.buy(party, item):
					break
				stats["gold_spent"] += item.price
		# A careful player carries the counters too, once the basics are bought (#133).
		for item in [ANTIDOTE, HOLY_WATER, SPADE]:
			if party.supplies.count(item) < 1 and party.supplies.gold >= item.price + 20:
				if camp.buy(party, item):
					stats["gold_spent"] += item.price
	# A bane that outlasted the trip: the nurse lifts it, if it's affordable.
	for hero: Companion in party.living_members():
		if hero.has_bane() and party.supplies.gold >= CampState.LIFT_BANE_PRICE + 20 and camp.lift_bane(party, hero):
			stats["gold_spent"] += CampState.LIFT_BANE_PRICE
			stats["banes_lifted"] += 1
	if camp.site_present("smith"):
		for hero: Companion in party.members:
			if hero.body == null:
				var coat: Equipment = CampState.SMITH_STOCK.filter(func(g): return g.slot == "body")[0]
				if party.supplies.gold >= coat.price + 15 and camp.buy_gear(party, coat):
					stats["gold_spent"] += coat.price
					party.equip(hero, coat)
			var current: int = hero.weapon.attack_max if hero.weapon else 0
			if current < IRON_SWORD.attack_max and not hero.has_reach() and party.supplies.gold >= IRON_SWORD.price + 15:
				if camp.buy_gear(party, IRON_SWORD):
					stats["gold_spent"] += IRON_SWORD.price
					party.equip(hero, IRON_SWORD)


## Finer gear found: kept if there's room, and worn at once if it's better.
func _take_gear(gear: Equipment) -> void:
	if gear == null or not party.supplies.has_room_for_gear():
		return
	party.supplies.gear.append(gear)
	stats["gear_found"] += 1
	for hero: Companion in party.living_members():
		if gear in party.supplies.gear and _better(hero, gear):
			party.equip(hero, gear)
			stats["gear_equipped"] += 1


## Is `gear` an upgrade for `hero`? Weapons by expected damage per swing,
## armour by armour, then by quality.
func _better(hero: Companion, gear: Equipment) -> bool:
	if gear.slot == "body":
		var now: Equipment = hero.body
		return now == null or gear.armour > now.armour or (gear.armour == now.armour and gear.tier != "common" and now.tier == "common")
	if gear.slot != "weapon" or (hero.has_reach() and not gear.reach):
		return false
	var held: Equipment = hero.weapon
	var before := _swing(hero)
	hero.weapon = gear
	var after := _swing(hero)
	hero.weapon = held
	return after > before + 0.1


func _swing(hero: Companion) -> float:
	var span := hero.attack_range()
	return (span.x + span.y) / 2.0 * clampf(hero.hit_accuracy(), 0.1, 0.95)


## A careful player wears what they can read: uniques first, then magic or
## rare jewellery. Trinkets that might be cursed (gear that isn't unique)
## are sold instead (#135).
func _wear_trinkets() -> void:
	for hero: Companion in party.living_members():
		if hero.trinket:
			continue
		var uniques: Array = party.supplies.gear.filter(func(g: Equipment): return g.slot == "trinket" and g.tier == "unique")
		if not uniques.is_empty():
			party.wear(hero, uniques[0])
			stats["trinkets_worn"] += 1
			continue
		for item: SupplyItem in party.supplies.items:
			var trinket: Equipment = Trinkets.for_treasure(item) if party.supplies.count(item) > 0 else null
			if trinket and trinket.tier in ["magic", "rare"]:
				party.wear_treasure(hero, item)
				stats["trinkets_worn"] += 1
				break


func _mean_level() -> float:
	if party.members.is_empty():
		return 1.0
	var total := 0
	for hero in party.members:
		total += hero.level
	return float(total) / party.members.size()


func _back_at_camp(ending: int) -> void:
	if ending == 1:  # wiped (#83): main heroes wake hurt; recruits are lost
		for hero: Companion in party.members:
			if hero.is_unconscious():
				hero.health = 1
				hero.add_injury(DEEP_WOUND)
		party.supplies.lose_everything()
	camp.expedition_returned()
	Story.on_return(camp)
	for hero in party.members.duplicate():
		if not hero.is_with_party():
			party.remove_member(hero)
	camp.rejoin(party)
	var reward: int = camp.collect_contract(party)
	stats["gold_contracts"] += reward
	if camp.queen_defeated and not camp.bounty_paid:
		camp.bounty_paid = true
		party.supplies.gold += CampState.QUEEN_BOUNTY
		stats["bounty"] = CampState.QUEEN_BOUNTY


# --- An expedition -------------------------------------------------------

## Returns 0 returned, 1 wiped.
func _expedition(start_depth: int) -> int:
	steps = 0
	var deepest := 0
	if not party.supplies.torch_lit() and not party.supplies.has_lantern and party.supplies.count(TORCH) > 0:
		party.supplies.light_torch(TORCH)
	if not _enter_floor(start_depth, true):
		return 1
	while true:
		deepest = maxi(deepest, depth)
		var outcome := _explore_floor()
		if outcome == "wiped":
			stats["wipes"] += 1
			stats["wipes_by_floor"][depth] += 1
			return 1
		if outcome == "stuck":
			return 0
		if outcome == "down":
			if not _enter_floor(depth + 1, true):
				return 1
			continue
		# "home": climb out floor by floor.
		while depth > 0:
			var up: Vector2i = _map().find_content(C.STAIRS_UP)
			var walked := _walk_to(up, true)
			if walked == "wiped":
				stats["wipes"] += 1
				stats["wipes_by_floor"][depth] += 1
				return 1
			if walked == "stuck":
				var m = _map()
				var reach: Dictionary = m.reachable_from(cell)
				stats["stuck"] = "no way up on floor %d (at %s, up %s, reachable %d cells, in hall %s, gate broken %s)" % [depth, cell, up, reach.size(), cell in m.marks.get("hall", []), camp.gate_broken]
				return 0
			if depth == 1:
				break
			_enter_floor(depth - 1, false)
		camp.record_depth(deepest)
		stats["returns"] += 1
		return 0
	return 0


func _map():
	return floors[depth]


func _enter_floor(to: int, from_above: bool) -> bool:
	# Healing that's still working finishes between floors, at its time cost (#65).
	var waited: int = party.remaining_effect_time()
	party.advance_time(waited)
	party.complete_pending_effects()
	depth = to
	if not floors.has(to):
		var site_seed: int = first_seed + (camp.day - 1) * Main.DAY_SEED_STEP
		var layout: PackedStringArray = FloorGenerator.generate(site_seed + (to - 1) * Main.FLOOR_SEED_STEP, to < FLOORS, to)
		var marks := {}
		if to == FORTRESS_DEPTH:
			var fortress: Dictionary = Fortress.fortify(layout, camp.gate_broken)
			layout = fortress["layout"]
			marks = {"hall": fortress["hall"], "gates": fortress["gates"]}
		var avoid: Array = marks.get("hall", []) + marks.get("gates", [])
		var join: Dictionary = {}
		if not avoid.is_empty():
			var plain = DungeonMap.new(layout, to)
			join = plain.walking_distances(plain.find_content(C.STAIRS_UP))
		var stamped: Dictionary = Packages.place(layout, Packages.active(camp, to), site_seed + to * 7919 + 13, avoid, join)
		var map = DungeonMap.new(stamped["layout"], to)
		map.marks = marks
		for c in map.contents:
			var event: RoomEvent = events_rules.pick(map.contents[c], to)
			if event:
				map.events[c] = event
		for c in stamped["events"]:
			map.events[c] = stamped["events"][c]
		map.fight_groups = stamped["fights"]
		floors[to] = map
	var map = _map()
	cell = map.find_content(C.STAIRS_UP) if from_above else map.find_content(C.STAIRS_DOWN)
	if cell == Vector2i(-1, -1):
		cell = map.start_cell
	stats["visits_by_floor"][to] += 1
	if not stats["first_arrival"].has(str(to)):
		stats["first_arrival"][str(to)] = {"day": camp.day, "mean_level": _mean_level(), "party": party.members.size()}
	return true


## Explores a floor: every visible room event and fight, then the stairs
## down - or turns for home. Returns "down", "home", "wiped" or "stuck".
func _explore_floor() -> String:
	var map = _map()
	# A floor with nothing left to teach (#47): straight for the stairs,
	# as a player chasing the queen would.
	var exploring: bool = depth == FORTRESS_DEPTH or camp.xp_left.get(depth, 0) > 0
	var skip := {}  # rooms only reachable through the queen's hall
	var rounds := 0
	while exploring:
		rounds += 1
		if rounds > 200:
			stats["stuck"] = "exploring floor %d went round 200 times" % depth
			return "stuck"
		if _should_go_home():
			return "home"
		var target := _next_target(map, skip)
		if target == Vector2i(-1, -1):
			break
		var walked := _walk_to(target, false)
		if walked != "ok":
			return walked
		if cell != target and not map.triggered.has(target):
			skip[target] = true
	if _should_go_home():
		return "home"
	if depth < FORTRESS_DEPTH:
		var down: Vector2i = map.find_content(C.STAIRS_DOWN)
		if down == Vector2i(-1, -1):
			return "home"
		var walked := _walk_to(down, false)
		if walked != "ok":
			return walked
		return "down"
	return _fortress()


## The fortress floor (#44): break the gate, then face the queen.
func _fortress() -> String:
	var map = _map()
	_heal_up()
	if not camp.gate_broken:
		if _health_fraction() < GATE_ABOVE:
			return "home"
		# Walk next to a gate and break it (its guards fight).
		var gates: Array = map.marks.get("gates", [])
		var distances: Dictionary = map.walking_distances(cell)
		var best := Vector2i(-1, -1)
		var gate_at := Vector2i(-1, -1)
		for gate in gates:
			for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var beside: Vector2i = gate + d
				if distances.has(beside) and (best == Vector2i(-1, -1) or distances[beside] < distances[best]):
					best = beside
					gate_at = gate
		if best == Vector2i(-1, -1):
			stats["stuck"] = "no reachable gate on floor 4"
			return "stuck"
		var walked := _walk_to(best, false)
		if walked != "ok":
			return walked
		stats["gate_tries"] += 1
		var gate_before := _snapshot()
		var fight := _fight(Main.GATE_FIGHT, "gate")
		gate_before["won"] = fight == CS.Result.VICTORY
		stats["gate_attempts"].append(gate_before)
		if fight == CS.Result.DEFEAT:
			return "wiped"
		if fight != CS.Result.VICTORY:
			return "home"
		camp.gate_broken = true
		stats["gate_day"] = camp.day
		for hero: Companion in party.living_members():
			hero.change_strain(-Main.GATE_RELIEF)
		for gate in gates:
			map.doors[gate] = DungeonMap.Door.OPEN
		_heal_up()
	if _health_fraction() < QUEEN_ABOVE or party.living_members().size() < 2 and _mean_level() < 3.0:
		return "home"
	var hall: Array = map.marks.get("hall", [])
	if hall.is_empty():
		stats["stuck"] = "no queen's hall on floor 4"
		return "stuck"
	var walked := _walk_to(hall[0], false, true)
	if walked != "ok":
		return walked
	stats["queen_tries"] += 1
	var before := _snapshot()
	var result := _fight(Main.QUEEN_FIGHT, "queen")
	before["won"] = result == CS.Result.VICTORY
	before["rounds"] = stats["queen_rounds"]
	stats["queen_attempts"].append(before)
	if result == CS.Result.DEFEAT:
		return "wiped"
	camp.queen_defeated = true
	var prize: Equipment = Trinkets.unique_reward(trinket_rng, [])  # her hoard (#135)
	if prize:
		party.supplies.gear.append(prize)
	Quests.set_stage(camp, "queen_claim", Quests.Stage.RESOLVED)
	camp.contract = {}
	stats["queen_day"] = camp.day
	return "home"


## Nearest unused visible room event or fight on this floor.
func _next_target(map, skip := {}) -> Vector2i:
	var distances: Dictionary = map.walking_distances(cell)
	var best := Vector2i(-1, -1)
	for c in map.contents:
		var kind: int = map.contents[c]
		if map.triggered.has(c) or skip.has(c) or kind in [C.STAIRS_UP, C.STAIRS_DOWN, C.TRAP]:
			continue  # traps are hidden; you find them by walking
		var at: Vector2i = c
		if not distances.has(at):
			continue
		if best == Vector2i(-1, -1) or distances[at] < distances[best]:
			best = at
	return best


## Walks a shortest path to `to`, handling whatever each cell holds.
## Returns "ok", "wiped", "home" (a retreat), or "stuck".
func _walk_to(to: Vector2i, going_home: bool, into_hall := false) -> String:
	var map = _map()
	var path: Array[Vector2i] = map.walking_path(cell, to)
	if path.is_empty():
		return "stuck" if cell != to else "ok"
	for i in range(1, path.size()):
		var next: Vector2i = path[i]
		if not into_hall and next in map.marks.get("hall", []) and not camp.queen_defeated:
			return "ok"  # the hall is entered on purpose only
		cell = next
		steps += 1
		if steps > STEP_LIMIT:
			stats["stuck"] = "walked %d steps in one expedition" % STEP_LIMIT
			return "stuck"
		party.advance_time(party.step_time())
		_keep_light()
		var band: String = ["out", "dim", "steady", "bright"][party.supplies.light_band()]
		stats["steps_" + band] += 1
		var result := _on_enter(next)
		if result != "ok":
			return result
		if not going_home and _should_go_home():
			return "home"
	return "ok"


## What happens on entering a cell (main.gd's _on_party_entered_cell).
func _on_enter(at: Vector2i) -> String:
	var map = _map()
	var fight_cell: Vector2i = map.encounter_zones.get(at, Vector2i(-1, -1))
	if fight_cell != Vector2i(-1, -1) and not map.triggered.has(fight_cell):
		map.enter(fight_cell)
		var types: Array = map.fight_groups.get(fight_cell, [])  # a quest package's own fight
		if types.is_empty():
			types = Main.encounter_pool(depth, party.living_members().size()).pick_random()
		var result := _fight(types, "")
		if result == CS.Result.DEFEAT:
			return "wiped"
		if result == CS.Result.RETREAT:
			map.triggered.erase(fight_cell)
			party.advance_time(CS.RETREAT_TIME)
			return "home"
		_patch_up()
		return "ok"
	var content: int = map.enter(at)
	if content in [C.CHEST, C.TRAP, C.STRANGE_OBJECT, C.REST_SPOT]:
		return _event(at)
	return "ok"


## A room event: try investigations, then the first real choice.
func _event(at: Vector2i) -> String:
	var map = _map()
	var event: RoomEvent = map.events.get(at)
	if event == null:
		return "ok"
	stats["events"] += 1
	events_rules.depth = depth
	var gold_before: int = party.supplies.gold
	var flags: Array = []  # preparation carries over to the real choice (#114)
	for choice: EventChoice in event.choices:
		if choice.missing(party) != "":
			continue  # needs an item or gold the party lacks (#133)
		if not choice.investigation and choice.outcomes.any(func(o: EventOutcome): return o.boon and o.boon.bane):
			continue  # a careful player doesn't gamble on a curse (#133)
		var boons_before := _boon_count()
		var result: Dictionary = events_rules.resolve(party, choice, -1, flags)
		var boons_after := _boon_count()
		stats["boons"] += maxi(0, boons_after.x - boons_before.x)
		stats["banes"] += maxi(0, boons_after.y - boons_before.y)
		if not result["ambush"].is_empty():
			stats["gold_found"] += maxi(0, party.supplies.gold - gold_before)
			var fight := _fight(result["ambush"], "")
			if fight == CS.Result.DEFEAT:
				return "wiped"
			_patch_up()
			return "ok" if fight == CS.Result.VICTORY else "home"
		if not choice.investigation:
			break
	stats["gold_found"] += maxi(0, party.supplies.gold - gold_before)
	if party.living_members().is_empty():
		return "wiped"
	if event.kind == 2:  # a chest may hold finer gear, as in the game
		_take_gear(GearGen.drop(trinket_rng, depth, "chest"))
	_patch_up()
	return "ok"


# --- Fights --------------------------------------------------------------

## Runs a fight with the bot's policy. `kind` is "", "gate" or "queen".
func _fight(group: Array, kind: String) -> int:
	stats["fights"] += 1
	var types: Array[EnemyType] = []
	types.assign(group)
	var state = CS.new(party, types)
	state.rng.seed = randi()
	state.prepare(depth, kind)  # deeper is tougher; some elites (#140), as in the game
	var start_health := _total_health()
	var injuries_before := _injury_count()
	var guard := 0
	while state.result == CS.Result.ONGOING and guard < 400:
		var actor = state.current_actor()
		if actor is Companion:
			_hero_turn(state, actor, kind)
		elif actor != null:
			if actor.intent in [CS.Intent.KILLING_BLOW, CS.Intent.CLEAVER]:
				state.prepare_killing_blow(actor)
			state.enemy_act(actor)
		if state.result == CS.Result.ONGOING:
			state.advance()
		guard += 1
	if guard >= 400:
		stats["stuck"] = "a fight ran 400 turns (%s)" % ", ".join(PackedStringArray(group.map(func(t): return t.display_name)))
	stats["damage_by_floor"][depth] += maxi(0, start_health - _total_health())
	stats["injuries"] += maxi(0, _injury_count() - injuries_before)
	if kind == "queen":
		stats["queen_rounds"] = state.round
	for foe in state.foes:
		if foe.health <= 0:
			camp.count_kill(foe.type.display_name)
			if foe.type.purse.y > 0:
				var coins := randi_range(foe.type.purse.x, foe.type.purse.y)
				party.supplies.gold += coins
				stats["gold_found"] += coins
	if state.result == CS.Result.VICTORY:
		stats["fights_won"] += 1
		_award_xp(state, kind)
		# Tougher foes sometimes leave a trinket (#135), as in the game.
		for foe in state.foes:
			if foe.health > 0:
				continue
			_take_gear(GearGen.drop(trinket_rng, depth, "foe", foe.type.max_health, foe.elite != ""))
			if foe.type.drop and trinket_rng.randf() < foe.type.drop_chance:
				party.supplies.add_what_fits(foe.type.drop)
			var find = Trinkets.drop(trinket_rng, depth, foe.type.max_health, foe.elite != "")
			if find is Equipment and party.supplies.has_room_for_gear():
				party.supplies.gear.append(find)
				stats["trinkets_found"] += 1
			elif find is SupplyItem and party.supplies.add_what_fits(find) > 0:
				stats["trinkets_found"] += 1
	elif state.result == CS.Result.RETREAT:
		stats["fight_retreats"] += 1
	return state.result


## A hero's turn: brace against a heavy blow when hurt, drink when low,
## otherwise hit the weakest enemy in reach; retreat from a lost cause.
func _hero_turn(state, hero: Companion, kind: String) -> void:
	var foes: Array = state.living_foes()
	var heavy: bool = foes.any(func(f): return f.intent in [CS.Intent.HEAVY, CS.Intent.KILLING_BLOW, CS.Intent.CLEAVER])
	var fraction := float(hero.health) / maxf(1.0, hero.effective_max_health())
	if kind != "queen" and _health_fraction() < 0.2 and foes.any(func(f): return f.health * 2 > f.type.max_health):
		state.retreat()
		return
	if fraction < 0.3 and party.cannot_use_reason(DRAUGHT, true) == "":
		state.hero_use_item(DRAUGHT)
		return
	if heavy and fraction < 0.6 and state.hero_in_front(hero):
		state.hero_defend(hero)
		return
	var reachable: Array = state.targets_for(hero)
	if reachable.is_empty():
		if party.living_members().size() > 1 and hero.row == "back" and not hero.has_reach():
			state.hero_move(hero)
		else:
			state.hero_defend(hero)
		return
	reachable.sort_custom(func(a, b): return a.health < b.health)
	state.hero_attack(hero, reachable[0])


## main.gd's _award_fight_xp and _grant_xp.
func _award_xp(state, kind: String) -> void:
	var amount := 0
	match kind:
		"gate":
			amount = Progression.GATE_XP
		"queen":
			amount = Progression.QUEEN_XP + Progression.CLEARED_XP
		_:
			var threat := 0
			for foe in state.foes:
				if not foe.is_alive():
					threat += foe.type.threat
			amount = camp.take_floor_xp(depth, threat * Progression.XP_PER_THREAT)
			if camp.xp_left.get(depth, 0) <= 0 and not stats["xp_spent_out_day"].has(str(depth)):
				stats["xp_spent_out_day"][str(depth)] = camp.day
	if amount <= 0:
		return
	var benchmark: int = Progression.THRESHOLDS[maxi(1, camp.best_level - 1)] if camp.best_level > 1 else 0
	for hero: Companion in party.members:
		if hero.is_with_party():
			hero.xp += amount + clampi(benchmark - hero.xp, 0, amount)


# --- Between fights --------------------------------------------------------

## After a fight or event: drink, eat, bind and relight as needed.
## Boons (x) and banes (y) the party carries now.
func _boon_count() -> Vector2i:
	var count := Vector2i.ZERO
	for hero: Companion in party.members:
		for entry in hero.boons:
			if entry["boon"].bane:
				count.y += 1
			else:
				count.x += 1
	return count


func _patch_up() -> void:
	if party.cannot_use_reason(HOLY_WATER) == "":
		party.use_item(HOLY_WATER)  # lift a bane in the field
		stats["banes_lifted"] += 1
	for hero: Companion in party.living_members():
		if float(hero.health) / hero.effective_max_health() < 0.5 and party.cannot_use_reason(DRAUGHT) == "":
			party.use_item(DRAUGHT)
	if party.first_undressed_injured() and party.cannot_use_reason(DRESSING) == "":
		party.use_item(DRESSING)
	var hungry: bool = party.living_members().any(func(h): return h.is_hungry())
	if hungry and party.cannot_use_reason(RATION) == "":
		party.use_item(RATION)
	_keep_light()


## Before the gate or the queen: drink and eat what helps, then wait for it
## to take hold (time passes; light burns; nerves fray a little).
func _heal_up() -> void:
	for hero: Companion in party.living_members():
		if float(hero.health) / hero.effective_max_health() < 0.75 and party.cannot_use_reason(DRAUGHT) == "":
			party.use_item(DRAUGHT)
	if _health_fraction() < 0.9 and party.cannot_use_reason(RATION) == "":
		party.use_item(RATION)
	var wait: int = party.remaining_effect_time()
	for i in wait:
		party.advance_time(1)
		_keep_light()


func _keep_light() -> void:
	var supplies = party.supplies
	if supplies.has_lantern and supplies.oil < 25.0 and party.cannot_use_reason(OIL) == "":
		party.use_item(OIL)
		stats["flasks_used"] += 1
	if supplies.light_band() == Supplies.Light.OUT and supplies.count(TORCH) > 0 and not supplies.torch_lit():
		supplies.light_torch(TORCH)
		stats["torches_lit"] += 1


func _should_go_home() -> bool:
	if party.living_members().is_empty():
		return true
	var supplies = party.supplies
	var no_light: bool = not supplies.has_lantern and supplies.count(TORCH) == 0 and not supplies.torch_lit()
	if no_light:
		stats["home_no_light"] += 1
		return true
	var healing: int = supplies.count(DRAUGHT) + supplies.count(RATION)
	if _health_fraction() < HOME_BELOW and healing == 0:
		return true
	if _health_fraction() < 0.3:
		return true
	return party.living_members().any(func(h: Companion): return h.strain_state() == StrainRules.State.PANICKING)


func _snapshot() -> Dictionary:
	return {"day": camp.day, "health": snappedf(_health_fraction(), 0.01), "size": party.living_members().size(),
			"levels": party.living_members().map(func(h): return h.level),
			"armour": party.living_members().filter(func(h): return h.body != null).size(),
			"strain": party.living_members().map(func(h): return roundi(h.strain)),
			"effect": party.living_members().map(func(h): return h.effectiveness()),
			"injured": party.living_members().filter(func(h): return not h.hindering_injuries().is_empty()).size(),
			"light": Supplies.LIGHT_NAMES[party.supplies.light_band()],
			"heroes": party.living_members().map(func(h): return "%s L%d %d/%d atk %s acc %.2f init %d wpn %s row %s" % [h.role if h.role != "" else h.display_name, h.level, h.health, h.effective_max_health(), h.attack_range(), h.hit_accuracy(), h.effective_initiative(), h.weapon.display_name if h.weapon else "-", h.row]),
			"roles": party.living_members().map(func(h): return h.role if h.role != "" else h.display_name)}


func _health_fraction() -> float:
	var have := 0
	var most := 0
	for hero: Companion in party.members:
		if hero.is_with_party():
			have += maxi(0, hero.health)
			most += hero.effective_max_health()
	return float(have) / maxf(1.0, most)


func _total_health() -> int:
	var total := 0
	for hero: Companion in party.members:
		total += maxi(0, hero.health)
	return total


func _injury_count() -> int:
	var total := 0
	for hero: Companion in party.members:
		total += hero.injuries.size()
	return total


# --- The report ------------------------------------------------------------

func _summarise(all: Dictionary) -> void:
	print("\n=== SUMMARY ===")
	for hero in all:
		var runs: Array = all[hero]
		var won: Array = runs.filter(func(r): return r["won"])
		print("\n%s: queen dead in %d/%d campaigns" % [hero, won.size(), runs.size()])
		if not won.is_empty():
			print("  days to win: median %s (range %d-%d); expeditions median %s" % [_median(won.map(func(r): return r["days"])),
					won.map(func(r): return r["days"]).min(), won.map(func(r): return r["days"]).max(), _median(won.map(func(r): return r["expeditions"]))])
		print("  wipes per campaign: mean %.2f; by floor %s" % [_mean(runs.map(func(r): return r["wipes"])), _sum_dicts(runs, "wipes_by_floor")])
		var dmg := _sum_dicts(runs, "damage_by_floor")
		var vis := _sum_dicts(runs, "visits_by_floor")
		var per_visit := {}
		for f in dmg:
			per_visit[f] = snappedf(float(dmg[f]) / maxf(1.0, vis[f]), 0.1)
		print("  health lost per floor visit: %s (visits %s)" % [per_visit, vis])
		for f in ["1", "2", "3", "4"]:
			var arrivals: Array = runs.filter(func(r): return r["first_arrival"].has(f)).map(func(r): return r["first_arrival"][f])
			if not arrivals.is_empty():
				print("  first reached floor %s: day median %s, mean party level %.2f, party size %.1f (%d runs)" % [f,
						_median(arrivals.map(func(a): return a["day"])), _mean(arrivals.map(func(a): return a["mean_level"])),
						_mean(arrivals.map(func(a): return a["party"])), arrivals.size()])
		print("  fights %.1f (won %.0f%%), fight retreats %.1f, events %.1f, injuries %.1f, nurse treatments %.1f per campaign" % [
				_mean(runs.map(func(r): return r["fights"])),
				100.0 * _mean(runs.map(func(r): return r["fights_won"])) / maxf(1.0, _mean(runs.map(func(r): return r["fights"]))),
				_mean(runs.map(func(r): return r["fight_retreats"])), _mean(runs.map(func(r): return r["events"])),
				_mean(runs.map(func(r): return r["injuries"])), _mean(runs.map(func(r): return r["treated"]))])
		print("  gold per campaign: found %.0f, contracts %.0f, sold %.0f, spent %.0f; lantern bought in %d runs; route bought %.1f times" % [
				_mean(runs.map(func(r): return r["gold_found"])), _mean(runs.map(func(r): return r["gold_contracts"])),
				_mean(runs.map(func(r): return r["gold_sold"])), _mean(runs.map(func(r): return r["gold_spent"])),
				runs.filter(func(r): return r["lantern_day"] > 0).size(), _mean(runs.map(func(r): return r["route_bought"]))])
		print("  boons gained %.1f, banes gained %.1f, banes lifted %.1f per campaign (#133); trinkets found %.1f, worn %.1f (#135); gear found %.1f, equipped %.1f" % [
				_mean(runs.map(func(r): return r["boons"])), _mean(runs.map(func(r): return r["banes"])),
				_mean(runs.map(func(r): return r["banes_lifted"])), _mean(runs.map(func(r): return r["trinkets_found"])),
				_mean(runs.map(func(r): return r["trinkets_worn"])), _mean(runs.map(func(r): return r["gear_found"])),
				_mean(runs.map(func(r): return r["gear_equipped"]))])
		var light_steps: float = _mean(runs.map(func(r): return r["steps_bright"] + r["steps_steady"] + r["steps_dim"] + r["steps_out"]))
		print("  light: steps bright %.0f%%, steady %.0f%%, dim %.0f%%, out %.0f%%; torches lit %.1f, oil flasks %.1f; trips ended for want of light %.1f per campaign" % [
				100.0 * _mean(runs.map(func(r): return r["steps_bright"])) / maxf(1.0, light_steps),
				100.0 * _mean(runs.map(func(r): return r["steps_steady"])) / maxf(1.0, light_steps),
				100.0 * _mean(runs.map(func(r): return r["steps_dim"])) / maxf(1.0, light_steps),
				100.0 * _mean(runs.map(func(r): return r["steps_out"])) / maxf(1.0, light_steps),
				_mean(runs.map(func(r): return r["torches_lit"])), _mean(runs.map(func(r): return r["flasks_used"])),
				_mean(runs.map(func(r): return r["home_no_light"]))])
		var gate_runs: Array = runs.filter(func(r): return r["gate_tries"] > 0)
		var queen_runs: Array = runs.filter(func(r): return r["queen_tries"] > 0)
		print("  gate: tried in %d runs (%.1f tries each), broken by day median %s" % [gate_runs.size(), _mean(gate_runs.map(func(r): return r["gate_tries"])),
				_median(runs.filter(func(r): return r["gate_day"] > 0).map(func(r): return r["gate_day"]))])
		print("  queen: tried in %d runs (%.1f tries each), won %d; rounds in the winning fight median %s" % [queen_runs.size(),
				_mean(queen_runs.map(func(r): return r["queen_tries"])), won.size(), _median(won.map(func(r): return r["queen_rounds"]))])
		print("  floor XP used up by day (median): %s" % _xp_days(runs))
		print("  levels at the end: %s" % _level_spread(runs))
		var stuck: Array = runs.filter(func(r): return r["stuck"] != "")
		print("  STUCK runs: %d %s" % [stuck.size(), stuck.map(func(r): return "%d: %s" % [r["seed"], r["stuck"]])])


func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += float(v)
	return total / values.size()


func _median(values: Array):
	if values.is_empty():
		return "-"
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]


func _sum_dicts(runs: Array, key: String) -> Dictionary:
	var out := {}
	for r in runs:
		for k in r[key]:
			out[k] = out.get(k, 0) + r[key][k]
	return out


func _xp_days(runs: Array) -> Dictionary:
	var out := {}
	for f in ["1", "2", "3", "4"]:
		var days: Array = runs.filter(func(r): return r["xp_spent_out_day"].has(f)).map(func(r): return r["xp_spent_out_day"][f])
		out[f] = "%s (%d runs)" % [_median(days), days.size()]
	return out


func _level_spread(runs: Array) -> Dictionary:
	var out := {}
	for r in runs:
		for level in r["levels_at_end"]:
			out[level] = out.get(level, 0) + 1
	return out
