class_name RabbitRig
extends RigBase
## Clover, the friendly forest rabbit. Small, round, big-eared, and very expressive.

var body: Node3D
var head: Node3D
var ears: Array[Node3D] = []
var arm_r: Node3D
var _hop_t := 0.0
var _hopping := false
var _fur := Color("#f6e6d4")
var _belly := Color("#fffaf3")


func _init(fur: Color = Color("#f6e6d4")) -> void:
	character_id = "clover"
	_fur = fur
	oneshots = {"happy_hop": 1.4, "worried": 1.6, "wave": 1.4, "point": 1.8, "nod": 0.8, "sniff": 1.2, "happy": 1.2}


func _build() -> void:
	var fur_m := Mat.toon_grad(_fur.darkened(0.06), _fur, 0.0, 0.5, {"outline": 0.01, "rim_color": Color(1, 0.95, 0.9), "rim_amount": 0.5, "shade_tint": Color(0.85, 0.7, 0.9)})
	var belly_m := Mat.toon(_belly, {"outline": 0.008})
	var pink_m := Mat.toon(Color("#ffb5cf"), {"outline": 0.006})
	body = Build.pivot(self, Vector3.ZERO, "Body")
	Build.sphere(body, 0.21, Vector3(0, 0.26, 0), fur_m, Vector3(1.0, 1.1, 1.05), 24)
	Build.sphere(body, 0.15, Vector3(0, 0.25, 0.09), belly_m, Vector3(1.0, 1.15, 0.8), 18)
	# hind feet
	for sx in [-1.0, 1.0]:
		Build.sphere(body, 0.075, Vector3(sx * 0.12, 0.05, 0.1), fur_m, Vector3(0.9, 0.55, 1.7), 12)
	# tail
	Build.sphere(body, 0.075, Vector3(0, 0.17, -0.22), belly_m, Vector3.ONE, 12)
	# arms
	arm_r = Build.pivot(body, Vector3(-0.15, 0.32, 0.1))
	Build.capsule(arm_r, 0.03, 0.16, Vector3(0, -0.06, 0.02), fur_m)
	var arm_l := Build.pivot(body, Vector3(0.15, 0.32, 0.1))
	Build.capsule(arm_l, 0.03, 0.16, Vector3(0, -0.06, 0.02), fur_m)
	# head
	head = Build.pivot(body, Vector3(0, 0.54, 0.05), "Head")
	Build.sphere(head, 0.17, Vector3.ZERO, fur_m, Vector3(1.05, 0.95, 1.0), 26)
	Build.sphere(head, 0.07, Vector3(0, -0.06, 0.15), belly_m, Vector3(1.2, 0.9, 0.8), 12)
	Build.sphere(head, 0.028, Vector3(0, -0.035, 0.21), pink_m, Vector3(1.2, 0.9, 0.8), 8)
	face_mat = Mat.face_material()
	face_mat.set_shader_parameter("eye_color", Color("#3a2a40"))
	face_mat.set_shader_parameter("show_nose", 0.0)
	face_mat.set_shader_parameter("show_brows", 1.0)
	face_mat.set_shader_parameter("brow_color", Color("#b89a86"))
	face_mat.set_shader_parameter("eye_sep", 0.5)
	face_mat.set_shader_parameter("eye_y", 0.02)
	face_mat.set_shader_parameter("eye_dim", Vector2(0.20, 0.26))
	face_mat.set_shader_parameter("mouth_y", -0.33)
	face_mat.set_shader_parameter("mouth_w", 0.14)
	face_mat.set_shader_parameter("lashes", 0.0)
	face_mat.set_shader_parameter("blush_color", Color("#ffa0b8"))
	Build.sphere(head, 0.172, Vector3.ZERO, face_mat, Vector3(1.05, 0.95, 1.0), 30)
	for sx in [-1.0, 1.0]:
		var ep := Build.pivot(head, Vector3(sx * 0.07, 0.13, -0.02))
		Build.capsule(ep, 0.045, 0.36, Vector3(0, 0.16, 0), fur_m, Vector3.ZERO, Vector3(0.75, 1.0, 0.9))
		Build.capsule(ep, 0.03, 0.26, Vector3(0, 0.15, 0.02), pink_m, Vector3.ZERO, Vector3(0.6, 1.0, 0.7))
		ep.rotation = Vector3(0, 0, sx * -0.18)
		ears.append(ep)


func _update_yaw(delta: float) -> void:
	var target := facing * deg_to_rad(48.0) * (1.0 - face_camera_amount * 0.7) + yaw_offset
	rotation.y = lerp_angle(rotation.y, target, 1.0 - exp(-delta * 10.0))


func _pose(delta: float) -> void:
	if body == null:
		return
	var t := _time
	var moving := move_speed > 0.2
	var y := 0.0
	var head_r := Vector3(sin(t * 3.0) * 0.02, sin(t * 0.7) * 0.08, 0)
	var ear_r := Vector2(0.0, 0.0)
	var arm_rx := 0.0
	var body_rot := Vector3.ZERO
	var sc := Vector3(1, 1.0 + sin(t * 3.4) * 0.015, 1)
	if moving:
		_hop_t += delta * 7.0
		y = absf(sin(_hop_t)) * 0.2
		body_rot.x = -sin(_hop_t) * 0.18
		ear_r.x = -sin(_hop_t) * 0.3
	# occasional nose-twitch / ear flick
	ear_r.y = 0.05 * sin(t * 2.1)
	if _oneshot != "":
		var p := oneshot_progress()
		var e := smoothstep(0.0, 0.12, p) * smoothstep(1.0, 0.85, p)
		var tt := _oneshot_t
		match _oneshot:
			"happy_hop", "happy":
				y += absf(sin(tt * 8.0)) * 0.3 * e
				ear_r.x = -0.4 * e
				sc.y *= 1.0 + 0.06 * sin(tt * 16.0) * e
			"worried":
				ear_r.y = 0.9 * e
				body_rot.z = sin(tt * 26.0) * 0.03 * e
				head_r.x = 0.2 * e
			"wave":
				arm_rx = (-2.4 + sin(tt * 12.0) * 0.4) * e
			"point":
				arm_rx = -1.5 * e
				head_r.y = -0.25 * e * facing
				ear_r.y = -0.3 * e
			"nod":
				head_r.x += sin(tt * 9.0) * 0.15 * e
			"sniff":
				head_r.x = -0.25 * e + sin(tt * 30.0) * 0.03
	var k := 1.0 - exp(-delta * 18.0)
	body.position.y = lerpf(body.position.y, y, k)
	body.rotation = body.rotation.lerp(body_rot, k)
	body.scale = body.scale.lerp(sc, k)
	head.rotation = head.rotation.lerp(head_r, k)
	arm_r.rotation.x = lerpf(arm_r.rotation.x, arm_rx, k)
	for i in ears.size():
		var sx := 1.0 if i == 1 else -1.0
		ears[i].rotation.z = lerpf(ears[i].rotation.z, sx * -0.18 - sx * ear_r.y, k)
		ears[i].rotation.x = lerpf(ears[i].rotation.x, ear_r.x, k)
