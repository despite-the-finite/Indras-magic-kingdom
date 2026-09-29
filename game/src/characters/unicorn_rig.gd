class_name UnicornRig
extends RigBase
## Baby unicorn (Lumi) / mama unicorn (Luna). Colours + scale come from data/characters/<id>.json ("visual").
## Big head, sparkly eyes, rainbow mane, glowing horn. Local +Z is forward.

var char_def: Dictionary = {}
var body: Node3D
var neck: Node3D
var head: Node3D
var legs: Array[Node3D] = []      # 0 FL, 1 FR, 2 BL, 3 BR
var ears: Array[Node3D] = []
var mane: Array[Node3D] = []
var tail: Array[Node3D] = []
var horn_tip: Node3D
var horn_glow: MeshInstance3D
var _phase := 0.0
var _scale_factor := 1.0
var _horn_energy := 1.0
var _aura: GPUParticles3D


func _init(id: String = "lumi") -> void:
	character_id = id
	char_def = Content.character(id)
	oneshots = {
		"happy_jump": 1.5, "look_up": 1.7, "hopeful": 1.9, "hug": 1.9, "eat": 1.7, "shimmy": 1.4,
		"nod": 0.9, "happy": 1.2, "cheer": 1.3, "brush_enjoy": 1.4, "horn_glow": 1.6, "sniff": 1.3, "wave": 1.2,
	}


func _col(key: String, fallback: String) -> Color:
	return Color(char_def.get("visual", {}).get("colors", {}).get(key, fallback))


