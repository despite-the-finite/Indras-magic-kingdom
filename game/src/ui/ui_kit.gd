class_name UiKit
## Shared storybook UI look: cream cards, gold trim, chunky rounded fonts, big touch targets.

const CREAM := Color("#fff4e0")
const CREAM_D := Color("#f6dcc0")
const PINK := Color("#ff7fb6")
const PINK_D := Color("#d9528f")
const LILAC := Color("#b58cf2")
const LILAC_D := Color("#8a62d0")
const MINT := Color("#5fd9a8")
const MINT_D := Color("#35b283")
const SKY := Color("#6ec6f5")
const SKY_D := Color("#3f9ad8")
const GOLD := Color("#ffc94d")
const GOLD_D := Color("#e0902a")
const PLUM := Color("#5c2a6b")
const INK := Color("#4a2a5c")

static var _body_font: Font
static var _title_font: Font


static func body_font() -> Font:
	if _body_font == null:
		var ff: FontFile = load("res://assets/fonts/Fredoka.ttf")
		var fv := FontVariation.new()
		fv.base_font = ff
		var ts := TextServerManager.get_primary_interface()
		fv.variation_opentype = {ts.name_to_tag("weight"): 600}
		_body_font = fv
	return _body_font


static func title_font() -> Font:
	if _title_font == null:
		_title_font = load("res://assets/fonts/LilitaOne.ttf")
	return _title_font


static func box(fill: Color, radius: int = 24, border: Color = Color(0, 0, 0, 0), border_w: int = 0, shadow: int = 0, shadow_col: Color = Color(0.35, 0.15, 0.45, 0.28)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(border_w)
	if shadow > 0:
		sb.shadow_size = shadow
		sb.shadow_color = shadow_col
		sb.shadow_offset = Vector2(0, shadow * 0.4)
	sb.anti_aliasing = true
	return sb


## Centre a Control in its parent regardless of when it is built (offsets, not absolute positions).
static func center(c: Control, size: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	c.set_anchors_preset(Control.PRESET_CENTER)
	c.offset_left = -size.x * 0.5 + offset.x
	c.offset_right = size.x * 0.5 + offset.x
	c.offset_top = -size.y * 0.5 + offset.y
	c.offset_bottom = size.y * 0.5 + offset.y


static func card_style(radius: int = 28) -> StyleBoxFlat:
	return box(CREAM, radius, Color("#ffd9a0"), 5, 14)


static func label(text: String, size: int = 28, color: Color = INK, use_title: bool = false, outline: Color = Color(0, 0, 0, 0), outline_w: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", title_font() if use_title else body_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline_w > 0:
		l.add_theme_color_override("font_outline_color", outline)
		l.add_theme_constant_override("outline_size", outline_w)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Star sparkle particles drawn on a CanvasItem (used by buttons and celebrations).
class Spark:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var size: float
	var color: Color
