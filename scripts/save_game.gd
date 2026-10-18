extends RefCounted
## Saving and loading (#45). Owner direction: save and exit any time (built
## for phones), and autosave on floor changes and on returning to camp.
##
## One save slot at user://save.dat. Objects are turned into plain data:
## resources with a file (items, gear, events, portraits) are stored by
## path; generated ones (recruits, party members) by their script variables.
## main.gd decides what goes in and how to rebuild the game from it.

## Test runs (started with --script) get their own file, so they never
## touch the player's save.
static var path := "user://test_save.dat" if "--script" in OS.get_cmdline_args() else "user://save.dat"
const VERSION := 1

## Set by the title screen's Continue before the game scene loads.
static var continue_requested := false
## The starting hero chosen for a new game (#95), as a resource path.
static var new_game_hero := ""


static func exists() -> bool:
	return FileAccess.file_exists(path)


static func delete() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func write(data: Dictionary) -> bool:
	data["version"] = VERSION
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't save: %s" % FileAccess.get_open_error())
		return false
	file.store_var(data)
	return true


static func read() -> Dictionary:
	if not exists():
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data = file.get_var()
	if not data is Dictionary or data.get("version", 0) != VERSION:
		return {}
	return data


## An object's script variables as plain data.
static func pack_object(object: Object, skip: Array = []) -> Dictionary:
	var out := {}
	for property in object.get_property_list():
		if not (property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE) or property["name"] in skip:
			continue
		out[property["name"]] = pack_value(object.get(property["name"]))
	return out


static func pack_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_OBJECT:
			if value == null:
				return null
			if value is Resource and value.resource_path != "" and not value.resource_path.contains("::"):
				return {"$res": value.resource_path}
			if value is Resource and value.get_script():
				return {"$obj": value.get_script().resource_path, "data": pack_object(value)}
			return null  # runtime-only objects (nodes, tweens) aren't saved
		TYPE_ARRAY:
			return value.map(func(v): return pack_value(v))
		TYPE_DICTIONARY:
			var pairs := []
			for key in value:
				pairs.append([pack_value(key), pack_value(value[key])])
			return {"$dict": pairs}
	return value


static func unpack_value(value: Variant) -> Variant:
	if value is Array:
		return value.map(func(v): return unpack_value(v))
	if value is Dictionary:
		if value.has("$res"):
			return load(value["$res"]) if ResourceLoader.exists(value["$res"]) else null
		if value.has("$obj"):
			var object: Object = load(value["$obj"]).new()
			unpack_into(object, value["data"])
			return object
		if value.has("$dict"):
			var out := {}
			for pair in value["$dict"]:
				out[unpack_value(pair[0])] = unpack_value(pair[1])
			return out
	return value


## Puts saved script variables back, keeping typed arrays typed.
static func unpack_into(object: Object, data: Dictionary) -> void:
	for key in data:
		var value: Variant = unpack_value(data[key])
		var current: Variant = object.get(key)
		if current is Array and value is Array:
			var typed: Array = current.duplicate()
			typed.clear()
			typed.assign(value.filter(func(v): return v != null) if current.is_typed() and current.get_typed_builtin() == TYPE_OBJECT else value)
			object.set(key, typed)
		elif current is Dictionary and value is Dictionary:
			var typed_dict: Dictionary = current.duplicate()
			typed_dict.clear()
			typed_dict.assign(value)
			object.set(key, typed_dict)
		else:
			object.set(key, value)
