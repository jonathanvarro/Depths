extends SceneTree
## Writes the first things worn on the back (owner, 2026-10-21) into
## data/gear: backpacks that add pack slots, and a cloak and a cape whose
## effects count like a trinket's. Rerun to rebuild:
##   Godot --headless --path . --script tools/story/build_back_gear.gd
## Icons: #138, source-backed field-kit-v1 inventory art.

const BACK_ICONS := {
	"satchel": "res://art/items/field-kit-v1/leather-satchel.png",
	"frame_pack": "res://art/items/field-kit-v1/miners-frame-pack.png",
	"oilcloth_cloak": "res://art/items/field-kit-v1/oilcloth-cloak.png",
	"wool_cape": "res://art/items/field-kit-v1/heavy-wool-cape.png",
}


func _effect(name: String, effects: Dictionary) -> Boon:
	var b := Boon.new()
	b.display_name = name
	for key in effects:
		b.set(key, effects[key])
	var text := b.effects_text()
	b.description = text.substr(0, 1).to_upper() + text.substr(1) + "."
	return b


func _back(id: String, name: String, about: String, price: int, extra: Dictionary) -> void:
	var g := Equipment.new()
	g.slot = "back"
	g.display_name = name
	g.icon = load(BACK_ICONS[id])
	g.description = about
	g.price = price
	g.attack_min = 0
	g.attack_max = 0
	for key in extra:
		g.set(key, extra[key])
	var path := "res://data/gear/%s.tres" % id
	print(path, " ", "ok" if ResourceSaver.save(g, path) == OK else "FAILED")


func _initialize() -> void:
	_back("satchel", "Leather satchel", "A soldier's satchel on a broad strap. Room for a little more.", 25, {"pack_slots": 2})
	_back("frame_pack", "Miner's frame pack", "A wooden frame and canvas, made for hauling ore. Room for a lot more, but it slows you.", 45, {"pack_slots": 4, "initiative_penalty": 1})
	_back("oilcloth_cloak", "Oilcloth cloak", "Waxed and dark. It keeps the drip off you, and the draught off your flame.", 20, {"effect": _effect("Oilcloth cloak", {"strain_rate": 0.9, "oil_rate": 0.9})})
	_back("wool_cape", "Heavy wool cape", "Thick grey wool. Warmth is its own kind of strength down here.", 18, {"effect": _effect("Heavy wool cape", {"max_health": 2})})
	print("done")
	quit()
