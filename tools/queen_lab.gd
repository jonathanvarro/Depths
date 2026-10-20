extends SceneTree
## The queen fight alone (#49, docs/balance-report-2026-10.md): 400 fights
## per party make-up at level 2 and full health, by how strained the party
## starts. Uses the campaign bot's fighting style.
##   Godot --headless --path . --script tools/queen_lab.gd
const PS := preload("res://scripts/party_state.gd")
const CS := preload("res://scripts/combat_state.gd")
const Recruits := preload("res://scripts/recruits.gd")
const Progression := preload("res://scripts/progression.gd")
const SWORD := preload("res://data/gear/iron_sword.tres")
const COAT := preload("res://data/gear/padded_coat.tres")
var rng := RandomNumberGenerator.new()
var Main

func _recruit(role: String, level: int) -> Companion:
	while true:
		var r: Companion = Recruits.make(rng, [], [], level)
		if r.role == role:
			return r
	return null

var start_strain := 10.0
func _party(lead: String, roles: Array, level: int, armour: bool):
	var p = PS.new()
	p.add_member(load("res://data/companions/%s.tres" % lead))
	var h: Companion = p.members[0]
	h.weapon = SWORD
	h.xp = Progression.THRESHOLDS[level] if level > 1 else 0
	Progression.auto_advance(h)
	for role in roles:
		p.add_member(_recruit(role, level))
	for m: Companion in p.members:
		if armour: m.body = COAT
		m.refresh_stats()
		m.health = m.effective_max_health()
		m.strain = start_strain
	return p

func _run(lead: String, roles: Array, level: int, armour: bool, focus_queen: bool) -> float:
	var wins := 0
	for n in 400:
		var p = _party(lead, roles, level, armour)
		var types: Array[EnemyType] = []
		types.assign(Main.QUEEN_FIGHT)
		var c = CS.new(p, types)
		var guard := 0
		while c.result == CS.Result.ONGOING and guard < 400:
			var a = c.current_actor()
			if a is Companion:
				var foes: Array = c.living_foes()
				var heavy: bool = foes.any(func(f): return f.intent in [CS.Intent.HEAVY, CS.Intent.KILLING_BLOW, CS.Intent.CLEAVER])
				var fr: float = float(a.health) / a.effective_max_health()
				var reach: Array = c.targets_for(a)
				if heavy and fr < 0.6 and c.hero_in_front(a):
					c.hero_defend(a)
				elif reach.is_empty():
					if p.living_members().size() > 1 and a.row == "back" and not a.has_reach(): c.hero_move(a)
					else: c.hero_defend(a)
				else:
					if focus_queen and reach.any(func(f): return f.type.tactic == EnemyType.Tactic.QUEEN):
						c.hero_attack(a, reach.filter(func(f): return f.type.tactic == EnemyType.Tactic.QUEEN)[0])
					else:
						reach.sort_custom(func(x, y): return x.health < y.health)
						c.hero_attack(a, reach[0])
			elif a != null:
				if a.intent in [CS.Intent.KILLING_BLOW, CS.Intent.CLEAVER]: c.prepare_killing_blow(a)
				c.enemy_act(a)
			if c.result == CS.Result.ONGOING: c.advance()
			guard += 1
		if c.result == CS.Result.VICTORY: wins += 1
	return wins / 4.0

func _initialize() -> void:
	Main = load("res://scripts/main.gd")
	rng.seed = 7
	for roles in [["Scout", "Scout"], ["Scout", "Warden"], ["Warden", "Brawler"]]:
		for lead in ["mara", "corin"]:
			var line := "%s + %s L2:" % [lead, "/".join(roles)]
			for s in [10.0, 30.0, 45.0]:
				start_strain = s
				line += "  strain %d: %.0f%%" % [s, _run(lead, roles, 2, false, false)]
			print(line)
	quit()
