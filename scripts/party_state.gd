extends RefCounted
## The party as a whole: up to three heroes, what they carry, and the time
## spent so far.
##
## Kept by main.gd for the whole session, so it carries across floors.
## The game starts with a lone survivor; the other slots fill later
## (recruitment at the campfire, #17).

const Classes := preload("res://scripts/classes.gd")
signal changed
signal brew_revealed  # a revealing brew was drunk: show the floor's rooms (#175)

const GearModel := preload("res://scripts/gear_model.gd")
const Supplies := preload("res://scripts/supplies.gd")
const Trinkets := preload("res://scripts/trinkets.gd")
const StrainRules := preload("res://scripts/strain.gd")
const Spells := preload("res://scripts/spells.gd")
const MAX_MEMBERS := 3
## Pack space (owner, 2026-10-21, #133): slots per hero, and never fewer
## than PACK_MINIMUM so a lone hero can carry a kit and still find things.
const PACK_SLOTS_PER_HERO := 4
const PACK_MINIMUM := 8
## A rest takes this long; it also finishes every effect in progress (#10).
const REST_TIME := 20

var members: Array[Companion] = []
## Time units spent this expedition. Every step costs one (#10).
var time_elapsed := 0
var supplies = Supplies.new()


## Adds a copy of `definition` (so the .tres file is never modified).
## Returns false if all slots are taken.
func add_member(definition: Companion) -> bool:
	if members.size() >= MAX_MEMBERS:
		return false
	var member: Companion = definition.duplicate()
	GearModel.instance_hero(member)  # worn pieces become items with mastery (#192)
	member.talents = definition.talents.duplicate()
	member.refresh_stats()
	member.pending_effects = []
	member.boons = []
	member.injuries = definition.injuries.duplicate()
	member.dressed = []
	members.append(member)
	update_capacity()
	changed.emit()
	return true


func remove_member(member: Companion) -> void:
	members.erase(member)
	update_capacity()
	changed.emit()


## The pack grows with the party. A smaller party may find it over-full:
## nothing is lost, but nothing more fits until something goes.
func update_capacity() -> void:
	var before: int = supplies.capacity
	steady_members()  # #101
	supplies.capacity = maxi(PACK_MINIMUM, PACK_SLOTS_PER_HERO * members.size()) + pack_extra() - pack_lost()
	if supplies.capacity != before:
		supplies.changed.emit()


## Slots backpacks add (owner, 2026-10-21), and a Brawler's strong back
## (#101).
const BRAWLER_PACK := 2

func pack_extra() -> int:
	var extra := 0
	for member in members:
		if member.back:
			extra += member.back.pack_slots
		if member.role == "Brawler" and member.is_alive():
			extra += BRAWLER_PACK  # only an unmigrated save's; classes (#179) have none
	return extra


## Whether a standing hero of `role` is with the party (#101).
func has_role(role: String) -> bool:
	return living_members().any(func(h: Companion): return h.role == role)


## A Warden's steady presence (#101): everyone's nerves fray this much
## slower while one stands.
const WARDEN_CALM := 0.85

func steady_members() -> void:
	var calm := WARDEN_CALM if has_role("Warden") else 1.0  # an unconverted Warden only: classes (#179) have no such perk
	for member in members:
		member.party_calm = calm


## Slots lost to injuries: a limping hero carries less (#104) until the
## limp is dressed or treated.
func pack_lost() -> int:
	var lost := 0
	for member in living_members():
		for injury in member.hindering_injuries():
			lost += injury.carry_penalty
	return lost


## The luckiest living hero bends coin flips (#77): [bonus, their name].
func luck() -> Array:
	var best: Companion = null
	var best_luck := 0.0
	for member in living_members():
		var own: float = member.luck + member.boon_total("luck")  # a knucklebone (#135)
		if own > 0.0 and (best == null or own > best_luck):
			best = member
			best_luck = own
	return [best_luck, best.display_name] if best else [0.0, ""]


## A living hero has this main-hero trait (#95).
func has_trait(id: String) -> bool:
	return living_members().any(func(m: Companion): return m.trait_id == id)


