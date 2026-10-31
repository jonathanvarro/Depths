extends SceneTree
## Slice 2's deep monsters (#150 concepts, owner-approved plan 2026-10-26),
## on placeholder looks until #166: the Underhound bites, then lunges at
## the back row; the Borrowed Pack bites once per head, and losing a head
## costs it a turn; the Marrow Shepherd births an unfinished hound every
## other turn, three in all, from a floor-6 lair. Args: tag, screenshot dir.

const CombatState := preload("res://scripts/combat_state.gd")
const Packages := preload("res://scripts/packages.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _party() -> Variant:
	var party = load("res://scripts/party_state.gd").new()
	for id in ["mara", "corin", "alwen"]:
		party.add_member(load("res://data/companions/%s.tres" % id).duplicate())
	return party


func _fight(enemy: String):
	var types: Array[EnemyType] = [load("res://data/enemies/%s.tres" % enemy)]
	var party = _party()
	party.members[2].row = "back"  # Alwen behind the others
	var state = CombatState.new(party, types)
	state.rng.seed = 7
	return state


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var I := CombatState.Intent

	# Underhound.
	var state = _fight("underhound")
	var hound = state.foes[0]
	check("the Underhound opens with a bite", hound.intent == I.BITE)
	state.enemy_act(hound)
	check("...then its jaw slides forward", hound.intent == I.REACH)
	var back: Array = state.party.living_members().filter(func(h): return not state.hero_in_front(h))
	check("...and the long lunge reaches the back row", not back.is_empty() and state.foe_can_reach(hound, back[0]))
	var picks := {}
	for i in 20:
		picks[state._choose_target(hound)] = true
	check("...aiming only at the back row", picks.keys().all(func(h): return not state.hero_in_front(h)), picks.keys().map(func(h): return h.display_name))

	# Borrowed Pack.
	state = _fight("borrowed_pack")
	var pack = state.foes[0]
	check("the Borrowed Pack has three heads", pack.heads == 3 and pack.intent == I.BITES)
	var out: Dictionary = state.enemy_act(pack)
	check("...and bites once per head", out["text"].contains("3 heads"), out["text"])
	pack.health = int(pack.type.max_health * 0.6)
	out = state.enemy_act(pack)
	check("a head dies: it loses its turn, off balance", pack.heads == 2 and out["text"].contains("off balance"), out["text"])
	out = state.enemy_act(pack)
	check("...then bites with what it has left", out["text"].contains("2 heads"), out["text"])

	# Marrow Shepherd.
	state = _fight("marrow_shepherd")
	var shepherd = state.foes[0]
	check("the Marrow Shepherd opens by birthing", shepherd.intent == I.BIRTH)
	var births := 0
	for i in 8:
		var before: int = state.foes.size()
		state.enemy_act(shepherd)
		if state.foes.size() > before:
			births += 1
		for f in state.foes:
			if f != shepherd:
				f.health = 0  # keep room for the next
	check("...every other turn, three in all", births == 3 and shepherd.calls == 3, "%d births" % births)
	check("...unfinished hounds, a weak pack", state.foes.any(func(f): return f.type.display_name == "Unfinished hound" and f.type.tactic == EnemyType.Tactic.PACK))

	# Where they turn up.
	var main_script = load("res://scripts/main.gd")
	var deep := func(depth: int, name: String) -> bool:
		return main_script.ENCOUNTER_GROUPS[depth].any(func(g): return g.any(func(t): return t.display_name == name))
	check("Underhounds and Borrowed Packs on floors 5 and 6", deep.call(5, "Underhound") and deep.call(5, "Borrowed pack") and deep.call(6, "Underhound") and deep.call(6, "Borrowed pack"))
	var lairs := []
	for s in 40:
		for p in Packages.lairs(6, s):
			lairs.append(p.id)
	check("the Marrow Shepherd keeps a lair on floor 6", "lair_shepherd" in lairs)
	check("...and nowhere shallower", not range(1, 6).any(func(d): return Packages.library().any(func(p): return p.id == "lair_shepherd" and d >= p.min_depth and d <= p.max_depth)))

	# ChatGPT's families (#166) carry every pose the fight asks for.
	var poses := {"underhound": ["idle", "attack", "hurt", "windup", "lunge", "defeated"],
			"borrowed_pack": ["idle", "attack", "hurt", "off-balance", "defeated"],
			"marrow_shepherd": ["idle", "tending", "birthing", "attack", "hurt", "defeated"],
			"unfinished_hound": ["idle", "attack", "hurt"]}
	for id in poses:
		var type: EnemyType = load("res://data/enemies/%s.tres" % id)
		var node: Node3D = type.scene.instantiate()
		var frames: SpriteFrames = node.get_node("Sprite").sprite_frames
		var missing: Array = poses[id].filter(func(p): return not frames.has_animation(p))
		check("%s: its own art, every pose, no placeholder tint" % type.display_name, missing.is_empty() and type.tint == Color.WHITE and is_equal_approx(type.sprite_scale, 1.0), missing)
		node.free()

	# The combat screen shows their moves.
	var screen = load("res://scripts/combat_screen.gd").new()
	check("every new move has a mark", [I.REACH, I.BITES, I.BIRTH].all(func(i): return screen._intent_icon(i) != null))
	screen.free()
	print("fails=", fails)
	quit()