func _build() -> void:
	_scale_factor = float(char_def.get("visual", {}).get("scale", 1.0))
	var body_c := _col("body", "#fff4fb")
	var shade_c := _col("body_shade", "#f3d9f5")
	var hoof_c := _col("hoof", "#ffd7f0")
	var horn_c := _col("horn", "#ffe27a")
	var eye_c := _col("eye", "#7a4dd8")
	var mane_cols: Array = char_def.get("visual", {}).get("colors", {}).get("mane", ["#ff8fd2", "#b58cf2", "#6ec6f5"])

	var root := Build.pivot(self, Vector3.ZERO, "Scaled")
	root.scale = Vector3.ONE * _scale_factor
	body = Build.pivot(root, Vector3.ZERO, "Body")

	var coat := Mat.toon_grad(shade_c, body_c, 0.0, 0.9, {"outline": 0.012, "rim_color": Color(1, 0.85, 1), "rim_amount": 0.5, "glitter": 0.12, "shade_tint": Color(0.78, 0.66, 0.98)})
	var coat_flat := Mat.toon(body_c, {"outline": 0.012, "rim_color": Color(1, 0.85, 1), "rim_amount": 0.5, "shade_tint": Color(0.78, 0.66, 0.98)})
	var pink_m := Mat.toon(Color("#ffc4e4"), {"outline": 0.008})
	var hoof_m := Mat.toon(hoof_c, {"outline": 0.008})

	# torso
	Build.sphere(body, 0.33, Vector3(0, 0.54, -0.06), coat, Vector3(1.0, 0.95, 1.32), 28)
	Build.sphere(body, 0.29, Vector3(0, 0.58, 0.2), coat_flat, Vector3(1.0, 1.05, 1.0), 24)
	Build.sphere(body, 0.3, Vector3(0, 0.55, -0.3), coat_flat, Vector3(1.0, 1.0, 1.0), 24)
	# belly blush
	Build.sphere(body, 0.22, Vector3(0, 0.36, -0.02), pink_m, Vector3(0.9, 0.35, 1.4), 16)

	# legs
	var leg_defs := [Vector3(0.16, 0.4, 0.24), Vector3(-0.16, 0.4, 0.24), Vector3(0.16, 0.4, -0.32), Vector3(-0.16, 0.4, -0.32)]
	for i in 4:
		var lp := Build.pivot(body, leg_defs[i])
		Build.capsule(lp, 0.078, 0.42, Vector3(0, -0.17, 0), coat_flat)
		Build.cyl(lp, 0.084, 0.092, 0.08, Vector3(0, -0.37, 0), hoof_m, 14)
		Build.torus(lp, 0.07, 0.096, Vector3(0, -0.3, 0), pink_m, Vector3.ZERO, 14)
		legs.append(lp)

	# neck + head
	neck = Build.pivot(body, Vector3(0, 0.68, 0.34), "Neck")
	Build.capsule(neck, 0.17, 0.42, Vector3(0, 0.15, 0.08), coat_flat, Vector3(deg_to_rad(26), 0, 0))
	head = Build.pivot(neck, Vector3(0, 0.36, 0.2), "Head")
	Build.sphere(head, 0.35, Vector3.ZERO, coat_flat, Vector3(1.0, 0.94, 1.0), 32)
	# muzzle
	Build.sphere(head, 0.17, Vector3(0, -0.14, 0.24), Mat.toon(body_c.lerp(Color("#ffd0e8"), 0.35), {"outline": 0.009, "rim_amount": 0.4}), Vector3(1.0, 0.85, 1.05), 20)
	Build.sphere(head, 0.024, Vector3(0.065, -0.1, 0.41), Mat.toon(Color("#c46a9a"), {}), Vector3(1, 1.2, 0.7), 8)
	Build.sphere(head, 0.024, Vector3(-0.065, -0.1, 0.41), Mat.toon(Color("#c46a9a"), {}), Vector3(1, 1.2, 0.7), 8)

	# face: eyes on the head, mouth on the muzzle
	face_mat = Mat.face_material()
	face_mat.set_shader_parameter("eye_color", eye_c)
	face_mat.set_shader_parameter("show_mouth", 0.0)
	face_mat.set_shader_parameter("show_nose", 0.0)
	face_mat.set_shader_parameter("show_brows", 0.0)
	face_mat.set_shader_parameter("eye_sep", 0.40)
	face_mat.set_shader_parameter("eye_y", -0.02)
	face_mat.set_shader_parameter("eye_dim", Vector2(0.21, 0.29))
	face_mat.set_shader_parameter("blush_color", Color("#ff9ad0"))
	Build.sphere(head, 0.355, Vector3.ZERO, face_mat, Vector3(1.0, 0.94, 1.0), 36)
	var mouth_mat := Mat.face_material()
	mouth_mat.set_shader_parameter("show_eyes", 0.0)
	mouth_mat.set_shader_parameter("show_nose", 0.0)
	mouth_mat.set_shader_parameter("mouth_y", -0.42)
	mouth_mat.set_shader_parameter("mouth_w", 0.34)
	mouth_mat.set_shader_parameter("lip_color", Color("#b8508a"))
	mouth_mat.set_shader_parameter("mouth_color", Color("#a03a6a"))
	var mm := Build.sphere(head, 0.172, Vector3(0, -0.14, 0.24), mouth_mat, Vector3(1.0, 0.85, 1.05), 24)
	mm.name = "MouthOverlay"
	_mouth_mat = mouth_mat

	# ears
	for sx in [-1.0, 1.0]:
		var ep := Build.pivot(head, Vector3(sx * 0.17, 0.28, -0.08))
		Build.cone(ep, 0.08, 0.26, Vector3(0, 0.12, 0), coat_flat, Vector3.ZERO, 12)
		Build.cone(ep, 0.05, 0.19, Vector3(0, 0.11, 0.02), pink_m, Vector3.ZERO, 10)
		ep.rotation = Vector3(0, 0, sx * -0.25)
		ears.append(ep)

	# horn
	var horn := Build.pivot(head, Vector3(0, 0.31, 0.18))
	horn.rotation = Vector3(deg_to_rad(24), 0, 0)
	var horn_m := Mat.glowing(horn_c, 0.9, {"outline": 0.008, "glitter": 0.5, "pulse": 0.8, "rim_color": Color(1, 1, 0.8), "rim_amount": 0.8})
	Build.cone(horn, 0.075, 0.42, Vector3(0, 0.21, 0), horn_m, Vector3.ZERO, 14)
	for k in 3:
		Build.torus(horn, 0.04 - k * 0.011, 0.076 - k * 0.016 + 0.006, Vector3(0, 0.07 + k * 0.09, 0), Mat.glowing(horn_c.lightened(0.3), 1.0), Vector3.ZERO, 14)
	horn_tip = Build.pivot(horn, Vector3(0, 0.42, 0))
	horn_glow = Fx.glow_sprite(horn_tip, Vector3.ZERO, Color(1, 0.95, 0.6, 0.6), 0.5)
	_aura = Fx.aura(horn_tip, Color(1, 0.95, 0.65), 10, 0.14)

	# forelock + mane (rainbow blobs down the neck)
	var mane_mats: Array[Material] = []
	for c in mane_cols:
		mane_mats.append(Mat.toon(Color(c), {"outline": 0.01, "rim_color": Color(1, 0.95, 1), "rim_amount": 0.6, "glitter": 0.25}))
	for k in 3:
		Build.sphere(head, 0.1, Vector3((k - 1) * 0.11, 0.25, 0.24 - absf(k - 1) * 0.04), mane_mats[k % mane_mats.size()], Vector3(1.1, 1.3, 0.8), 12)
	for k in 8:
		var t := float(k) / 7.0
		var mp := Build.pivot(neck, Vector3(0, 0.36 - t * 0.5, 0.2 - t * 0.28 - 0.1))
		var mi := clampi(int(t * mane_mats.size()), 0, mane_mats.size() - 1)
		Build.sphere(mp, 0.13 - t * 0.02, Vector3(0, -0.05, -0.05), mane_mats[mi], Vector3(0.75, 1.35, 0.9), 14)
		mane.append(mp)
	# tail (a fluffy rainbow plume)
	for k in 7:
		var t := float(k) / 6.0
		var tp := Build.pivot(body, Vector3(0, 0.66 + t * 0.2 - t * t * 0.1, -0.5 - t * 0.28))
		var mi2 := clampi(int(t * mane_mats.size()), 0, mane_mats.size() - 1)
		Build.sphere(tp, 0.14 - t * 0.02, Vector3.ZERO, mane_mats[mi2], Vector3(0.85, 1.2, 1.2), 14)
		tail.append(tp)
	# sparkles on the coat come from the toon glitter; a soft ground shadow blob helps in flat scenes
	_apply_face_defaults()


