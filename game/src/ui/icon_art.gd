class_name IconArt
## Vector icon set drawn in code (crisp at any size, tintable, animatable). Non-readers navigate by these.
## usage inside a Control's _draw():   IconArt.draw(self, "flower", center, radius)

const GOLD := Color("#ffc94d")
const GOLD_L := Color("#fff0a0")
const PINK := Color("#ff7fb6")
const PINK_L := Color("#ffc4e0")
const LILAC := Color("#b58cf2")
const SKY := Color("#6ec6f5")
const MINT := Color("#5fd9a8")
const CREAM := Color("#fff4e0")
const BROWN := Color("#a0684a")
const PLUM := Color("#5c2a6b")
const RED := Color("#ff6f8f")


static func draw(ci: CanvasItem, kind: String, c: Vector2, r: float, dim: float = 0.0) -> void:
	match kind:
		"star": _star(ci, c, r)
		"heart": _heart(ci, c, r, PINK)
		"flower": _flower(ci, c, r)
		"paw", "animals": _paw(ci, c, r)
		"rainbow", "rainbow_bridge": _rainbow(ci, c, r)
		"starlight": _sparkle(ci, c, r, GOLD)
		"coop_shine": _star(ci, c, r)
		"magic", "wand": _wand(ci, c, r)
		"hand", "touch": _hand(ci, c, r)
		"brush": _brush(ci, c, r)
		"apple", "rainbow_apple": _apple(ci, c, r)
		"hug": _heart(ci, c, r, PINK)
		"home": _home(ci, c, r)
		"map": _map(ci, c, r)
		"play": _play(ci, c, r)
		"back": _arrow(ci, c, r, PI)
		"left": _arrow(ci, c, r, PI)
		"right": _arrow(ci, c, r, 0.0)
		"up": _arrow(ci, c, r, -PI * 0.5)
		"gear": _gear(ci, c, r)
		"lock": _lock(ci, c, r)
		"butterfly": _butterfly(ci, c, r)
		"crown": _crown(ci, c, r)
		"horseshoe": _horseshoe(ci, c, r)
		"moon": _moon(ci, c, r)
		"sun": _sun(ci, c, r)
		"castle": _castle(ci, c, r)
		"dragon": _dragon(ci, c, r)
		"shell": _shell(ci, c, r)
		"snowflake": _snowflake(ci, c, r)
		"check": _check(ci, c, r)
		"close": _close(ci, c, r)
		"sound": _sound(ci, c, r)
		"face": _face(ci, c, r)
		"eye": _eye(ci, c, r)
		"hair": _hair(ci, c, r)
		"drop": _drop(ci, c, r)
		"dress": _dress(ci, c, r)
		"boot": _boot(ci, c, r)
		"cape": _cape(ci, c, r)
		"sparkle": _sparkle(ci, c, r, GOLD)
		"shuffle": _sparkle(ci, c, r, LILAC)
		_: ci.draw_circle(c, r * 0.6, PINK_L)
	if dim > 0.0:
		ci.draw_circle(c, r * 1.05, Color(0.25, 0.15, 0.35, dim))


# ---- helpers -----------------------------------------------------------------
static func _pts_star(c: Vector2, ro: float, ri: float, n: int = 5, rot: float = -PI * 0.5) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n * 2:
		var a := rot + float(i) / (n * 2) * TAU
		var rr := ro if i % 2 == 0 else ri
		p.append(c + Vector2(cos(a), sin(a)) * rr)
	return p


static func _outline_poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, line: Color, w: float) -> void:
	ci.draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, line, w, true)


static func _star(ci: CanvasItem, c: Vector2, r: float) -> void:
	var pts := _pts_star(c, r, r * 0.48)
	_outline_poly(ci, pts, GOLD, Color("#e0902a"), maxf(r * 0.12, 1.5))
	var hi := _pts_star(c + Vector2(-r * 0.05, -r * 0.08), r * 0.6, r * 0.28)
	ci.draw_colored_polygon(hi, GOLD_L)
	ci.draw_circle(c + Vector2(-r * 0.22, -r * 0.22), r * 0.1, Color(1, 1, 1, 0.9))


