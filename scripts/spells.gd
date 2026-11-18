extends RefCounted
## Magic (#170, owner 2026-11-02; DESIGN.md "Magic"). The first spells are
## prayers, cast only by a Mage (items that grant spells come later, and so
## do the end-game spells borrowed from the thing below).
##
## - A few casts per trip: every Mage sets out with CASTS. A votive candle
##   (outside a fight) gives one back.
## - Learned from tomes, kept for the whole campaign (separate from the
##   talents, which reset each trip). Every Mage knows Mend.
## - A prayer can go wrong: a Shaken or Panicking caster may find nothing
##   answers. The cast is spent and their nerves fray.

const StrainRules := preload("res://scripts/strain.gd")
const GearModel := preload("res://scripts/gear_model.gd")

const CASTS := 3
## id -> name, what it does, and where it can be cast.
const SPELLS := {
	"mend": {"name": "Mend", "text": "Heals the most hurt hero %d at once.", "fight": true, "field": true},
	"light": {"name": "Holy light", "text": "A steady glow for %d time: bright light without oil. In a fight it blinds them like a flare.", "fight": true, "field": true},
	"bind": {"name": "Bind", "text": "Holds the chosen foe in place: it loses its next %d turns.", "fight": true, "field": false},
	"watch": {"name": "Watchful eye", "text": "For %d time, the monsters on this floor show on the map.", "fight": false, "field": true},
	"discern": {"name": "Discern", "text": "Reveals the hidden properties, and any curse, of every unidentified piece the party wears or carries.", "fight": false, "field": true},
}
const ORDER := ["mend", "light", "bind", "watch", "discern"]
const STARTING := ["mend"]
const MEND := 8
const LIGHT_TIME := 40
const BIND_TURNS := 2
const BIND_BOSS_TURNS := 1  # the queen shrugs it off sooner
const WATCH_TIME := 60
## Miscasts, by the caster's strain.
const MISCAST := {StrainRules.State.SHAKEN: 0.15, StrainRules.State.PANICKING: 0.3}
const MISCAST_STRAIN := 6.0


static func name_of(id: String) -> String:
	return SPELLS[id]["name"]


static func describe(id: String, hero: Companion = null) -> String:
	var text: String = SPELLS[id]["text"]
	match id:
		"mend": return text % mend_amount(hero)
		"light": return text % light_time(hero)
		"bind": return text % bind_turns(hero)
		"watch": return text % watch_time(hero)
	return text


## How much a Mage's staff or wand adds to their prayers (#260, owner
## 2026-11-17): 0, then 1 at its mastery 3 and 2 at mastery 6.
static func focus_power(hero: Companion) -> int:
	if hero == null or hero.weapon == null or not hero.weapon.focus:
		return 0
	var level: int = load("res://scripts/gear_model.gd").level_of(hero.weapon)
	return 2 if level >= 6 else (1 if level >= 3 else 0)


static func mend_amount(hero: Companion = null) -> int:
	return MEND + 2 * focus_power(hero)


static func light_time(hero: Companion = null) -> int:
	return LIGHT_TIME + 10 * focus_power(hero)


static func bind_turns(hero: Companion = null) -> int:
	return BIND_TURNS + (1 if focus_power(hero) >= 2 else 0)


static func watch_time(hero: Companion = null) -> int:
	return WATCH_TIME + 20 * focus_power(hero)


static func is_caster(hero: Companion) -> bool:
	return hero != null and load("res://scripts/classes.gd").of(hero.role) == "Mage"


## The prayers `hero` knows, in book order.
static func known(hero: Companion) -> Array:
	if not is_caster(hero):
		return []
	return ORDER.filter(func(id): return id in STARTING or id in hero.spells)


## A fresh trip: every caster's casts come back.
static func refill(hero: Companion) -> void:
	hero.casts = CASTS if is_caster(hero) else 0


## Why `hero` can't cast `id` here, or "".
static func cannot_cast(hero: Companion, id: String, in_fight: bool) -> String:
	if not is_caster(hero) or id not in known(hero):
		return "Not known"
	if not hero.is_alive():
		return "Needs a conscious caster"
	if hero.casts <= 0:
		return "No casts left this trip"
	if not SPELLS[id]["fight" if in_fight else "field"]:
		return "Only in a fight" if in_fight == false else "Not in a fight"
	return ""


## Spends a cast and rolls for a miscast. Returns the failure message, or "".
static func spend(hero: Companion, rng: RandomNumberGenerator) -> String:
	hero.casts -= 1
	hero.emit_changed()
	var chance: float = MISCAST.get(hero.strain_state(), 0.0)
	if chance > 0.0 and rng.randf() < chance:
		hero.change_strain(MISCAST_STRAIN)
		return "%s's prayer falters. Nothing answers." % hero.display_name
	return ""


## Mend: the most hurt hero (or `who`) heals at once.
static func mend(party, who: Companion = null, caster: Companion = null) -> String:
	var target: Companion = who if who != null else party.most_hurt()
	if target == null:
		return "No one is hurt."
	var before := target.health
	target.change_health(mend_amount(caster))
	return "%s is mended (+%d)." % [target.display_name, target.health - before]


## Casting outside a fight, from the Pack. Returns the message.
static func cast_in_field(party, hero: Companion, id: String, rng: RandomNumberGenerator) -> String:
	if cannot_cast(hero, id, false) != "":
		return ""
	if id == "mend" and party.most_hurt() == null:
		return ""
	if id == "discern" and party.unidentified().is_empty():
		return ""
	var failed := spend(hero, rng)
	party.advance_time(1)
	if failed != "":
		return failed
	match id:
		"mend":
			return mend(party, null, hero)
		"light":
			party.supplies.kindle(light_time(hero))
			return "A pale light gathers around %s." % hero.display_name
		"watch":
			party.watch_left = watch_time(hero)
			party.changed.emit()
			return "%s prays, and the floor's monsters show on the map." % hero.display_name
		"discern":  # owner, 2026-11-03: identification
			var read := PackedStringArray()
			for piece: Equipment in party.unidentified():
				read.append(GearModel.identify(piece))
			party.changed.emit()
			party.supplies.changed.emit()
			return "%s prays over the gear. %s" % [hero.display_name, " ".join(read)]
	return ""
