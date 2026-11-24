extends Node3D
## Anonymous, static floor prop. Search/recovery and collision stay with Main.
const Materials := preload("res://art/materials/worked-props-v2/materials.gd")

func _ready() -> void:
	var shared := Materials.make()
	var skin := StandardMaterial3D.new()
	skin.vertex_color_use_as_albedo = true
	skin.roughness = 1.0
	shared["Skin"] = skin
	Materials.apply(self, shared)