static func _sparkle(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var p := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.22, -r * 0.22), c + Vector2(r, 0), c + Vector2(r * 0.22, r * 0.22),
		c + Vector2(0, r), c + Vector2(-r * 0.22, r * 0.22), c + Vector2(-r, 0), c + Vector2(-r * 0.22, -r * 0.22)])
	_outline_poly(ci, p, col, col.darkened(0.25), maxf(r * 0.1, 1.5))
	_star_small(ci, c + Vector2(r * 0.62, -r * 0.62), r * 0.24, Color.WHITE)
	_star_small(ci, c + Vector2(-r * 0.66, r * 0.55), r * 0.16, Color.WHITE)


static func _star_small(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var p := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.25, -r * 0.25), c + Vector2(r, 0), c + Vector2(r * 0.25, r * 0.25),
		c + Vector2(0, r), c + Vector2(-r * 0.25, r * 0.25), c + Vector2(-r, 0), c + Vector2(-r * 0.25, -r * 0.25)])
	ci.draw_colored_polygon(p, col)


static func _heart(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 41:
		var t := float(i) / 40.0 * TAU
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(c + Vector2(x, y + 1.5) * (r / 17.5))
	_outline_poly(ci, pts, col, col.darkened(0.3), maxf(r * 0.1, 1.5))
	ci.draw_circle(c + Vector2(-r * 0.42, -r * 0.35), r * 0.12, Color(1, 1, 1, 0.85))


static func _flower(ci: CanvasItem, c: Vector2, r: float) -> void:
	for i in 6:
		var a := float(i) / 6.0 * TAU
		var pc := c + Vector2(cos(a), sin(a)) * r * 0.5
		ci.draw_circle(pc, r * 0.36, PINK)
		ci.draw_circle(pc + Vector2(-r * 0.05, -r * 0.05), r * 0.2, PINK_L)
	ci.draw_circle(c, r * 0.3, GOLD)
	ci.draw_circle(c + Vector2(-r * 0.07, -r * 0.07), r * 0.13, GOLD_L)


static func _paw(ci: CanvasItem, c: Vector2, r: float) -> void:
	var col := Color("#c98a5e")
	ci.draw_circle(c + Vector2(0, r * 0.28), r * 0.44, col)
	for i in 4:
		var a := deg_to_rad(-150.0 + i * 40.0)
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.66 + Vector2(0, -r * 0.05), r * 0.2, col)
	ci.draw_circle(c + Vector2(-r * 0.12, r * 0.15), r * 0.12, Color(1, 1, 1, 0.35))


static func _rainbow(ci: CanvasItem, c: Vector2, r: float) -> void:
	var cols := [Color("#ff6f8f"), Color("#ffb04a"), Color("#ffe066"), Color("#66dd99"), Color("#5cb8ff"), Color("#a684ff")]
	var w := r * 0.17
	for i in cols.size():
		ci.draw_arc(c + Vector2(0, r * 0.45), r * (0.95 - i * 0.14), PI, TAU, 32, cols[i], w + 1.0, true)
	ci.draw_circle(c + Vector2(-r * 0.92, r * 0.42), r * 0.1, Color.WHITE)


