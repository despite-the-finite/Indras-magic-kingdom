class_name Flutter
extends Node3D
## Flutter, the magical butterfly guide. She is the physical form of the hint system's level 3/4
## ("a butterfly flies toward it") and the gentle rescue if the princess ever falls.
##
## Modes:  follow (hover near the princess)  guide (fly to a target, wait, bob)  hold (stay at a point)

enum Mode { FOLLOW, GUIDE, HOLD, CARRY }

var mode := Mode.FOLLOW
var follow_target: Node3D
var guide_pos := Vector3.ZERO
var speed := 5.0
var _wings: Array[Node3D] = []
var _t := 0.0
var _vel := Vector3.ZERO
var _trail: GPUParticles3D
var _glow: MeshInstance3D
var _side := 1.0
var palette := [Mat.PINK, Mat.LILAC, Mat.SKY]


func _ready() -> void:
	_build()
	_t = randf() * 10.0


func _build() -> void:
	var body_m := Mat.glowing(Color("#ffe6f6"), 0.8, {"outline": 0.006})
	Build.capsule(self, 0.028, 0.16, Vector3.ZERO, body_m, Vector3(PI * 0.5, 0, 0))
	Build.sphere(self, 0.032, Vector3(0, 0, 0.09), body_m, Vector3.ONE, 10)
	# antennae
	for sx in [-1.0, 1.0]:
		Build.cyl(self, 0.003, 0.003, 0.09, Vector3(sx * 0.02, 0.05, 0.11), body_m, 5, Vector3(deg_to_rad(-25), 0, sx * deg_to_rad(-20)))
	# wings: big upper pair, small lower pair; each side pivots at the body
	for sx in [-1.0, 1.0]:
		var wp := Build.pivot(self, Vector3.ZERO)
		var up := MeshInstance3D.new()
		up.mesh = Build.wing_mesh(0.36)
		up.material_override = Mat.toon(palette[0], {"two_sided": true, "emission_color": palette[0], "emission_energy": 1.0, "glitter": 0.9, "rim_color": Color.WHITE, "rim_amount": 1.0, "albedo_top": palette[1], "gradient_amount": 1.0, "gradient_min": -0.15, "gradient_max": 0.25})
		up.rotation = Vector3(0, 0, deg_to_rad(20))
		wp.add_child(up)
		var lo := MeshInstance3D.new()
		lo.mesh = Build.wing_mesh(0.24)
		lo.material_override = Mat.toon(palette[2], {"two_sided": true, "emission_color": palette[2], "emission_energy": 0.9, "glitter": 0.8, "rim_color": Color.WHITE, "rim_amount": 1.0})
		lo.rotation = Vector3(0, 0, deg_to_rad(-40))
		wp.add_child(lo)
		# mirror the left wing
		up.scale.x = 1.0
		lo.scale.x = 1.0
		wp.scale.x = sx
		_wings.append(wp)
	_glow = Fx.glow_sprite(self, Vector3.ZERO, Color(1, 0.8, 0.95, 0.55), 0.8)
	_trail = Fx.trail(self, Color(1, 0.85, 0.98), 26)


func follow(node: Node3D) -> void:
	follow_target = node
	mode = Mode.FOLLOW


func guide_to(pos: Vector3) -> void:
	guide_pos = pos
	mode = Mode.GUIDE


func hold_at(pos: Vector3) -> void:
	guide_pos = pos
	mode = Mode.HOLD


func celebrate() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 1.35, 0.15)
	tw.tween_property(self, "scale", Vector3.ONE, 0.3)
	Fx.sparkle_burst(get_parent(), global_position, Color(1, 0.85, 0.95), 14, 2.0, 0.22)


func _process(delta: float) -> void:
	_t += delta
	var goal := global_position
	match mode:
		Mode.FOLLOW:
			if follow_target and is_instance_valid(follow_target):
				var f := follow_target.global_position
				# lazy figure-8 around a point above/behind the princess's shoulder
				goal = f + Vector3(-1.1 * _side + sin(_t * 0.9) * 0.5, 1.9 + sin(_t * 1.7) * 0.25, 0.4 + cos(_t * 0.9) * 0.4)
		Mode.GUIDE, Mode.HOLD:
			goal = guide_pos + Vector3(sin(_t * 1.3) * 0.35, 0.9 + sin(_t * 2.1) * 0.2, 0.3)
		Mode.CARRY:
			if follow_target and is_instance_valid(follow_target):
				goal = follow_target.global_position + Vector3(0, 2.2, 0.2)
	var to := goal - global_position
	var dist := to.length()
	var want_speed := clampf(dist * 2.4, 0.0, speed if mode != Mode.CARRY else speed * 1.4)
	var desired := to.normalized() * want_speed if dist > 0.02 else Vector3.ZERO
	_vel = _vel.lerp(desired, 1.0 - exp(-delta * 4.0))
	global_position += _vel * delta
	# face the direction of travel (in the 2.5D plane)
	if absf(_vel.x) > 0.2:
		_side = signf(_vel.x)
		rotation.y = lerp_angle(rotation.y, deg_to_rad(65.0) * _side, 1.0 - exp(-delta * 6.0))
	rotation.z = lerpf(rotation.z, clampf(-_vel.x * 0.05, -0.4, 0.4), 1.0 - exp(-delta * 5.0))
	# wing flap
	var flap := sin(_t * 17.0)
	for w in _wings:
		var sx := signf(w.scale.x)
		w.rotation.y = sx * (0.15 + 0.85 * absf(flap))
	if _glow:
		_glow.scale = Vector3.ONE * (1.0 + 0.15 * sin(_t * 4.0))
