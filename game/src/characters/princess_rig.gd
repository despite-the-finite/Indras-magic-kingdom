class_name PrincessRig
extends RigBase
## The player's princess. Built entirely from the appearance dictionary (see data/customization.json),
## so every combination of skin / face / hair / dress / boots / crown / cape / accessory works.
## Height ~1.55 m, big head (chibi proportions), faces the camera in 3/4 view.
##
## Joint convention (local, character faces +Z):  arm/leg rotation.x < 0 swings forward,
## arm rotation.z opens the arm outward (+ for the +X arm, - for the -X arm). Her right hand is at -X.

var appearance: Dictionary = {}

var body: Node3D
var torso: Node3D
var head: Node3D
var arm_l: Node3D        # +X side
var arm_r: Node3D        # -X side (wand hand)
var leg_l: Node3D
var leg_r: Node3D
var skirt: Node3D
var cape_pivot: Node3D
var wand_tip: Node3D
var crown_root: Node3D
var hair_sway: Array[Node3D] = []
var wings: Array[Node3D] = []
var clip_butterfly: Node3D
var orbit_butterflies: Node3D
var _crown_fx: Node3D
var _crown_level := -1
var _phase := 0.0
var _skirt_kind := "gown"
var _skin: Color
var _hair: Color
var _hair_style := "long"
var _lag := 0.0


func _init(app: Dictionary = {}) -> void:
	appearance = app.duplicate(true)
	character_id = "princess"
	oneshots = {
		"wave": 1.7, "cast": 0.9, "celebrate": 2.0, "hug": 1.8, "curious": 1.9, "surprised": 1.0,
		"giggle": 1.5, "dance": 4.0, "point": 1.6, "pet": 1.2, "brush": 1.2, "nod": 0.8, "fall": 1.2,
		"happy": 1.3, "cheer": 1.2, "bow": 1.5, "spin": 1.1, "wonder": 1.6, "feed": 1.2, "push": 1.1,
	}


static func opt(category: String, id: String) -> Dictionary:
	for o in Content.customization.get("options", {}).get(category, []):
		if o.id == id:
			return o
	var list: Array = Content.customization.get("options", {}).get(category, [])
	return list[0] if list.size() > 0 else {}


func _a(key: String) -> Dictionary:
	return opt(key, appearance.get(key, Content.customization.get("default_appearance", {}).get(key, "")))


func apply_appearance(app: Dictionary) -> void:
	## Rebuild in place (used by the customization screen for instant preview).
	appearance = app.duplicate(true)
	for c in get_children():
		c.queue_free()
	hair_sway.clear()
	wings.clear()
	_crown_fx = null
	_crown_level = -1
	_build()
	set_crown_level(GameState.crown_level())
	set_emotion(emotion)


