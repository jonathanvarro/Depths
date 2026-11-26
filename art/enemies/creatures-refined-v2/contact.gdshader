shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled;
uniform float strength=.13;
void fragment(){float r=length((UV-.5)*2.0);ALBEDO=vec3(.015,.012,.01);ALPHA=pow(max(0.0,1.0-r),2.0)*strength;}
