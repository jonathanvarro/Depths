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
	TREASURE,  ## not usable: sold to the merchant for `price` (#42)
	TOOL,  ## not used up: carrying it opens choices on events (pick, spade; #133)
	CURE_VENOM,  ## clears spider venom from one hero (in fights too); also purifies water
	LIFT_BANE,  ## lifts one bane from a hero; also blesses evil shrines (#133)
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
## Gold: what the merchant charges, or for treasure what he pays (#42).
@export var price := 0
## "a spade", "an antidote", "holy water": for "needs ..." on event
## choices (#133). Empty: "a" plus the name.
@export var a_name := ""
## How many fit in one pack slot (#133). 0: by kind - treasure 3, tools 1,
## everything else 5.
@export var stack := 0


func with_article() -> String:
	if a_name != "":
		return a_name
	var noun := display_name.to_lower()
	return ("an " if noun[0] in "aeiou" else "a ") + noun


func stack_size() -> int:
	if stack > 0:
		return stack
	match effect:
		Effect.TREASURE:
			return 3
		Effect.TOOL:
			return 1
	return 5