# =============================================================================
# construction
# =============================================================================
func _build() -> void:
	var skin_o := _a("skin")
	var face_o := _a("face")
	var hair_o := _a("hair_color")
	var dress_o := _a("dress")
	var boots_o := _a("boots")
	var cape_o := _a("cape")

	_skin = Color(skin_o.get("color", "#c98b57"))
	_hair = Color(hair_o.get("color", "#8b4f2a"))
	_hair_style = String(appearance.get("hair_style", "long"))
	var c1 := Color(dress_o.get("c1", "#ff8fbf"))
	var c2 := Color(dress_o.get("c2", "#ffd6ec"))
	_skirt_kind = String(dress_o.get("type", "gown"))
	var boot_c := Color(boots_o.get("color", "#ff8fbf"))
	var gold := Mat.GOLD

	var skin_m := Mat.toon(_skin, {"outline": 0.010, "shade_tint": _skin.darkened(0.35).lerp(Mat.LILAC, 0.3), "rim_color": _skin.lightened(0.5), "rim_amount": 0.4})
	var hair_m := Mat.toon_grad(_hair.darkened(0.12), _hair.lightened(0.18), -0.2, 0.55, {"outline": 0.011, "rim_color": _hair.lightened(0.6), "rim_amount": 0.55, "glitter": 0.10, "shade_tint": _hair.darkened(0.3).lerp(Mat.PLUM, 0.4)})
	var c1_m := Mat.toon_grad(c1, c1.lightened(0.18), 0.1, 0.9, {"outline": 0.010, "glitter": 0.22})
	var c2_m := Mat.toon(c2, {"outline": 0.008, "glitter": 0.15})
	var boot_m := Mat.toon(boot_c, {"outline": 0.010})
	var gold_m := Mat.glowing(gold, 0.35, {"outline": 0.008, "rim_amount": 0.7})
	var white_m := Mat.toon(Color("#fdf6ff"), {"outline": 0.008})

	# ---- root pivots -----------------------------------------------------------
	body = Build.pivot(self, Vector3.ZERO, "Body")

	# ---- legs ----------------------------------------------------------------------
	var leg_col := c2 if _skirt_kind == "pants" else Color("#fdf6ff")
	var leg_m := Mat.toon(leg_col, {"outline": 0.008})
	leg_l = _make_leg(Vector3(0.095, 0.44, 0), leg_m, boot_m, _skirt_kind == "pants")
	leg_r = _make_leg(Vector3(-0.095, 0.44, 0), leg_m, boot_m, _skirt_kind == "pants")

	# ---- torso ---------------------------------------------------------------------
	torso = Build.pivot(body, Vector3(0, 0.66, 0), "Torso")
	Build.capsule(torso, 0.155, 0.42, Vector3(0, 0.12, 0), c1_m)
	Build.cyl(torso, 0.055, 0.06, 0.09, Vector3(0, 0.36, 0), skin_m, 12)   # neck
	# sash / belt
	var sash_c := c2 if _skirt_kind != "pants" else Color("#8a5a3c")
	Build.torus(torso, 0.145, 0.185, Vector3(0, -0.02, 0), Mat.toon(sash_c, {"outline": 0.008}), Vector3.ZERO)
	# back bow
	if _skirt_kind != "pants":
		Build.sphere(torso, 0.05, Vector3(-0.05, -0.02, -0.17), c2_m, Vector3(1.3, 0.8, 0.7))
		Build.sphere(torso, 0.05, Vector3(0.05, -0.02, -0.17), c2_m, Vector3(1.3, 0.8, 0.7))
		Build.sphere(torso, 0.03, Vector3(0, -0.02, -0.175), c2_m)
	# collar
	Build.torus(torso, 0.095, 0.135, Vector3(0, 0.29, 0.0), c2_m, Vector3.ZERO)

	# ---- skirt ---------------------------------------------------------------------
	skirt = Build.pivot(body, Vector3(0, 0.66, 0), "Skirt")
	match _skirt_kind:
		"gown":
			Build.cyl(skirt, 0.15, 0.44, 0.52, Vector3(0, -0.27, 0), Mat.toon_grad(c1, c1.lightened(0.22), -0.5, 0.0, {"outline": 0.010, "glitter": 0.3, "rim_amount": 0.5}), 32)
			Build.torus(skirt, 0.405, 0.465, Vector3(0, -0.5, 0), c2_m, Vector3.ZERO, 36)
			for i in 14:
				var a := float(i) / 14.0 * TAU
				Build.sphere(skirt, 0.055, Vector3(cos(a) * 0.435, -0.5, sin(a) * 0.435), c2_m, Vector3(1.0, 0.75, 1.0), 12)
		"tutu":
			Build.cyl(skirt, 0.15, 0.27, 0.22, Vector3(0, -0.12, 0), c1_m, 24)
			for i in 4:
				var rr := 0.30 + i * 0.055
				var mat := c2_m if i % 2 == 0 else Mat.toon(c1.lerp(c2, 0.5), {"outline": 0.008, "glitter": 0.25})
				Build.cyl(skirt, rr * 0.86, rr, 0.055, Vector3(0, -0.13 - i * 0.075, 0), mat, 32, Vector3(0, i * 0.4, 0))
				for k in 10:
					var a := float(k) / 10.0 * TAU + i * 0.3
					Build.sphere(skirt, 0.045, Vector3(cos(a) * rr, -0.13 - i * 0.075, sin(a) * rr), mat, Vector3(1, 0.6, 1), 10)
		"pants":
			Build.cyl(skirt, 0.16, 0.27, 0.26, Vector3(0, -0.12, 0), c1_m, 24)
			Build.torus(skirt, 0.24, 0.29, Vector3(0, -0.245, 0), Mat.toon(Color("#8a5a3c"), {"outline": 0.008}), Vector3.ZERO)

	# ---- arms ----------------------------------------------------------------------
	arm_l = _make_arm(Vector3(0.185, 0.87, 0), c2_m, skin_m, c1_m)
	arm_r = _make_arm(Vector3(-0.185, 0.87, 0), c2_m, skin_m, c1_m)

	# ---- head ----------------------------------------------------------------------
	head = Build.pivot(body, Vector3(0, 1.235, 0), "Head")
	Build.sphere(head, 0.30, Vector3.ZERO, skin_m, Vector3(1.0, 0.97, 1.0), 32)
	# ears
	Build.sphere(head, 0.05, Vector3(0.29, -0.03, 0.0), skin_m, Vector3(0.55, 1.0, 0.8), 12)
	Build.sphere(head, 0.05, Vector3(-0.29, -0.03, 0.0), skin_m, Vector3(0.55, 1.0, 0.8), 12)
	_build_face(face_o, hair_o, skin_o)
	_build_hair(hair_m, c2_m)
	_build_crown(gold_m, white_m, c2)
	_build_cape(cape_o, gold_m)
	_build_accessory(gold_m, c2_m)
	set_crown_level(GameState.crown_level() if GameState else 0)


func _make_leg(pos: Vector3, leg_m: Material, boot_m: Material, pants: bool) -> Node3D:
	var p := Build.pivot(body, pos)
	Build.capsule(p, 0.05 if not pants else 0.056, 0.40, Vector3(0, -0.19, 0), leg_m)
	Build.cyl(p, 0.068, 0.078, 0.17, Vector3(0, -0.32, 0), boot_m, 16)
	Build.sphere(p, 0.085, Vector3(0, -0.385, 0.035), boot_m, Vector3(1.0, 0.62, 1.45), 14)
	Build.torus(p, 0.062, 0.088, Vector3(0, -0.24, 0), Mat.toon(Color("#fdf6ff"), {"outline": 0.006}), Vector3.ZERO, 16)
	return p


func _make_arm(pos: Vector3, sleeve_m: Material, skin_m: Material, cuff_m: Material) -> Node3D:
	var p := Build.pivot(body, pos)
	Build.capsule(p, 0.042, 0.27, Vector3(0, -0.12, 0), skin_m)
	Build.sphere(p, 0.075, Vector3(0, 0.0, 0), sleeve_m, Vector3(1.0, 0.95, 1.0), 16)        # puffy sleeve
	Build.sphere(p, 0.052, Vector3(0, -0.27, 0), skin_m, Vector3.ONE, 14)                    # hand
	return p


