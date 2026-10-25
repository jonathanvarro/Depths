extends SceneTree
## Writes the mini-boss lairs (#145, owner 2026-10-25) into data/packages:
## a Broodmother nest on floors 2-3 and a gate captain's post on 3-4, each
## an optional side room with a warning at its threshold. Rerun to rebuild:
## Godot --headless --path . --script tools/story/build_lairs.gd

func _e(id: String) -> EnemyType:
	return load("res://data/enemies/%s.tres" % id)


func _lair(id: String, fields: Dictionary) -> void:
	var p := QuestPackage.new()
	p.id = id
	p.rows = PackedStringArray(["#######", "#,,,,,#", "#,,E,,#", "#,,,,,#", "###.###"])
	for key in fields:
		if key in ["fight", "full_party_extra"]:
			p.get(key).assign(fields[key])
		else:
			p.set(key, fields[key])
	var path := "res://data/packages/%s.tres" % id
	print(path, " ", "ok" if ResourceSaver.save(p, path) == OK else "FAILED")


func _initialize() -> void:
	_lair("lair_brood", {
		"lair": "brood", "min_depth": 2, "max_depth": 3,
		"warning": "Thick webbing chokes the way ahead, and something large clicks in the dark beyond. A Broodmother's nest. Go in?",
		# She calls her two hatchlings whatever the party's size.
		"fight": [_e("broodmother")], "full_party_extra": [_e("spider")],
	})
	_lair("lair_captain", {
		"lair": "captain", "min_depth": 3, "max_depth": 4,
		"warning": "A goblin barricade, a horn hung on a spike, and a captain's growl behind it. A gate captain's post. Go in?",
		"fight": [_e("gate_captain"), _e("goblin")], "full_party_extra": [_e("goblin_archer")],
	})
	quit()
