shader_type spatial;
// Glowing rainbow ribbon. UV.y across the ribbon width, UV.x along it. `reveal` grows it along its length.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float intensity = 1.25;
uniform float fade_ends = 0.08;
uniform float shimmer = 1.0;
uniform float alpha = 0.95;

vec3 band(float t) {
	// red orange yellow green blue indigo violet (softened, pastel)
	vec3 c0 = vec3(1.00, 0.45, 0.55);
	vec3 c1 = vec3(1.00, 0.68, 0.42);
	vec3 c2 = vec3(1.00, 0.93, 0.50);
	vec3 c3 = vec3(0.55, 0.95, 0.60);
	vec3 c4 = vec3(0.45, 0.80, 1.00);
	vec3 c5 = vec3(0.60, 0.55, 1.00);
	vec3 c6 = vec3(0.85, 0.55, 1.00);
	float x = clamp(t, 0.0, 1.0) * 6.0;
	if (x < 1.0) return mix(c0, c1, x);
	if (x < 2.0) return mix(c1, c2, x - 1.0);
	if (x < 3.0) return mix(c2, c3, x - 2.0);
	if (x < 4.0) return mix(c3, c4, x - 3.0);
	if (x < 5.0) return mix(c4, c5, x - 4.0);
	return mix(c5, c6, x - 5.0);
}

void fragment() {
	float across = UV.y;
	float edge = smoothstep(0.0, 0.16, across) * smoothstep(1.0, 0.84, across);
	float along = smoothstep(0.0, fade_ends, UV.x) * smoothstep(1.0, 1.0 - fade_ends, UV.x);
	float grow = 1.0 - smoothstep(reveal - 0.06, reveal, UV.x);
	vec3 c = band(across) * intensity;
	float tw = 1.0 + shimmer * 0.25 * sin(TIME * 4.0 + UV.x * 30.0);
	ALBEDO = c * tw;
	ALPHA = edge * along * grow * alpha;
}
