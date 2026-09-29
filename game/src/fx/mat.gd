class_name Mat
## Material factory + the game's colour language (see docs/STYLE_BIBLE.md).

# ---- palette ----------------------------------------------------------------
const PINK := Color("#ff8fbf")
const BLUSH := Color("#ffd6ec")
const LILAC := Color("#b58cf2")
const SKY := Color("#6ec6f5")
const MINT := Color("#66d9b0")
const SUN := Color("#ffe27a")
const GOLD := Color("#ffc94d")
const CREAM := Color("#fff4e0")
const PLUM := Color("#5c2a6b")
const LEAF := Color("#57c98a")
const LEAF_LIGHT := Color("#a5f0a0")
const BARK := Color("#9b6b4e")
const NIGHT := Color("#2a1f5c")

static var _toon: Shader
static var _toon2: Shader
static var _outline: Shader
static var _rainbow: Shader
static var _water: Shader
static var _face: Shader
static var _cache: Dictionary = {}


static func toon_shader() -> Shader:
	if _toon == null:
		_toon = load("res://shaders/toon.gdshader")
	return _toon


static func outline_material(thickness: float = 0.012, color: Color = Color(0.36, 0.16, 0.42)) -> ShaderMaterial:
	if _outline == null:
		_outline = load("res://shaders/outline.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _outline
	m.set_shader_parameter("thickness", thickness)
	m.set_shader_parameter("outline_color", color)
	return m


## Toon material. `o` = extra shader params, e.g. {"albedo_top": c, "gradient_amount": 1.0, "wind": 0.2}
## Special keys: "outline" (bool / float thickness).
static func toon(color: Color, o: Dictionary = {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	if o.get("two_sided", false):
		if _toon2 == null:
			_toon2 = load("res://shaders/toon_2s.gdshader")
		m.shader = _toon2
	else:
		m.shader = toon_shader()
	m.set_shader_parameter("albedo", color)
	for k in o:
		if k == "outline":
			if o[k]:
				m.next_pass = outline_material(o[k] if o[k] is float else 0.012)
		elif k == "two_sided":
			m.set_shader_parameter("double_sided", o[k])
		else:
			m.set_shader_parameter(k, o[k])
	return m


## Two-tone vertical gradient (bottom -> top in model space y).
static func toon_grad(bottom: Color, top: Color, y0: float, y1: float, o: Dictionary = {}) -> ShaderMaterial:
	var d := {"albedo_top": top, "gradient_amount": 1.0, "gradient_min": y0, "gradient_max": y1}
	d.merge(o, true)
	return toon(bottom, d)


static func glowing(color: Color, energy: float = 1.5, o: Dictionary = {}) -> ShaderMaterial:
	var d := {"emission_color": color, "emission_energy": energy, "rim_amount": 0.0, "shade_strength": 0.2}
	d.merge(o, true)
	return toon(color, d)


## Unlit additive material (light shafts, halos, beams).
static func additive(color: Color, tex: Texture2D = null, billboard: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = color
	m.albedo_texture = tex
	m.vertex_color_use_as_albedo = true
	m.disable_receive_shadows = true
	m.no_depth_test = false
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	return m


static func rainbow_material() -> ShaderMaterial:
	if _rainbow == null:
		_rainbow = load("res://shaders/rainbow.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _rainbow
	return m


static func water_material(deep: Color = Color(0.16, 0.56, 0.86), shallow: Color = Color(0.45, 0.88, 0.92)) -> ShaderMaterial:
	if _water == null:
		_water = load("res://shaders/water.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _water
	m.set_shader_parameter("deep_color", deep)
	m.set_shader_parameter("shallow_color", shallow)
	return m


static func face_material() -> ShaderMaterial:
	if _face == null:
		_face = load("res://shaders/face.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _face
	m.render_priority = 5
	return m


static func lerp_col(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, t)


static func shade(c: Color, amount: float) -> Color:
	## amount < 0 darkens toward plum, > 0 lightens toward cream
	if amount < 0.0:
		return c.lerp(PLUM, -amount)
	return c.lerp(CREAM, amount)
