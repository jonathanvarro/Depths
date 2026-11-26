shader_type spatial;
render_mode depth_prepass_alpha, diffuse_burley, specular_schlick_ggx;
uniform int surface_kind=2;
uniform float opacity : hint_range(0.0,1.0)=1.0;
void fragment(){
    ALBEDO=COLOR.rgb;
    ROUGHNESS=.65;
    SPECULAR=.22;
    // Retain the earlier rat's tiny threatening red eye marks. This does
    // not illuminate the cave, alter caller visibility or add a light.
    if(COLOR.r>COLOR.g*2.5 && COLOR.r>.20) EMISSION=vec3(.26,.009,.003);
    ALPHA=opacity;
}
