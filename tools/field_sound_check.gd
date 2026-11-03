extends SceneTree
## #217: ChatGPT's field sounds connected. Every floor theme uses the soft
## stone steps, its own bed, the new bump and passage sounds (no
## placeholders left); every enemy has a hurt and a death cry; prayers,
## Pack actions, brews, traps, stairs, level-ups, map warnings and the
## smith each have a sound that exists; the place bed plays on Effects.

const Sounds := preload("res://scripts/sounds.gd")
const Spells := preload("res://scripts/spells.gd")

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	# Themes.
	var beds := {"cave": "ambience-cave", "fungal-caverns": "ambience-fungal", "stone": "ambience-stone", "fortress": "ambience-fortress"}
	for id in beds:
		var theme: EnvironmentTheme = load("res://themes/%s.tres" % id)
		var paths: Array = theme.footstep_sounds.map(func(s): return s.resource_path)
		var all: Array = paths + [theme.ambience.resource_path, theme.bump_sound.resource_path, theme.open_sound.resource_path]
		check("%s: four soft stone steps" % id, paths.size() == 4 and paths.all(func(p): return p.begins_with("res://audio/field-v1/step-stone-")), paths)
		check("...its own bed, the new bump and passage", theme.ambience.resource_path.ends_with(beds[id] + ".wav") and theme.bump_sound.resource_path.ends_with("wall-bump.wav") and theme.open_sound.resource_path.begins_with("res://audio/field-v1/passage-"))
		check("...no placeholders left", not all.any(func(p): return p.contains("placeholder")))
	var web: EnvironmentTheme = load("res://themes/cave.tres")
	var door: EnvironmentTheme = load("res://themes/stone.tres")
	check("webs tear, doors scrape", web.open_sound.resource_path.ends_with("passage-web.wav") and door.open_sound.resource_path.ends_with("passage-stone-door.wav"))
	check("tangled roots rustle when pushed; barred doors just bump", web.blocked_sound.resource_path.ends_with("passage-roots.wav") and load("res://themes/fungal-caverns.tres").blocked_sound != null and door.blocked_sound == null)

	# Monsters.
	var missing := []
	var families := {}
	for file in DirAccess.get_files_at("res://data/enemies/"):
		if not file.ends_with(".tres"):
			continue
		var type: EnemyType = load("res://data/enemies/" + file)
		var family := Sounds.creature(type)
		families[family] = families.get(family, 0) + 1
		for end in ["_hurt", "_death"]:
			if not Sounds.EFFECTS.has(family + end):
				missing.append(file + end)
	check("every enemy has a hurt and a death cry", missing.is_empty(), missing)
	check("...across all six families", families.size() == 6, families)
	check("rats, spiders, goblins and the deep land where they should", Sounds.creature(load("res://data/enemies/great_rat.tres")) == "rat" and Sounds.creature(load("res://data/enemies/webspinner.tres")) == "spider" and Sounds.creature(load("res://data/enemies/goblin_queen.tres")) == "goblin" and Sounds.creature(load("res://data/enemies/underhound.tres")) == "deep")

	# Prayers, items, the rest.
	check("each prayer has its sound, and a falter its own", Spells.ORDER.all(func(id): return Sounds.EFFECTS.has(Sounds.prayer(id, false))) and Sounds.prayer("mend", true) == "prayer_miscast" and Sounds.prayer("bind", false) == "prayer_bind")
	var items := {"ration": "pack_eat", "dressing": "pack_bandage", "oil_flask": "pack_oil", "tome_light": "pack_tome"}
	check("eating, bandaging, oil and reading sound once each", items.keys().all(func(i): return Sounds.for_item(load("res://data/items/%s.tres" % i)) == items[i] and Sounds.EFFECTS.has(items[i])))
	var keys := ["brew_drink", "brew_shatter", "level_up", "stairs_down", "stairs_up", "map_noticed", "map_heavy_blow", "smith_temper",
			"trap_dart", "trap_snare", "trap_alarm_bell", "trap_tripwire"]
	check("brews, level-ups, stairs, map warnings, traps and the smith", keys.all(func(k): return Sounds.EFFECTS.has(k) and Sounds.EFFECTS[k] != null), keys.filter(func(k): return not Sounds.EFFECTS.has(k)))
	var screen = load("res://scripts/event_screen.gd").new()
	var traps := {}
	for id in ["trap_dart", "trap_snare", "trap_bell_wire", "trap_tripwire", "trap_hollow_floor"]:
		screen._event = load("res://data/events/%s.tres" % id)
		traps[id] = screen._trap_sound()
	screen.free()
	check("each trap springs with its own sound; a hollow floor still drops", traps["trap_dart"] == "trap_dart" and traps["trap_bell_wire"] == "trap_alarm_bell" and traps["trap_hollow_floor"] == "fall", traps)

	# The place bed: Effects, everywhere.
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	check("floor 1's bed is the new cave ambience, on Effects", main._ambience_player.bus == "Effects" and main._ambience_player.stream.resource_path.ends_with("ambience-cave.wav"), main._ambience_player.bus)
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	await process_frame
	check("...floor 2's is the fungal one", main._ambience_player.stream.resource_path.ends_with("ambience-fungal.wav"), main._ambience_player.stream.resource_path)
	print("fails=", fails)
	quit()
