extends SceneTree
## Research for #97. Uses live combat and isolated in-memory hero copies.
## Does not change gameplay definitions, saves, XP or the shipping rules.
## Godot --headless --path . --log-file <writable path> --script res://tools/stats_research_probe.gd

const CS := preload("res://scripts/combat_state.gd")
const PS := preload("res://scripts/party_state.gd")
const SuppliesDef := preload("res://scripts/supplies.gd")
const RUNS := 600
const SEED_BASE := 20261018
const OUTPUT := "res://docs/stats-monsters-xp-results.json"
const PROFILES := {
	"Guide": {"hp": 20, "attack": Vector2i(2, 4), "accuracy": 0.75, "initiative": 10, "guard": 0.5, "toughness": 0, "str": 2},
	"Warden": {"hp": 24, "attack": Vector2i(2, 3), "accuracy": 0.70, "initiative": 8, "guard": 0.25, "toughness": 0, "str": 2},
	"Scout": {"hp": 16, "attack": Vector2i(2, 3), "accuracy": 0.85, "initiative": 13, "guard": 0.5, "toughness": 0, "str": 1},
	"Brawler": {"hp": 22, "attack": Vector2i(3, 5), "accuracy": 0.65, "initiative": 9, "guard": 0.5, "toughness": -1, "str": 3},
}


func _initialize() -> void:
	var cases := {
		"floor1_rats": ["rat", "rat", "rat"],
		"floor1_mixed": ["rat", "spider"],
		"floor2_mixed": ["goblin", "rat", "rat"],
		"floor2_spiders": ["spider", "spider"],
		"floor3_patrol": ["goblin", "goblin", "goblin_archer"],
		"floor3_venom": ["goblin", "spider", "spider", "rat"],
		"fortress_gate": ["goblin_guard", "goblin_guard", "goblin_archer"],
		"queen": ["goblin_queen", "goblin_guard", "goblin_guard"],
	}
	var scenarios := [
		{"id": "current_L1", "level": 1, "armour": 0, "candidate": false, "scout": false, "worn": false},
		{"id": "candidate_L1", "level": 1, "armour": 0, "candidate": true, "scout": false, "worn": false},
		{"id": "candidate_L3", "level": 3, "armour": 0, "candidate": true, "scout": false, "worn": false},
		{"id": "candidate_L3_armour1", "level": 3, "armour": 1, "candidate": true, "scout": false, "worn": false},
		{"id": "candidate_L3_armour2", "level": 3, "armour": 2, "candidate": true, "scout": false, "worn": false},
		{"id": "candidate_L3_scout", "level": 3, "armour": 0, "candidate": true, "scout": true, "worn": false},
		{"id": "candidate_L3_worn", "level": 3, "armour": 0, "candidate": true, "scout": false, "worn": true},
		{"id": "current_L1_torch", "level": 1, "armour": 0, "candidate": false, "scout": false, "worn": false, "torch": true},
		{"id": "candidate_L3_torch", "level": 3, "armour": 0, "candidate": true, "scout": false, "worn": false, "torch": true},
	]
	var records: Array = []
	var torches_only := "--torches-only" in OS.get_cmdline_user_args()
	if torches_only and FileAccess.file_exists(OUTPUT):
		var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUTPUT))
		for record in previous.results:
			if not str(record.scenario).ends_with("_torch"):
				records.append(record)
	for scenario in scenarios:
		if torches_only and not scenario.get("torch", false):
			continue
		for case_id in cases:
			if scenario.get("torch", false) and case_id not in ["floor1_rats", "queen"]:
				continue
			var types: Array[EnemyType] = []
			for enemy_id in cases[case_id]:
				types.append(load("res://data/enemies/%s.tres" % enemy_id))
			var record := _sample(scenario, types)
			record["scenario"] = scenario.id
			record["encounter"] = case_id
			records.append(record)
			print("%s / %s: win %.1f%%, rounds %.2f, loss %.2f, any down %.1f%%" % [scenario.id, case_id, record.win_percent, record.mean_rounds, record.mean_hp_lost, record.any_downed_percent])
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write research results")
		quit(1)
		return
	var hashes := {}
	for source in ["scripts/combat_state.gd", "scripts/companion.gd", "scripts/party_state.gd", "scripts/strain.gd", "scripts/enemy_type.gd", "scripts/equipment.gd", "scripts/supplies.gd", "tools/stats_research_probe.gd"]:
		hashes[source] = FileAccess.get_sha256("res://" + source)
	for folder in ["data/enemies", "data/gear"]:
		for name in DirAccess.get_files_at("res://" + folder):
			if name.ends_with(".tres"):
				var source: String = str(folder) + "/" + str(name)
				hashes[source] = FileAccess.get_sha256("res://" + source)
	file.store_string(JSON.stringify({"date": "2026-10-18", "reference_commit": "c987f29", "source_sha256": hashes, "runs_per_case": RUNS, "seed_base": SEED_BASE, "method": "Live CombatState; paired seeds; simple focus-fire/defend policy; fresh fights except worn scenario; candidate modifiers are proxies, not implemented stats/talents", "scenarios": scenarios, "results": records}, "\t") + "\n")
	file.close()
	quit()


