shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled;
uniform sampler2D fog_texture : source_color,filter_linear,repeat_enable;
uniform float phase=0.0;
uniform float layer_offset=0.0;
uniform float opacity=.32;
uniform float light_strength=1.0;
uniform vec3 centre=vec3(0.0);
uniform vec3 mist_colour : source_color=vec3(.36,.42,.40);
varying vec3 world;
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
    vec2 flow=vec2(phase*.009+layer_offset,phase*.003);
    vec4 a=texture(fog_texture,world.xz*vec2(.19,.31)+flow);
    vec4 b=texture(fog_texture,world.zx*vec2(.23,.27)-flow*.63);
    float ed=1.0-smoothstep(2.8,5.4,length(world.xz-centre.xz));
    float whorl=.6+.4*sin(world.x*.83+world.z*.69+phase*.15+layer_offset*8.0);
    ALBEDO=mist_colour*clamp(light_strength,.0,1.0);
    ALPHA=clamp((a.a+b.a)*4.0,.0,1.0)*whorl*ed*opacity*light_strength;
}