var _mouth_mat: ShaderMaterial


func _apply_face_defaults() -> void:
	face_mat.set_shader_parameter("lashes", 1.0)
	face_mat.set_shader_parameter("blush", 0.6)


func _base_eye_size() -> float:
	return 1.0


func set_horn_energy(e: float) -> void:
	_horn_energy = e


func horn_world() -> Vector3:
	return horn_tip.global_position if horn_tip else global_position + Vector3(0, 1.5, 0)


func head_world() -> Vector3:
	return head.global_position if head else global_position + Vector3(0, 1.4, 0)


func back_world() -> Vector3:
	## saddle point for riding
	return body.global_position + Vector3(0, 0.95, -0.02) * _scale_factor


# ---- mouth follows the same emotion state as the eyes ------------------------------
func _update_face(delta: float) -> void:
	super._update_face(delta)
	if _mouth_mat and face_mat:
		for k in ["smile", "mouth_open", "mouth_round"]:
			_mouth_mat.set_shader_parameter(k, face_mat.get_shader_parameter(k))


# =============================================================================
# animation
# =============================================================================
func _update_yaw(delta: float) -> void:
	var target := facing * deg_to_rad(52.0) * (1.0 - face_camera_amount * 0.62) + yaw_offset
	rotation.y = lerp_angle(rotation.y, target, 1.0 - exp(-delta * 9.0))


func _env(p: float, a: float = 0.12, b: float = 0.15) -> float:
	return smoothstep(0.0, a, p) * smoothstep(1.0, 1.0 - b, p)