func _party(scenario: Dictionary):
	var party = PS.new()
	if scenario.get("torch", false):
		party.supplies.source = SuppliesDef.Source.TORCH
		party.supplies.has_lantern = false
		party.supplies.oil = 0.0
		party.supplies.torch_left = SuppliesDef.TORCH_BURN_TIME
	var roles := ["Guide", "Warden", "Scout" if scenario.scout else "Brawler"]
	for role in roles:
		var spec: Dictionary = PROFILES[role]
		var hero := Companion.new()
		hero.display_name = role
		hero.role = role
		hero.main_hero = role == "Guide"
		hero.max_health = spec.hp
		hero.attack_min = spec.attack.x
		hero.attack_max = spec.attack.y
		hero.accuracy = spec.accuracy
		hero.initiative = spec.initiative
		hero.guard_factor = spec.guard
		hero.toughness = spec.toughness + int(scenario.armour)
		if role == "Scout":
			hero.row = "back"
			hero.reach = true
		if role == "Guide":
			hero.weapon = load("res://data/gear/iron_sword.tres").duplicate()
		if scenario.candidate:
			if role == "Warden":
				hero.weapon = load("res://data/gear/wooden_club.tres").duplicate()
			elif role == "Brawler":
				hero.weapon = load("res://data/gear/woodcutters_axe.tres").duplicate()
			var strength: int = spec.str
			if int(scenario.level) >= 3:
				if role in ["Guide", "Brawler"]:
					strength += 1
				elif role == "Warden":
					hero.max_health += 4  # chosen Vitality point
			hero.max_health += 2 * (int(scenario.level) - 1)
			if hero.weapon:
				hero.weapon.attack_min = maxi(1, hero.weapon.attack_min + strength - 2)
				hero.weapon.attack_max = maxi(hero.weapon.attack_min, hero.weapon.attack_max + strength - 2)
		hero.health = hero.max_health
		hero.strain = 0.0
		if scenario.worn:
			hero.health = floori(hero.max_health * 0.75)
			hero.strain = 35.0
		party.add_member(hero)
	return party


func _sample(scenario: Dictionary, types: Array[EnemyType]) -> Dictionary:
	var wins := 0
	var downed := 0
	var timed_out := 0
	var rounds_total := 0
	var hp_total := 0
	var rounds_samples: Array[int] = []
	var losses: Array[int] = []
	for run in RUNS:
		var party = _party(scenario)
		var start := 0
		for hero in party.members:
			start += hero.health
		var combat = CS.new(party, types)
		combat.rng.seed = SEED_BASE + run
		# _init plans before a seed can be supplied. Reset only on these fresh
		# enemies, then plan in their existing order under the paired seed.
		for foe in combat.foes:
			foe.intent = CS.Intent.ATTACK
			foe.has_webbed = false
			foe.enraged = false
			foe.row_override = ""
			combat.plan(foe)
		var actions := 0
		while combat.result == CS.Result.ONGOING and actions < 300:
			var actor = combat.current_actor()
			if actor is Companion:
				var heavy: bool = combat.living_foes().any(func(foe): return foe.intent in [CS.Intent.HEAVY, CS.Intent.KILLING_BLOW, CS.Intent.CLEAVER])
				if actor.role == "Warden" and heavy:
					combat.hero_defend(actor)
				else:
					var targets: Array = combat.targets_for(actor)
					if targets.is_empty():
						combat.hero_defend(actor)
					else:
						targets.sort_custom(func(a, b): return a.health < b.health)
						combat.hero_attack(actor, targets[0])
			else:
				combat.enemy_act(actor)
			if combat.result == CS.Result.ONGOING:
				combat.advance()
			actions += 1
		if combat.result == CS.Result.VICTORY:
			wins += 1
		elif combat.result == CS.Result.ONGOING:
			timed_out += 1
		var remaining := 0
		var someone_fell := false
		for hero in party.members:
			remaining += hero.health
			someone_fell = someone_fell or not hero.is_alive()
		if someone_fell:
			downed += 1
		rounds_total += combat.round
		hp_total += start - remaining
		rounds_samples.append(combat.round)
		losses.append(start - remaining)
	rounds_samples.sort()
	losses.sort()
	return {"win_percent": wins * 100.0 / RUNS, "any_downed_percent": downed * 100.0 / RUNS, "mean_rounds": float(rounds_total) / RUNS, "p90_rounds": rounds_samples[ceili(RUNS * 0.9) - 1], "mean_hp_lost": float(hp_total) / RUNS, "p90_hp_lost": losses[ceili(RUNS * 0.9) - 1], "timed_out": timed_out}
