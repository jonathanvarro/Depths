extends SceneTree
## Exploring perks by role (#101, owner 2026-10-25): a Brawler carries 2
## more and heaves rubble aside without a tool; a standing Warden steadies
## everyone's nerves (15% slower); a Fixer gets 25% more for treasure, 10%
## off at the merchant, and one more recruit by the fire. Each recruit's
## card says what they bring. Args: tag, screenshot dir.

const Recruits := preload("res://scripts/recruits.gd")
const CampState := preload("res://scripts/camp_state.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _party(ids := ["mara"]):
	var party = load("res://scripts/party_state.gd").new()
	for id in ids:
		party.add_member(load("res://data/companions/%s.tres" % id))
	return party


func _recruit(role: String) -> Companion:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return Recruits.make(rng, [], [], 1, role)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""

	# The Fixer, a new recruit role.
	var fixer := _recruit("Fixer")
	check("a Fixer can be recruited, with lines of their own", fixer.role == "Fixer" and fixer.dialogue != null and fixer.dialogue.lines.has("need_light") and fixer.row == "back")
	check("every role's card says what they bring", ["Warden", "Scout", "Brawler", "Fixer"].all(func(r): return Recruits.perk(r) != ""))

	# Brawler: a strong back.
	var party = _party(["mara"])
	party.update_capacity()
	var alone: int = party.supplies.capacity
	party.add_member(_recruit("Brawler"))
	party.update_capacity()
	check("a Brawler carries 2 more", party.supplies.capacity == alone + party.PACK_SLOTS_PER_HERO * 0 + 2 or party.supplies.capacity == maxi(party.PACK_MINIMUM, party.PACK_SLOTS_PER_HERO * 2) + 2, "%d -> %d" % [alone, party.supplies.capacity])

	# Warden: steady presence.
	party = _party(["mara"])
	party.update_capacity()
	var mara: Companion = party.members[0]
	mara.strain = 0.0
	mara.change_strain(20.0)
	var plain: float = mara.strain
	party.add_member(_recruit("Warden"))
	party.update_capacity()
	mara.strain = 0.0
	mara.change_strain(20.0)
	check("with a Warden standing, nerves fray 15% slower", is_equal_approx(mara.strain, plain * 0.85), "%.2f vs %.2f" % [mara.strain, plain])

	# Fixer: an eye for value.
	party = _party(["mara"])
	var camp = CampState.new()
	var goblet: SupplyItem = load("res://data/items/silver_goblet.tres")
	var torch: SupplyItem = load("res://data/items/torch.tres")
	var base_sale: int = CampState.sell_price(party, goblet)
	var base_price: int = CampState.price_for(party, CampState.LANTERN_PRICE)
	check("without a Fixer: plain prices, three by the fire", base_sale == CampState.sale_price(goblet) and base_price == CampState.LANTERN_PRICE and camp.candidate_count(party) == 3)
	party.add_member(fixer)
	check("with a Fixer: treasure sells for 25% more", CampState.sell_price(party, goblet) == roundi(base_sale * 1.25), "%d vs %d" % [CampState.sell_price(party, goblet), base_sale])
	check("...gear doesn't", CampState.sell_price(party, load("res://data/gear/plain_knife.tres")) == CampState.sale_price(load("res://data/gear/plain_knife.tres")))
	check("...10% off at the merchant", CampState.price_for(party, CampState.LANTERN_PRICE) == ceili(CampState.LANTERN_PRICE * 0.9))
	check("...and one more recruit by the fire", camp.candidate_count(party) == 4)

	# In the game: rubble, and the campfire with four cards.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var ps = main._party_state
	for item in [load("res://data/items/spade.tres"), load("res://data/items/pick.tres")]:
		while ps.supplies.count(item) > 0:
			ps.supplies.take(item)
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	main._on_party_blocked(main._party.cell)
	check("no tool, no Brawler: the rubble stays", not main._prompt.visible)
	ps.add_member(_recruit("Brawler"))
	main._on_party_blocked(main._party.cell)
	check("a Brawler offers to heave it aside", main._prompt.visible and main._prompt_label.text.contains("heave"), main._prompt_label.text)
	main._answer_prompt(false)
	ps.add_member(_recruit("Fixer"))
	main._end_expedition(main.Expedition.Ending.RETURNED)
	await process_frame
	main._results.continue_pressed.emit()
	await create_timer(0.3).timeout
	main._camp_state.rest(ps)
	await process_frame
	main._camp._close_activity()
	main._camp._buttons["fire"].pressed.emit()
	for i in 4:
		await process_frame
	var cards: Array = main._camp._body.find_children("*", "PanelContainer", true, false)
	var bar: VScrollBar = main._camp._scroll.get_v_scroll_bar()
	var edge: float = main._camp._scroll.get_global_rect().end.x
	check("with a Fixer, four recruits wait by the fire", main._camp_state.candidates.size() == 4 and cards.size() == 4, "%d %d" % [main._camp_state.candidates.size(), cards.size()])
	check("...and the campfire still fits, no scrolling", bar.max_value <= main._camp._scroll.size.y + 1.0 and cards.all(func(c): return c.get_global_rect().end.x <= edge + 1.0), "%.0f / %.0f" % [bar.max_value, main._camp._scroll.size.y])
	if dir != "":
		for i in 4:
			await process_frame
		root.get_texture().get_image().save_png("%s/roles_%s_fire.png" % [dir, tag])
	print("fails=", fails)
	quit()