func _build_face(face_o: Dictionary, hair_o: Dictionary, skin_o: Dictionary) -> void:
	face_mat = Mat.face_material()
	face_mat.set_shader_parameter("eye_color", Color(face_o.get("eye", "#6b3f2a")))
	face_mat.set_shader_parameter("blush_color", Color(face_o.get("blush", "#ff8fa8")))
	face_mat.set_shader_parameter("freckles", 1.0 if face_o.get("freckles", false) else 0.0)
	face_mat.set_shader_parameter("lashes", float(face_o.get("lashes", 1.0)))
	face_mat.set_shader_parameter("brow_color", _hair.darkened(0.25))
	face_mat.set_shader_parameter("nose_color", _skin.darkened(0.3).lerp(Color("#a04a3a"), 0.25))
	Build.sphere(head, 0.305, Vector3.ZERO, face_mat, Vector3(1.0, 0.97, 1.0), 36)


func _build_hair(hair_m: Material, accent_m: Material) -> void:
	# common: back/top cap + fringe
	var cap := Build.sphere(head, 0.338, Vector3(0, 0.05, -0.10), hair_m, Vector3(1.0, 1.03, 1.0), 32)
	cap.name = "HairCap"
	if _hair_style != "puffs" and _hair_style != "curls":
		for i in 7:
			var t := float(i) / 6.0 - 0.5                 # -0.5 .. 0.5
			var az := t * deg_to_rad(96.0)
			var el := deg_to_rad(52.0 - absf(t) * 16.0)
			var dir := Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el))
			var s := Build.sphere(head, 0.088, dir * 0.292, hair_m, Vector3(1.25, 0.95, 0.75), 14)
			s.rotation = Vector3(0, az, -t * 0.7)
	elif _hair_style == "puffs":
		for i in 4:
			var t := float(i) / 3.0 - 0.5
			var az := t * deg_to_rad(70.0)
			var el := deg_to_rad(56.0)
			var dir := Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el))
			Build.sphere(head, 0.078, dir * 0.292, hair_m, Vector3(1.25, 0.9, 0.7), 12)

	match _hair_style:
		"long":
			var sw := Build.pivot(head, Vector3(0, 0.10, -0.15))
			hair_sway.append(sw)
			Build.capsule(sw, 0.22, 0.86, Vector3(0, -0.40, -0.02), hair_m, Vector3.ZERO, Vector3(1.22, 1.0, 0.62))
			for k in 5:
				Build.sphere(sw, 0.1, Vector3(-0.2 + k * 0.1, -0.83 + (0.03 if k % 2 == 0 else 0.0), -0.02), hair_m, Vector3(1, 1, 0.8), 12)
			for sx in [-1.0, 1.0]:
				var lock := Build.pivot(head, Vector3(sx * 0.27, 0.0, 0.03))
				hair_sway.append(lock)
				Build.capsule(lock, 0.062, 0.5, Vector3(0, -0.24, 0), hair_m, Vector3(0, 0, sx * -0.05))
				Build.sphere(lock, 0.075, Vector3(0, -0.5, 0), hair_m, Vector3.ONE, 12)
		"pigtails":
			for sx in [-1.0, 1.0]:
				var pv := Build.pivot(head, Vector3(sx * 0.32, 0.02, -0.06))
				hair_sway.append(pv)
				Build.sphere(pv, 0.13, Vector3(sx * 0.04, 0.02, 0), hair_m, Vector3.ONE, 16)
				Build.sphere(pv, 0.05, Vector3(0, 0.05, 0.02), accent_m, Vector3.ONE, 10)
				Build.capsule(pv, 0.085, 0.46, Vector3(sx * 0.05, -0.28, 0), hair_m, Vector3(0, 0, sx * -0.1))
				Build.sphere(pv, 0.09, Vector3(sx * 0.07, -0.52, 0), hair_m, Vector3.ONE, 12)
		"bun":
			var bun := Build.pivot(head, Vector3(0, 0.40, -0.10))
			hair_sway.append(bun)
			Build.sphere(bun, 0.175, Vector3.ZERO, hair_m, Vector3.ONE, 20)
			Build.torus(bun, 0.16, 0.20, Vector3(0, -0.08, 0), accent_m, Vector3.ZERO, 20)
			for k in 8:
				var a := float(k) / 8.0 * TAU
				Build.sphere(bun, 0.05, Vector3(cos(a) * 0.14, 0.05 + sin(a * 2.0) * 0.02, sin(a) * 0.14), hair_m, Vector3.ONE, 8)
			for sx in [-1.0, 1.0]:
				var lock := Build.pivot(head, Vector3(sx * 0.29, 0.02, 0.04))
				hair_sway.append(lock)
				Build.capsule(lock, 0.05, 0.28, Vector3(0, -0.12, 0), hair_m)
		"puffs":
			for sx in [-1.0, 1.0]:
				var pv := Build.pivot(head, Vector3(sx * 0.29, 0.29, -0.04))
				hair_sway.append(pv)
				Build.sphere(pv, 0.2, Vector3.ZERO, hair_m, Vector3.ONE, 20)
				for k in 9:
					var a := float(k) / 9.0 * TAU
					var b := float(k % 3) / 3.0 * PI - 0.6
					Build.sphere(pv, 0.09, Vector3(cos(a) * cos(b), sin(b), sin(a) * cos(b)) * 0.17, hair_m, Vector3.ONE, 10)
				Build.torus(pv, 0.13, 0.17, Vector3(sx * -0.13, -0.11, 0), accent_m, Vector3(0, 0, sx * 0.9), 16)
		"curls":
			for k in 16:
				var az := deg_to_rad(lerpf(-190.0, 190.0, float(k) / 15.0))
				var el := deg_to_rad(20.0 + 50.0 * absf(sin(float(k) * 1.7)))
				var dir := Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el))
				if dir.z > 0.55 and dir.y < 0.75:
					continue
				Build.sphere(head, 0.12, dir * 0.33 + Vector3(0, 0.03, -0.06), hair_m, Vector3.ONE, 12)
			for sx in [-1.0, 1.0]:
				var lock := Build.pivot(head, Vector3(sx * 0.31, -0.03, 0.0))
				hair_sway.append(lock)
				for k in 4:
					Build.sphere(lock, 0.085 - k * 0.006, Vector3(sx * 0.02 * (k % 2), -0.06 - k * 0.11, 0.0), hair_m, Vector3.ONE, 10)
			for i in 5:
				var t := float(i) / 4.0 - 0.5
				var az := t * deg_to_rad(80.0)
				var el := deg_to_rad(58.0)
				var dir := Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el))
				Build.sphere(head, 0.075, dir * 0.30, hair_m, Vector3(1.1, 0.9, 0.8), 10)
		"braid":
			var sw := Build.pivot(head, Vector3(0.12, 0.05, -0.2))
			hair_sway.append(sw)
			Build.capsule(sw, 0.19, 0.5, Vector3(-0.1, -0.2, 0.0), hair_m, Vector3.ZERO, Vector3(1.1, 1.0, 0.65))
			for k in 8:
				Build.sphere(sw, 0.075 - k * 0.003, Vector3(0.02 + 0.03 * (k % 2 * 2 - 1), -0.32 - k * 0.095, 0.0), hair_m, Vector3(1.0, 1.25, 1.0), 12)
			Build.sphere(sw, 0.05, Vector3(0.02, -1.11, 0.0), accent_m, Vector3.ONE, 10)
			Build.sphere(sw, 0.06, Vector3(-0.02, -0.28, 0.02), accent_m, Vector3(1.2, 0.8, 0.8), 10)


