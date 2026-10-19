extends RefCounted
## Player settings (#52): volumes, fullscreen, screen flashes and text size,
## kept in user://settings.cfg and applied at startup. Test runs (started
## with --script) use their own file.

const UiTheme := preload("res://scripts/ui_theme.gd")
const PATH_GAME := "user://settings.cfg"
const PATH_TEST := "user://test_settings.cfg"
const BUSES := ["Master", "Music", "Effects"]
## Text and interface size steps (the whole UI scales with it).
const TEXT_SIZES := {"Normal": 1.0, "Large": 1.15, "Larger": 1.3}

const DEFAULTS := {
	"Master": 1.0, "Music": 0.8, "Effects": 1.0,
	"fullscreen": false, "flashes": true, "text_size": "Normal",
}
## Current values live in engine metadata, not static variables: static
## variables kept this script alive at exit (#100).
const STATE := "depths_settings"


static func _values() -> Dictionary:
	if not Engine.has_meta(STATE):
		Engine.set_meta(STATE, DEFAULTS.duplicate())
	return Engine.get_meta(STATE)


static func path() -> String:
	return PATH_TEST if "--script" in OS.get_cmdline_args() else PATH_GAME


static func load_settings() -> void:
	if Engine.has_meta(STATE + "_loaded"):
		return
	Engine.set_meta(STATE + "_loaded", true)
	var config := ConfigFile.new()
	if config.load(path()) != OK:
		return
	for key in _values():
		_values()[key] = config.get_value("settings", key, _values()[key])


static func save() -> void:
	var config := ConfigFile.new()
	for key in _values():
		config.set_value("settings", key, _values()[key])
	config.save(path())


static func get_value(key: String) -> Variant:
	load_settings()
	return _values()[key]


static func set_value(key: String, value: Variant, tree: SceneTree = null) -> void:
	load_settings()
	_values()[key] = value
	save()
	apply(tree)


## Music and effects get their own buses (made here if the project has
## none), so their volumes can be set apart from the master volume.
static func ensure_buses() -> void:
	for bus in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")


static func apply(tree: SceneTree = null) -> void:
	load_settings()
	ensure_buses()
	for bus in BUSES:
		var index := AudioServer.get_bus_index(bus)
		var level: float = _values()[bus]
		AudioServer.set_bus_mute(index, level <= 0.001)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.001)))
	if not OS.has_feature("mobile") and DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if _values()["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode and (_values()["fullscreen"] or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN):
			DisplayServer.window_set_mode(mode)
	if tree:
		tree.root.content_scale_factor = TEXT_SIZES.get(_values()["text_size"], 1.0)
		UiTheme.install()  # the shared Field kit style (#51)
