class_name EventOutcome
extends Resource
## One possible result of a room-event choice (#16). A choice can have
## several, picked at random by weight.

enum Target {
	ONE,  ## one living hero (the one who acted, or at random)
	EVERYONE,  ## every living hero
}

@export var weight := 1
## A bell wire rang (#94): the next fight on this floor can't be heard
## first, and they act first.
@export var alarm := false
## A noise (falling stones, a clatter): wandering monsters come looking
## (owner, 2026-10-26). A rung bell does this too.
@export var stirs := false
@export_multiline var text := ""
@export var target := Target.ONE
## Immediate change to health (negative hurts).
@export var health := 0
## Healing that arrives over 20 time, or at the next rest (#10).
@export var heal_over_time := 0
@export var strain := 0.0
@export var injury: Injury
## Oil poured straight into the lantern (negative spills it).
@export var oil := 0.0
## Supplies found.
@export var loot: Dictionary[SupplyItem, int] = {}
## Gold coins found (#42).
@export var gold := 0
## Random valuables found, drawn from RoomEvents.TREASURE for the depth.
@export var treasure := 0
## Gear found (goes into the pack, unequipped).
@export var gear: Array[Equipment] = []
## The party rests here (as at a rest spot).
@export var rest := false
## Enemies that attack once the text is read.
@export var ambush: Array[EnemyType] = []
## A blessing or curse on whoever acted, or everyone (#133).
@export var boon: Boon
## Lifts a bane from whoever acted, or everyone (holy water, a kind shrine).
@export var lift_bane := false
## Preparation that sticks (#114): this outcome marks the room (e.g. "the
## charm is down")...
@export var sets_flag := ""
## ...and an outcome with this flag in `blocked_by` can't happen once the
## room is marked (no charm left to rattle).
@export var blocked_by := ""
## Story (#123): mark a flag on a quest and/or move it to a stage
## (quests.gd), e.g. the evidence is found.
@export var quest := ""
@export var quest_flag := ""
@export var quest_stage := -1
