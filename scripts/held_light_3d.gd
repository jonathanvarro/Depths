extends Node3D
## The torch and lantern the party holds up while exploring, as small 3D
## models (owner request, 2026-10-20), replacing the flat held-light art.
## Built from simple shapes and small pixel textures, rendered by
## held_light_view.gd into a low-resolution view so they share the game's
## chunky pixel look and never clip into walls. Presentation only: the
## Supplies model owns fuel, time and light.

const TEX := "res://art/props/held-3d-v1/"
const FLAME_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform float intensity = 1.0;
uniform float seed = 0.0;
uniform float lean = 0.0;
uniform vec3 hot : source_color = vec3(1.0, 0.94, 0.62);
uniform vec3 warm : source_color = vec3(1.0, 0.56, 0.14);
uniform vec3 cool : source_color = vec3(0.78, 0.2, 0.05);

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float y = 1.0 - UV.y;  // 0 at the base, 1 at the tip
	float t = TIME * 3.2 + seed;
	float sway = (noise(vec2(y * 3.0, t)) - 0.5) * 0.32 * y + lean * y * y;
	float x = UV.x - 0.5 - sway;
	// A teardrop: a round belly low down, drawn to a flickering tip.
	float width = 0.62 * sqrt(y) * pow(1.0 - y, 1.25) * (0.85 + 0.3 * noise(vec2(t * 1.4, y * 5.0)));
	float n = noise(vec2(UV.x * 7.0, y * 5.0 - t * 2.2));
	float shape = 1.0 - smoothstep(width * 0.55, width, abs(x));
	shape *= 1.0 - smoothstep(0.66 + 0.3 * n, 1.0, y);
	float heat = shape * (1.05 - y * 0.85) * (0.75 + 0.5 * n);
	heat = floor(heat * 5.0) / 5.0;  // stepped bands, like painted pixel flames
	vec3 col = heat > 0.62 ? hot : (heat > 0.36 ? warm : cool);
	ALBEDO = col * intensity;
	ALPHA = step(0.18, heat) * clamp(intensity, 0.0, 1.0);
}
"""

var kind := "torch"  # "torch" or "lantern"
var _flames: Array[MeshInstance3D] = []
var _flame_root: Node3D
var _light: OmniLight3D
var _sparks: CPUParticles3D
var _glass: StandardMaterial3D
var _strength := 1.0  # 0 unlit .. 1 full
var _flicker_clock := 0.0


func build(which: String) -> void:
	kind = which
	if kind == "torch":
		_build_torch()
	else:
		_build_lantern()


## How strongly it burns: 1 full, 0.6 low, 0 out.
func set_strength(value: float) -> void:
	_strength = value
	if _flame_root:
		_flame_root.visible = value > 0.0
		_flame_root.scale = Vector3.ONE * lerpf(0.45, 1.0, clampf(value, 0.0, 1.0))
	for flame in _flames:
		(flame.material_override as ShaderMaterial).set_shader_parameter("intensity", clampf(0.55 + 0.45 * value, 0.0, 1.0))
	if _sparks:
		_sparks.emitting = value > 0.5
	if _glass:
		_glass.emission = Color(1.0, 0.62, 0.25) * (0.08 + 0.3 * value) if value > 0.0 else Color(0.03, 0.025, 0.02)


## Lean the flames against motion (positive leans left on screen).
func set_lean(value: float) -> void:
	for flame in _flames:
		(flame.material_override as ShaderMaterial).set_shader_parameter("lean", value)


func _process(delta: float) -> void:
	if _light == null:
		return
	_flicker_clock += delta
	var flicker := 0.85 + 0.15 * sin(_flicker_clock * 17.0) * sin(_flicker_clock * 5.3) + randf_range(-0.05, 0.05)
	_light.light_energy = (2.2 if kind == "torch" else 1.6) * _strength * flicker


# --- Torch ------------------------------------------------------------------

func _build_torch() -> void:
	var wood := _material("wood.png")
	var cloth := _material("cloth.png")
	var leather := _material("leather.png")
	# Shaft: a little thicker at the hand, faceted like the cave's low-poly world.
	_part(_cylinder(0.0105, 0.0135, 0.44), wood, Vector3(0, -0.13, 0))
	_part(_cylinder(0.0152, 0.0152, 0.07), leather, Vector3(0, -0.22, 0))  # grip binding
	_part(_cylinder(0.0158, 0.0158, 0.012), leather, Vector3(0, -0.18, 0))
	# The head: pitch-soaked rag wound in three uneven turns, charred on top.
	_part(_cylinder(0.026, 0.021, 0.035), cloth, Vector3(0, 0.095, 0), Vector3(0, 0.3, 0))
	_part(_cylinder(0.031, 0.027, 0.04), cloth, Vector3(0.002, 0.13, 0), Vector3(0, 1.1, 0.06))
	_part(_cylinder(0.021, 0.03, 0.032), cloth, Vector3(0, 0.165, 0), Vector3(0, 2.0, -0.05))
	_add_flame(Vector3(0, 0.255, 0.004), Vector2(0.11, 0.19), 0.0)
	_add_flame(Vector3(0.006, 0.235, 0.012), Vector2(0.06, 0.11), 3.7)  # a brighter inner tongue
	_add_light(Vector3(0, 0.23, 0.05), 0.55, Color(1.0, 0.62, 0.28))
	_sparks = CPUParticles3D.new()
	_sparks.amount = 7
	_sparks.lifetime = 0.9
	_sparks.local_coords = false
	_sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_sparks.emission_sphere_radius = 0.02
	_sparks.direction = Vector3.UP
	_sparks.spread = 25.0
	_sparks.initial_velocity_min = 0.08
	_sparks.initial_velocity_max = 0.2
	_sparks.gravity = Vector3(0, 0.04, 0)
	_sparks.scale_amount_min = 0.6
	_sparks.scale_amount_max = 1.0
	var spark_mesh := QuadMesh.new()
	spark_mesh.size = Vector2(0.007, 0.007)
	var spark_material := StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_material.albedo_color = Color(1.0, 0.6, 0.2)
	spark_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	spark_mesh.material = spark_material
	_sparks.mesh = spark_mesh
	_sparks.position = Vector3(0, 0.22, 0)
	_flame_root.add_child(_sparks)


# --- Lantern -----------------------------------------------------------------

func _build_lantern() -> void:
	var brass := _material("brass.png", 0.2, 0.55)
	brass.albedo_color = Color(1.35, 1.15, 0.85)  # aged brass catching the light
	var iron := _material("iron.png", 0.4, 0.7)
	_part(_cylinder(0.058, 0.058, 0.018), brass, Vector3(0, -0.15, 0))  # foot
	_part(_cylinder(0.05, 0.058, 0.05), brass, Vector3(0, -0.116, 0))  # oil font
	_part(_cylinder(0.042, 0.046, 0.012), brass, Vector3(0, -0.085, 0))  # collar
	_part(_cylinder(0.006, 0.006, 0.02), iron, Vector3(0.05, -0.1, 0.0), Vector3(0, 0, PI / 2))  # wick key
	# The glass chimney, glowing with the flame inside.
	_glass = StandardMaterial3D.new()
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.albedo_color = Color(0.95, 0.88, 0.7, 0.1)
	_glass.roughness = 0.15
	_glass.emission_enabled = true
	_glass.emission = Color(1.0, 0.68, 0.3)
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var globe := _cylinder(0.036, 0.042, 0.1)
	globe.radial_segments = 10
	_part(globe, _glass, Vector3(0, -0.03, 0))
	# A wire guard: four bars and two hoops.
	for i in 4:
		var angle := PI / 4 + i * PI / 2
		var bar := BoxMesh.new()
		bar.size = Vector3(0.005, 0.108, 0.005)
		_part(bar, iron, Vector3(cos(angle) * 0.048, -0.03, sin(angle) * 0.048))
	for y in [-0.065, 0.005]:
		var hoop := TorusMesh.new()
		hoop.inner_radius = 0.045
		hoop.outer_radius = 0.051
		hoop.rings = 12
		hoop.ring_segments = 4
		_part(hoop, iron, Vector3(0, y, 0))
	# The hood, chimney and bail handle.
	_part(_cylinder(0.046, 0.046, 0.014), brass, Vector3(0, 0.026, 0))
	_part(_cylinder(0.013, 0.047, 0.045), brass, Vector3(0, 0.055, 0))
	_part(_cylinder(0.013, 0.013, 0.022), iron, Vector3(0, 0.087, 0))
	_part(_cylinder(0.021, 0.021, 0.006), brass, Vector3(0, 0.1, 0))
	var bail_radius := 0.062
	for i in 9:  # a semicircle of short wire segments
		var a0 := PI * i / 9.0
		var a1 := PI * (i + 1) / 9.0
		var mid := (a0 + a1) / 2.0
		var segment := BoxMesh.new()
		segment.size = Vector3(0.006, bail_radius * (a1 - a0) * 1.15, 0.006)
		_part(segment, iron, Vector3(cos(mid) * bail_radius, 0.035 + sin(mid) * bail_radius, 0), Vector3(0, 0, mid))
	_add_flame(Vector3(0, -0.045, 0.0), Vector2(0.034, 0.062), 1.3)
	_add_light(Vector3(0, -0.04, 0.03), 0.5, Color(1.0, 0.72, 0.38))


# --- Helpers -------------------------------------------------------------------

func _material(texture: String, metallic := 0.0, roughness := 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(TEX + texture)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.metallic = metallic
	material.roughness = roughness
	return material


func _cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	return mesh


func _part(mesh: Mesh, material: Material, at: Vector3, turn := Vector3.ZERO) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = at
	part.rotation = turn
	add_child(part)
	return part


func _add_flame(at: Vector3, size: Vector2, seed_value: float) -> void:
	if _flame_root == null:
		_flame_root = Node3D.new()
		_flame_root.position = Vector3(at.x, at.y - size.y * 0.45, at.z)
		add_child(_flame_root)
	var quad := QuadMesh.new()
	quad.size = size
	var shader := Shader.new()
	shader.code = FLAME_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("seed", seed_value)
	var flame := MeshInstance3D.new()
	flame.mesh = quad
	flame.material_override = material
	flame.position = at - _flame_root.position
	_flame_root.add_child(flame)
	_flames.append(flame)


func _add_light(at: Vector3, reach: float, color: Color) -> void:
	_light = OmniLight3D.new()
	_light.position = at
	_light.omni_range = reach
	_light.light_color = color
	_light.omni_attenuation = 1.4
	add_child(_light)
