class_name SupplyItem
extends Resource
## A kind of consumable supply (oil flask, ration, draught...). Definitions
## live in `data/items/*.tres`; the pack counts how many of each it holds.
##
## Use is only allowed outside combat, and healing works over time: it
## finishes gradually as the party walks, or at once when they rest or change
## floor (#8, #10).

enum Effect {
	REFILL_LANTERN,  ## pours `amount` oil into the lantern
	FEED_PARTY,  ## every living hero heals `amount` over `duration`
	HEAL_ONE,  ## the most hurt living hero heals `amount` over `duration`
	DRESS_INJURY,  ## binds one injury until camp (#11)
	LIGHT_TORCH,  ## lights a torch to hold; it burns down (#59)
}

@export var display_name := "Supply"
@export_multiline var description := ""
@export var icon: Texture2D
@export var effect := Effect.FEED_PARTY
@export var amount := 0
## Time units over which healing arrives.
@export var duration := 20
## Time units spent using it.
@export var use_time := 1
## Shown after use.
@export var use_message := ""
## Food and healing are for outside combat (#10); only items marked here can
## be used in a fight.
@export var usable_in_combat := false
