extends SceneTree
## Read-only gameplay research for #134, at the 2026-10-21 baseline.
## Observations here document current behaviour; they are not proposed balance rules.
## Godot --headless --path . --script tools/boon_tradeoff_review.gd
## Writes only res://build/boon-review/audit.json. No player saves are read/written.

const PartyRules := preload("res://scripts/party_state.gd")
const EventRules := preload("res://scripts/room_events.gd")
const SaveRules := preload("res://scripts/save_game.gd")

var checks := 0
var failures := 0
var report := {"date": "2026-10-21", "baseline": "7560c71", "scope": "Live rule and event-screen probes, not a campaign balance simulation"}


func _initialize() -> void:
	_run.call_deferred()


func observe(label: String, condition: bool) -> void:
	checks += 1
	if not condition:
		failures += 1
	print("PASS " if condition else "FAIL ", label)


func party_with_mara():
	var party = PartyRules.new()
	party.add_member(load("res://data/companions/mara.tres"))
	return party


func boon(id: String) -> Boon:
	return load("res://data/boons/%s.tres" % id)


func event(id: String) -> RoomEvent:
	return load("res://data/events/%s.tres" % id)


func choice_at(room: RoomEvent, prefix: String) -> EventChoice:
	for choice: EventChoice in room.choices:
		if choice.label.begins_with(prefix):
			return choice
	return null


func ambush_probability(choice: EventChoice, hunted: bool, flags: Array = []) -> float:
	var total := 0
	var bad := 0
	for outcome: EventOutcome in choice.outcomes:
		if outcome.blocked_by != "" and outcome.blocked_by in flags:
			continue
		var weight: int = outcome.weight * (2 if hunted and not outcome.ambush.is_empty() else 1)
		total += weight
		if not outcome.ambush.is_empty():
			bad += weight
	return float(bad) / total if total else 0.0


func full_tank_time(rate: float) -> int:
	var supplies = load("res://scripts/supplies.gd").new()
	var elapsed := 0
	while supplies.oil > 0.0 and elapsed < 10000:
		supplies.burn(1, rate)
		elapsed += 1
	return elapsed