## Field medic (#95): healing heals half again as much with them along.
const FIELD_MEDIC_BONUS := 1.5
## Field medic's binding without a dressing: once per expedition.
var field_bind_used := false


func can_field_bind(hero: Companion) -> bool:
	var allowed := 2 if living_members().any(func(m: Companion): return m.has_talent("triage")) else 1
	return has_trait("field_medic") and field_binds < allowed and not hero.hindering_injuries().is_empty()


## Bindings used this trip (field_bind_used kept for the first one).
var field_binds := 0
## A Mage's Watchful eye (#170): time left showing the floor's monsters.
var watch_left := 0


func field_bind(hero: Companion) -> bool:
	if not can_field_bind(hero):
		return false
	field_binds += 1
	field_bind_used = true
	hero.dress_injury()
	changed.emit()
	return true


## How fast the lantern burns, after boons and banes (#133).
func oil_rate() -> float:
	var rate := 1.0
	for member in living_members():
		rate *= member.boon_product("oil_rate")
	return rate


## Traps show: Mara's keen eyes (#95), a boon, or a Scout's Trap sense (#94).
func sees_traps() -> bool:
	return has_trait("keen_eyes") or living_members().any(func(m: Companion): return m.boon_flag("reveals_traps") or m.has_talent("trap_sense"))


func draws_ambush() -> bool:
	return living_members().any(func(m: Companion): return m.boon_flag("draws_ambush"))


func free_slots() -> int:
	return MAX_MEMBERS - members.size()


func advance_time(units := 1) -> void:
	time_elapsed += units
	update_capacity()  # injuries come and go (#104)
	for i in units:
		supplies.burn(1, oil_rate())
		var light: Supplies.Light = supplies.light_band()
		for member in living_members():
			member.hunger += 1
			member.change_strain(StrainRules.per_time_unit(member, light))
	for member in members:
		member.advance_time(units)
	watch_left = maxi(0, watch_left - units)
	changed.emit()


## The hero under the most strain, if anyone is panicking (else null).
func panicking_member() -> Companion:
	var worst: Companion = null
	for member in living_members():
		if member.strain_state() == StrainRules.State.PANICKING and (worst == null or member.strain > worst.strain):
			worst = member
	return worst


## Time a step costs the party: they move at the pace of the slowest hero.
func step_time() -> int:
	var cost := 1
	for member in living_members():
		cost = maxi(cost, member.step_time())
	return cost


## The first living hero with an injury that a dressing could bind.
func first_undressed_injured() -> Companion:
	for member in living_members():
		if not member.hindering_injuries().is_empty():
			return member
	return null


## Wields `item` from the pack; whatever the hero held goes into the pack.
func equip(hero: Companion, item: Equipment) -> void:
	if item not in supplies.gear:
		return
	if item.slot == "trinket":  # #135
		if hero.is_cursed():
			return  # a cursed trinket won't come off
		supplies.gear.erase(item)
		_put_on(hero, item)
		return
	# Cursed weapons and armour won't come off (2026-10-22).
	if (item.slot == "body" and hero.body and hero.body.curse) or (item.slot == "weapon" and hero.weapon and hero.weapon.curse):
		return
	if Classes.refuses(hero, item) != "":
		return  # #179: what the class may wear
	supplies.gear.erase(item)
	if item.slot == "body":  # armour (#93)
		if hero.body:
			supplies.gear.append(hero.body)
		hero.body = item
		hero.emit_changed()
		supplies.changed.emit()
		changed.emit()
		return
	if item.slot == "back":  # a backpack, cloak or cape
		if hero.back:
			supplies.gear.append(hero.back)
		hero.back = item
		hero.health = mini(hero.health, hero.effective_max_health())
		hero.emit_changed()
		update_capacity()
		changed.emit()
		return
	if hero.weapon:
		supplies.gear.append(hero.weapon)
	hero.weapon = item
	hero.emit_changed()
	supplies.changed.emit()
	changed.emit()


