extends RefCounted
## The party as a whole: up to three heroes, what they carry, and the time
## spent so far.
##
## Kept by main.gd for the whole session, so it carries across floors.
## The game starts with a lone survivor; the other slots fill later
## (recruitment at the campfire, #17).

signal changed

const Supplies := preload("res://scripts/supplies.gd")
const Trinkets := preload("res://scripts/trinkets.gd")
const StrainRules := preload("res://scripts/strain.gd")
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
	var extra := 0
	for member in members:
		if member.back:
			extra += member.back.pack_slots  # a backpack (owner, 2026-10-21)
	supplies.capacity = maxi(PACK_MINIMUM, PACK_SLOTS_PER_HERO * members.size()) + extra
	supplies.changed.emit()


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


## Traps show: Mara's keen eyes (#95), or a boon.
func sees_traps() -> bool:
	return has_trait("keen_eyes") or living_members().any(func(m: Companion): return m.boon_flag("reveals_traps"))


func draws_ambush() -> bool:
	return living_members().any(func(m: Companion): return m.boon_flag("draws_ambush"))


func free_slots() -> int:
	return MAX_MEMBERS - members.size()


func advance_time(units := 1) -> void:
	time_elapsed += units
	for i in units:
		supplies.burn(1, oil_rate())
		var light: Supplies.Light = supplies.light_band()
		for member in living_members():
			member.hunger += 1
			member.change_strain(StrainRules.per_time_unit(member, light))
	for member in members:
		member.advance_time(units)
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


## Why `item` can't be used right now, or "" if it can.
func cannot_use_reason(item: SupplyItem, in_combat := false) -> String:
	if in_combat and not item.usable_in_combat:
		return "Not during a fight"
	if supplies.count(item) <= 0 and not (item.effect == SupplyItem.Effect.REFILL_LANTERN and supplies.open_flask > 0.0):
		return "None left"
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
func use_item(item: SupplyItem, in_combat := false) -> String:
	if cannot_use_reason(item, in_combat) != "":
		return ""
	match item.effect:
		SupplyItem.Effect.REFILL_LANTERN:
			supplies.refill(item)
		SupplyItem.Effect.FEED_PARTY:
			supplies.take(item)
			for member in living_members():
				member.eat()
				member.add_effect_over_time("health", _healing(item.amount), item.duration)
		SupplyItem.Effect.HEAL_ONE:
			var target := most_hurt()
			supplies.take(item)
			target.add_effect_over_time("health", _healing(item.amount), item.duration)
		SupplyItem.Effect.DRESS_INJURY:
			supplies.take(item)
			var patient := first_undressed_injured()
			patient.dress_injury()
			if living_members().any(func(m: Companion): return m.has_talent("steady_hands")):
				patient.add_effect_over_time("health", 4, 20)  # steady hands (#47)
		SupplyItem.Effect.LIGHT_TORCH:
			supplies.light_torch(item)
		SupplyItem.Effect.LIFT_BANE:
			supplies.take(item)
			for member in living_members():
				if member.has_bane():
					var lifted: Boon = member.lift_bane()
					if not in_combat:
						advance_time(item.use_time)
					return "%s: %s lifts." % [member.display_name, lifted.display_name]
	if not in_combat:  # in a fight, the round's time covers it
		advance_time(item.use_time)
	return item.use_message


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
