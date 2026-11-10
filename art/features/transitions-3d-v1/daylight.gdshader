shader_type spatial;
render_mode unshaded,shadows_disabled;
varying float height;
void vertex() { height=VERTEX.y; }
void fragment() {
    ALBEDO=mix(vec3(.40,.47,.43),vec3(.69,.77,.75),smoothstep(.15,2.3,height));
}
