extends SceneTree
## Combat balance (#49): a party fights every enemy group a floor can throw
## at it, many times over, playing simply (Wardens defend against heavy
## blows; everyone else attacks the weakest enemy). Prints win rate, rounds
## and health lost per fight. Run headless:
##   Godot --headless --path . --script res://tools/balance_sim.gd

const RUNS := 400

var CS
var PS
var Main


func _initialize() -> void:
	CS = load("res://scripts/combat_state.gd")
	PS = load("res://scripts/party_state.gd")
	Main = load("res://scripts/main.gd")
	for size in [1, 2, 3]:
		print("--- party of %d ---" % size)
		for depth in Main.ENCOUNTER_GROUPS:
			var fitting: Array = Main.encounter_pool(depth, size)
			var wins := 0.0; var rounds := 0.0; var lost := 0.0; var worst := 0
			for group in fitting:
				var r := _simulate(size, group)
				wins += r[0]; rounds += r[1]; lost += r[2]; worst = maxi(worst, r[3])
			var n := float(fitting.size())
			print("depth %d: win %.0f%%  rounds %.1f  health lost per fight %.1f (worst %d)" % [depth, wins / n, rounds / n, lost / n, worst])
	quit()


## Mara with the iron sword, then a Warden and a Brawler of average build.
func _party(size: int):
	var p = PS.new()
	var mara: Companion = load("res://data/companions/mara.tres")
	p.add_member(mara)
	p.members[0].weapon = load("res://data/gear/iron_sword.tres")
	var roles := [["Warden", 24, Vector2i(2, 3), 0.7, 8, 0.25, 0], ["Brawler", 22, Vector2i(3, 5), 0.65, 9, 0.5, -1]]
	for i in size - 1:
		var spec: Array = roles[i]
		var hero := Companion.new()
		hero.display_name = spec[0]; hero.role = spec[0]
		hero.max_health = spec[1]; hero.attack_min = spec[2].x; hero.attack_max = spec[2].y
		hero.accuracy = spec[3]; hero.initiative = spec[4]; hero.guard_factor = spec[5]; hero.toughness = spec[6]
		p.add_member(hero)
	for hero: Companion in p.members:
		hero.health = hero.max_health
		hero.strain = 0.0
		hero.injuries.clear()
	return p


## [win %, average rounds, average total health lost, worst loss]
func _simulate(size: int, group: Array) -> Array:
	var wins := 0; var rounds := 0; var lost := 0; var worst := 0
	for n in RUNS:
		var p = _party(size)
		var start := 0
		for m in p.members: start += m.health
		var types: Array[EnemyType] = []
		types.assign(group)
		var c = CS.new(p, types)
		var guard := 0
		while c.result == CS.Result.ONGOING and guard < 300:
			var actor = c.current_actor()
			if actor is Companion:
				var heavy: bool = c.living_foes().any(func(f): return f.intent == CS.Intent.HEAVY)
				if actor.role == "Warden" and heavy:
					c.hero_defend(actor)
				else:
					var foes: Array = c.living_foes()
					foes.sort_custom(func(a, b): return a.health < b.health)
					c.hero_attack(actor, foes[0])
			else:
				c.enemy_act(actor)
			if c.result == CS.Result.ONGOING:
				c.advance()
			guard += 1
		if c.result == CS.Result.VICTORY: wins += 1
		rounds += c.round
		var end := 0
		for m in p.members: end += m.health
		lost += start - end
		worst = maxi(worst, start - end)
	return [wins * 100.0 / RUNS, float(rounds) / RUNS, float(lost) / RUNS, worst]
