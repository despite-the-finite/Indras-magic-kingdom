shader_type spatial;
// Inverted-hull outline used as `next_pass` on characters. Soft plum colour rather than black = storybook, not comic.
render_mode cull_front, unshaded, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.36, 0.16, 0.42, 1.0);
uniform float thickness = 0.012;

void vertex() {
	vec4 vp = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 vn = normalize((MODELVIEW_NORMAL_MATRIX * NORMAL));
	vp.xyz += vn * thickness * clamp(-vp.z * 0.16, 0.6, 3.0);
	POSITION = PROJECTION_MATRIX * vp;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
