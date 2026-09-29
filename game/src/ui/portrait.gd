class_name Portrait
extends Control
## Round character portrait for dialogue (drawn in code, follows the line's emotion, flaps while speaking).

var character_id := "narrator"
var emotion := "neutral"
var speaking := false
var _t := 0.0


func _init(p_size: float = 120.0) -> void:
	custom_minimum_size = Vector2(p_size, p_size)
	size = Vector2(p_size, p_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_character(id: String, emo: String) -> void:
	character_id = id
	emotion = emo
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := size.x * 0.5
	var ring := Content.character_color(character_id) if Content.characters.has(character_id) else Color("#ffc4e0")
	if character_id == "princess":
		ring = Color("#ff9ad5")
	elif character_id == "narrator":
		ring = Color("#ffd86a")
	# glow + ring + backing
	draw_circle(c, r, ring.darkened(0.15))
	draw_circle(c, r - 5.0, ring.lightened(0.55))
	var bob := sin(_t * 3.0) * 1.5
	var emo: Dictionary = RigBase.EMOTIONS.get(RigBase.EMOTION_ALIASES.get(emotion, emotion), RigBase.EMOTIONS["neutral"])
	var smile: float = emo.smile
	var open: float = emo.mouth_open
	if speaking:
		open = maxf(open, 0.25 + 0.5 * absf(sin(_t * 13.0)))
	var happy_eyes: float = emo.happy
	match character_id:
		"princess": _draw_princess(c, r, bob, smile, open, happy_eyes)
		"lumi", "luna": _draw_unicorn(c, r, bob, smile, open, happy_eyes)
		"clover": _draw_rabbit(c, r, bob, smile, open, happy_eyes)
		_: _draw_narrator(c, r)


func _eye(p: Vector2, s: float, col: Color, happy: float) -> void:
	if happy > 0.5:
		draw_arc(p + Vector2(0, s * 0.3), s * 0.85, deg_to_rad(200), deg_to_rad(340), 10, Color("#3a1f4a"), s * 0.32, true)
		return
	draw_circle(p, s, Color("#2a1638"))
	draw_circle(p, s * 0.86, col)
	draw_circle(p, s * 0.5, Color("#1c0d28"))
	draw_circle(p + Vector2(-s * 0.3, -s * 0.3), s * 0.3, Color.WHITE)
	draw_circle(p + Vector2(s * 0.28, s * 0.3), s * 0.13, Color(1, 1, 1, 0.9))


func _mouth(p: Vector2, w: float, smile: float, open: float) -> void:
	var col := Color("#c04a68")
	if open > 0.12:
		var h := w * (0.25 + 0.6 * open)
		var pts := PackedVector2Array()
		for i in 13:
			var t := float(i) / 12.0
			pts.append(p + Vector2(lerpf(-w, w, t), -sin(t * PI) * w * 0.05 - (0.0)))
		for i in 13:
			var t := 1.0 - float(i) / 12.0
			pts.append(p + Vector2(lerpf(-w, w, t), sin(t * PI) * h))
		draw_colored_polygon(pts, Color("#7a1f3a"))
		draw_circle(p + Vector2(0, h * 0.55), w * 0.32, Color("#ff8fa8"))
	else:
		draw_arc(p + Vector2(0, -w * 0.4 * smile + w * 0.1), w * 0.9, deg_to_rad(30), deg_to_rad(150), 12, col, w * 0.16, true)


func _draw_princess(c: Vector2, r: float, bob: float, smile: float, open: float, happy: float) -> void:
	var app := GameState.appearance()
	var skin := Color(PrincessRig.opt("skin", app.get("skin", "honey")).get("color", "#c98b57"))
	var hair := Color(PrincessRig.opt("hair_color", app.get("hair_color", "chestnut")).get("color", "#8b4f2a"))
	var eye := Color(PrincessRig.opt("face", app.get("face", "sparkle")).get("eye", "#6b3f2a"))
	c += Vector2(0, bob)
	draw_circle(c + Vector2(0, r * 0.05), r * 0.86, hair.darkened(0.1))
	draw_circle(c + Vector2(0, r * 0.12), r * 0.7, skin)
	draw_arc(c + Vector2(0, -r * 0.05), r * 0.74, deg_to_rad(190), deg_to_rad(350), 20, hair, r * 0.3, true)
	for i in 5:
		var a := deg_to_rad(215.0 + i * 22.0)
		draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.55 + Vector2(0, -r * 0.02), r * 0.14, hair)
	_eye(c + Vector2(-r * 0.27, r * 0.1), r * 0.12, eye, happy)
	_eye(c + Vector2(r * 0.27, r * 0.1), r * 0.12, eye, happy)
	draw_circle(c + Vector2(-r * 0.42, r * 0.3), r * 0.09, Color(1, 0.5, 0.6, 0.55))
	draw_circle(c + Vector2(r * 0.42, r * 0.3), r * 0.09, Color(1, 0.5, 0.6, 0.55))
	_mouth(c + Vector2(0, r * 0.38), r * 0.16, smile, open)
	# tiara
	draw_arc(c + Vector2(0, -r * 0.05), r * 0.6, deg_to_rad(215), deg_to_rad(325), 12, Color("#ffc94d"), r * 0.08, true)
	draw_circle(c + Vector2(0, -r * 0.62), r * 0.07, Color("#ff7fb6"))


