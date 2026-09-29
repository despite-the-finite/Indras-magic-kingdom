shader_type spatial;
// Procedural expressive face, drawn on a slightly enlarged sphere over the head (front = +Z in model space).
// No textures: every expression is a set of uniforms, so faces animate smoothly and cost nothing to author.
render_mode unshaded, blend_mix, depth_draw_never, cull_back;

uniform vec4 tint : source_color = vec4(1.0);          // scene tint (night scenes darken the face slightly)

// what to draw (a unicorn draws eyes on the head sphere and the mouth on a separate muzzle sphere)
uniform float show_eyes = 1.0;
uniform float show_mouth = 1.0;
uniform float show_nose = 1.0;
uniform float show_brows = 1.0;

// eyes
uniform vec4 eye_color : source_color = vec4(0.42, 0.25, 0.16, 1.0);
uniform float eye_size = 1.0;
uniform float eye_sep = 0.36;
uniform float eye_y = -0.06;
uniform vec2 eye_dim = vec2(0.20, 0.27);               // half width / half height in radians
uniform float blink : hint_range(0.0, 1.0) = 0.0;
uniform float happy : hint_range(0.0, 1.0) = 0.0;     // ^ ^ closed happy eyes
uniform vec2 look = vec2(0.0, 0.0);
uniform float lashes : hint_range(0.0, 1.0) = 1.0;
uniform float sparkle : hint_range(0.0, 1.0) = 0.0;   // extra shiny eyes (wonder / joy)
uniform float wet : hint_range(0.0, 1.0) = 0.0;       // watery eyes (hopeful / sad)

// brows
uniform vec4 brow_color : source_color = vec4(0.30, 0.18, 0.12, 1.0);
uniform float brow_raise : hint_range(-1.0, 1.0) = 0.0;
uniform float brow_tilt : hint_range(-1.0, 1.0) = 0.0;  // + = worried (inner ends up), - = determined

// mouth
uniform float mouth_y = -0.46;
uniform float mouth_w = 0.20;
uniform float smile : hint_range(-1.0, 1.0) = 0.5;
uniform float mouth_open : hint_range(0.0, 1.0) = 0.0;
uniform float mouth_round : hint_range(0.0, 1.0) = 0.0;
uniform vec4 mouth_color : source_color = vec4(0.62, 0.20, 0.28, 1.0);
uniform vec4 lip_color : source_color = vec4(0.72, 0.30, 0.34, 1.0);

// cheeks
uniform vec4 blush_color : source_color = vec4(1.0, 0.55, 0.65, 1.0);
uniform float blush : hint_range(0.0, 1.0) = 0.4;
uniform float freckles : hint_range(0.0, 1.0) = 0.0;
uniform vec4 nose_color : source_color = vec4(0.55, 0.30, 0.22, 1.0);
uniform float tears : hint_range(0.0, 1.0) = 0.0;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

float ell(vec2 p, vec2 c, vec2 r) {
	return length((p - c) / r);
}
float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}
vec4 over(vec4 dst, vec3 col, float a) {
	float oa = a + dst.a * (1.0 - a);
	vec3 oc = (col * a + dst.rgb * dst.a * (1.0 - a)) / max(oa, 0.0001);
	return vec4(oc, oa);
}

vec4 draw_eye(vec4 acc, vec2 p, float s) {
	vec2 c = vec2(s * eye_sep, eye_y);
	float open = max(1.0 - blink, 0.07);
	vec2 r = eye_dim * eye_size * vec2(1.0, open);
	float px = 0.006;

	// open iris
	float d = ell(p, c, r);
	float iris_a = (1.0 - smoothstep(1.0 - 0.05, 1.0, d)) * (1.0 - happy);
	if (iris_a > 0.0) {
		vec2 q = (p - c) / r;
		vec3 top = eye_color.rgb * 0.45;
		vec3 bot = mix(eye_color.rgb, vec3(1.0), 0.28);
		vec3 col = mix(bot, top, smoothstep(-0.6, 0.9, q.y));
		// dark limbal ring
		col = mix(col, eye_color.rgb * 0.30, smoothstep(0.72, 0.97, d));
		// pupil follows `look`
		vec2 pc = look * 0.28;
		float pd = length((q - pc) / vec2(0.47, 0.52));
		col = mix(col, vec3(0.05, 0.03, 0.07), 1.0 - smoothstep(0.9, 1.0, pd));
		// big highlight + small highlight (+ sparkle stars)
		float h1 = 1.0 - smoothstep(0.85, 1.0, length((q - vec2(-0.34, 0.42) - pc * 0.4) / vec2(0.26, 0.28)));
		float h2 = 1.0 - smoothstep(0.85, 1.0, length((q - vec2(0.36, -0.36) - pc * 0.3) / vec2(0.11, 0.12)));
		col = mix(col, vec3(1.0), max(h1, h2 * 0.9));
		float sp = sparkle * (1.0 - smoothstep(0.85, 1.0, length((q - vec2(0.05, 0.05)) / vec2(0.09, 0.09))));
		col = mix(col, vec3(1.0), sp);
		// wet lower rim
		col += vec3(0.5, 0.75, 1.0) * wet * smoothstep(-0.5, -0.95, q.y) * 0.5;
		// upper lash line
		float lid = smoothstep(0.55, 0.98, q.y) * smoothstep(0.86, 1.0, d) * 0.9;
		col = mix(col, vec3(0.10, 0.05, 0.12), lid);
		acc = over(acc, col, iris_a);
	}
	// closed happy arc
	if (happy > 0.0) {
		vec2 hp = p - (c + vec2(0.0, -r.y * 0.35));
		float arc = abs(length(hp / vec2(1.0, 0.85)) - eye_dim.x * eye_size * 0.85);
		float mask = step(0.0, hp.y + 0.01);
		float a = (1.0 - smoothstep(0.018, 0.028, arc)) * mask * happy;
		acc = over(acc, vec3(0.10, 0.05, 0.12), a);
	}
	// lash flick at the outer corner
	if (lashes > 0.4) {
		vec2 lc = c + vec2(s * r.x * 0.92, r.y * 0.62);
		float l = seg(p, lc, lc + vec2(s * 0.075, 0.055));
		float a = (1.0 - smoothstep(0.010, 0.018, l)) * lashes * (1.0 - blink * 0.5);
		acc = over(acc, vec3(0.10, 0.05, 0.12), a);
	}
	// brow
	if (show_brows > 0.5) {
		float by = eye_y + eye_dim.y * eye_size * 1.55 + brow_raise * 0.09;
		vec2 inner = vec2(s * (eye_sep - 0.16), by + brow_tilt * 0.06);
		vec2 outer = vec2(s * (eye_sep + 0.17), by - brow_tilt * 0.055 + 0.015);
		float bd = seg(p - vec2(0.0, sin((p.x - inner.x) * 8.0) * 0.006), inner, outer);
		float ba = 1.0 - smoothstep(0.014, 0.024, bd);
		acc = over(acc, brow_color.rgb, ba * 0.95);
	}
	// tear
	if (tears > 0.0) {
		vec2 tp = vec2(s * (eye_sep + 0.03), eye_y - eye_dim.y * eye_size * 1.15 - 0.06 * tears);
		float ta = (1.0 - smoothstep(0.85, 1.0, ell(p, tp, vec2(0.028, 0.05)))) * tears;
		acc = over(acc, vec3(0.65, 0.85, 1.0), ta * 0.9);
	}
	return acc;
}

