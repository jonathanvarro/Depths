shader_type canvas_item;
render_mode unshaded;
uniform float phase = 0.0;
void fragment() {
    vec2 uv = UV;
    uv.x = fract(uv.x * 1.15 + phase * 0.003);
    vec4 bank = texture(TEXTURE, uv);
    float edge = smoothstep(0.0,0.18,UV.x) * (1.0-smoothstep(0.82,1.0,UV.x));
    float vertical = smoothstep(0.0,0.22,UV.y) * (1.0-smoothstep(0.68,1.0,UV.y));
    COLOR = vec4(0.38,0.43,0.46,bank.a * edge * vertical * 0.12);
}