func _build_crown(gold_m: Material, white_m: Material, c2: Color) -> void:
	crown_root = Build.pivot(head, Vector3(0, 0.22, 0.02), "Crown")
	var kind := String(appearance.get("crown", "tiara"))
	var ring_r := 0.285
	match kind:
		"crown":
			Build.torus(crown_root, ring_r - 0.018, ring_r + 0.018, Vector3(0, 0.0, 0), gold_m, Vector3.ZERO, 30)
			for i in 7:
				var a := float(i) / 7.0 * TAU
				var h := 0.13 + (0.05 if i % 2 == 0 else 0.0)
				Build.cone(crown_root, 0.04, h, Vector3(cos(a) * ring_r, h * 0.5, sin(a) * ring_r), gold_m, Vector3.ZERO, 10)
				Build.sphere(crown_root, 0.022, Vector3(cos(a) * ring_r, h + 0.005, sin(a) * ring_r), Mat.glowing([Mat.PINK, Mat.SKY, Mat.MINT][i % 3], 1.0), Vector3.ONE, 8)
		"flowers":
			for i in 11:
				var a := float(i) / 11.0 * TAU
				var fc: Color = [Mat.PINK, Color.WHITE, Mat.SUN, Mat.LILAC][i % 4]
				var fp := Build.pivot(crown_root, Vector3(cos(a) * ring_r, 0.01, sin(a) * ring_r))
				for k in 5:
					var pa := float(k) / 5.0 * TAU
					Build.sphere(fp, 0.032, Vector3(cos(pa) * 0.034, sin(pa) * 0.034, 0.0).rotated(Vector3.UP, -a + PI * 0.5) + Vector3.ZERO, Mat.toon(fc, {"outline": 0.005}), Vector3.ONE, 8)
				Build.sphere(fp, 0.02, Vector3.ZERO, Mat.toon(Mat.SUN.darkened(0.1), {}), Vector3.ONE, 8)
				Build.sphere(crown_root, 0.03, Vector3(cos(a + 0.28) * ring_r, -0.01, sin(a + 0.28) * ring_r), Mat.toon(Mat.LEAF, {}), Vector3(1.5, 0.6, 1.0), 8)
		"star_circlet":
			_gold_arc(crown_root, gold_m, ring_r, 75.0)
			var st := Build.pivot(crown_root, Vector3(0, 0.09, ring_r * 0.98))
			var sm := MeshInstance3D.new()
			sm.mesh = Build.star_mesh(0.11, 0.05, 0.035)
			sm.material_override = Mat.glowing(Mat.SUN, 1.6, {"outline": 0.006})
			st.add_child(sm)
			sm.name = "CrownStar"
		"moon_tiara":
			_gold_arc(crown_root, gold_m, ring_r, 75.0)
			var mp := Build.pivot(crown_root, Vector3(0, 0.10, ring_r * 0.98))
			var mm := MeshInstance3D.new()
			mm.mesh = Build.crescent(0.10, 0.045, 0.035)
			mm.material_override = Mat.glowing(Color("#fff0b0"), 1.2, {"outline": 0.006})
			mm.rotation = Vector3(0, 0, deg_to_rad(90.0))
			mp.add_child(mm)
		_:  # tiara
			_gold_arc(crown_root, gold_m, ring_r, 78.0)
			for i in 5:
				var t := float(i) / 4.0 - 0.5
				var a := PI * 0.5 - t * deg_to_rad(96.0)
				var h := 0.06 + 0.075 * (1.0 - absf(t) * 1.6)
				Build.cone(crown_root, 0.028, h, Vector3(cos(a) * ring_r, h * 0.5, sin(a) * ring_r), gold_m, Vector3.ZERO, 8)
			var gem := Build.sphere(crown_root, 0.035, Vector3(0, 0.055, ring_r + 0.005), Mat.glowing(Mat.PINK, 1.6), Vector3.ONE, 12)
			gem.name = "TiaraGem"