static func _wand(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_line(c + Vector2(-r * 0.7, r * 0.7), c + Vector2(r * 0.15, -r * 0.15), Color("#fff4e0"), r * 0.2, true)
	ci.draw_line(c + Vector2(-r * 0.7, r * 0.7), c + Vector2(-r * 0.05, 0.05 * r), Color("#ffc4e0"), r * 0.2, true)
	var pts := _pts_star(c + Vector2(r * 0.32, -r * 0.32), r * 0.55, r * 0.26)
	_outline_poly(ci, pts, GOLD, Color("#e0902a"), maxf(r * 0.08, 1.2))
	_star_small(ci, c + Vector2(-r * 0.15, -r * 0.7), r * 0.16, Color.WHITE)
	_star_small(ci, c + Vector2(r * 0.8, r * 0.25), r * 0.13, Color.WHITE)


static func _hand(ci: CanvasItem, c: Vector2, r: float) -> void:
	var skin := Color("#ffd2b0")
	var line := Color("#d8956e")
	ci.draw_circle(c + Vector2(0, r * 0.25), r * 0.5, skin)
	for i in 4:
		var x := (i - 1.5) * r * 0.27
		var top := -r * (0.7 if i in [1, 2] else 0.55)
		ci.draw_line(c + Vector2(x, r * 0.1), c + Vector2(x, top), skin, r * 0.24, true)
		ci.draw_circle(c + Vector2(x, top), r * 0.12, skin)
	ci.draw_line(c + Vector2(-r * 0.4, r * 0.3), c + Vector2(-r * 0.75, -r * 0.05), skin, r * 0.24, true)
	ci.draw_arc(c + Vector2(0, r * 0.25), r * 0.5, deg_to_rad(20), deg_to_rad(160), 12, line, 1.5, true)


static func _brush(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_line(c + Vector2(r * 0.15, r * 0.55), c + Vector2(r * 0.7, -r * 0.1), Color("#c98a5e"), r * 0.3, true)
	var head := PackedVector2Array([c + Vector2(-r * 0.75, -r * 0.05), c + Vector2(-r * 0.15, -r * 0.75), c + Vector2(r * 0.35, -r * 0.3), c + Vector2(-r * 0.25, r * 0.35)])
	_outline_poly(ci, head, PINK, Color("#d05a8c"), r * 0.08)
	for i in 4:
		var f := 0.15 + i * 0.2
		var a := head[0].lerp(head[1], f)
		var b := head[3].lerp(head[2], f)
		ci.draw_line(a, b, PINK_L, r * 0.08, true)


static func _apple(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(-r * 0.25, r * 0.08), r * 0.55, Color("#ff6f8f"))
	ci.draw_circle(c + Vector2(r * 0.25, r * 0.08), r * 0.55, Color("#ff6f8f"))
	ci.draw_circle(c + Vector2(0, r * 0.15), r * 0.6, Color("#ff7f9f"))
	ci.draw_arc(c + Vector2(0, r * 0.15), r * 0.42, deg_to_rad(200), deg_to_rad(330), 12, Color("#ffe066"), r * 0.1, true)
	ci.draw_arc(c + Vector2(0, r * 0.15), r * 0.3, deg_to_rad(200), deg_to_rad(330), 12, Color("#66dd99"), r * 0.1, true)
	ci.draw_line(c + Vector2(0, -r * 0.4), c + Vector2(r * 0.08, -r * 0.7), Color("#8a5a3c"), r * 0.1, true)
	var leaf := PackedVector2Array([c + Vector2(r * 0.1, -r * 0.55), c + Vector2(r * 0.5, -r * 0.8), c + Vector2(r * 0.45, -r * 0.45)])
	ci.draw_colored_polygon(leaf, MINT)
	ci.draw_circle(c + Vector2(-r * 0.35, -r * 0.15), r * 0.1, Color(1, 1, 1, 0.8))


static func _home(ci: CanvasItem, c: Vector2, r: float) -> void:
	var roof := PackedVector2Array([c + Vector2(-r * 0.95, -r * 0.05), c + Vector2(0, -r * 0.9), c + Vector2(r * 0.95, -r * 0.05)])
	ci.draw_rect(Rect2(c + Vector2(-r * 0.68, -r * 0.1), Vector2(r * 1.36, r * 0.9)), CREAM)
	ci.draw_colored_polygon(roof, PINK)
	ci.draw_rect(Rect2(c + Vector2(-r * 0.16, r * 0.25), Vector2(r * 0.32, r * 0.55)), BROWN)
	ci.draw_circle(c + Vector2(0, -r * 0.3), r * 0.11, GOLD)
	ci.draw_rect(Rect2(c + Vector2(r * 0.3, -r * 0.05), Vector2(r * 0.25, r * 0.25)), SKY)


static func _map(ci: CanvasItem, c: Vector2, r: float) -> void:
	var p := PackedVector2Array([c + Vector2(-r, -r * 0.7), c + Vector2(-r * 0.33, -r * 0.55), c + Vector2(r * 0.33, -r * 0.75), c + Vector2(r, -r * 0.55),
		c + Vector2(r, r * 0.7), c + Vector2(r * 0.33, r * 0.55), c + Vector2(-r * 0.33, r * 0.75), c + Vector2(-r, r * 0.55)])
	_outline_poly(ci, p, Color("#ffe8b8"), Color("#c9975a"), r * 0.08)
	ci.draw_line(c + Vector2(-r * 0.33, -r * 0.55), c + Vector2(-r * 0.33, r * 0.75), Color("#e0c088"), r * 0.06, true)
	ci.draw_line(c + Vector2(r * 0.33, -r * 0.75), c + Vector2(r * 0.33, r * 0.55), Color("#e0c088"), r * 0.06, true)
	ci.draw_line(c + Vector2(-r * 0.6, r * 0.25), c + Vector2(0, -r * 0.1), Color("#ff6f8f"), r * 0.08, true)
	ci.draw_line(c + Vector2(0, -r * 0.1), c + Vector2(r * 0.55, r * 0.15), Color("#ff6f8f"), r * 0.08, true)
	ci.draw_line(c + Vector2(r * 0.4, -r * 0.05), c + Vector2(r * 0.7, r * 0.25), Color("#ff3f6f"), r * 0.12, true)
	ci.draw_line(c + Vector2(r * 0.7, -r * 0.05), c + Vector2(r * 0.4, r * 0.25), Color("#ff3f6f"), r * 0.12, true)


static func _play(ci: CanvasItem, c: Vector2, r: float) -> void:
	var p := PackedVector2Array([c + Vector2(-r * 0.5, -r * 0.8), c + Vector2(r * 0.85, 0), c + Vector2(-r * 0.5, r * 0.8)])
	_outline_poly(ci, p, Color.WHITE, Color("#e08aa8"), r * 0.1)


static func _arrow(ci: CanvasItem, c: Vector2, r: float, ang: float) -> void:
	var f := func(v: Vector2) -> Vector2: return c + v.rotated(ang) * r
	var p := PackedVector2Array([f.call(Vector2(0.9, 0)), f.call(Vector2(0.1, -0.8)), f.call(Vector2(0.1, -0.35)), f.call(Vector2(-0.8, -0.35)),
		f.call(Vector2(-0.8, 0.35)), f.call(Vector2(0.1, 0.35)), f.call(Vector2(0.1, 0.8))])
	_outline_poly(ci, p, Color.WHITE, Color("#e08aa8"), r * 0.1)


static func _gear(ci: CanvasItem, c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := float(i) / 16.0 * TAU
		var rr := r if (i % 2 == 0) else r * 0.78
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
		pts.append(c + Vector2(cos(a + TAU / 32.0), sin(a + TAU / 32.0)) * rr)
	_outline_poly(ci, pts, Color("#c7b8ee"), Color("#8a6fc0"), r * 0.08)
	ci.draw_circle(c, r * 0.36, Color("#fff4e0"))


static func _lock(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_arc(c + Vector2(0, -r * 0.15), r * 0.42, PI, TAU, 16, Color("#c7b8ee"), r * 0.16, true)
	ci.draw_line(c + Vector2(-r * 0.42, -r * 0.15), c + Vector2(-r * 0.42, r * 0.1), Color("#c7b8ee"), r * 0.16, true)
	ci.draw_line(c + Vector2(r * 0.42, -r * 0.15), c + Vector2(r * 0.42, r * 0.1), Color("#c7b8ee"), r * 0.16, true)
	var body := PackedVector2Array([c + Vector2(-r * 0.62, r * 0.05), c + Vector2(r * 0.62, r * 0.05), c + Vector2(r * 0.62, r * 0.85), c + Vector2(-r * 0.62, r * 0.85)])
	_outline_poly(ci, body, GOLD, Color("#e0902a"), r * 0.08)
	ci.draw_circle(c + Vector2(0, r * 0.4), r * 0.12, PLUM)
	ci.draw_line(c + Vector2(0, r * 0.4), c + Vector2(0, r * 0.65), PLUM, r * 0.1, true)


static func _butterfly(ci: CanvasItem, c: Vector2, r: float) -> void:
	for sx in [-1.0, 1.0]:
		ci.draw_circle(c + Vector2(sx * r * 0.45, -r * 0.3), r * 0.5, PINK)
		ci.draw_circle(c + Vector2(sx * r * 0.4, r * 0.4), r * 0.34, LILAC)
		ci.draw_circle(c + Vector2(sx * r * 0.5, -r * 0.38), r * 0.16, PINK_L)
	ci.draw_line(c + Vector2(0, -r * 0.5), c + Vector2(0, r * 0.6), PLUM, r * 0.14, true)
	ci.draw_line(c + Vector2(0, -r * 0.5), c + Vector2(-r * 0.2, -r * 0.85), PLUM, r * 0.06, true)
	ci.draw_line(c + Vector2(0, -r * 0.5), c + Vector2(r * 0.2, -r * 0.85), PLUM, r * 0.06, true)


static func _crown(ci: CanvasItem, c: Vector2, r: float) -> void:
	var p := PackedVector2Array([c + Vector2(-r, r * 0.55), c + Vector2(-r * 0.95, -r * 0.4), c + Vector2(-r * 0.5, r * 0.05), c + Vector2(0, -r * 0.7),
		c + Vector2(r * 0.5, r * 0.05), c + Vector2(r * 0.95, -r * 0.4), c + Vector2(r, r * 0.55)])
	_outline_poly(ci, p, GOLD, Color("#e0902a"), r * 0.09)
	ci.draw_rect(Rect2(c + Vector2(-r, r * 0.4), Vector2(r * 2.0, r * 0.26)), Color("#ffd86a"))
	ci.draw_circle(c + Vector2(0, -r * 0.7), r * 0.14, PINK)
	ci.draw_circle(c + Vector2(-r * 0.95, -r * 0.4), r * 0.12, SKY)
	ci.draw_circle(c + Vector2(r * 0.95, -r * 0.4), r * 0.12, MINT)
	ci.draw_circle(c + Vector2(0, r * 0.53), r * 0.13, PINK)


static func _horseshoe(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_arc(c, r * 0.7, deg_to_rad(-40), deg_to_rad(220), 24, Color("#c7b8ee"), r * 0.3, true)
	for i in 3:
		var a := deg_to_rad(-20.0 + i * 100.0 - 20)
		ci.draw_circle(c + Vector2(cos(a), -sin(a)) * r * 0.7, r * 0.06, Color("#8a6fc0"))


static func _moon(ci: CanvasItem, c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var a := deg_to_rad(60.0 + float(i) / 24.0 * 240.0)
		pts.append(c + Vector2(cos(a), -sin(a)) * r * 0.9)
	for i in 25:
		var a := deg_to_rad(300.0 - float(i) / 24.0 * 240.0)
		pts.append(c + Vector2(cos(a) * 0.72 + 0.42, -sin(a) * 0.72) * r * 0.9)
	_outline_poly(ci, pts, Color("#fff0a0"), Color("#e0b84a"), r * 0.07)


static func _sun(ci: CanvasItem, c: Vector2, r: float) -> void:
	for i in 10:
		var a := float(i) / 10.0 * TAU
		ci.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.65, c + Vector2(cos(a), sin(a)) * r * 0.98, GOLD, r * 0.12, true)
	ci.draw_circle(c, r * 0.5, GOLD)
	ci.draw_circle(c + Vector2(-r * 0.12, -r * 0.12), r * 0.2, GOLD_L)


static func _castle(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.1), Vector2(r * 1.4, r * 0.9)), Color("#ffe0f0"))
	for sx in [-1.0, 1.0]:
		ci.draw_rect(Rect2(c + Vector2(sx * r * 0.55 - r * 0.2, -r * 0.5), Vector2(r * 0.4, r * 1.3)), Color("#fff0f8"))
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(sx * r * 0.55 - r * 0.28, -r * 0.5), c + Vector2(sx * r * 0.55, -r * 1.0), c + Vector2(sx * r * 0.55 + r * 0.28, -r * 0.5)]), LILAC)
	ci.draw_rect(Rect2(c + Vector2(-r * 0.22, -r * 0.7), Vector2(r * 0.44, r * 1.5)), Color("#fff0f8"))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.3, -r * 0.7), c + Vector2(0, -r * 1.2), c + Vector2(r * 0.3, -r * 0.7)]), PINK)
	ci.draw_rect(Rect2(c + Vector2(-r * 0.12, r * 0.3), Vector2(r * 0.24, r * 0.5)), BROWN)


