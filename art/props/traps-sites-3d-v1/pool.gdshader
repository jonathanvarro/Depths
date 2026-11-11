shader_type spatial;
render_mode shadows_disabled;
uniform sampler2D water_texture : source_color,filter_nearest,repeat_enable;
uniform float phase=0.0;
uniform bool disturbed=false;
varying vec3 world;
varying vec3 local_point;
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; local_point=VERTEX; }
void fragment() {
    vec3 tex=texture(water_texture,world.xz*1.7+vec2(phase*.004,0.0)).rgb;
    float ripple=sin(length(local_point.xz)*54.0-phase*.8)*.5+.5;
    ALBEDO=mix(vec3(.10,.17,.17),tex,.21)+(disturbed?ripple*.026:0.0);
    ROUGHNESS=.76;
    SPECULAR=.20;
}