func _draw_unicorn(c: Vector2, r: float, bob: float, smile: float, open: float, happy: float) -> void:
	var is_luna := character_id == "luna"
	var coat := Color("#fff8ff") if not is_luna else Color("#f4eeff")
	var eye := Color("#7a4dd8") if not is_luna else Color("#4d7ad8")
	var mane_a := Color("#ff8fd2") if not is_luna else Color("#6ec6f5")
	var mane_b := Color("#b58cf2")
	c += Vector2(0, bob)
	for sx in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([c + Vector2(sx * r * 0.32, -r * 0.35), c + Vector2(sx * r * 0.62, -r * 0.92), c + Vector2(sx * r * 0.72, -r * 0.3)]), coat)
		draw_colored_polygon(PackedVector2Array([c + Vector2(sx * r * 0.4, -r * 0.42), c + Vector2(sx * r * 0.6, -r * 0.78), c + Vector2(sx * r * 0.63, -r * 0.4)]), Color("#ffc4e4"))
	draw_circle(c + Vector2(0, r * 0.08), r * 0.72, coat)
	draw_circle(c + Vector2(0, r * 0.5), r * 0.36, Color("#ffe0f0"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.1, -r * 0.55), c + Vector2(0, -r * 1.05), c + Vector2(r * 0.1, -r * 0.55)]), Color("#ffe27a"))
	for i in 3:
		draw_circle(c + Vector2((i - 1) * r * 0.22, -r * 0.5), r * 0.16, [mane_a, mane_b, Color("#6ec6f5")][i])
	_eye(c + Vector2(-r * 0.3, r * 0.05), r * 0.15, eye, happy)
	_eye(c + Vector2(r * 0.3, r * 0.05), r * 0.15, eye, happy)
	draw_circle(c + Vector2(-r * 0.5, r * 0.28), r * 0.09, Color(1, 0.55, 0.75, 0.55))
	draw_circle(c + Vector2(r * 0.5, r * 0.28), r * 0.09, Color(1, 0.55, 0.75, 0.55))
	draw_circle(c + Vector2(-r * 0.09, r * 0.44), r * 0.035, Color("#c46a9a"))
	draw_circle(c + Vector2(r * 0.09, r * 0.44), r * 0.035, Color("#c46a9a"))
	_mouth(c + Vector2(0, r * 0.6), r * 0.14, smile, open)


func _draw_rabbit(c: Vector2, r: float, bob: float, smile: float, open: float, happy: float) -> void:
	var fur := Color("#f6e6d4")
	c += Vector2(0, bob)
	for sx in [-1.0, 1.0]:
		draw_circle(c + Vector2(sx * r * 0.28, -r * 0.7), r * 0.2, fur)
		draw_line(c + Vector2(sx * r * 0.28, -r * 0.5), c + Vector2(sx * r * 0.28, -r * 0.9), fur, r * 0.34, true)
		draw_line(c + Vector2(sx * r * 0.28, -r * 0.55), c + Vector2(sx * r * 0.28, -r * 0.85), Color("#ffb5cf"), r * 0.14, true)
	draw_circle(c + Vector2(0, r * 0.12), r * 0.7, fur)
	draw_circle(c + Vector2(0, r * 0.4), r * 0.3, Color("#fffaf3"))
	_eye(c + Vector2(-r * 0.3, r * 0.05), r * 0.13, Color("#3a2a40"), happy)
	_eye(c + Vector2(r * 0.3, r * 0.05), r * 0.13, Color("#3a2a40"), happy)
	draw_circle(c + Vector2(0, r * 0.3), r * 0.06, Color("#ff9ab8"))
	_mouth(c + Vector2(0, r * 0.5), r * 0.12, smile, open)


func _draw_narrator(c: Vector2, r: float) -> void:
	# Flutter-style butterfly = the storyteller
	IconArt.draw(self, "butterfly", c + Vector2(0, sin(_t * 2.0) * 2.0), r * 0.62)