static func _dragon(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(0, r * 0.1), r * 0.55, Color("#b58cf2"))
	for sx in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(sx * r * 0.3, -r * 0.35), c + Vector2(sx * r * 0.55, -r * 0.95), c + Vector2(sx * r * 0.7, -r * 0.2)]), Color("#ffd27a"))
		ci.draw_circle(c + Vector2(sx * r * 0.22, 0), r * 0.1, PLUM)
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(sx * r * 0.5, r * 0.3), c + Vector2(sx * r * 1.0, r * 0.05), c + Vector2(sx * r * 0.8, r * 0.7)]), Color("#e0c8ff"))
	ci.draw_circle(c + Vector2(0, r * 0.32), r * 0.14, PINK_L)


static func _shell(ci: CanvasItem, c: Vector2, r: float) -> void:
	var p := PackedVector2Array()
	p.append(c + Vector2(0, r * 0.8))
	for i in 15:
		var a := deg_to_rad(200.0 + float(i) / 14.0 * 140.0)
		p.append(c + Vector2(cos(a), sin(a)) * r * 0.95 + Vector2(0, r * 0.2))
	_outline_poly(ci, p, Color("#ffd0e8"), Color("#e08aa8"), r * 0.07)
	for i in 5:
		var a := deg_to_rad(215.0 + i * 27.5)
		ci.draw_line(c + Vector2(0, r * 0.8), c + Vector2(cos(a), sin(a)) * r * 0.9 + Vector2(0, r * 0.2), Color("#ffb0d0"), r * 0.06, true)


