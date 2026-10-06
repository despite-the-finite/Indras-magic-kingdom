class_name EnvKit
## One-call lighting/sky/fog/glow presets so every place shares the same painterly look.
## Presets are plain dictionaries; tweak one value to re-time a scene.

const PRESETS := {
	"day_forest": {
		"sky_top": "#5aa6f0", "sky_mid": "#8fcaf8", "sky_horizon": "#ffe6f2", "sky_ground": "#b9a6e8",
		"sun_dir": Vector3(0.42, 0.38, -0.80), "sun_color": "#fff0b8", "cloud_cover": 0.55, "stars": 0.0, "moon": 0.0,
		"key_dir": Vector3(-42, 28, 0), "key_color": "#fff2d6", "key_energy": 1.25,
		"rim_dir": Vector3(-25, 200, 0), "rim_color": "#ffd0f0", "rim_energy": 0.55,
		"ambient_energy": 1.0, "ambient_color": "#c8b8ff",
		"fog_color": "#cfc6f8", "fog_density": 0.0038,
		"glow": 0.85, "bloom": 0.10, "exposure": 0.92, "saturation": 1.32, "contrast": 1.14,
	},
	"dusk_forest": {
		"sky_top": "#3a2b86", "sky_mid": "#8a5ac8", "sky_horizon": "#ffb0c8", "sky_ground": "#5a3f9a",
		"sun_dir": Vector3(0.5, 0.12, -0.85), "sun_color": "#ffc6a0", "cloud_cover": 0.45, "stars": 0.35, "moon": 0.0,
		"key_dir": Vector3(-25, 25, 0), "key_color": "#ffcfae", "key_energy": 1.0,
		"rim_dir": Vector3(-20, 200, 0), "rim_color": "#c9a0ff", "rim_energy": 0.7,
		"ambient_energy": 0.95, "ambient_color": "#a58cf0",
		"fog_color": "#8a64c8", "fog_density": 0.0095,
		"glow": 1.0, "bloom": 0.14, "exposure": 1.0, "saturation": 1.2, "contrast": 1.08,
	},
	"moonlit_forest": {
		"sky_top": "#1f1a6a", "sky_mid": "#3d2f9a", "sky_horizon": "#9a78e0", "sky_ground": "#3a2f8a",
		"sun_dir": Vector3(0.4, -0.4, -0.8), "sun_color": "#8888ff", "cloud_cover": 0.32, "stars": 1.0, "moon": 1.0,
		"moon_dir": Vector3(-0.30, 0.52, -0.80),
		"key_dir": Vector3(-40, 30, 0), "key_color": "#c8d4ff", "key_energy": 1.5,
		"rim_dir": Vector3(-20, 200, 0), "rim_color": "#f0c0ff", "rim_energy": 1.0,
		"ambient_energy": 1.9, "ambient_color": "#9a90f0",
		"fog_color": "#5a48b0", "fog_density": 0.006,
		"glow": 1.25, "bloom": 0.2, "exposure": 1.02, "saturation": 1.08, "contrast": 1.05,
	},
	"castle_day": {
		"sky_top": "#62b0f5", "sky_mid": "#a0d6fb", "sky_horizon": "#fff0f6", "sky_ground": "#cbb8f0",
		"sun_dir": Vector3(0.35, 0.44, -0.82), "sun_color": "#fff2c0", "cloud_cover": 0.6, "stars": 0.0, "moon": 0.0,
		"key_dir": Vector3(-46, 32, 0), "key_color": "#fff4dc", "key_energy": 1.3,
		"rim_dir": Vector3(-25, 205, 0), "rim_color": "#ffd6ee", "rim_energy": 0.5,
		"ambient_energy": 1.05, "ambient_color": "#d4c4ff",
		"fog_color": "#d6ccf8", "fog_density": 0.0032,
		"glow": 0.8, "bloom": 0.1, "exposure": 0.93, "saturation": 1.3, "contrast": 1.12,
	},
	"stable_warm": {
		"sky_top": "#ffb8a0", "sky_mid": "#ffd6b8", "sky_horizon": "#fff0d0", "sky_ground": "#e8b8c8",
		"sun_dir": Vector3(0.3, 0.3, -0.9), "sun_color": "#ffd890", "cloud_cover": 0.3, "stars": 0.0, "moon": 0.0,
		"key_dir": Vector3(-38, 22, 0), "key_color": "#ffe0b0", "key_energy": 1.1,
		"rim_dir": Vector3(-20, 200, 0), "rim_color": "#ffb8e0", "rim_energy": 0.5,
		"ambient_energy": 1.1, "ambient_color": "#ffd0c0",
		"fog_color": "#ffe0d0", "fog_density": 0.006,
		"glow": 0.95, "bloom": 0.12, "exposure": 1.05, "saturation": 1.15, "contrast": 1.05,
	},
	"rainbow_sky": {
		"sky_top": "#4fa8ff", "sky_mid": "#98d8ff", "sky_horizon": "#ffe0f8", "sky_ground": "#d8c0ff",
		"sun_dir": Vector3(0.1, 0.5, -0.85), "sun_color": "#fff6c8", "cloud_cover": 0.7, "stars": 0.0, "moon": 0.0,
		"key_dir": Vector3(-50, 20, 0), "key_color": "#fff6dc", "key_energy": 1.3,
		"rim_dir": Vector3(-25, 200, 0), "rim_color": "#ffd0f0", "rim_energy": 0.5,
		"ambient_energy": 1.1, "ambient_color": "#d8c8ff",
		"fog_color": "#d8ccf8", "fog_density": 0.003,
		"glow": 1.0, "bloom": 0.14, "exposure": 0.93, "saturation": 1.3, "contrast": 1.12,
	},
	"castle_inside": {
		"sky_top": "#f0d8ff", "sky_mid": "#ffe6f4", "sky_horizon": "#fff4e6", "sky_ground": "#e8c8f0",
		"sun_dir": Vector3(0.2, 0.6, -0.75), "sun_color": "#fff6d8", "cloud_cover": 0.3, "stars": 0.0, "moon": 0.0,
		"key_dir": Vector3(-35, 20, 0), "key_color": "#fff0dc", "key_energy": 1.2,
		"rim_dir": Vector3(-20, 200, 0), "rim_color": "#ffd0f0", "rim_energy": 0.5,
		"ambient_energy": 1.35, "ambient_color": "#e8d0ff",
		"fog_color": "#f0dcf8", "fog_density": 0.003,
		"glow": 0.9, "bloom": 0.12, "exposure": 0.95, "saturation": 1.22, "contrast": 1.08,
	},
	"map_parchment": {
		"sky_top": "#ffe9c8", "sky_mid": "#ffe0d0", "sky_horizon": "#fff4e0", "sky_ground": "#f0d0b8",
		"sun_dir": Vector3(0.2, 0.7, -0.6), "sun_color": "#ffffff", "cloud_cover": 0.0, "stars": 0.0, "moon": 0.0,
		"key_dir": Vector3(-58, 20, 0), "key_color": "#fff2dc", "key_energy": 1.25,
		"rim_dir": Vector3(-25, 200, 0), "rim_color": "#ffd6ee", "rim_energy": 0.35,
		"ambient_energy": 1.1, "ambient_color": "#ffe8d8",
		"fog_color": "#fff0e0", "fog_density": 0.0,
		"glow": 0.7, "bloom": 0.08, "exposure": 0.86, "saturation": 1.25, "contrast": 1.1,
	},
}


