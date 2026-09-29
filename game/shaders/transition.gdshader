shader_type canvas_item;
// Storybook transitions. progress 0 = clear, 1 = fully covered.
// mode 0: puffy clouds sweep in (travel between places)   mode 1: a magical page turn (menus)

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int mode = 0;
uniform vec4 cloud_a : source_color = vec4(1.0, 0.97, 0.99, 1.0);
uniform vec4 cloud_b : source_color = vec4(0.99, 0.80, 0.92, 1.0);
uniform vec4 paper : source_color = vec4(1.0, 0.96, 0.86, 1.0);
uniform float aspect = 1.7778;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + 11.7;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	vec2 p = vec2(uv.x * aspect, uv.y);
	vec4 col = vec4(0.0);
	if (mode == 0) {
		float n = fbm(p * 2.6 + vec2(TIME * 0.05, 0.0));
		float bubbles = fbm(p * 5.0 - vec2(0.0, TIME * 0.03));
		float field = mix(n, bubbles, 0.35);
		// coverage grows radially from the screen centre so the middle closes last -> feels like flying through clouds
		float radial = distance(uv, vec2(0.5)) * 0.9;
		float t = progress * 1.55 - 0.25;
		float cover = smoothstep(field * 0.85 + radial * 0.5 - 0.1, field * 0.85 + radial * 0.5 + 0.12, t);
		float shade = fbm(p * 3.4 + 3.1 + vec2(0.0, -0.15));
		vec3 c = mix(cloud_b.rgb, cloud_a.rgb, smoothstep(0.25, 0.75, shade + (1.0 - uv.y) * 0.2));
		// twinkles inside the clouds
		float tw = step(0.985, hash(floor(p * 60.0))) * (0.5 + 0.5 * sin(TIME * 8.0 + hash(floor(p * 60.0)) * 20.0));
		c += vec3(1.0, 0.95, 0.7) * tw * cover * 0.7;
		col = vec4(c, cover);
	} else {
		float curl = 1.0 - progress * 1.25;              // page edge moves right -> left
		float wob = sin(uv.y * 5.0 + 1.0) * 0.015 + sin(uv.y * 13.0) * 0.004;
		float edge = curl + wob;
		float cover = smoothstep(edge - 0.004, edge + 0.004, uv.x);
		float d = uv.x - edge;                            // distance behind the edge
		float shade = 1.0 - smoothstep(0.0, 0.32, d) * 0.06;
		float lip = smoothstep(0.0, 0.07, d) * (1.0 - smoothstep(0.07, 0.11, d));
		vec3 c = paper.rgb * shade + vec3(1.0, 1.0, 0.95) * lip * 0.25;
		// paper grain + gold dust along the edge
		c -= (fbm(p * 40.0) - 0.5) * 0.035;
		float dust = step(0.992, hash(floor(vec2(uv.x * 90.0, uv.y * 50.0 + TIME * 4.0)))) * (1.0 - smoothstep(0.0, 0.2, abs(d)));
		c += vec3(1.0, 0.85, 0.4) * dust;
		// soft shadow cast on the page underneath (in front of the edge)
		float sh = smoothstep(0.0, 0.10, -d) * 0.0 + (1.0 - smoothstep(0.0, 0.10, -d)) * step(d, 0.0) * 0.25;
		col = vec4(mix(vec3(0.0), c, cover), max(cover, sh * 0.7));
		col.rgb = mix(vec3(0.15, 0.05, 0.2), c, cover);
	}
	COLOR = col;
}
