shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float phase = 0.0;
uniform float strength = 0.17;
uniform vec4 tint : source_color = vec4(0.92, 0.45, 0.13, 1.0);
void fragment() {
    float radius = length((UV - 0.5) * 2.0);
    float falloff = pow(max(0.0, 1.0 - radius), 2.0);
    float pulse = 0.96 + 0.025*sin(phase*1.4) + 0.015*sin(phase*2.1);
    COLOR = vec4(tint.rgb, falloff * strength * pulse);
}