## Wears a piece of jewellery from the pack as its trinket (#135). Returns
## a message ("" if it can't be worn): a cursed one reveals itself here.
func wear_treasure(hero: Companion, item: SupplyItem) -> String:
	var trinket: Equipment = Trinkets.for_treasure(item)
	if trinket == null or hero.is_cursed() or not supplies.take(item):
		return ""
	return _put_on(hero, trinket)


## Puts on a trinket carried as gear (a unique, or a cursed one). Returns
## the message, or "" if it can't be worn now.
func wear(hero: Companion, trinket: Equipment) -> String:
	if trinket not in supplies.gear or trinket.slot != "trinket" or hero.is_cursed():
		return ""
	supplies.gear.erase(trinket)
	return _put_on(hero, trinket)


## Takes off what's on a hero's back, into the pack. The pack may end up
## over-full if it was a backpack: nothing is lost, but nothing more fits.
func take_off_back(hero: Companion) -> bool:
	if hero.back == null:
		return false
	supplies.gear.append(hero.back)
	hero.back = null
	hero.health = mini(hero.health, hero.effective_max_health())
	hero.emit_changed()
	update_capacity()
	changed.emit()
	return true


## Takes a trinket off, back into the pack. False if it's cursed.
func take_off_trinket(hero: Companion) -> bool:
	if hero.trinket == null or hero.is_cursed():
		return false
	_stow(hero.trinket)
	hero.trinket = null
	hero.health = mini(hero.health, hero.effective_max_health())
	hero.emit_changed()
	changed.emit()
	return true


func _put_on(hero: Companion, trinket: Equipment) -> String:
	if hero.trinket:
		_stow(hero.trinket)
	hero.trinket = trinket
	hero.health = mini(hero.health, hero.effective_max_health())
	hero.emit_changed()
	supplies.changed.emit()
	changed.emit()
	if trinket.curse:
		return "The clasp bites as %s puts on the %s. Cursed with %s - and it won't come off." % [hero.display_name, trinket.display_name.to_lower(), trinket.curse.display_name.to_lower()]
	return "%s puts on the %s." % [hero.display_name, trinket.display_name.to_lower()]


## A trinket taken off goes back as the treasure it came from, or as gear.
func _stow(trinket: Equipment) -> void:
	if trinket.treasure:
		supplies.add(trinket.treasure)
	else:
		supplies.gear.append(trinket)
	supplies.changed.emit()


## Throws gear away for good.
func drop(item: Equipment) -> void:
	supplies.gear.erase(item)
	supplies.changed.emit()
	changed.emit()


## Resting: time passes (the lantern keeps burning) and everything in
## progress, like food and draughts, finishes.
func rest() -> void:
	advance_time(REST_TIME)
	complete_pending_effects()
	for member in members:
		if member.is_unconscious():  # a rest brings them round (#83)
			member.change_health(maxi(1, member.effective_max_health() / 4))
	for member in living_members():
		member.change_strain(StrainRules.RESTING)


func living_members() -> Array[Companion]:
	return members.filter(func(m: Companion): return m.is_alive())


## The living hero furthest below full health, or null if nobody is hurt.
func most_hurt() -> Companion:
	for member in members:
		if member.is_unconscious():
			return member  # a draught revives an unconscious main hero first (#83)
	var worst: Companion = null
	for member in living_members():
		if member.health < member.effective_max_health() and (worst == null or member.effective_max_health() - member.health > worst.effective_max_health() - worst.health):
			worst = member
	return worst


