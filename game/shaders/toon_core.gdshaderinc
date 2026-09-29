
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 albedo_top : source_color = vec4(1.0);
uniform float gradient_amount : hint_range(0.0, 1.0) = 0.0;
uniform float gradient_min = 0.0;
uniform float gradient_max = 1.0;
uniform bool use_vertex_color = false;
uniform bool double_sided = false;

uniform vec4 shade_tint : source_color = vec4(0.70, 0.58, 0.95, 1.0);
uniform float shade_strength : hint_range(0.0, 1.0) = 0.55;
uniform float shade_softness : hint_range(0.01, 0.8) = 0.22;

uniform vec4 rim_color : source_color = vec4(1.0, 0.86, 0.95, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform float rim_amount : hint_range(0.0, 2.0) = 0.22;

uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 8.0) = 0.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed = 2.2;

uniform float wind : hint_range(0.0, 1.5) = 0.0;
uniform float wind_speed = 1.4;
uniform float sway_height = 1.0;

uniform float glitter : hint_range(0.0, 1.0) = 0.0;

varying float v_h;
varying vec3 v_wpos;

void vertex() {
	v_h = VERTEX.y;
	if (wind > 0.0) {
		float h = clamp(VERTEX.y / sway_height, 0.0, 1.6);
		float ph = TIME * wind_speed + MODEL_MATRIX[3].x * 0.7 + MODEL_MATRIX[3].z * 0.35;
		float w = h * h * wind;
		VERTEX.x += sin(ph + VERTEX.y * 1.3) * w;
		VERTEX.z += cos(ph * 0.8 + VERTEX.y) * w * 0.5;
	}
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float g = smoothstep(gradient_min, gradient_max, v_h);
	vec3 base = mix(albedo.rgb, albedo_top.rgb, g * gradient_amount);
	if (use_vertex_color) {
		base *= COLOR.rgb;
	}
	ALBEDO = base;
	ROUGHNESS = 1.0;
	vec3 n = NORMAL;
	if (double_sided && !FRONT_FACING) {
		n = -n;
	}
	// rim only on true silhouettes (a ground plane seen at a grazing angle must not glow)
	float rim = pow(smoothstep(0.55, 1.0, 1.0 - clamp(dot(n, VIEW), 0.0, 1.0)), rim_power * 0.6) * (1.0 - smoothstep(0.0, 0.5, abs(n.y) * 0.0));
	float pl = 1.0 + pulse * 0.35 * sin(TIME * pulse_speed + v_wpos.x * 0.5);
	vec3 em = emission_color.rgb * emission_energy * pl;
	em += rim_color.rgb * rim * rim_amount;
	if (glitter > 0.0) {
		vec2 c = floor(v_wpos.xy * 38.0 + v_wpos.z * 11.0);
		float h = fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
		float tw = step(0.965, h) * (0.5 + 0.5 * sin(TIME * 5.0 + h * 40.0));
		em += vec3(1.0, 0.95, 0.85) * tw * glitter;
	}
	EMISSION = em;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(-shade_softness * 0.6, shade_softness, ndl);
	float lit = band * ATTENUATION;
	vec3 shade = mix(vec3(1.0), shade_tint.rgb, shade_strength);
	vec3 lc = LIGHT_COLOR / PI;
	DIFFUSE_LIGHT += lc * lit + lc * shade * (1.0 - lit) * 0.18;
}
