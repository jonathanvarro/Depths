shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform float opacity : hint_range(0.0,1.0) = 1.0;
varying vec3 skin_position;
void vertex(){skin_position=VERTEX;}
void fragment(){
    float fine=sin(skin_position.x*121.0+skin_position.z*143.0)*.018;
    ALBEDO=COLOR.rgb*(1.0+fine);
    ROUGHNESS=.82;SPECULAR=.18;
    BACKLIGHT=COLOR.rgb*.13;
    ALPHA=opacity;
}
