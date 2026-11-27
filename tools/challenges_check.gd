extends SceneTree
## Areas as challenge families (#305, owner 2026-11-26): each area leans on a
## kind of obstacle, the right class gets a cheap way through, and the
## arrival card and the fire say so. Args: tag, screenshot dir.

const Challenges := preload("res://scripts/challenges.gd")
const FloorGenerator := preload("res://scripts/floor_generator.gd")
const Recruits := preload("res://scripts/recruits.gd")
const PartyState := preload("res://scripts/party_state.gd")
const WallLights := preload("res://scripts/wall_lights.gd")

var fails := 0
var rng := RandomNumberGenerator.new()


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func hero(role: String) -> Companion:
	return Recruits.make(rng, [], [], 1, role)


func party_of(roles: Array):
	var party = PartyState.new()
	for role in roles:
		party.add_member(hero(role))
	return party


## Totals of each symbol over many seeds of an area at `depth`.
func tally(area: String, depth: int) -> Dictionary:
	var out := {}
	for seed_value in 60:
		for row in FloorGenerator.generate(4000 + seed_value * 13, true, depth, area):
			for c in row:
				if c in ["E", "T", "B", "D", "C"]:
					out[c] = out.get(c, 0) + 1
	return out


func _initialize() -> void:
	rng.seed = 3051
	# Same walls whatever the area: only contents and passages are weighted.
	var plain := FloorGenerator.generate(77, true, 2)
	var damp := FloorGenerator.generate(77, true, 2, "damp")
	var same := true
	for y in plain.size():
		for x in plain[y].length():
			same = same and ((plain[y][x] == "#") == (damp[y][x] == "#"))
	check("an area changes contents, never the walls", same)

	var base := tally("", 2)
	var mines := tally("mines", 2)
	var damp_t := tally("damp", 2)
	var cavern := tally("cavern", 2)
	check("the Mines have more rubble", mines.get("B", 0) > base.get("B", 0) * 1.4, [mines.get("B"), base.get("B")])
	check("the Damp Caves have more traps and shut passages", damp_t.get("T", 0) > base.get("T", 0) * 1.3 and damp_t.get("D", 0) > base.get("D", 0), [damp_t.get("T"), base.get("T"), damp_t.get("D"), base.get("D")])
	check("the Cavern has more fights, fewer traps and little rubble", cavern.get("E", 0) > base.get("E", 0) * 1.2 and cavern.get("T", 0) < base.get("T", 0) and cavern.get("B", 0) < base.get("B", 0) / 2, [cavern, base])
	check("every area leans on a class", Challenges.AREAS.keys().all(func(a): return not Challenges.leans(a).is_empty() and Challenges.hint(a) != ""))

	# Spores: nerves fray faster without an Acolyte.
	var soldiers = party_of(["Melee", "Melee"])
	soldiers.area = "hollows"
	soldiers.steady_members()
	check("in the Hollows, spores fray nerves faster", soldiers.members[0].party_calm > 1.2, soldiers.members[0].party_calm)
	var with_acolyte = party_of(["Melee", "Mage"])
	with_acolyte.area = "hollows"
	with_acolyte.steady_members()
	check("...unless an Acolyte stands with the party", is_equal_approx(with_acolyte.members[0].party_calm, 1.0), with_acolyte.members[0].party_calm)
	with_acolyte.members[1].health = 0
	with_acolyte.steady_members()
	check("...and a fallen Acolyte doesn't count", with_acolyte.members[0].party_calm > 1.2)
	soldiers.area = "mines"
	soldiers.steady_members()
	check("elsewhere no spores", is_equal_approx(soldiers.members[0].party_calm, 1.0))

	# Water: a Scout finds the shallows.
	check("a Scout halves wading's cost", Challenges.wade_share(party_of(["Scout", "Melee"])) < 1.0 and Challenges.wade_share(party_of(["Melee", "Melee"])) == 1.0)

	# The arrival card and the threshold.
	check("the arrival card names the area's leaning", Challenges.arrival_line("damp", party_of(["Scout"])).contains("Scout ground") and not Challenges.arrival_line("damp", party_of(["Scout"])).contains("no Scout"))
	check("...and warns a party without its class", Challenges.arrival_line("damp", party_of(["Melee"])).contains("no Scout"), Challenges.arrival_line("damp", party_of(["Melee"])))
	check("...two-class areas name both", Challenges.arrival_line("galleries", party_of(["Melee"])).contains("Sapper or Scout"))
	check("the fire's \"Suits\" lists reached areas the party fits", Challenges.suited([hero("Fixer")], {"mines": true, "damp": true, "jail": true}) == ["mines", "jail"])

	# In the game.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 3051
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	for m in ps.members.duplicate():
		ps.remove_member(m)
	for role in ["Melee", "Melee"]:
		ps.add_member(hero(role))
	main._go_to_area("hollows", main.Arrival.FROM_ABOVE)
	check("arriving sets the party's area and remembers it", ps.area == "hollows" and main._camp_state.areas_seen.has("hollows"))
	check("...and the card warns there's no Acolyte", main._message_label.text.contains("Fungal Hollows") and main._message_label.text.contains("no Acolyte"), main._message_label.text)
	var hollow_lights: int = main._map.marks.get("wall_lights", {}).size()
	main._go_to_area("damp", main.Arrival.FROM_ABOVE)
	var damp_lights: int = main._map.marks.get("wall_lights", {}).size()
	check("the Hollows keep fewer wall lights", hollow_lights < damp_lights, [hollow_lights, damp_lights])
	main._go_to_area("cavern", main.Arrival.FROM_ABOVE)
	var cavern_quiet: int = main._wanderers.quiet
	main._go_to_area("damp", main.Arrival.FROM_ABOVE)
	check("wanderers come sooner in the Cavern: a shorter quiet spell", cavern_quiet < load("res://scripts/wanderers.gd").WANDER[3][0], cavern_quiet)
	# Wading with and without a Scout.
	var water: Array = main._map.water.keys()
	check("the Damp Caves have water to wade", not water.is_empty())
	if not water.is_empty():
		var t: int = ps.time_elapsed
		var s0: float = ps.members[0].strain
		main._wade(water[0])
		var plain_cost: float = ps.members[0].strain - s0
		check("wading without a Scout costs time", ps.time_elapsed > t)
		ps.add_member(hero("Scout"))
		ps.steady_members()
		t = ps.time_elapsed
		s0 = ps.members[0].strain
		main._wade(water[0])
		check("...a Scout finds the shallows: no time and less strain", ps.time_elapsed == t and ps.members[0].strain - s0 < plain_cost, [ps.members[0].strain - s0, plain_cost])
	# The fire names what the party suits.
	main._camp.open(main._camp_state, ps)
	main._camp.open_activity("fire")
	await process_frame
	var texts: Array = main._camp._body.find_children("*", "Label", true, false).map(func(l): return l.text)
	check("the fire says which reached areas suit the party", texts.any(func(t): return String(t).contains("Suits: ") and String(t).contains("Damp Caves")), texts.filter(func(t): return String(t).contains("Suits")))
	var args := OS.get_cmdline_user_args()
	if args.size() > 1:
		await create_timer(2.5).timeout
		for i in 4:
			await process_frame
		var image := root.get_texture().get_image()
		if image:  # none when headless
			image.save_png(args[1] + "/challenges_fire.png")
	print("fails=", fails)
	quit()
