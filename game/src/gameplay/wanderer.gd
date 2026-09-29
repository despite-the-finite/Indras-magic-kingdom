class_name Wanderer
extends Node3D
## Makes a rescued friend feel alive at the castle: strolls around, grazes, and hurries over to greet the
## princess when she comes near. Drives any RigBase (unicorn, rabbit...).

var rig: RigBase
var terrain: Terrain
var x_min := -10.0
var x_max := 10.0
var speed := 1.7
var greet_target: Node3D
var greet_distance := 4.5
var z_lane := 0.0
var state := "idle"
var _timer := 1.0
var _target_x := 0.0
var _cooldown := 6.0
var _greeting := false
var idle_anims: Array[String] = ["eat", "sniff"]


func _ready() -> void:
	if rig and rig.get_parent() == null:
		add_child(rig)
	_target_x = position.x


func _process(delta: float) -> void:
	if rig == null:
		return
	_cooldown -= delta
	_timer -= delta
	position.y = terrain.height_at(position.x) if terrain else position.y
	position.z = z_lane
	var walking := false
	if greet_target and not _greeting and _cooldown <= 0.0:
		var d := absf(greet_target.global_position.x - global_position.x)
		if d < greet_distance and d > 1.5:
			_start_greet()
	if _greeting:
		var gx := greet_target.global_position.x - signf(greet_target.global_position.x - global_position.x) * 1.5
		walking = _walk_to(gx, speed * 2.4, delta)
		if not walking:
			_greeting = false
			_cooldown = 14.0
			rig.face_toward(greet_target.global_position.x - global_position.x)
			rig.set_emotion("joyful")
			rig.play("happy_jump" if rig is UnicornRig else "happy_hop")
			Fx.heart_burst(get_parent(), global_position + Vector3(0, 1.4, 0), 6)
			Audio.sfx("happy_chime", -4.0)
			state = "idle"
			_timer = 3.0
	elif state == "walk":
		walking = _walk_to(_target_x, speed, delta)
		if not walking:
			state = "idle"
			_timer = randf_range(2.0, 5.0)
	elif state == "idle" and _timer <= 0.0:
		if randf() < 0.45:
			rig.play(idle_anims[randi() % idle_anims.size()])
			_timer = 2.5
		else:
			_target_x = clampf(position.x + randf_range(-5.0, 5.0), x_min, x_max)
			state = "walk"
	rig.move_speed = speed if walking and not _greeting else (speed * 2.6 if walking else 0.0)


func _start_greet() -> void:
	_greeting = true
	rig.set_emotion("excited")
	Fx.sparkle_burst(get_parent(), global_position + Vector3(0, 1.6, 0), Color(1, 0.9, 0.6), 8, 1.5, 0.25, 0.6)


func _walk_to(x: float, spd: float, delta: float) -> bool:
	var dx := x - position.x
	if absf(dx) < 0.12:
		return false
	rig.facing = signf(dx)
	position.x += signf(dx) * minf(absf(dx), spd * delta)
	return true
