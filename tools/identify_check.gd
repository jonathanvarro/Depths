extends SceneTree
## Identification (owner, 2026-11-03): a found piece with properties starts
## unidentified. Its type, quality and border show; its properties and any
## curse don't, though it works in full when worn. The smith reads one for a
## fee, a touchstone reads one underground, and a Mage's Discern prayer reads
## them all. Unidentified gear sells as a plain piece.
## Args: tag, screenshot dir.

const GearModel := preload("res://scripts/gear_model.gd")
const GearGen := preload("res://scripts/gear_gen.gd")
const CampState := preload("res://scripts/camp_state.gd")
const Spells := preload("res://scripts/spells.gd")
const SaveGame := preload("res://scripts/save_game.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _hero(id: String) -> Companion:
	var hero: Companion = load("res://data/companions/%s.tres" % id).duplicate(true)
	load("res://scripts/classes.gd").migrate(hero)
	return hero


func _party(ids: Array):
	var party = load("res://scripts/party_state.gd").new()
	for id in ids:
		party.add_member(_hero(id))
	return party


## A found iron sword with the given properties, unidentified.
func _found(mods: Array, rng: RandomNumberGenerator) -> Equipment:
	var item := GearModel.generate(rng, "iron_sword", "fine")
	item.mods = PackedStringArray(mods)
	GearModel.apply(item)
	return GearModel.conceal(item)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "desk"
	var dir: String = args[1] if args.size() > 1 else ""
	var rng := RandomNumberGenerator.new()
	rng.seed = 223

	# What shows and what doesn't.
	var sword := _found(["heavy"], rng)
	var lines := "\n".join(GearModel.card_lines(sword))
	check("a found piece with a property starts unidentified", not sword.identified and sword.display_name == "Unidentified fine iron sword", sword.display_name)
	check("...its border still shows how many properties", sword.tier == "magic")
	check("...the card says one is hidden, not what it is", lines.contains("1 hidden property") and not lines.contains("+1 damage"), lines)
	var plain: Equipment = GearModel.known(sword)
	check("...it works in full: the hidden +1 damage is there", sword.attack_max == plain.attack_max + 1, "%d vs %d" % [sword.attack_max, plain.attack_max])
	check("...what shows is the plain piece", plain.mods.is_empty() and plain.curse == null)
	var bare := GearModel.generate(rng, "iron_sword", "fine")
	bare.mods = PackedStringArray()
	GearModel.apply(bare)
	check("a piece with nothing hidden needs no reading", GearModel.conceal(bare).identified)

	var again := sword.price
	GearModel.apply(sword)
	GearModel.apply(sword)
	check("recomputing a piece doesn't inflate its price", sword.price == again, "%d then %d" % [again, sword.price])

	# Selling: as a plain piece.
	var true_price := floori(sword.price * CampState.GEAR_RESALE)
	check("unidentified, it sells as a plain piece", CampState.sale_price(sword) == floori(plain.price * CampState.GEAR_RESALE) and CampState.sale_price(sword) < true_price, "%d < %d" % [CampState.sale_price(sword), true_price])

	# The smith.
	var camp = CampState.new()
	var party = _party(["alwen", "corin"])
	var alwen: Companion = party.members[0]
	party.supplies.gear.append(sword)
	party.supplies.gold = 5
	check("the smith asks 10 gold for a magic piece", camp.identify_price(party, sword) == 10)
	check("...and won't read it for less", camp.identify(party, sword) == "Need 10 gold" and not sword.identified)
	party.supplies.gold = 30
	var read: String = camp.identify(party, sword)
	check("the smith reads it: its name and property show", sword.identified and party.supplies.gold == 20 and sword.display_name == "Fine heavy iron sword" and read.contains("+1 damage"), read)
	check("...and it sells at its true price", CampState.sale_price(sword) == true_price)
	var rare := _found(["keen", "heavy"], rng)
	check("a rare piece costs 20", camp.identify_price(party, rare) == 20)
	var worn := _found(["keen"], rng)
	party.members[1].weapon = worn
	check("...a worn piece can be read too", worn in party.unidentified())

	# Curses stay hidden until read.
	var cursed := _found(["keen"], rng)
	cursed.curse = load("res://data/boons/%s.tres" % GearGen.CURSES[0])
	GearModel.apply(cursed)
	check("a curse is hidden: the card doesn't mention it", not "\n".join(GearModel.card_lines(cursed)).to_lower().contains("curse") and GearModel.known(cursed).curse == null)
	check("...reading it names the curse", GearModel.identify(cursed).contains("curse"))

	# A touchstone, underground.
	var stone: SupplyItem = load("res://data/items/touchstone.tres")
	var below = _party(["corin"])
	below.supplies.add(stone, 2)
	check("a touchstone with nothing to read: no use", below.cannot_use_reason(stone) == "Nothing to identify")
	var magic := _found(["keen"], rng)
	var twice := _found(["keen", "heavy"], rng)
	below.supplies.gear.append(magic)
	below.supplies.gear.append(twice)
	var stoned: String = below.use_item(stone)
	check("used from the pack, it reads the rarest piece first", twice.identified and not magic.identified and below.supplies.count(stone) == 1, stoned)
	check("...or the one it's held to", below.touchstone(magic) != "" and magic.identified and below.supplies.count(stone) == 0)
	check("the merchant sells touchstones", stone in CampState.MERCHANT_STOCK)

	# Discern: a Mage's prayer reads everything.
	alwen.strain = 0
	alwen.casts = Spells.CASTS
	party.supplies.add(load("res://data/items/tome_discern.tres"))
	party.use_item(load("res://data/items/tome_discern.tres"))
	check("a Mage learns Discern from its tome", "discern" in Spells.known(alwen))
	check("...it isn't a fighting prayer", Spells.cannot_cast(alwen, "discern", true) != "")
	var prayed: String = Spells.cast_in_field(party, alwen, "discern", rng)
	check("Discern reads every piece, worn or carried", worn.identified and rare not in party.unidentified() and party.unidentified().is_empty() and alwen.casts == Spells.CASTS - 1, prayed)
	check("...with nothing hidden, no cast is spent", Spells.cast_in_field(party, alwen, "discern", rng) == "" and alwen.casts == Spells.CASTS - 1)

	# Finds and saves.
	var finds := 0
	var hidden := 0
	for i in 3000:
		var find := GearGen.drop(rng, 3, "chest")
		if find:
			finds += 1
			if not find.identified:
				hidden += 1
				if find.mods.is_empty():
					hidden = -100000
	check("chest finds with properties arrive unidentified, plain ones don't", hidden > 0 and hidden < finds, "%d of %d" % [hidden, finds])
	var later := _found(["keen"], rng)
	var packed: Dictionary = SaveGame.pack_object(later)
	check("the identified flag is saved", packed.has("identified") and packed["identified"] == false)

	# In the game: the Pack card shows what shows, and offers the touchstone.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var shown := _found(["heavy"], rng)
	main._party_state.supplies.gear.append(shown)
	main._party_state.supplies.add(stone)
	main._set_pack(true)
	await process_frame
	main._pack.inspect_item(shown)
	await process_frame
	var labels: Array = main._pack._detail_text.get_children().map(func(l): return l.text)
	labels.append(main._pack._detail_title.text)
	var text := "\n".join(labels)
	check("the Pack card names it unidentified and hides the property", text.contains("Unidentified fine iron sword") and text.contains("1 hidden property") and not text.contains("+1 damage"), text)
	var identify_button: Button = null
	for b in main._pack._detail_actions.get_children():
		if b is Button and b.text == "Identify":
			identify_button = b
	check("...with a touchstone, the card offers Identify", identify_button != null and not identify_button.disabled)
	if dir != "":
		for i in 10:
			await process_frame
		var shot := root.get_texture().get_image()
		if shot:
			shot.save_png("%s/identify_%s_pack.png" % [dir, tag])
	if identify_button:
		identify_button.pressed.emit()
		await process_frame
	check("...which reads it", shown.identified and shown.display_name == "Fine heavy iron sword")
	print("fails=", fails)
	quit()
