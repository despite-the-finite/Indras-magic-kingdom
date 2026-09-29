shader_type sky;
// Painterly storybook sky: gradient, soft toon clouds, sun / moon glow, twinkling stars.

uniform vec4 top_color : source_color = vec4(0.42, 0.62, 0.95, 1.0);
uniform vec4 mid_color : source_color = vec4(0.62, 0.78, 0.98, 1.0);
uniform vec4 horizon_color : source_color = vec4(1.0, 0.86, 0.92, 1.0);
uniform vec4 ground_color : source_color = vec4(0.75, 0.70, 0.90, 1.0);

uniform vec3 sun_dir = vec3(0.45, 0.42, -0.78);
uniform vec4 sun_color : source_color = vec4(1.0, 0.93, 0.7, 1.0);
uniform float sun_size = 0.05;
uniform float sun_glow = 0.55;

uniform float cloud_cover : hint_range(0.0, 1.0) = 0.55;
uniform vec4 cloud_light : source_color = vec4(1.0, 0.98, 0.98, 1.0);
uniform vec4 cloud_shadow : source_color = vec4(0.86, 0.80, 0.97, 1.0);
uniform float cloud_speed = 0.006;

uniform float star_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 moon_dir = vec3(-0.35, 0.5, -0.8);
uniform vec4 moon_color : source_color = vec4(1.0, 0.98, 0.85, 1.0);
uniform float moon_amount : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x), mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.02 + 7.3;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	vec3 col;
	if (h >= 0.0) {
		col = mix(horizon_color.rgb, mid_color.rgb, smoothstep(0.0, 0.22, h));
		col = mix(col, top_color.rgb, smoothstep(0.18, 0.9, h));
	} else {
		col = mix(horizon_color.rgb, ground_color.rgb, smoothstep(0.0, -0.3, h));
	}

	// stars
	if (star_amount > 0.0 && h > -0.05) {
		vec3 sp = d * 60.0;
		vec3 cell = floor(sp);
		float r = hash31(cell);
		float tw = 0.6 + 0.4 * sin(TIME * (1.0 + r * 3.0) + r * 60.0);
		float star = smoothstep(0.32, 0.0, length(fract(sp) - 0.5)) * step(0.955, r) * tw;
		col += vec3(1.0, 0.96, 0.85) * star * star_amount * smoothstep(0.0, 0.25, h);
	}

	// sun & moon
	vec3 sd = normalize(sun_dir);
	float sdot = dot(d, sd);
	float sang = acos(clamp(sdot, -1.0, 1.0));
	float sdisc = 1.0 - smoothstep(sun_size * 0.85, sun_size, sang);
	float sglow = pow(max(sdot, 0.0), 14.0) * sun_glow + pow(max(sdot, 0.0), 90.0) * 0.6;
	col += sun_color.rgb * (sdisc + sglow) * (1.0 - moon_amount);

	if (moon_amount > 0.0) {
		vec3 md = normalize(moon_dir);
		float mdot = dot(d, md);
		float mang = acos(clamp(mdot, -1.0, 1.0));
		float mdisc = 1.0 - smoothstep(0.075, 0.085, mang);
		float mglow = pow(max(mdot, 0.0), 22.0) * 0.55 + pow(max(mdot, 0.0), 160.0) * 0.6;
		// soft craters
		float cr = 0.9 + 0.1 * vnoise((d.xz - md.xz) * 90.0);
		col += moon_color.rgb * (mdisc * cr + mglow) * moon_amount;
	}

	// clouds (skipped for the ambient cubemap pass: cheaper + stable ambient light)
	if (!AT_CUBEMAP_PASS && h > 0.0) {
		vec2 uv = d.xz / (h + 0.16) * 0.85 + vec2(TIME * cloud_speed, 0.0);
		float n = fbm(uv * 1.5);
		float thr = 1.0 - cloud_cover * 0.7;
		float c = smoothstep(thr, thr + 0.11, n);
		float n2 = fbm(uv * 1.5 + sd.xz * 0.07);
		float lit = clamp((n - n2) * 5.0 + 0.55, 0.0, 1.0);
		vec3 cc = mix(cloud_shadow.rgb, cloud_light.rgb, lit);
		cc = mix(cc, mix(horizon_color.rgb, cc, 0.6), smoothstep(0.35, 0.0, h));
		c *= smoothstep(0.0, 0.14, h);
		col = mix(col, cc, c * 0.92);
	}
	COLOR = col;
}
