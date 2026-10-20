extends SceneTree
## Actual Godot resource/import contract for #112's full item library.

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)


func _run() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/items/refined-v2/catalog.json"))
	_check(catalogue["items"].size() == 32, "Complete live item/gear catalogue")
	var seen: Dictionary = {}
	for entry: Dictionary in catalogue["items"]:
		var item: Resource = load(entry["resource"])
		_check(item is SupplyItem or item is Equipment, "Typed resource " + entry["id"])
		_check(item.display_name == entry["name"] and item.description == entry["description"], "Live copy " + entry["id"])
		_check(item.icon != null and item.icon.resource_path == entry["icon"], "Live binding " + entry["id"])
		_check(item.icon.get_size() == Vector2(128, 128), "Native128 import " + entry["id"])
		_check(not seen.has(item.icon.resource_path), "Distinct icon " + entry["id"])
		seen[item.icon.resource_path] = true
	for entry: Dictionary in catalogue["auxiliary"]:
		var texture: Texture2D = load(entry["icon"])
		_check(texture != null and texture.get_size() == Vector2(128, 128), "Lantern import " + entry["id"])
	print("REFINED_ITEMS: checks=%d failures=%d resources=%d" % [checks, failures, seen.size()])
	quit(0 if failures == 0 else 1)
