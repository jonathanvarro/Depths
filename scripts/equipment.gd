class_name Equipment
extends Resource
## A piece of gear a hero can wield (#58, a first slice of #48). Carried
## gear sits in the pack until equipped; equipping swaps out what the hero
## held before. Definitions live in `data/gear/*.tres`.

@export var display_name := "Gear"
@export_multiline var description := ""
@export var icon: Texture2D
## Damage range when attacking with it.
@export var attack_min := 1
@export var attack_max := 2
## Added to the hero's hit chance (negative for a poor weapon).
@export_range(-0.5, 0.5) var accuracy_bonus := 0.0
## Gold at the smith; the merchant buys it back for 30% (#42).
@export var price := 0
## Reaches past the front row: usable from the back, hits enemies' back row (#72).
@export var reach := false
## "weapon", "body" (armour, #93), "trinket" (#135) or "back" (a backpack,
## cloak or cape; owner 2026-10-21).
@export_enum("weapon", "body", "trinket", "back") var slot := "weapon"
## A backpack: pack slots it adds while worn (owner, 2026-10-21).
@export var pack_slots := 0
## Body armour: taken off every blow (minimum 1), and how much it slows.
@export var armour := 0
@export var initiative_penalty := 0
## Strength adds to force weapons; a light weapon ignores a weak arm (#47).
@export var force := true
@export var light := false
## How it lands (spoils arrival, owner 2026-10-20): "slash" for blades,
## "smash" for clubs and maces, "pierce" for spears.
@export_enum("slash", "smash", "pierce") var strike := "slash"

@export_group("Trinket")
## Trinkets (#135; owner 2026-10-21), and cloaks and capes on the back:
## what wearing it does, as long as it's worn.
@export var effect: Boon
## Quality (owner, 2026-10-21), shown as the icon's border: common (the base
## item, no border), fine (slightly better base numbers), magic (better base
## plus a modifier, blue), rare (two modifiers) and unique (named, a
## playstyle effect). A trinket has no base numbers, so it starts at magic.
@export_enum("common", "fine", "magic", "rare", "unique") var tier := "common"
## Jewellery found as treasure is worn as this; taken off, it goes back to
## the pack as that treasure (and still sells as treasure).
@export var treasure: SupplyItem
## A cursed trinket's hidden bane, shown only once worn. It can't be taken
## off until cleansed (holy water, the nurse), when it becomes `cleansed`.
@export var curse: Boon
@export var cleansed: Equipment


## What a back item does, in words: "+2 pack slots", "nerves fray 10% slower".
static func back_text(item: Equipment) -> String:
	var parts := PackedStringArray()
	if item.pack_slots > 0:
		parts.append("+%d pack slots" % item.pack_slots)
	if item.initiative_penalty > 0:
		parts.append("slower by %d" % item.initiative_penalty)
	if item.effect:
		parts.append(item.effect.effects_text())
	return ", ".join(parts)
