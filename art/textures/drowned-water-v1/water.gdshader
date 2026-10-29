shader_type spatial;
// Two low-frequency samples of one opaque tile. No refraction, screen/depth
// textures, normal maps, dynamic lights or transparent sorting pass.
uniform sampler2D surface_texture : source_color, repeat_enable, filter_nearest;
uniform bool motion_enabled = true;
uniform float tile_meters = 2.0;
varying vec2 world_uv;
void vertex() {
 world_uv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz / tile_meters;
}
void fragment() {
 float t = motion_enabled ? TIME : 0.0;
 vec3 a = texture(surface_texture, world_uv + vec2(t * 0.003, t * 0.0015)).rgb;
 vec3 b = texture(surface_texture, world_uv + vec2(0.37 - t * 0.002, 0.51 + t * 0.002)).rgb;
 ALBEDO = mix(a, b, 0.22);
 ROUGHNESS = 0.2;
 METALLIC = 0.0;
 SPECULAR = 0.3;
}