## Why `item` can't be used right now, or "" if it can. An explicit recipient
## targets single-hero medicine; omitted retains legacy automatic targeting.
## Food and light sources always retain their shared-party effects.
func cannot_use_reason(item: SupplyItem, in_combat := false, recipient: Companion = null) -> String:
	if in_combat and not item.usable_in_combat:
		return "Not during a fight"
	if supplies.count(item) <= 0 and not (item.effect == SupplyItem.Effect.REFILL_LANTERN and supplies.open_flask > 0.0):
		return "None left"
	if item.effect in [SupplyItem.Effect.TOME, SupplyItem.Effect.CANDLE]:  # #170
		var reader := _spell_reader(item, recipient)
		if reader == null:
			if not living_members().any(func(m: Companion): return Spells.is_caster(m)):
				return "Needs a Mage"
			if item.effect == SupplyItem.Effect.TOME:
				return "Already known"
			return "Casts are full"
		return ""
	if item.effect == SupplyItem.Effect.IDENTIFY and unidentified().is_empty():
		return "Nothing to identify"
	if item.effect == SupplyItem.Effect.BREW:
		if in_combat:
			return "Throw it at a foe"
		if living_members().is_empty():
			return "No one to drink it"
		return ""
	if recipient != null and item.effect in [SupplyItem.Effect.HEAL_ONE, SupplyItem.Effect.DRESS_INJURY, SupplyItem.Effect.LIFT_BANE]:
		if recipient not in members:
			return "That hero is not in the party"
		if not recipient.is_alive() and not (item.effect == SupplyItem.Effect.HEAL_ONE and recipient.is_unconscious()):
			return "Needs a conscious hero"
		match item.effect:
			SupplyItem.Effect.HEAL_ONE:
				if recipient.health >= recipient.effective_max_health():
					return recipient.display_name + " is not hurt"
			SupplyItem.Effect.DRESS_INJURY:
				if recipient.hindering_injuries().is_empty():
					return "No injury to bind on " + recipient.display_name
			SupplyItem.Effect.LIFT_BANE:
				if not recipient.has_bane():
					return recipient.display_name + " is not cursed"
	match item.effect:
		SupplyItem.Effect.TREASURE:
			return "Sell it at camp"
		SupplyItem.Effect.TOOL:
			return "A tool: kept for the right place"
		SupplyItem.Effect.CURE_VENOM:
			if not in_combat:
				return "For venom, in a fight"
		SupplyItem.Effect.LIFT_BANE:
			if not living_members().any(func(m: Companion): return m.has_bane()):
				return "No one is cursed"
		SupplyItem.Effect.REFILL_LANTERN:
			if not supplies.has_lantern:
				return "No lantern"
			if supplies.lantern_is_full():
				return "Lantern is full"
		SupplyItem.Effect.LIGHT_TORCH:
			if supplies.torch_lit():
				return "One is already lit"
		SupplyItem.Effect.FEED_PARTY:
			if most_hurt() == null and not living_members().any(func(m: Companion): return m.is_hungry()):
				return "Nobody needs it"
		SupplyItem.Effect.HEAL_ONE:
			if most_hurt() == null:
				return "Nobody is hurt"
		SupplyItem.Effect.DRESS_INJURY:
			if first_undressed_injured() == null:
				return "No injury to bind"
	return ""