func _run() -> void:
	var rules = EventRules.new()
	rules.rng.seed = 13420261021
	var party = party_with_mara()
	var hero: Companion = party.members[0]
	var definitions := []
	for file in DirAccess.get_files_at("res://data/boons"):
		if not file.ends_with(".tres"):
			continue
		var effect: Boon = load("res://data/boons/" + file)
		definitions.append({"id": file.get_basename(), "name": effect.display_name, "bane": effect.bane, "fights": effect.fights, "description": effect.description})
	report["effects"] = definitions
	observe("eleven current effect definitions", definitions.size() == 11)

	# The one mixed bargain keeps its cost attached: cleansing cannot strip just the downside.
	hero.add_boon(boon("blood_of_the_deep"))
	report["mixed_bargain"] = {"damage": hero.boon_total("damage"), "healing_multiplier": hero.boon_product("healing"), "cleanse_recognizes_as_bane": hero.has_bane(), "lift_returns_null": hero.lift_bane() == null}
	observe("Blood's upside and downside are bundled, not cleanseable separately", hero.boon_total("damage") == 2 and is_equal_approx(hero.boon_product("healing"), 0.5) and not hero.has_bane())
	hero.boons.clear()
	hero.add_boon(boon("withering"))
	hero.add_boon(boon("sickness"))
	hero.trip_ended()
	observe("trip return clears Sickness but keeps three-fight Withering", hero.boons.size() == 1 and hero.boons[0]["boon"] == boon("withering"))
	var restored := Companion.new()
	SaveRules.unpack_into(restored, SaveRules.pack_object(hero))
	observe("fight duration and resource identity survive serialization", restored.boons.size() == 1 and restored.boons[0]["fights_left"] == 3 and restored.boons[0]["boon"] == boon("withering"))
	hero.add_boon(boon("withering"))
	observe("repeated same effect refreshes without stacking", hero.boons.size() == 1 and hero.boons[0]["fights_left"] == 3)
	hero.fight_ended()
	report["duration"] = {"after_trip": "Sickness gone, Withering kept", "after_one_fight_end": hero.boons[0]["fights_left"], "saved_fights_left": restored.boons[0]["fights_left"]}

	# Well healing is scheduled BEFORE its Hearty boon is granted.
	party = party_with_mara()
	hero = party.members[0]
	party.supplies.add(load("res://data/items/antidote.tres"))
	var well_choice := choice_at(event("object_fouled_well"), "Stir")
	rules.resolve(party, well_choice, 0)
	var scheduled: float = hero.pending_effects[-1]["per_unit"] * hero.pending_effects[-1]["units_left"]
	report["well"] = {"scheduled_healing": scheduled, "future_healing_multiplier": hero.boon_product("healing"), "first_target": hero.display_name, "targets": well_choice.outcomes[0].target}
	observe("well schedules eight, then grants +50% to later healing doses", is_equal_approx(scheduled, 8.0) and is_equal_approx(hero.boon_product("healing"), 1.5))
	hero.pending_effects.clear()
	hero.add_effect_over_time("health", 8, 20)
	observe("a later eight-point dose becomes twelve", is_equal_approx(hero.pending_effects[-1]["per_unit"] * 20, 12.0))
	hero.boons.clear()
	hero.pending_effects.clear()
	hero.add_effect_over_time("health", 8, 20)
	hero.add_boon(boon("blood_of_the_deep"))
	observe("already-scheduled healing is not rescaled by a later pact", is_equal_approx(hero.pending_effects[-1]["per_unit"] * 20, 8.0))

	# Two ways to spend the same initial full lantern plus full flask.
	var normal := full_tank_time(1.0)
	var blessed := full_tank_time(0.75)
	report["oil"] = {"normal_tank_steps": normal, "blessed_tank_steps": blessed, "keep_flask_two_tank_steps": normal * 2, "offer_flask_one_blessed_tank_steps": blessed, "flask_amount": load("res://data/items/oil_flask.tres").amount, "excludes": "event/refill time, light's combat effects, free refills and extra flasks"}
	observe("with only one spare flask, keeping its fuel lasts longer than offering it", normal * 2 > blessed)
	party = party_with_mara()
	var traps_before: bool = party.sees_traps()
	party.members[0].add_boon(boon("deep_eyes"))
	report["deep_eyes_with_mara"] = {"before": traps_before, "after": party.sees_traps()}
	observe("Deep eyes duplicates Mara's existing trap visibility", traps_before and party.sees_traps())

	# Marked doubles weights, not normalized probabilities. Preparation still removes an outcome.
	var stash := choice_at(event("chest_goblin_stash"), "Dig")
	var normal_chance := ambush_probability(stash, false)
	var marked_chance := ambush_probability(stash, true)
	var marked_rolls := 0
	for i in 10000:
		if not rules._pick_outcome(stash, [], true).ambush.is_empty():
			marked_rolls += 1
	report["marked"] = {"normal_probability": normal_chance, "marked_probability": marked_chance, "actual_seeded_ambushes_per_10000": marked_rolls, "prepared_and_marked_probability": ambush_probability(stash, true, ["charm_down"])}
	observe("stash ambush is 25% normally and 40% when marked", is_equal_approx(normal_chance, 0.25) and is_equal_approx(marked_chance, 0.4))
	observe("seeded weighted sampler agrees within two percentage points", absf(float(marked_rolls) / 10000 - marked_chance) < 0.02)
	observe("taking the charm down still rules out an ambush while marked", is_equal_approx(ambush_probability(stash, true, ["charm_down"]), 0.0))

	var shrine_event := event("object_defiled_shrine")
	var touch := choice_at(shrine_event, "Touch")
	var flags: Array = []
	var studied_party = party_with_mara()
	rules.resolve(studied_party, choice_at(shrine_event, "Study"), 0, flags)
	report["new_shrine_coin_flags"] = {}
	for id in ["object_miners_shrine", "object_defiled_shrine", "object_fouled_well", "chest_buried_cache"]:
		report["new_shrine_coin_flags"][id] = event(id).choices.any(func(c): return c.coin_flip)
	observe("new shrine study grants a narrative clue without a preparation flag", flags.is_empty() and touch.outcomes[0].weight == touch.outcomes[1].weight)
	observe("new shrine gambles do not invoke the visible coin", report["new_shrine_coin_flags"].values().all(func(v): return not v))
	observe("old rigged strongbox still invokes the coin", event("chest_strongbox").choices[0].coin_flip)
	var pick_party = party_with_mara()
	pick_party.supplies.add(load("res://data/items/pick.tres"))
	rules.resolve(pick_party, choice_at(event("chest_buried_cache"), "Break"), 0)
	var ore_count: int = pick_party.supplies.count(load("res://data/items/copper_ore.tres"))
	report["pick_cache_ore_granted"] = ore_count
	observe("loaded pick-cache outcome grants no promised ore", ore_count == 0)

	# Event-screen information and a real choice -> Continue -> finished signal.
	var screen = load("res://scripts/event_screen.gd").new()
	root.add_child(screen)
	await process_frame
	party = party_with_mara()
	screen.show_event(shrine_event, party, rules)
	var labels: Array = screen._buttons.get_children().map(func(b): return b.text)
	report["defiled_shrine_before_choice"] = {"clue": screen._body.text, "buttons": labels}
	observe("Touch label does not disclose effect, duration or probability", not str(labels).contains("healing") and not str(labels).contains("50%") and not str(labels).contains("3 fights"))
	await process_frame
	party = party_with_mara()
	party.supplies.add(load("res://data/items/spade.tres"))
	party.supplies.add_what_fits(load("res://data/items/torch.tres"), 999)
	var found: Array = []
	var emitted: Array = []
	rules.loot_found.connect(func(loot): found.append(loot))
	screen.finished.connect(func(result): emitted.append(result))
	var cache := event("chest_buried_cache")
	screen.show_event(cache, party, rules)
	screen._choose(choice_at(cache, "Dig it out"))
	await process_frame
	var continue_button: Button = screen._buttons.get_children().filter(func(b): return b.text == "Continue")[0]
	continue_button.pressed.emit()
	report["full_pack_event_screen"] = {"loot_generated": not found.is_empty(), "finished_result_has_no_room": emitted[0].has("no_room"), "finished_result_keys": emitted[0].keys()}
	observe("event UI emits no overflow payload despite generating full-pack loot", not found.is_empty() and not emitted[0].has("no_room"))
	# The chest sound is cosmetic; release its playback before this short probe exits.
	for child in screen.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await create_timer(0.2).timeout
	screen.queue_free()
	await process_frame
	report["checks"] = checks
	report["failures"] = failures
	report["runtime_file_hashes"] = {}
	for path in ["scripts/boon.gd", "scripts/companion.gd", "scripts/room_events.gd", "scripts/event_screen.gd", "scripts/main.gd"]:
		report["runtime_file_hashes"][path] = FileAccess.get_sha256("res://" + path)
	DirAccess.make_dir_recursive_absolute("res://build/boon-review")
	var output := FileAccess.open("res://build/boon-review/audit.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t") + "\n")
	output.close()
	print("Research observations: ", checks, ", failures: ", failures)
	quit.call_deferred(1 if failures else 0)