void fragment() {
	vec3 n = normalize(lp);
	float lon = atan(n.x, n.z);
	float lat = asin(clamp(n.y, -1.0, 1.0));
	vec2 p = vec2(lon * cos(lat), lat);
	vec4 acc = vec4(0.0);

	if (show_eyes > 0.5) {
		// blush behind everything
		float bl = 0.0;
		for (int i = 0; i < 2; i++) {
			float s = (i == 0) ? -1.0 : 1.0;
			bl = max(bl, 1.0 - smoothstep(0.55, 1.0, ell(p, vec2(s * (eye_sep + 0.20), eye_y - 0.24), vec2(0.17, 0.10))));
		}
		acc = over(acc, blush_color.rgb, bl * blush * 0.62);
		if (freckles > 0.0) {
			for (int i = 0; i < 2; i++) {
				float s = (i == 0) ? -1.0 : 1.0;
				vec2 fc = vec2(s * (eye_sep + 0.12), eye_y - 0.20);
				float f = 0.0;
				f = max(f, 1.0 - smoothstep(0.6, 1.0, length((p - fc - vec2(-0.05, 0.03)) / 0.018)));
				f = max(f, 1.0 - smoothstep(0.6, 1.0, length((p - fc - vec2(0.05, 0.05)) / 0.016)));
				f = max(f, 1.0 - smoothstep(0.6, 1.0, length((p - fc - vec2(0.0, -0.03)) / 0.017)));
				f = max(f, 1.0 - smoothstep(0.6, 1.0, length((p - fc - vec2(0.10, -0.02)) / 0.015)));
				acc = over(acc, nose_color.rgb, f * freckles * 0.7);
			}
		}
		acc = draw_eye(acc, p, -1.0);
		acc = draw_eye(acc, p, 1.0);
	}

	if (show_nose > 0.5) {
		float nd = 1.0 - smoothstep(0.5, 1.0, ell(p, vec2(0.0, eye_y - 0.24), vec2(0.03, 0.02)));
		acc = over(acc, nose_color.rgb, nd * 0.55);
	}

	if (show_mouth > 0.5) {
		float x = p.x;
		float mw = mouth_w * mix(1.0, 0.55, mouth_round);
		float t = clamp(x / mw, -1.0, 1.0);
		float curve = mouth_y + (t * t - 0.5) * smile * mw * 0.75;
		// lip line
		float line_d = abs(p.y - curve);
		float within = 1.0 - smoothstep(0.9, 1.0, abs(x) / mw);
		float line_a = (1.0 - smoothstep(0.012, 0.022, line_d)) * within * (1.0 - mouth_open);
		acc = over(acc, lip_color.rgb * 0.85, line_a);
		// open mouth
		if (mouth_open > 0.01) {
			float depth = mouth_open * (0.055 + 0.085 * mouth_round) * (1.0 + smile * 0.3) ;
			float lens = 1.0 - t * t;
			float below = curve - p.y;
			float inside = smoothstep(0.0, 0.01, below) * (1.0 - smoothstep(depth * lens - 0.01, depth * lens, below));
			inside *= within;
			// upper lip line
			float up = (1.0 - smoothstep(0.010, 0.020, abs(p.y - curve))) * within;
			vec3 mcol = mix(mouth_color.rgb, vec3(1.0, 0.55, 0.62), smoothstep(depth * 0.35, depth * 0.95, below) * 0.9);
			acc = over(acc, mcol, inside);
			acc = over(acc, lip_color.rgb * 0.8, up * 0.8);
		}
	}

	float face_mask = 1.0 - smoothstep(1.05, 1.3, abs(lon));
	face_mask *= smoothstep(0.0, 0.15, n.z);
	ALBEDO = acc.rgb * tint.rgb;
	ALPHA = acc.a * face_mask;
}