static func _snowflake(ci: CanvasItem, c: Vector2, r: float) -> void:
	for i in 3:
		var a := float(i) / 3.0 * PI
		ci.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.9, c - Vector2(cos(a), sin(a)) * r * 0.9, Color("#bfe6ff"), r * 0.13, true)
	ci.draw_circle(c, r * 0.18, Color.WHITE)


static func _check(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.6, 0), c + Vector2(-r * 0.15, r * 0.5), c + Vector2(r * 0.7, -r * 0.5)]), MINT, r * 0.28, true)


static func _close(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_line(c + Vector2(-r * 0.6, -r * 0.6), c + Vector2(r * 0.6, r * 0.6), PINK, r * 0.28, true)
	ci.draw_line(c + Vector2(r * 0.6, -r * 0.6), c + Vector2(-r * 0.6, r * 0.6), PINK, r * 0.28, true)


static func _sound(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.3), c + Vector2(-r * 0.35, -r * 0.3), c + Vector2(r * 0.1, -r * 0.75),
		c + Vector2(r * 0.1, r * 0.75), c + Vector2(-r * 0.35, r * 0.3), c + Vector2(-r * 0.8, r * 0.3)]), Color("#c7b8ee"))
	ci.draw_arc(c, r * 0.45, deg_to_rad(-45), deg_to_rad(45), 10, Color("#8a6fc0"), r * 0.12, true)
	ci.draw_arc(c, r * 0.8, deg_to_rad(-45), deg_to_rad(45), 12, Color("#8a6fc0"), r * 0.12, true)


