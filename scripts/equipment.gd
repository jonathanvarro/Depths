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
## "weapon", "body" (armour, #93) or "trinket" (#135).
@export_enum("weapon", "body", "trinket") var slot := "weapon"
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
## Trinkets (#135; owner 2026-10-21): what wearing it does, as long as it's
## worn. Common: a benefit and a drawback; fine: a clear benefit, a small
## drawback; rare: two benefits; unique: a playstyle buff.
@export var effect: Boon
@export_enum("common", "fine", "rare", "unique") var tier := "common"
## Jewellery found as treasure is worn as this; taken off, it goes back to
## the pack as that treasure (and still sells as treasure).
@export var treasure: SupplyItem
## A cursed trinket's hidden bane, shown only once worn. It can't be taken
## off until cleansed (holy water, the nurse), when it becomes `cleansed`.
@export var curse: Boon
@export var cleansed: Equipment
