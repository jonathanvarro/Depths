extends RefCounted
## Item quality, shown as a border round the icon (owner, 2026-10-21):
##   common  - none: the base item, as the smith sells it
##   fine    - pale bronze, thin: slightly better base numbers
##   magic   - blue: better base plus a modifier
##   rare    - cold silver with corner studs: two modifiers
##   unique  - amber gold, thick, with a slow glint: named, a playstyle effect
##   cursed  - violet, once worn; until then it passes for its apparent tier
## Colour is never the only cue: weight and studs differ too, and the tier
## is named in the item's text.

const Trinkets := preload("res://scripts/trinkets.gd")
const Settings := preload("res://scripts/settings.gd")
const COLOURS := {
	"fine": Color("b9915f"),
	"magic": Color("4f86e0"),
	"rare": Color("c8d2dc"),
	"unique": Color("f0b445"),
	"cursed": Color("a35bd1"),
}
const WIDTHS := {"fine": 1, "magic": 2, "rare": 2, "unique": 3, "cursed": 2}


## The tier to show for `item` (an Equipment, or a SupplyItem). Jewellery
## takes its trinket's tier. A cursed trinket shows "cursed" only once
## `worn_by` has put it on.
static func tier_of(item, worn_by: Companion = null) -> String:
	if item is Equipment:
		if item.curse and worn_by and worn_by.trinket == item:
			return "cursed"
		return item.tier
	if item is SupplyItem and item.effect == SupplyItem.Effect.TREASURE:
		var trinket: Equipment = Trinkets.for_treasure(item)
		if trinket:
			return trinket.tier
	return "common"


## An icon of `size`, framed for its tier (common: the bare icon).
static func framed(texture: Texture2D, tier: String, size: Vector2) -> Control:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not COLOURS.has(tier):
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return icon
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", style(tier))
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_meta("tier", tier)
	frame.add_child(icon)
	if tier == "rare":
		frame.add_child(_studs())
	if tier == "unique" and Settings.get_value("flashes"):
		# A slow glint on the border only (self_modulate leaves the icon be).
		frame.ready.connect(func():
			var glint := frame.create_tween().set_loops()
			glint.tween_property(frame, "self_modulate", Color(1.45, 1.35, 1.15), 1.2).set_trans(Tween.TRANS_SINE)
			glint.tween_property(frame, "self_modulate", Color.WHITE, 1.2).set_trans(Tween.TRANS_SINE))
	return frame


## The border as a stylebox (also for tile buttons, e.g. the chest screen).
static func style(tier: String, background := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	if COLOURS.has(tier):
		box.border_color = COLOURS[tier]
		box.set_border_width_all(WIDTHS[tier])
		box.set_content_margin_all(WIDTHS[tier] + 1)
	box.set_corner_radius_all(2)
	return box


## Gives a tile button its tier's border, keeping its own background.
static func apply_to_button(button: Button, tier: String) -> void:
	if not COLOURS.has(tier):
		return
	for state in ["normal", "hover", "pressed", "focus"]:
		var base := button.get_theme_stylebox(state)
		var background := (base as StyleBoxFlat).bg_color if base is StyleBoxFlat else Color(0.1, 0.09, 0.08, 0.9)
		var box := style(tier, background)
		if state == "focus":
			box.bg_color = Color(0, 0, 0, 0)
		button.add_theme_stylebox_override(state, box)
	button.set_meta("tier", tier)
	if tier == "rare":
		button.add_child(_studs())


## Rare's corner studs: a second cue besides colour.
static func _studs() -> Control:
	var studs := Control.new()
	studs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	studs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	studs.draw.connect(func():
		var s := 4.0
		for corner in [Vector2.ZERO, Vector2(studs.size.x - s, 0), Vector2(0, studs.size.y - s), studs.size - Vector2(s, s)]:
			studs.draw_rect(Rect2(corner, Vector2(s, s)), COLOURS["rare"]))
	return studs
