class_name EnvironmentTheme
extends Resource
## How one environment (cave, stone dungeon, crypt...) looks and talks.
##
## Game logic only knows what a feature *does*: a closed passage, a blocked
## passage, a way down, a way up. A theme decides what each one *is* in this
## place: a web or a wooden door, a pit or a staircase. Themes live in
## `themes/` and are picked on the Main node.
##
## Every feature has a placeholder shape tinted with its colour. Assign a
## scene to replace the placeholder with real art; the scene's origin is the
## cell centre on the floor, facing -Z (along the passage).

@export var display_name := "Unnamed environment"

@export_group("Surfaces")
@export var wall_material: Material
## Used on roughly one wall in five for variety (optional).
@export var wall_variant_material: Material
@export var floor_material: Material
@export var ceiling_material: Material

@export_group("Closed passage")
## Opens when the party steps into it (door, web, curtain of roots...).
@export var closed_name := "Door"
@export var closed_open_message := "The door opens."
@export var closed_color := Color("6b4a2f")
@export var closed_scene: PackedScene
## Shown after opening (optional; nothing is shown if empty).
@export var opened_scene: PackedScene
## Broken remains for marked fortress gates; ordinary doors use opened_scene.
@export var gate_opened_scene: PackedScene

@export_group("Blocked passage")
## Cannot be passed yet (locked door, rubble, thick roots...).
@export var blocked_name := "Locked door"
@export var blocked_message := "It won't open."
@export var blocked_color := Color("3d3d3d")
@export var blocked_scene: PackedScene

@export_group("Way down")
@export var descent_name := "Stairs down"
@export var descent_prompt := "Descend the stairs?"
@export var descent_color := Color("050505")
@export var descent_scene: PackedScene

@export_group("Way up")
@export var ascent_name := "Stairs up"
@export var ascent_prompt := "Climb back up?"
## Shown on the first floor, where the way up leads out of the site.
@export var exit_message := "The way out."
@export var ascent_color := Color("8a7b5c")
@export var ascent_scene: PackedScene

@export_group("Sound")
## Loops for as long as the party is in this environment.
@export var ambience: AudioStream
## One is picked at random for each step, with slight pitch variation.
@export var footstep_sounds: Array[AudioStream] = []
## Walking into a wall or blocked passage.
@export var bump_sound: AudioStream
## Opening a closed passage (tearing a web, creaking a door...).
@export var open_sound: AudioStream