func _gold_arc(parent: Node3D, mat: Material, r: float, half_deg: float) -> void:
	var n := 13
	for i in n:
		var t := float(i) / (n - 1) - 0.5
		var a := PI * 0.5 - t * deg_to_rad(half_deg * 2.0)
		Build.sphere(parent, 0.026, Vector3(cos(a) * r, 0.0, sin(a) * r), mat, Vector3.ONE, 8)


func _build_cape(cape_o: Dictionary, gold_m: Material) -> void:
	if cape_o.get("id", "none") == "none":
		return
	var cc := Color(cape_o.get("color", "#ff6fae"))
	cape_pivot = Build.pivot(body, Vector3(0, 1.0, -0.15), "Cape")
	var cm := MeshInstance3D.new()
	cm.mesh = Build.cape_mesh(0.30, 0.66, 0.86)
	cm.material_override = Mat.toon_grad(cc, cc.lightened(0.3), 0.0, 0.9, {"two_sided": true, "outline": false, "wind": 0.10, "wind_speed": 2.0, "sway_height": 0.9, "glitter": 0.2, "gradient_amount": 1.0})
	cm.rotation = Vector3(0, 0, PI)
	cape_pivot.add_child(cm)
	# clasp
	Build.sphere(body, 0.028, Vector3(0.10, 1.0, 0.13), gold_m, Vector3.ONE, 10)
	Build.sphere(body, 0.028, Vector3(-0.10, 1.0, 0.13), gold_m, Vector3.ONE, 10)


func _build_accessory(gold_m: Material, accent_m: Material) -> void:
	var kind := String(appearance.get("accessory", "wand_star"))
	# The wand is always in her hand for casting; the accessory chooses its style or adds something else.
	var hand := arm_r
	var wand := Build.pivot(hand, Vector3(0, -0.27, 0.02))
	wand.rotation = Vector3(deg_to_rad(-55.0), 0, 0)
	Build.cyl(wand, 0.011, 0.014, 0.44, Vector3(0, 0.16, 0), Mat.toon(Color("#fff4e0"), {"outline": 0.005}), 8)
	wand_tip = Build.pivot(wand, Vector3(0, 0.40, 0))
	var tip_mat := Mat.glowing(Mat.SUN, 1.8, {"outline": 0.005})
	if kind == "wand_heart":
		var h := Build.sphere(wand_tip, 0.05, Vector3(-0.03, 0.02, 0), Mat.glowing(Mat.PINK, 1.8), Vector3.ONE, 10)
		h.name = "TipL"
		Build.sphere(wand_tip, 0.05, Vector3(0.03, 0.02, 0), Mat.glowing(Mat.PINK, 1.8), Vector3.ONE, 10)
		Build.cone(wand_tip, 0.06, 0.09, Vector3(0, -0.03, 0), Mat.glowing(Mat.PINK, 1.8), Vector3(PI, 0, 0), 10)
	else:
		var sm := MeshInstance3D.new()
		sm.mesh = Build.star_mesh(0.085, 0.038, 0.03)
		sm.material_override = tip_mat
		sm.name = "TipStar"
		wand_tip.add_child(sm)
	Fx.glow_sprite(wand_tip, Vector3.ZERO, Color(1, 0.9, 0.55, 0.55), 0.42)
	match kind:
		"wings":
			for sx in [-1.0, 1.0]:
				var wp := Build.pivot(body, Vector3(sx * 0.05, 1.0, -0.17))
				var wm := MeshInstance3D.new()
				wm.mesh = Build.wing_mesh(0.6)
				wm.material_override = Mat.toon(Color("#c8f0ff"), {"two_sided": true, "emission_color": Color("#b8e8ff"), "emission_energy": 0.6, "glitter": 0.7, "rim_color": Color.WHITE, "rim_amount": 0.8})
				wm.scale = Vector3(sx, 1.0, 1.0)
				wp.add_child(wm)
				wp.rotation = Vector3(0, sx * deg_to_rad(-25.0), 0)
				wings.append(wp)
		"butterfly":
			clip_butterfly = Build.pivot(head, Vector3(0.22, 0.22, 0.2))
			for sx in [-1.0, 1.0]:
				var wm := MeshInstance3D.new()
				wm.mesh = Build.wing_mesh(0.12)
				wm.material_override = Mat.toon(Mat.LILAC, {"two_sided": true, "emission_color": Mat.PINK, "emission_energy": 0.5})
				wm.scale = Vector3(sx, 1.0, 1.0)
				clip_butterfly.add_child(wm)
		"necklace":
			Build.torus(torso, 0.095, 0.108, Vector3(0, 0.30, 0.03), gold_m, Vector3(deg_to_rad(15), 0, 0), 20)
			var ps := MeshInstance3D.new()
			ps.mesh = Build.star_mesh(0.045, 0.02, 0.02)
			ps.material_override = Mat.glowing(Mat.SUN, 1.4)
			ps.position = Vector3(0, 0.185, 0.145)
			torso.add_child(ps)


