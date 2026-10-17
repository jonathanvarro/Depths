extends RefCounted
## The party as a whole: up to three heroes, what they carry, and the time
## spent so far.
##
## Kept by main.gd for the whole session, so it carries across floors.
## The game starts with a lone survivor; the other slots fill later
## (recruitment at the campfire, #17).

signal changed

const Supplies := preload("res://scripts/supplies.gd")
const MAX_MEMBERS := 3
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
	member.pending_effects = []
	member.injuries = definition.injuries.duplicate()
	member.dressed = []
	members.append(member)
	changed.emit()
	return true


func remove_member(member: Companion) -> void:
	members.erase(member)
	changed.emit()


func free_slots() -> int:
	return MAX_MEMBERS - members.size()


func advance_time(units := 1) -> void:
	time_elapsed += units
	supplies.burn(units)
	for member in members:
		member.advance_time(units)
	changed.emit()


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


## Resting: time passes (the lantern keeps burning) and everything in
## progress, like food and draughts, finishes.
func rest() -> void:
	advance_time(REST_TIME)
	complete_pending_effects()


func living_members() -> Array[Companion]:
	return members.filter(func(m: Companion): return m.is_alive())


## The living hero furthest below full health, or null if nobody is hurt.
func most_hurt() -> Companion:
	var worst: Companion = null
	for member in living_members():
		if member.health < member.effective_max_health() and (worst == null or member.effective_max_health() - member.health > worst.effective_max_health() - worst.health):
			worst = member
	return worst


## Why `item` can't be used right now, or "" if it can.
func cannot_use_reason(item: SupplyItem) -> String:
	if supplies.count(item) <= 0 and not (item.effect == SupplyItem.Effect.REFILL_LANTERN and supplies.open_flask > 0.0):
		return "None left"
	match item.effect:
		SupplyItem.Effect.REFILL_LANTERN:
			if supplies.lantern_is_full():
				return "Lantern is full"
		SupplyItem.Effect.FEED_PARTY, SupplyItem.Effect.HEAL_ONE:
			if most_hurt() == null:
				return "Nobody is hurt"
		SupplyItem.Effect.DRESS_INJURY:
			if first_undressed_injured() == null:
				return "No injury to bind"
	return ""


## Uses one `item` (outside combat). Returns a message to show, or "" if it
## couldn't be used.
func use_item(item: SupplyItem) -> String:
	if cannot_use_reason(item) != "":
		return ""
	match item.effect:
		SupplyItem.Effect.REFILL_LANTERN:
			supplies.refill(item)
		SupplyItem.Effect.FEED_PARTY:
			supplies.take(item)
			for member in living_members():
				member.add_effect_over_time("health", item.amount, item.duration)
		SupplyItem.Effect.HEAL_ONE:
			var target := most_hurt()
			supplies.take(item)
			target.add_effect_over_time("health", item.amount, item.duration)
		SupplyItem.Effect.DRESS_INJURY:
			supplies.take(item)
			first_undressed_injured().dress_injury()
	advance_time(item.use_time)
	return item.use_message


## Moving between floors: every effect with a duration finishes now, so the
## party arrives with healing (and the like) fully received.
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
