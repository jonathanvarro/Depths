shader_type canvas_item;
render_mode unshaded;
uniform float phase = 0.0;
void fragment() {
    vec2 uv = UV;
    uv.x += sin(uv.y * 11.0 + phase * 2.2) * 0.012 * (1.0 - uv.y);
    vec4 flame = texture(TEXTURE, uv);
    flame.a *= 0.96 + 0.025 * sin(phase * 2.7);
    COLOR = flame;
}
