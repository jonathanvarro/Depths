extends RefCounted
## The party as a whole: up to three heroes and the time spent so far.
##
## Kept by main.gd for the whole session, so it carries across floors.
## The game starts with a lone survivor; the other slots fill later
## (recruitment at the campfire, #17).

signal changed

const MAX_MEMBERS := 3

var members: Array[Companion] = []
## Time units spent this expedition. Every step costs one (#10).
var time_elapsed := 0


## Adds a copy of `definition` (so the .tres file is never modified).
## Returns false if all slots are taken.
func add_member(definition: Companion) -> bool:
	if members.size() >= MAX_MEMBERS:
		return false
	var member: Companion = definition.duplicate()
	member.pending_effects = []
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
	for member in members:
		member.advance_time(units)
	changed.emit()


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
		parts.append("%s %d/%d%s" % [member.display_name, member.health, member.max_health, pending])
	for i in free_slots():
		parts.append("[empty]")
	return ", ".join(parts)