# =============================================================================
# crown progression (stars -> visible jewels)
# =============================================================================
func set_crown_level(level: int) -> void:
	if crown_root == null or level == _crown_level:
		return
	_crown_level = level
	if _crown_fx and is_instance_valid(_crown_fx):
		_crown_fx.queue_free()
	_crown_fx = Build.pivot(crown_root, Vector3.ZERO, "CrownFx")
	orbit_butterflies = null
	if level >= 1:
		var star := MeshInstance3D.new()
		star.mesh = Build.star_mesh(0.07, 0.03, 0.03)
		star.material_override = Mat.glowing(Mat.SUN, 2.2, {"pulse": 1.0})
		star.position = Vector3(0, 0.18, 0.0)
		_crown_fx.add_child(star)
		Fx.glow_sprite(_crown_fx, Vector3(0, 0.18, 0.02), Color(1, 0.9, 0.5, 0.6), 0.38)
	if level >= 2:
		var cols := [Mat.PINK, Mat.SKY, Mat.MINT, Mat.LILAC]
		for i in 4:
			var a := PI * 0.5 + (float(i) - 1.5) * 0.62
			Build.sphere(_crown_fx, 0.03, Vector3(cos(a) * 0.29, 0.03, sin(a) * 0.29), Mat.glowing(cols[i], 2.0, {"pulse": 0.6}), Vector3.ONE, 10)
	if level >= 3:
		Fx.aura(_crown_fx, Color(1, 0.92, 0.6), 12, 0.32)
	if level >= 4:
		orbit_butterflies = Build.pivot(_crown_fx, Vector3(0, 0.18, 0))
		for k in 2:
			var bp := Build.pivot(orbit_butterflies, Vector3(0.36 * (1.0 if k == 0 else -1.0), 0.02 * k, 0))
			for sx in [-1.0, 1.0]:
				var wm := MeshInstance3D.new()
				wm.mesh = Build.wing_mesh(0.10)
				wm.material_override = Mat.toon([Mat.PINK, Mat.SKY][k], {"two_sided": true, "emission_color": [Mat.PINK, Mat.SKY][k], "emission_energy": 0.8})
				wm.scale = Vector3(sx, 1.0, 1.0)
				bp.add_child(wm)
	if level >= 5:
		var rb := MeshInstance3D.new()
		rb.mesh = Build.arc_ribbon(0.34, 0.09, 180.0, 40)
		rb.material_override = Mat.rainbow_material()
		rb.position = Vector3(0, 0.05, -0.05)
		_crown_fx.add_child(rb)


func wand_tip_world() -> Vector3:
	return wand_tip.global_position if wand_tip else global_position + Vector3(0, 1.2, 0)


func head_world() -> Vector3:
	return head.global_position if head else global_position + Vector3(0, 1.2, 0)


# =============================================================================
# animation
# =============================================================================
func _env(p: float, a: float = 0.12, b: float = 0.15) -> float:
	return smoothstep(0.0, a, p) * smoothstep(1.0, 1.0 - b, p)