func _pose(delta: float) -> void:
	if body == null:
		return
	var t := _time
	var spd := clampf(move_speed / 4.0, 0.0, 2.2)
	var gallop := move_speed > 6.0 or anim == "gallop"
	var moving := move_speed > 0.15 or anim == "gallop"
	_phase += delta * ((5.0 + spd * 3.0) if not gallop else (11.0 + spd * 1.5)) * (1.0 if moving else 0.0)
	var ph := _phase

	var body_y := 0.0
	var body_rot := Vector3.ZERO
	var neck_r := Vector3(sin(t * 1.2) * 0.02, 0, 0)
	var head_r := Vector3(sin(t * 0.8) * 0.03, sin(t * 0.6) * 0.05, sin(t * 0.7) * 0.03)
	var leg_r: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var ear_z := 0.0
	var tail_wag := 0.5
	var body_scale := Vector3.ONE
	var body_x := 0.0

	body_scale.y = 1.0 + sin(t * 2.0) * 0.012
	body_scale.z = 1.0 - sin(t * 2.0) * 0.006

	if moving and grounded:
		if gallop:
			var a := sin(ph)
			leg_r[0].x = a * 0.95
			leg_r[1].x = a * 0.95 * 0.9
			leg_r[2].x = sin(ph + 1.3) * 0.95
			leg_r[3].x = sin(ph + 1.3) * 0.95 * 0.9
			body_y = absf(sin(ph * 0.5 + 0.4)) * 0.14
			body_rot.x = -sin(ph) * 0.09
			neck_r.x = 0.05 + sin(ph) * 0.1
			head_r.x = -0.05
			tail_wag = 1.4
		else:
			var a := sin(ph)
			leg_r[0].x = -a * 0.5
			leg_r[3].x = -a * 0.5
			leg_r[1].x = a * 0.5
			leg_r[2].x = a * 0.5
			body_y = absf(sin(ph)) * 0.03
			body_rot.z = a * 0.02
			neck_r.x = sin(ph * 2.0) * 0.05
			tail_wag = 0.9
	elif not grounded:
		leg_r[0].x = -0.6
		leg_r[1].x = -0.5
		leg_r[2].x = 0.7
		leg_r[3].x = 0.6
		neck_r.x = -0.1
		tail_wag = 1.2

	# ---- looping states -----------------------------------------------------------
	match anim:
		"cry":
			neck_r.x = 0.55
			head_r.x = 0.35
			body_rot.z = sin(t * 18.0) * 0.015
			ear_z = 0.85
			tail_wag = 0.2
		"trapped":
			neck_r.x = 0.45
			head_r.x = 0.3
			body_rot.z = sin(t * 26.0) * 0.02
			body_y = -0.02
			ear_z = 0.8
			tail_wag = 0.1
		"sleep":
			body_y = -0.3
			leg_r[0].x = -1.45
			leg_r[1].x = -1.45
			leg_r[2].x = 1.3
			leg_r[3].x = 1.3
			neck_r.x = 0.65
			head_r.x = 0.3
			head_r.z = 0.25
			ear_z = 0.5
			body_scale.y = 1.0 + sin(t * 1.4) * 0.03
			tail_wag = 0.1
		"ride":
			pass

	# ---- one-shots ------------------------------------------------------------------
	if _oneshot != "":
		var p := oneshot_progress()
		var e := _env(p)
		var tt := _oneshot_t
		match _oneshot:
			"happy_jump":
				body_y += absf(sin(tt * 6.2)) * 0.4 * e
				leg_r[0].x -= 0.7 * e
				leg_r[1].x -= 0.7 * e
				leg_r[2].x += 0.5 * e
				leg_r[3].x += 0.5 * e
				neck_r.x = -0.25 * e
				head_r.x = -0.2 * e
				tail_wag = 2.0
				yaw_offset = sin(tt * 3.1) * 0.35 * e
			"look_up":
				neck_r.x = -0.5 * e
				head_r.x = -0.35 * e
				ear_z = -0.2 * e
				body_rot.x = -0.06 * e
			"hopeful":
				head_r.z = 0.32 * e
				neck_r.x = 0.1 * e
				leg_r[0].x = -absf(sin(tt * 5.0)) * 0.5 * e
				ear_z = 0.35 * e
			"hug", "brush_enjoy", "sniff":
				neck_r.x = 0.3 * e
				head_r.z = 0.28 * e
				head_r.x = 0.1 * e
				body_rot.z = sin(tt * 3.0) * 0.03 * e
			"eat":
				neck_r.x = (0.75 + sin(tt * 11.0) * 0.1) * e
				head_r.x = 0.45 * e
			"shimmy":
				body_rot.z = sin(tt * 15.0) * 0.14 * e
				body_scale.x *= 1.0 + sin(tt * 15.0) * 0.05 * e
				tail_wag = 2.2
				ear_z = sin(tt * 15.0) * 0.3 * e
			"nod":
				head_r.x += sin(tt * 9.0) * 0.16 * e
			"happy", "cheer", "wave":
				body_y += absf(sin(tt * 8.0)) * 0.12 * e
				leg_r[0].x -= 0.5 * e
				tail_wag = 1.8
			"horn_glow":
				neck_r.x = -0.2 * e
				head_r.x = -0.15 * e
				_horn_energy = 1.0 + 2.5 * e
	else:
		yaw_offset = lerpf(yaw_offset, 0.0, 1.0 - exp(-delta * 8.0))
		_horn_energy = lerpf(_horn_energy, 1.0, 1.0 - exp(-delta * 4.0))

	# emotion-driven ears
	if emotion == "sad" or emotion == "worried":
		ear_z = maxf(ear_z, 0.6)
	elif emotion == "excited" or emotion == "wonder" or emotion == "surprised":
		ear_z = minf(ear_z, -0.15)

	# landing squash
	var sq := squash_amount()
	body_scale = Vector3(body_scale.x * (1.0 + 0.1 * sq), body_scale.y * (1.0 - 0.13 * sq), body_scale.z * (1.0 + 0.06 * sq))

	# ---- apply -----------------------------------------------------------------------
	var k := 1.0 - exp(-delta * 18.0)
	body.position.y = lerpf(body.position.y, body_y, k)
	body.position.x = lerpf(body.position.x, body_x, k)
	body.rotation = body.rotation.lerp(body_rot, k)
	body.scale = body.scale.lerp(body_scale, 1.0 - exp(-delta * 28.0))
	neck.rotation = neck.rotation.lerp(neck_r, k)
	head.rotation = head.rotation.lerp(head_r, k)
	for i in 4:
		legs[i].rotation = legs[i].rotation.lerp(leg_r[i], k)
	for i in ears.size():
		var sx := 1.0 if i == 1 else -1.0
		var target := sx * -0.25 + sx * -ear_z * 0.9 + sin(t * 1.3 + i * 2.0) * 0.03
		ears[i].rotation.z = lerpf(ears[i].rotation.z, target, k)
		# occasional ear twitch
		if int(t * 0.8 + i) % 7 == 0:
			ears[i].rotation.x = sin(t * 30.0) * 0.12
		else:
			ears[i].rotation.x = lerpf(ears[i].rotation.x, 0.0, k)
	for i in mane.size():
		mane[i].rotation.z = sin(t * 2.4 - i * 0.5) * 0.12 * (0.5 + tail_wag * 0.3)
		mane[i].rotation.x = -_lagv() * 0.4 + sin(t * 2.0 - i * 0.4) * 0.05
	for i in tail.size():
		tail[i].rotation.z = sin(t * (2.0 + tail_wag * 2.0) - i * 0.6) * 0.18 * tail_wag * (float(i) / tail.size() + 0.2)
	if horn_glow:
		var s := 0.5 + 0.08 * sin(t * 3.0) * _horn_energy + 0.16 * (_horn_energy - 1.0)
		horn_glow.scale = Vector3.ONE * s * 2.0
		(horn_glow.material_override as StandardMaterial3D).albedo_color.a = clampf(0.45 + 0.2 * (_horn_energy - 1.0), 0.3, 1.0)


func _lagv() -> float:
	return clampf(move_speed * 0.04, 0.0, 0.5)