## Adds WorldEnvironment + key light + rim light to `parent`. Returns {"env","key","rim","sky_mat"}.
static func apply(parent: Node, preset_name: String, overrides: Dictionary = {}) -> Dictionary:
	var p: Dictionary = PRESETS.get(preset_name, PRESETS["day_forest"]).duplicate()
	p.merge(overrides, true)

	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky.gdshader")
	sky_mat.set_shader_parameter("top_color", Color(p.sky_top))
	sky_mat.set_shader_parameter("mid_color", Color(p.sky_mid))
	sky_mat.set_shader_parameter("horizon_color", Color(p.sky_horizon))
	sky_mat.set_shader_parameter("ground_color", Color(p.sky_ground))
	sky_mat.set_shader_parameter("sun_dir", (p.sun_dir as Vector3).normalized())
	sky_mat.set_shader_parameter("sun_color", Color(p.sun_color))
	sky_mat.set_shader_parameter("cloud_cover", float(p.cloud_cover))
	sky_mat.set_shader_parameter("star_amount", float(p.stars))
	sky_mat.set_shader_parameter("moon_amount", float(p.moon))
	if p.has("moon_dir"):
		sky_mat.set_shader_parameter("moon_dir", (p.moon_dir as Vector3).normalized())
	var cloud_night := float(p.moon) > 0.5
	if cloud_night:
		sky_mat.set_shader_parameter("cloud_light", Color("#9c8ee8"))
		sky_mat.set_shader_parameter("cloud_shadow", Color("#4a3f9e"))

	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_64

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = float(p.ambient_energy) * 0.11
	env.ambient_light_sky_contribution = 0.55
	env.ambient_light_color = Color(p.ambient_color)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = float(p.exposure) * 0.92
	env.fog_enabled = float(p.fog_density) > 0.0
	env.fog_light_color = Color(p.fog_color)
	env.fog_density = float(p.fog_density)
	env.fog_sky_affect = 0.0
	env.glow_enabled = Settings.glow_enabled()
	env.glow_intensity = float(p.glow) * 0.6
	env.glow_bloom = float(p.bloom)
	env.glow_strength = 1.0
	env.glow_hdr_threshold = 1.15
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.adjustment_enabled = true
	env.adjustment_saturation = float(p.saturation)
	env.adjustment_contrast = float(p.contrast)

	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = p.key_dir
	key.light_color = Color(p.key_color)
	key.light_energy = float(p.key_energy) * 0.13   # toon light() is full-strength in lit bands; keep the sum ~1.0
	key.shadow_enabled = Settings.shadows_enabled()
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	key.directional_shadow_max_distance = 70.0
	key.shadow_blur = 1.6
	key.shadow_bias = 0.04
	key.shadow_normal_bias = 1.2
	key.light_angular_distance = 0.4
	parent.add_child(key)

	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = p.rim_dir
	rim.light_color = Color(p.rim_color)
	rim.light_energy = float(p.rim_energy) * 0.09
	rim.shadow_enabled = false
	parent.add_child(rim)

	return {"env": env, "key": key, "rim": rim, "sky_mat": sky_mat, "we": we}
