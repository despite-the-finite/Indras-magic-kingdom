shader_type spatial;
// Stylised flowing water: gentle waves, foam bands, bank foam, sky fresnel and twinkling glints.
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.16, 0.56, 0.86, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.45, 0.88, 0.92, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 sky_color : source_color = vec4(0.85, 0.92, 1.0, 1.0);
uniform float flow_speed = 0.35;
uniform float wave_amp = 0.05;
uniform float flow_dir = 1.0;
uniform float glint_amount = 1.0;
uniform float alpha_base = 0.86;
uniform bool flow_along_z = true;

varying vec3 v_wpos;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += (sin(w.x * 1.7 + TIME * 1.6) + sin(w.x * 0.9 - TIME * 1.1 + w.z * 1.3)) * wave_amp * 0.5;
	v_wpos = w;
}

void fragment() {
	vec2 p = flow_along_z ? vec2(v_wpos.z, v_wpos.x) : v_wpos.xz;
	float t = TIME * flow_speed * flow_dir;
	// analytic wave slopes
	float dx = cos(p.x * 2.3 - t * 3.0) * 0.20 + cos(p.x * 4.1 + p.y * 2.0 - t * 4.4) * 0.10;
	float dz = cos(p.y * 3.0 + t * 1.4) * 0.12 + cos(p.x * 1.2 + p.y * 3.4 - t * 2.0) * 0.08;
	vec3 wn = normalize(vec3(-dx, 1.0, -dz));
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);

	float bank = abs(UV.x - 0.5) * 2.0;            // 0 centre .. 1 banks (UV.x runs across the river)
	vec3 col = mix(deep_color.rgb, shallow_color.rgb, smoothstep(0.15, 0.95, bank));
	// light bands drifting downstream
	float bands = sin(p.x * 3.2 - t * 6.0 + sin(p.y * 2.0) * 1.5) * 0.5 + 0.5;
	col += vec3(0.08, 0.12, 0.14) * smoothstep(0.7, 1.0, bands);
	// foam streaks + bank foam
	float streak = smoothstep(0.86, 1.0, sin(p.x * 5.5 - t * 8.0 + sin(p.y * 4.0 + t) * 1.2) * 0.5 + 0.5);
	float foam = max(streak * 0.35 * bank, smoothstep(0.86, 1.0, bank) * (0.6 + 0.4 * sin(p.x * 6.0 + TIME * 1.4)));
	col = mix(col, foam_color.rgb, clamp(foam, 0.0, 1.0));
	// sky fresnel
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	col = mix(col, sky_color.rgb, fres * 0.55);
	ALBEDO = col;
	ROUGHNESS = 0.12;
	SPECULAR = 0.7;
	// glints
	vec2 gc = floor(p * 9.0 + vec2(t * 3.0, 0.0));
	float gh = hash(gc);
	float tw = step(0.965, gh) * (0.5 + 0.5 * sin(TIME * 6.0 + gh * 50.0));
	EMISSION = vec3(1.0, 0.98, 0.9) * tw * glint_amount * 0.8;
	ALPHA = clamp(alpha_base + foam * 0.14, 0.0, 1.0);
}
