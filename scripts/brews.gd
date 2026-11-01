extends RefCounted
## Unknown brews (#175, owner 2026-10-30): cave brews found underground are
## known by their look until someone drinks one, throws one at a foe, or an
## Alwen (field medic) or a Fixer in the party names one as it's found.
## Each expedition reshuffles which look (glass shape, liquid colour, stopper
## mark) goes with which kind; within it the look stays put (saves, floors),
## and naming one bottle names its kind. A test that shows nothing (healing
## someone unhurt) names nothing. Bought medicine is always reliable.
##
## The mapping lives on the party's Supplies (brew_looks, brews_known). The
## item resources are shared, so refresh() renames them in place.

const BrewArt := preload("res://art/items/brews-v1/compose.gd")
const KINDS := ["restorative", "caustic", "slumber", "frenzy", "revealing"]
const COLOUR_NAMES := ["rust-red", "ochre", "moss-green", "slate-blue", "violet", "milky"]
const SHAPE_NAMES := {"squat": "squat bottle", "tall": "tall bottle", "flask": "flask", "vial": "vial", "gourd": "gourd", "jar": "cracked jar"}
const MARK_NAMES := {"eye": "an eye", "tooth": "a tooth", "spiral": "a spiral", "hand": "a hand", "moon": "a moon", "cross": "a cross"}
const KNOWN := {
	"restorative": ["Restorative brew", "Drunk: heals 8 over a little time. Thrown: heals the foe."],
	"caustic": ["Caustic brew", "Drunk: burns for 3. Thrown: 6 damage that no armour stops."],
	"slumber": ["Slumber brew", "Drunk: a deep, steadying sleep (time passes). Thrown: the foe loses its next turn."],
	"frenzy": ["Frenzy brew", "Drunk: a racing heart (strain). Thrown: the foe turns Savage."],
	"revealing": ["Revealing brew", "Drunk: the floor's rooms show on the map. Thrown: the journal learns the foe's weaknesses."],
}
const HEAL := 8
const BURN := 3
const THROWN_BURN := 6
const THROWN_HEAL := 6
const SLEEP_TIME := 30
const SLEEP_CALM := -15.0
const FRENZY_STRAIN := 15.0
## How often a treasure find is a brew instead.
const FIND_CHANCE := 0.2


## Held here so the renamed resources aren't freed and reloaded plain.
static func item(kind: String) -> SupplyItem:
	var key := "brew_item_" + kind
	if not Engine.has_meta(key):
		Engine.set_meta(key, load("res://data/items/brew_%s.tres" % kind))
	return Engine.get_meta(key)


static func is_brew(i) -> bool:
	return i is SupplyItem and i.effect == SupplyItem.Effect.BREW


