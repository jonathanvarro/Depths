extends SceneTree
## Owner playtest, 2026-11-23 (second round): a pointer to the quest site,
## bigger stacks of monster materials, a visible panic bolt, spare torches
## and lightable lanterns on the walls, and clear pools in dripping halls.
## Args: tag, screenshot dir.

const WallLights := preload("res://scripts/wall_lights.gd")
const Q := preload("res://scripts/quests.gd")
const Supplies := preload("res://scripts/supplies.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	# Monster materials stack a little higher.
	var stacks := {"rat_pelt": 8, "bat_wing": 8, "spider_silk": 8, "goblin_scrap": 8, "beetle_shell": 5, "hound_hide": 4}
	for id in stacks:
		var item: SupplyItem = load("res://data/items/%s.tres" % id)
		check("%s stacks to %d" % [id, stacks[id]], item.stack_size() == stacks[id], item.stack_size())

	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 77
	root.add_child(main)
	await create_timer(0.5).timeout
	Q.set_stage(main._camp_state, "left_behind", Q.Stage.RESOLVED)
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	await process_frame

	# Panic bolts with a quick spin, a blink and a racing heart.
	var party = main._party
	var yaw: float = party.rotation.y
	var tries := 0
	while tries < 20:
		party._bolt()
		if not is_equal_approx(party.rotation.y, yaw) or party._busy:
			break
		tries += 1
	check("a bolt spins round over a moment, not in a cut", party._busy and party.BOLT_TURN_TIME > 0.1, [party._busy])
	await create_timer(1.0).timeout
	check("...and shows a blink", main._panic_blink != null)
	check("...then runs on", not party._busy)
	# A short cooldown after a bolt (owner, 2026-11-24).
	check("after a bolt, nerves settle for a few steps", party.panic_rest > 0 and party.panic_rest < party.PANIC_COOLDOWN, party.panic_rest)
	party.panic_chance = 1.0
	check("...so the next step can't bolt, even at certain panic", not party.bolts_now(), party.panic_rest)
	party.panic_rest = 0
	check("...until it has passed", party.bolts_now())
	party.panic_chance = 0.0
	# Resting at camp shows the night passing, without a day count.
	main._camp._camp = main._camp_state
	main._camp._show_rest()
	var veil = main._camp.get_node_or_null("RestVeil")
	check("resting at camp shows the night passing", veil != null and not veil.get_child(0).text.contains("Day"), veil.get_child(0).text if veil else "")
	# Once between trips, unless nobody can go and the nurse needs the nights.
	var rest_camp = load("res://scripts/camp_state.gd").new()
	var rest_party = load("res://scripts/party_state.gd").new()
	rest_party.add_member(load("res://data/companions/mara.tres"))
	check("a rest is allowed", rest_camp.can_rest(rest_party))
	rest_camp.rest(rest_party)
	check("...but not twice in a row", not rest_camp.can_rest(rest_party))
	rest_camp.leave_behind(rest_party)
	rest_camp.rejoin(rest_party)
	check("...until the party has been down again", rest_camp.can_rest(rest_party))
	rest_camp.rest(rest_party)
	rest_party.members[0].add_injury(load("res://data/injuries/deep_wound.tres"))
	rest_camp.treat(rest_party.members[0])
	check("...or nobody is fit to go", rest_camp.can_rest(rest_party))
	# Every result chip describes itself (a rest spot's too).
	var rest_spot: RoomEvent = load("res://data/events/rest_dry_alcove.tres")
	var rested: Dictionary = main._room_events.resolve(main._party_state, rest_spot.choices[0])
	check("event result icons all describe themselves", not rested["changes"].is_empty() and rested["changes"].all(func(c): return c.get("tip", "").length() > 5), rested["changes"].map(func(c): return c.get("tip", "")))

	# Wall lights on every floor.
	var map = main._map
	var lights: Dictionary = map.marks.get("wall_lights", {})
	var torches: Array = lights.keys().filter(func(c): return lights[c]["kind"] == "torch")
	var lanterns: Array = lights.keys().filter(func(c): return lights[c]["kind"] == "lantern")
	check("a floor has spare torches and old lanterns on its walls", torches.size() >= 1 and lanterns.size() >= 1, [torches.size(), lanterns.size()])
	check("...with art for each", main._wall_light_nodes.size() == lights.size(), main._wall_light_nodes.size())
	check("...on clear cells against a wall", lights.keys().all(func(c): return map.content_at(c) == 0 and map.is_wall(c + lights[c]["side"])))

	var supplies = main._party_state.supplies
	var before: int = supplies.count(main.TORCH)
	# Only on purpose (2026-11-24): stepping into the cell does nothing,
	# walking into its wall takes it.
	party.place(map, torches[0])
	main._on_party_entered_cell(torches[0])
	check("passing by a spare torch leaves it", supplies.count(main.TORCH) == before and not lights[torches[0]]["taken"])
	main._on_party_bumped_wall(torches[0] + lights[torches[0]]["side"])
	check("walking into its wall takes it", supplies.count(main.TORCH) == before + 1 and lights[torches[0]]["taken"] and not main._wall_light_nodes.has(torches[0]))
	main._on_party_bumped_wall(torches[0] + lights[torches[0]]["side"])
	check("...only once", supplies.count(main.TORCH) == before + 1)

	# In the dark: light an old lantern and the map works again.
	supplies.source = Supplies.Source.NONE
	supplies.oil = 0.0
	supplies.glow_left = 0.0
	var spot: Vector2i = lanterns[0]
	party.place(map, spot)
	main._update_lantern()
	check("in the dark, no light, no map", not party.lit and main._minimap.dark)
	check("a lantern to light hangs whole and straight", main._wall_light_nodes[spot].get_node("Model/Glass").visible and is_zero_approx(main._wall_light_nodes[spot].get_node("Model").rotation.z))
	var broken = main.Dressing._put(Node3D.new(), "lantern-hanging", Vector3.ZERO, 0.0)
	check("...while the dressing's are broken and askew", not broken.get_node("Model/Glass").visible and broken.get_node("Model").rotation.z > 0.1 and not broken.lit)
	broken.get_parent().free()
	main._on_party_bumped_wall(spot + lights[spot]["side"])
	check("walking into its wall offers to light it", main._prompt.visible and main._prompt_action.is_valid())
	main._prompt.visible = false
	party.locked = false
	var hero: Companion = main._party_state.living_members()[0]
	hero.strain = 40.0
	main._light_wall_lantern(spot)
	check("lighting an old lantern eases nerves a little", hero.strain < 40.0 and hero.strain > 30.0, hero.strain)
	check("...and its light lets the map work", party.lit and not main._minimap.dark and main._party_state.near_light)
	check("...the lantern burns", main._wall_light_nodes[spot].get_node("WallLanternLight").visible)
	for member in main._party_state.members:
		member.hunger = 0  # hunger frays nerves too; this is about the light
	var calm: float = hero.strain
	main._party_state.advance_time(5)
	check("in its light, nerves ease very slightly over time", hero.strain < calm and hero.strain > calm - 2.0, [calm, hero.strain])
	main._party_state.advance_time(WallLights.BURN)
	main._update_lantern()
	main._refresh_wall_lights()
	check("it burns out in time", not party.lit and not main._wall_light_nodes[spot].get_node("WallLanternLight").visible)

	# Monster spawns are left off the map; found traps stay.
	check("no monster marks on the map", main.Minimap.marker_for(1) == null and main.Minimap.marker_for(3) != null)
	# Rows change on the go: tap a card's row tag.
	var member: Companion = main._party_state.members[0]
	var row_before := member.row
	main._swap_row(main._cards[0])
	check("tapping a card's row tag swaps rows while exploring", member.row != row_before, member.row)
	main._in_combat = true
	main._swap_row(main._cards[0])
	main._in_combat = false
	check("...but not in a fight (Move takes a turn there)", member.row != row_before)
	# The quest site's pointer and tip are there for an open site.
	check("no pointer to quest sites any more (owner, 2026-11-25)", not main._minimap.has_method("_draw_quest_pointer"))

	# Dripping halls: two in three hold a clear pool, safer than the still pool.
	var halls := 0
	var pools := 0
	for s in 150:
		main._site_seed = 3000 + s
		main._floors.clear()
		main._go_to_floor(1 + s % 3, main.Arrival.FROM_ABOVE)
		if main._map.landmarks.any(func(l): return l["id"] == "dripping_hall"):
			halls += 1
			var pool: Vector2i = main._map.marks.get("dripping_pool", Vector2i(-1, -1))
			if pool != Vector2i(-1, -1):
				pools += 1
				var hall: Dictionary = main._map.landmarks.filter(func(l): return l["id"] == "dripping_hall")[0]
				if pools == 1:
					check("the pool is in the hall", pool in hall["cells"] and main._map.events.get(pool) == main.DRIPPING_POOL_EVENT and main._props.has(pool))
					main._build_level()
					check("...and stays there when the level is rebuilt", main._map.marks.get("dripping_pool") == pool and main._map.events.get(pool) == main.DRIPPING_POOL_EVENT)
		if halls >= 12:
			break
	check("most dripping halls hold a clear pool", halls >= 6 and pools * 2 >= halls, [pools, halls])
	# Wall pieces (a coal seam, a shrine) always stand against a wall.
	var loose := 0
	var wall_pieces := 0
	for s in 40:
		main._site_seed = 5000 + s
		main._floors.clear()
		main._go_to_floor(1 + s % 4, main.Arrival.FROM_ABOVE)
		for c in main._map.events:
			if main._map.events[c].prop_on_wall:
				wall_pieces += 1
				if main.Dressing._wall_sides(main._map, c).is_empty():
					loose += 1
	check("wall pieces (coal seams, shrines) always have a wall behind them", wall_pieces > 10 and loose == 0, [loose, wall_pieces])
	# A torch can be lit in a fight; it takes the hero's turn like any item.
	check("a torch can be lit in a fight", main.TORCH.usable_in_combat)
	main._party_state.supplies.source = Supplies.Source.NONE
	check("...when none is burning", main._party_state.cannot_use_reason(main.TORCH, true) == "", main._party_state.cannot_use_reason(main.TORCH, true))
	# Old Whisker is a real fight now.
	var Elites = load("res://scripts/elites.gd")
	check("Old Whisker brings two great rats and two rats", Elites.types("whisker").size() == 4)
	# 2026-11-24: the stash's gold spends at camp, pack first.
	var purse_camp = load("res://scripts/camp_state.gd").new()
	var purse_party = load("res://scripts/party_state.gd").new()
	purse_party.add_member(load("res://data/companions/mara.tres"))
	purse_party.supplies.gold = 1
	purse_camp.stash.gold = 50
	purse_camp.site_presence["supplies"] = true
	purse_camp.merchant_unloading = false
	var torch_item: SupplyItem = load("res://data/items/torch.tres")
	var torch_price: int = purse_camp.price_for(purse_party, torch_item.price)
	check("the merchant takes gold from the stash too", purse_camp.can_trade() and purse_camp.buy(purse_party, torch_item) and purse_party.supplies.gold == 0 and purse_camp.stash.gold == 51 - torch_price, [purse_party.supplies.gold, purse_camp.stash.gold, torch_price])
	purse_camp.stash.gold = 0
	check("...but not more than there is", not purse_camp.buy(purse_party, torch_item))
	# Rook's still face matches his rig.
	var rook: Companion = load("res://scripts/named_cast.gd").make(purse_camp, "rook")
	check("Rook's picture by the fire is his own face", rook.portrait.resource_path == "res://art/portraits/fixer-v1/fixer-a/preview.png" and rook.portrait_set.resource_path.ends_with("fixer-a.tres"), rook.portrait.resource_path)
	# The results explain an injury in numbers.
	var tip: String = load("res://scripts/results_screen.gd").injury_tip(load("res://data/injuries/deep_wound.tres"))
	check("a deep wound is explained in numbers on the results", tip.contains("-5 maximum health") and tip.contains("2 nights"), tip)
	var clear: RoomEvent = main.DRIPPING_POOL_EVENT
	var good := 0
	var total := 0
	for o: EventOutcome in clear.choices[0].outcomes:
		total += o.weight
		if o.health >= 0 and o.strain <= 0.0:
			good += o.weight
	check("drinking from it never hurts", good == total)
	print("fails=", fails)
	quit()