## Uses one `item` (outside combat). Returns a message to show, or "" if it
## couldn't be used.
func use_item(item: SupplyItem, in_combat := false, recipient: Companion = null) -> String:
	if cannot_use_reason(item, in_combat, recipient) != "":
		return ""
	match item.effect:
		SupplyItem.Effect.TOME:  # #170: a Mage learns the prayer for good
			var reader := _spell_reader(item, recipient)
			supplies.take(item)
			reader.spells.append(item.spell)
			reader.emit_changed()
			advance_time(item.use_time)
			return "%s learns %s." % [reader.display_name, Spells.name_of(item.spell)]
		SupplyItem.Effect.IDENTIFY:  # the rarest piece first
			var pieces := unidentified()
			pieces.sort_custom(func(a: Equipment, b: Equipment): return a.mods.size() > b.mods.size())
			return touchstone(pieces[0])
		SupplyItem.Effect.CANDLE:
			var reader := _spell_reader(item, recipient)
			supplies.take(item)
			reader.casts = mini(Spells.CASTS, reader.casts + maxi(1, item.amount))
			reader.emit_changed()
			advance_time(item.use_time)
			return "%s prays by the candle's light (%d casts)." % [reader.display_name, reader.casts]
		SupplyItem.Effect.BREW:  # #175: drinking is the test
			var drinker := recipient if recipient != null and recipient.is_alive() else (most_hurt() if most_hurt() != null and most_hurt().is_alive() else living_members()[0])
			return load("res://scripts/brews.gd").drink(self, item, drinker)
		SupplyItem.Effect.REFILL_LANTERN:
			supplies.refill(item)
		SupplyItem.Effect.FEED_PARTY:
			supplies.take(item)
			for member in living_members():
				member.eat()
				member.add_effect_over_time("health", _healing(item.amount), item.duration)
		SupplyItem.Effect.HEAL_ONE:
			var target := recipient if recipient != null else most_hurt()
			supplies.take(item)
			target.add_effect_over_time("health", _healing(item.amount), item.duration)
		SupplyItem.Effect.DRESS_INJURY:
			supplies.take(item)
			var patient := recipient if recipient != null else first_undressed_injured()
			patient.dress_injury()
			if living_members().any(func(m: Companion): return m.has_talent("steady_hands")):
				patient.add_effect_over_time("health", 4, 20)  # steady hands (#47)
		SupplyItem.Effect.LIGHT_TORCH:
			supplies.light_torch(item)
		SupplyItem.Effect.LIFT_BANE:
			supplies.take(item)
			var patients: Array = [recipient] if recipient != null else living_members()
			for member in patients:
				if member.has_bane():
					var lifted: Boon = member.lift_bane()
					if not in_combat:
						advance_time(item.use_time)
					return "%s: %s lifts." % [member.display_name, lifted.display_name]
	if not in_combat:  # in a fight, the round's time covers it
		advance_time(item.use_time)
	return item.use_message


## Unidentified pieces, worn or carried (owner, 2026-11-03).
func unidentified() -> Array:
	return GearModel.owned_by(self).filter(func(i: Equipment): return not i.identified)


## A touchstone reads `piece`. Returns what it turned out to be, or "".
func touchstone(piece: Equipment) -> String:
	var stone: SupplyItem = null
	for item in supplies.items:
		if item is SupplyItem and item.effect == SupplyItem.Effect.IDENTIFY:
			stone = item
	if stone == null or piece == null or piece.identified or not supplies.take(stone):
		return ""
	advance_time(stone.use_time)
	var text := GearModel.identify(piece)
	supplies.changed.emit()
	changed.emit()
	return text


## Who a tome or candle is for: `recipient` if they can use it, else the
## first Mage who can.
func _spell_reader(item: SupplyItem, recipient: Companion) -> Companion:
	var can := func(m: Companion) -> bool:
		if m == null or m not in members or not m.is_alive() or not Spells.is_caster(m):
			return false
		if item.effect == SupplyItem.Effect.TOME:
			return item.spell not in Spells.known(m)
		return m.casts < Spells.CASTS
	if can.call(recipient):
		return recipient
	for m in living_members():
		if can.call(m):
			return m
	return null


func _healing(amount: int) -> int:
	var healed := float(amount)
	if has_trait("field_medic"):
		healed *= FIELD_MEDIC_BONUS
	if living_members().any(func(m: Companion): return m.has_talent("herbalist")):
		healed *= 1.25
	return roundi(healed)


## Moving between floors: every effect with a duration finishes now, so the
## party arrives with healing (and the like) fully received.
## Time until every hero's effects have fully played out (the longest).
func remaining_effect_time() -> int:
	var longest := 0
	for member in living_members():
		for effect in member.pending_effects:
			longest = maxi(longest, effect["units_left"])
	return longest


func complete_pending_effects() -> void:
	for member in members:
		member.complete_pending_effects()
	changed.emit()


func summary() -> String:
	var parts := PackedStringArray()
	for member in members:
		var pending := " (+%d effects)" % member.pending_effects.size() if member.pending_effects.size() > 0 else ""
		var hurts := PackedStringArray(member.injuries.map(func(i: Injury): return i.display_name + ("*" if i in member.dressed else "")))
		var injured := " [%s]" % ", ".join(hurts) if not hurts.is_empty() else ""
		parts.append("%s %d/%d%s%s" % [member.display_name, member.health, member.effective_max_health(), pending, injured])
	for i in free_slots():
		parts.append("[empty]")
	return ", ".join(parts)
