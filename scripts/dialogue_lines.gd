class_name DialogueLines
extends Resource
## What a hero might say, by situation (#57). One line is picked at random
## (avoiding the last one said). Write lines in `data/dialogue/*.tres`;
## add situations freely - the game asks for them by name.
##
## Situations used so far: wake, bodies, bleeding, find_exit, lost, web,
## fight_start, fight_won, hurt, panic, dark, daylight.

@export var lines: Dictionary[String, PackedStringArray] = {}


func pick(situation: String, avoid := "") -> String:
	var options: PackedStringArray = lines.get(situation, PackedStringArray())
	if options.is_empty():
		return ""
	if options.size() > 1 and avoid in options:
		var others := Array(options).filter(func(l): return l != avoid)
		return others.pick_random()
	return options[randi() % options.size()]