static func _face(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r * 0.9, Color("#ffd2b0"))
	ci.draw_circle(c + Vector2(-r * 0.32, -r * 0.05), r * 0.13, PLUM)
	ci.draw_circle(c + Vector2(r * 0.32, -r * 0.05), r * 0.13, PLUM)
	ci.draw_circle(c + Vector2(-r * 0.32, -r * 0.09), r * 0.05, Color.WHITE)
	ci.draw_circle(c + Vector2(r * 0.32, -r * 0.09), r * 0.05, Color.WHITE)
	ci.draw_arc(c + Vector2(0, r * 0.15), r * 0.36, deg_to_rad(30), deg_to_rad(150), 10, Color("#c95a6f"), r * 0.1, true)
	ci.draw_circle(c + Vector2(-r * 0.55, r * 0.2), r * 0.13, Color(1, 0.55, 0.65, 0.6))
	ci.draw_circle(c + Vector2(r * 0.55, r * 0.2), r * 0.13, Color(1, 0.55, 0.65, 0.6))


static func _eye(ci: CanvasItem, c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 21:
		var t := float(i) / 20.0
		pts.append(c + Vector2(lerpf(-r, r, t), -sin(t * PI) * r * 0.55))
	for i in 21:
		var t := 1.0 - float(i) / 20.0
		pts.append(c + Vector2(lerpf(-r, r, t), sin(t * PI) * r * 0.55))
	ci.draw_colored_polygon(pts, Color.WHITE)
	ci.draw_circle(c, r * 0.42, Color("#7a4dd8"))
	ci.draw_circle(c, r * 0.2, PLUM)
	ci.draw_circle(c + Vector2(-r * 0.12, -r * 0.14), r * 0.09, Color.WHITE)


static func _hair(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(0, r * 0.1), r * 0.65, Color("#ffd2b0"))
	var hair := Color("#8b4f2a")
	ci.draw_arc(c + Vector2(0, r * 0.1), r * 0.78, deg_to_rad(180), deg_to_rad(360), 20, hair, r * 0.32, true)
	ci.draw_line(c + Vector2(-r * 0.78, r * 0.05), c + Vector2(-r * 0.78, r * 0.85), hair, r * 0.32, true)
	ci.draw_line(c + Vector2(r * 0.78, r * 0.05), c + Vector2(r * 0.78, r * 0.85), hair, r * 0.32, true)


static func _drop(ci: CanvasItem, c: Vector2, r: float) -> void:
	var body := Color("#ff8fd2")
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.52, r * 0.1), c + Vector2(-r * 0.52, r * 0.1)]), body)
	ci.draw_circle(c + Vector2(0, r * 0.3), r * 0.62, Color("#c95a9f"))
	ci.draw_circle(c + Vector2(0, r * 0.3), r * 0.55, body)
	ci.draw_circle(c + Vector2(-r * 0.22, r * 0.18), r * 0.11, Color(1, 1, 1, 0.8))


