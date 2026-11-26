extends SceneTree
## Story quest sites (owner, 2026-11-24): whenever a quest is active, its
## floor is built with the site, the site is whole and reachable, and
## nothing else is put in it. Many seeds, every story package. Also: a floor
## missing a site is noticed (and rebuilt), and F3 reports it.
## Args: tag, screenshot dir.

const Packages := preload("res://scripts/packages.gd")
const Quests := preload("res://scripts/quests.gd")
const WallLights := preload("res://scripts/wall_lights.gd")

const SEEDS := 20

var fails := 0


func check(label: String, ok: bool, detail = "") -> void:
	if not ok: fails += 1
	print("PASS " if ok else "FAIL ", label, "  ", detail)


func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.play_opening = false
	main.wandering = false
	main.floor_seed = 11
	root.add_child(main)
	await create_timer(0.5).timeout
	var story: Array = Packages.library().filter(func(p: QuestPackage): return p.lair == "" and p.chance == 0.0)
	check("there are story packages to test", story.size() >= 3, story.size())
	# The real cause (2026-11-24): the export's text-to-binary conversion
	# emptied every package's rows and flags, so the exported game had no
	# quest sites. Exports ship the text files instead; keep it that way.
	check("exports keep the data files as text (binary conversion emptied the quest sites)", ProjectSettings.get_setting("editor/export/convert_text_resources_to_binary", true) == false)
	var floors := 0
	var problems: Array[String] = []
	for package: QuestPackage in story:
		for s in SEEDS:
			main._camp_state.quests = {}
			Quests.set_stage(main._camp_state, package.quest, package.stages[0])
			for flag in package.needs_flags:
				Quests.set_flag(main._camp_state, package.quest, flag)
			var depth: int = package.min_depth + s % (package.max_depth - package.min_depth + 1)
			main._site_seed = 7000 + s * 13
			main._floors.clear()
			main._go_to_floor(depth, main.Arrival.FROM_ABOVE)
			floors += 1
			var map = main._map
			var tag := "%s floor %d seed %d" % [package.id, depth, main._site_seed]
			if not Packages.active(main._camp_state, depth).has(package):
				continue  # another of its rules keeps it off this floor
			if package.id not in map.packages:
				problems.append(tag + ": not placed")
				continue
			var site: Rect2i = map.marks.get("sites", {}).get(package.id, Rect2i())
			if site.size == Vector2i.ZERO:
				problems.append(tag + ": no site recorded")
				continue
			var own: Array = []
			for c in map.events:
				if site.has_point(c):
					if map.events[c] in package.events:
						own.append(c)
					else:
						problems.append("%s: a foreign event %s inside the site" % [tag, map.events[c].title])
			if own.size() < package.events.size():
				problems.append("%s: %d of %d events present" % [tag, own.size(), package.events.size()])
			var reach: Dictionary = map.walking_distances(map.find_content(map.Content.STAIRS_UP))
			if not own.is_empty() and not own.any(func(c): return reach.has(c) or map.solid.has(c) and [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].any(func(d): return reach.has(c + d))):
				problems.append(tag + ": the site can't be reached from the way in")
			for c in map.marks.get("wall_lights", {}):
				if site.grow(1).has_point(c):
					problems.append(tag + ": a wall light in the site")
			for landmark: Dictionary in map.landmarks:
				if landmark["cells"].any(func(c): return site.has_point(c)):
					problems.append("%s: landmark %s in the site" % [tag, landmark["id"]])
			for key in ["lost_cache", "dripping_pool", "refuge"]:
				if map.marks.has(key) and site.has_point(map.marks[key]):
					problems.append("%s: %s in the site" % [tag, key])
			if not map.marks.get("elite", {}).is_empty() and site.has_point(map.marks["elite"]["cell"]):
				problems.append(tag + ": the named pack starts in the site")
			if main._missing_quest_site(map, depth):
				problems.append(tag + ": a whole floor reports its site missing")
	check("every active story quest gets its whole site, reachable, with nothing else in it (%d floors)" % floors, problems.is_empty(), problems.slice(0, 8))

	# A floor whose site lost its events is noticed, and rebuilt on the way in.
	var left_behind: QuestPackage = Packages.find("left_behind")
	main._camp_state.quests = {}
	Quests.set_stage(main._camp_state, "left_behind", left_behind.stages[0])
	main._site_seed = 4242
	main._floors.clear()
	main._go_to_floor(1, main.Arrival.FROM_ABOVE)
	check("F3 reports the survey site as whole", main._quest_site_report().contains("left_behind OK"), main._quest_site_report())
	# The site has to be found (owner, 2026-11-25): off the map until the
	# party is within a room or a hallway of it.
	var site_rect: Rect2i = main._map.marks["quests"]["left_behind"]
	main._notice_quest_sites(main._party.cell)
	var far: bool = main._map.walking_path(main._party.cell, site_rect.get_center()).size() > main.QUEST_NEAR_STEPS
	check("arriving far from the site, it isn't on the map yet", not far or not main._map.marks.get("quests_near", {}).has("left_behind"))
	var path: Array = main._map.walking_path(main._party.cell, site_rect.get_center())
	var near_cell: Vector2i = path[maxi(0, path.size() - main.QUEST_NEAR_STEPS + 2)]
	main._party.place(main._map, near_cell)
	main._notice_quest_sites(near_cell)
	check("...and goes on it once the party is close", main._map.marks.get("quests_near", {}).has("left_behind"), [path.size(), near_cell])
	# A floor that lost only its note of the site (owner's save, 2026-11-24)
	# gets the note back from where the events lie, unchanged.
	var kept_site: Rect2i = main._map.marks["sites"]["left_behind"]
	main._map.packages.clear()
	main._map.marks["sites"] = {}
	main._map.marks.erase("quests")
	check("a floor that lost its site record isn't counted missing", not main._missing_quest_site(main._map, 1))
	check("...its record comes back from the events, the same", main._map.marks["sites"].get("left_behind") == kept_site and main._map.marks["quests"].get("left_behind") == kept_site, [main._map.marks["sites"], kept_site])
	var broken = main._map
	for c in broken.events.keys():
		if broken.events[c] in left_behind.events:
			broken.events.erase(c)
	check("a floor missing the site's events is noticed", main._missing_quest_site(broken, 1))
	check("...and F3 says so", main._quest_site_report().contains("left_behind MISSING"), main._quest_site_report())
	main._go_to_floor(2, main.Arrival.FROM_ABOVE)
	main._go_to_floor(1, main.Arrival.FROM_BELOW)
	check("...and going back in rebuilds it whole", not main._missing_quest_site(main._map, 1) and main._map != broken)
	# Continuing a save on such a floor rebuilds it from the way in.
	main._save_now()
	var data: Dictionary = main.SaveGame.read()
	for pair in data["floors"]:
		if pair[0] == 1:
			var events: Dictionary = main.SaveGame.unpack_value(pair[1]["events"])
			for c in events.keys():
				if events[c] in left_behind.events:
					events.erase(c)
			pair[1]["events"] = main.SaveGame.pack_value(events)
	data["depth"] = 1
	data["at_camp"] = false
	data["resume"] = false
	main._restore(data)
	await process_frame
	check("continuing on a floor without its site rebuilds it", not main._missing_quest_site(main._map, 1) and main._party.cell == main._map.find_content(main.DungeonMap.Content.STAIRS_UP))
	print("fails=", fails)
	quit()