## A new expedition: new looks for every kind, nothing known.
static func shuffle(supplies, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var shapes: Array = BrewArt.SHAPES.duplicate()
	var marks: Array = BrewArt.MARKS.duplicate()
	var colours: Array = range(BrewArt.COLOURS.size())
	for list in [shapes, marks, colours]:
		for i in range(list.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t = list[i]; list[i] = list[j]; list[j] = t
	supplies.brew_looks = {}
	for i in KINDS.size():
		supplies.brew_looks[KINDS[i]] = [shapes[i], colours[i], marks[i]]
	supplies.brews_known = []
	refresh(supplies)


static func known(supplies, kind: String) -> bool:
	return kind in supplies.brews_known


## Names a kind for the rest of the expedition. Returns true if it was new.
static func identify(supplies, kind: String) -> bool:
	if known(supplies, kind):
		return false
	supplies.brews_known.append(kind)
	refresh(supplies)
	return true


## Renames and redraws the shared brew items to match the party's mapping.
static func refresh(supplies) -> void:
	if supplies.brew_looks.is_empty():
		shuffle(supplies, randi())
		return
	for kind in KINDS:
		var look: Array = supplies.brew_looks.get(kind, ["flask", 0, "eye"])
		var res := item(kind)
		var is_known := known(supplies, kind)
		if is_known:
			res.display_name = KNOWN[kind][0]
			res.description = "%s, %s liquid, %s on the stopper. %s" % [SHAPE_NAMES[look[0]].capitalize(), COLOUR_NAMES[int(look[1])], MARK_NAMES[look[2]], KNOWN[kind][1]]
		else:
			res.display_name = "%s %s" % [COLOUR_NAMES[int(look[1])].capitalize(), SHAPE_NAMES[look[0]]]
			res.description = "A cave brew, %s on the stopper. Unknown: drink it to learn (outside a fight), or throw it at a foe." % MARK_NAMES[look[2]]
		res.a_name = "a " + res.display_name.to_lower()
		res.icon = _icon(look, kind if is_known else "")


static func _icon(look: Array, kind: String) -> Texture2D:
	var key := "brew_icon_%s_%d_%s_%s" % [look[0], int(look[1]), look[2], kind]
	if Engine.has_meta(key):
		return Engine.get_meta(key)
	var tex := ImageTexture.create_from_image(BrewArt.compose(look[0], int(look[1]), look[2], kind))
	Engine.set_meta(key, tex)
	return tex


## Drinking one outside a fight. `party.brew_revealed` asks main.gd to show
## the floor's rooms. Returns the message.
static func drink(party, brew: SupplyItem, hero: Companion) -> String:
	var kind := brew.brew
	var shown := true
	var text := ""
	party.supplies.take(brew)
	match kind:
		"restorative":
			if hero.health < hero.effective_max_health():
				hero.add_effect_over_time("health", HEAL, 6)
				text = "%s's wounds warm and knit." % hero.display_name
			else:
				shown = false
				text = "%s drinks: herbs and iron, and nothing to mend. No telling what it was." % hero.display_name
		"caustic":
			hero.change_health(-BURN)
			text = "It burns all the way down! %s retches." % hero.display_name
		"slumber":
			party.advance_time(SLEEP_TIME)
			hero.change_strain(SLEEP_CALM)
			text = "%s sleeps where they sit; the others keep watch. They wake calmer." % hero.display_name
		"frenzy":
			hero.change_strain(FRENZY_STRAIN)
			text = "%s's heart hammers; their eyes go wide and wild." % hero.display_name
		"revealing":
			party.brew_revealed.emit()
			text = "The walls seem to glow: %s sees the floor's rooms." % hero.display_name
	hero.emit_changed()
	if shown and identify(party.supplies, kind):
		text += " It was a %s." % KNOWN[kind][0].to_lower()
	party.supplies.changed.emit()
	return text


## Thrown at `foe` in a fight. Returns {damage, healed, slept, killed, text}.
static func throw_at(state, brew: SupplyItem, foe) -> Dictionary:
	var kind := brew.brew
	var out := {"damage": 0, "healed": 0, "slept": false, "killed": false, "text": ""}
	var shown := true
	var name: String = foe.name.to_lower()
	state.party.supplies.take(brew)
	match kind:
		"restorative":
			var healed: int = mini(THROWN_HEAL, foe.type.max_health - foe.health)
			if healed > 0:
				foe.health += healed
				out["healed"] = healed
				out["text"] = "The bottle bursts over the %s - and its wounds close." % name
			else:
				shown = false
				out["text"] = "The bottle bursts over the %s. Nothing seems to happen." % name
		"caustic":
			foe.health = maxi(0, foe.health - THROWN_BURN)
			out["damage"] = THROWN_BURN
			out["killed"] = foe.health <= 0
			out["text"] = "The brew hisses and eats into the %s for %d.%s" % [name, THROWN_BURN, " It falls." if out["killed"] else ""]
		"slumber":
			state.put_to_sleep(foe)
			out["slept"] = true
			out["text"] = "Fumes wrap the %s; it sways, eyes drooping." % name
		"frenzy":
			if foe.elite == "":
				state.make_elite(foe, "Savage")
				foe.health = mini(foe.health, foe.type.max_health)
			out["text"] = "The %s breathes the fumes and goes wild!" % name
		"revealing":
			state.studied.append(foe.type.display_name)
			out["text"] = "Pale light clings to the %s, showing every weak joint. (The journal notes it.)" % name
	if shown and identify(state.party.supplies, kind):
		out["text"] += " It was a %s." % KNOWN[kind][0].to_lower()
	state.party.supplies.changed.emit()
	return out


## Found in a room: an Alwen (field medic) or a Fixer names an unknown kind.
static func on_found(party, brew: SupplyItem) -> String:
	if known(party.supplies, brew.brew):
		return ""
	for hero in party.living_members():
		if hero.trait_id == "field_medic" or hero.role == "Fixer":
			identify(party.supplies, brew.brew)
			return "%s sniffs the cork: a %s." % [hero.display_name, KNOWN[brew.brew][0].to_lower()]
	return ""