static func _dress(ci: CanvasItem, c: Vector2, r: float) -> void:
	var p := PackedVector2Array([c + Vector2(-r * 0.3, -r * 0.9), c + Vector2(r * 0.3, -r * 0.9), c + Vector2(r * 0.25, -r * 0.1), c + Vector2(r * 0.95, r * 0.9),
		c + Vector2(-r * 0.95, r * 0.9), c + Vector2(-r * 0.25, -r * 0.1)])
	_outline_poly(ci, p, PINK, Color("#d05a8c"), r * 0.08)
	ci.draw_line(c + Vector2(-r * 0.27, -r * 0.1), c + Vector2(r * 0.27, -r * 0.1), GOLD, r * 0.12, true)
	ci.draw_circle(c + Vector2(0, r * 0.45), r * 0.1, PINK_L)


static func _boot(ci: CanvasItem, c: Vector2, r: float) -> void:
	var p := PackedVector2Array([c + Vector2(-r * 0.4, -r * 0.9), c + Vector2(r * 0.2, -r * 0.9), c + Vector2(r * 0.2, r * 0.15), c + Vector2(r * 0.85, r * 0.35),
		c + Vector2(r * 0.85, r * 0.8), c + Vector2(-r * 0.4, r * 0.8)])
	_outline_poly(ci, p, PINK, Color("#d05a8c"), r * 0.08)
	ci.draw_rect(Rect2(c + Vector2(-r * 0.4, -r * 0.9), Vector2(r * 0.6, r * 0.22)), Color("#fff4e0"))


static func _cape(ci: CanvasItem, c: Vector2, r: float) -> void:
	var p := PackedVector2Array([c + Vector2(-r * 0.4, -r * 0.9), c + Vector2(r * 0.4, -r * 0.9), c + Vector2(r * 0.95, r * 0.6), c + Vector2(r * 0.4, r * 0.85),
		c + Vector2(0, r * 0.7), c + Vector2(-r * 0.4, r * 0.85), c + Vector2(-r * 0.95, r * 0.6)])
	_outline_poly(ci, p, LILAC, Color("#7a5ac0"), r * 0.08)
	ci.draw_circle(c + Vector2(0, -r * 0.8), r * 0.13, GOLD)