func _pose(delta: float) -> void:
	if body == null:
		return
	var t := _time
	var spd := clampf(move_speed / 5.0, 0.0, 1.4)
	var airborne := not grounded
	_phase += delta * (4.0 + spd * 8.0) * (1.0 if spd > 0.02 else 0.0)
	var s := sin(_phase)

	# ---- relaxed defaults ---------------------------------------------------------
	var body_y := 0.0
	var body_rot := Vector3.ZERO
	var body_scale := Vector3.ONE
	var torso_r := Vector3(0.0 + spd * 0.1, 0.0, sin(t * 1.3) * 0.01)
	var head_r := Vector3(-spd * 0.05, sin(t * 0.7) * 0.06, sin(t * 0.9) * 0.03)
	var al := Vector3(0.0, 0.0, 0.10 + sin(t * 1.6) * 0.02)
	var ar := Vector3(0.0, 0.0, -0.10 - sin(t * 1.6 + 1.0) * 0.02)
	var ll := Vector3.ZERO
	var lr := Vector3.ZERO
	var skirt_r := Vector3.ZERO
	var skirt_s := Vector3.ONE

	torso_r.x += sin(t * 2.2) * 0.008
	# ---- locomotion -----------------------------------------------------------------
	if airborne:
		if vertical_speed > 0.3:
			ll = Vector3(-0.55, 0, 0)
			lr = Vector3(0.35, 0, 0)
			al = Vector3(0.0, 0.0, 2.2)
			ar = Vector3(0.0, 0.0, -2.2)
			skirt_s = Vector3(0.94, 1.08, 0.94)
			head_r.x = -0.12
		else:
			ll = Vector3(-0.25, 0, 0.1)
			lr = Vector3(0.2, 0, -0.1)
			al = Vector3(0.0, 0.0, 1.35 + sin(t * 9.0) * 0.1)
			ar = Vector3(0.0, 0.0, -1.35 - sin(t * 9.0) * 0.1)
			skirt_s = Vector3(1.12, 0.9, 1.12)
			head_r.x = 0.05
	elif spd > 0.02:
		ll = Vector3(-s * 0.7 * spd, 0, 0)
		lr = Vector3(s * 0.7 * spd, 0, 0)
		al = Vector3(s * 0.6 * spd, 0.0, 0.10)
		ar = Vector3(-s * 0.6 * spd, 0.0, -0.10)
		body_y = absf(sin(_phase)) * 0.05 * spd
		skirt_r = Vector3(0.0, 0.0, s * 0.07 * spd)
		body_rot.z = s * 0.02 * spd
		head_r.z = -s * 0.03 * spd
		torso_r.y = s * 0.05 * spd
	else:
		# idle: weight shift + breathing
		body_rot.z = sin(t * 1.1) * 0.012
		body_y = sin(t * 2.2) * 0.006

	body_scale.y *= 1.0 + sin(t * 2.2) * 0.008

	# ---- looping special states ----------------------------------------------------
	if anim == "ride":
		ll = Vector3(-1.25, 0, -0.55)
		lr = Vector3(-1.25, 0, 0.55)
		al = Vector3(-0.85, 0.0, 0.3)
		ar = Vector3(-0.85, 0.0, -0.3)
		torso_r.x = 0.12 + sin(t * 9.0) * 0.03
		body_y = sin(t * 9.0) * 0.03
		skirt_r = Vector3(-0.5, 0, 0)
	elif anim == "sit":
		ll = Vector3(-1.4, 0, 0)
		lr = Vector3(-1.4, 0, 0)
		body_y = -0.22

	# ---- one-shots -----------------------------------------------------------------
	if _oneshot != "":
		var p := oneshot_progress()
		var e := _env(p)
		var tt := _oneshot_t
		match _oneshot:
			"wave":
				ar = Vector3(0.0, 0.0, lerpf(ar.z, -2.55 - sin(tt * 11.0) * 0.28, e))
				head_r.z = 0.10 * e
				torso_r.z = 0.05 * e
			"cast":
				ar = Vector3(lerpf(ar.x, -1.55, e), 0.0, lerpf(ar.z, -0.2, e))
				torso_r.x += 0.12 * e
				head_r.x = -0.05 * e
				body_y += sin(p * PI) * 0.03
			"celebrate":
				body_y += absf(sin(tt * 7.0)) * 0.26 * e
				al = Vector3(0.0, 0.0, lerpf(al.z, 2.65 + sin(tt * 14.0) * 0.2, e))
				ar = Vector3(0.0, 0.0, lerpf(ar.z, -2.65 - sin(tt * 14.0) * 0.2, e))
				yaw_offset = smoothstep(0.0, 1.0, p) * TAU * facing
				skirt_s = Vector3(1.0 + 0.1 * e, 1.0, 1.0 + 0.1 * e)
				ll.x += sin(tt * 14.0) * 0.4 * e
				lr.x -= sin(tt * 14.0) * 0.4 * e
			"hug":
				al = Vector3(lerpf(al.x, -1.35, e), lerpf(0.0, -0.35, e), lerpf(al.z, -0.6, e))
				ar = Vector3(lerpf(ar.x, -1.35, e), lerpf(0.0, 0.35, e), lerpf(ar.z, 0.6, e))
				torso_r.x += 0.22 * e
				head_r.z = 0.16 * e
				head_r.x = 0.08 * e
			"curious":
				head_r.z = 0.26 * e
				head_r.x = -0.14 * e
				ar = Vector3(lerpf(ar.x, -1.0, e), 0.0, lerpf(ar.z, -0.25, e))
				torso_r.z += sin(tt * 2.0) * 0.03 * e
			"surprised":
				body_y += sin(clampf(p * 2.0, 0.0, 1.0) * PI) * 0.13
				al = Vector3(0.0, 0.0, lerpf(al.z, 1.6, e))
				ar = Vector3(0.0, 0.0, lerpf(ar.z, -1.6, e))
				head_r.x = -0.12 * e
				torso_r.x -= 0.1 * e
			"giggle":
				torso_r.z += sin(tt * 22.0) * 0.05 * e
				head_r.z = 0.15 * e
				ar = Vector3(lerpf(ar.x, -1.95, e), 0.0, lerpf(ar.z, 0.0, e))
				body_y += absf(sin(tt * 11.0)) * 0.02 * e
			"dance":
				var w := sin(tt * 4.5)
				body_rot.z += w * 0.12 * e
				body_y += absf(w) * 0.07 * e
				al = Vector3(0.0, 0.0, lerpf(al.z, 1.6 + w * 0.6, e))
				ar = Vector3(0.0, 0.0, lerpf(ar.z, -1.6 + w * 0.6, e))
				ll.x += w * 0.35 * e
				lr.x -= w * 0.35 * e
				yaw_offset = sin(tt * 2.25) * 0.5 * e
				skirt_r.y = tt * 3.0 * e
				head_r.z = -w * 0.1 * e
			"point":
				ar = Vector3(lerpf(ar.x, -1.55, e), 0.0, lerpf(ar.z, -0.15, e))
				torso_r.x += 0.08 * e
			"pet", "brush":
				var stroke := sin(tt * (9.0 if _oneshot == "brush" else 6.0))
				ar = Vector3(lerpf(ar.x, -1.15 + stroke * 0.35, e), 0.0, lerpf(ar.z, -0.2, e))
				al = Vector3(lerpf(al.x, -0.7, e * 0.6), 0.0, al.z)
				torso_r.x += 0.16 * e
				head_r.x = 0.05 * e
			"feed":
				ar = Vector3(lerpf(ar.x, -1.4, e), 0.0, lerpf(ar.z, -0.2, e))
				al = Vector3(lerpf(al.x, -1.4, e), 0.0, lerpf(al.z, 0.2, e))
				torso_r.x += 0.1 * e
			"push":
				al = Vector3(lerpf(al.x, -1.5, e), 0.0, lerpf(al.z, -0.15, e))
				ar = Vector3(lerpf(ar.x, -1.5, e), 0.0, lerpf(ar.z, 0.15, e))
				torso_r.x += 0.3 * e
				ll.x = lerpf(ll.x, 0.5, e)
				lr.x = lerpf(lr.x, -0.5, e)
			"nod":
				head_r.x += sin(tt * 9.0) * 0.14 * e
			"fall":
				al = Vector3(0.0, 0.0, lerpf(al.z, 2.0 + sin(tt * 18.0) * 0.4, e))
				ar = Vector3(0.0, 0.0, lerpf(ar.z, -2.0 - sin(tt * 18.0) * 0.4, e))
				ll.x = lerpf(ll.x, sin(tt * 16.0) * 0.5, e)
				lr.x = lerpf(lr.x, -sin(tt * 16.0) * 0.5, e)
			"happy":
				body_y += absf(sin(tt * 8.0)) * 0.12 * e
				al = Vector3(0.0, 0.0, lerpf(al.z, 0.9, e))
				ar = Vector3(0.0, 0.0, lerpf(ar.z, -0.9, e))
			"cheer":
				al = Vector3(0.0, 0.0, lerpf(al.z, 2.7, e))
				ar = Vector3(0.0, 0.0, lerpf(ar.z, -2.7, e))
				body_y += absf(sin(tt * 10.0)) * 0.1 * e
			"bow":
				torso_r.x += 0.55 * e
				head_r.x = 0.1 * e
				ll.x = lerpf(ll.x, -0.2, e)
				lr.x = lerpf(lr.x, 0.2, e)
				body_y -= 0.04 * e
				al.z = lerpf(al.z, 0.6, e)
				ar.z = lerpf(ar.z, -0.6, e)
			"spin":
				yaw_offset = smoothstep(0.0, 1.0, p) * TAU * facing
				skirt_s = Vector3(1.0 + 0.16 * e, 1.0, 1.0 + 0.16 * e)
				al.z = lerpf(al.z, 1.0, e)
				ar.z = lerpf(ar.z, -1.0, e)
			"wonder":
				head_r.x = -0.18 * e
				al.z = lerpf(al.z, 0.6, e)
				ar.z = lerpf(ar.z, -0.6, e)
	else:
		yaw_offset = lerpf(yaw_offset, 0.0, 1.0 - exp(-delta * 8.0))
		if absf(yaw_offset) < 0.01:
			yaw_offset = 0.0

	# ---- landing squash ----------------------------------------------------------------
	var sq := squash_amount()
	body_scale = Vector3(body_scale.x * (1.0 + 0.10 * sq), body_scale.y * (1.0 - 0.14 * sq), body_scale.z * (1.0 + 0.10 * sq))

	# ---- apply (smoothed) -----------------------------------------------------------------
	var k := 1.0 - exp(-delta * 20.0)
	body.position.y = lerpf(body.position.y, body_y, k)
	body.rotation = body.rotation.lerp(body_rot, k)
	body.scale = body.scale.lerp(body_scale, 1.0 - exp(-delta * 30.0))
	torso.rotation = torso.rotation.lerp(torso_r, k)
	head.rotation = head.rotation.lerp(head_r, k)
	arm_l.rotation = arm_l.rotation.lerp(al, k)
	arm_r.rotation = arm_r.rotation.lerp(ar, k)
	leg_l.rotation = leg_l.rotation.lerp(ll, k)
	leg_r.rotation = leg_r.rotation.lerp(lr, k)
	skirt.rotation = skirt.rotation.lerp(skirt_r, k)
	skirt.scale = skirt.scale.lerp(skirt_s, 1.0 - exp(-delta * 14.0))

	# ---- secondary motion (hair / cape / wings) -------------------------------------------
	_lag = lerpf(_lag, clampf(move_speed * 0.05 + (vertical_speed * -0.03), -0.6, 0.6), 1.0 - exp(-delta * 6.0))
	for i in hair_sway.size():
		var n := hair_sway[i]
		n.rotation.x = _lag * 0.7 + sin(t * 2.0 + i) * 0.03
		n.rotation.z = sin(t * 1.7 + i * 1.3) * 0.04 + (0.05 * sin(_phase) * spd)
	if cape_pivot:
		var drag := clampf(spd * 0.6 + (0.3 if airborne else 0.0), 0.0, 1.0)
		cape_pivot.rotation.x = lerpf(cape_pivot.rotation.x, 0.06 + drag * 0.55, 1.0 - exp(-delta * 7.0))
		cape_pivot.rotation.z = sin(t * 1.5) * 0.02
	for i in wings.size():
		var flap := sin(t * (5.0 if spd > 0.05 or airborne else 2.4) + i * PI) * 0.45
		var sx := -1.0 if i == 0 else 1.0
		wings[i].rotation.y = sx * deg_to_rad(-25.0) + flap * -sx
	if clip_butterfly:
		clip_butterfly.scale.x = 0.8 + 0.2 * sin(t * 6.0)
	if orbit_butterflies:
		orbit_butterflies.rotation.y += delta * 1.4
		for bp in orbit_butterflies.get_children():
			bp.scale.x = 0.85 + 0.25 * sin(t * 10.0)
			bp.rotation.y = -orbit_butterflies.rotation.y
	if crown_root:
		var gem := crown_root.get_node_or_null("TiaraGem")
		if gem:
			gem.scale = Vector3.ONE * (1.0 + 0.15 * sin(t * 3.0))
