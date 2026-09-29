class_name Companion
extends CharacterBody3D
## A rescued friend who follows the princess and contributes an ability (data/characters/<id>.json "companion").
## Lumi: her horn makes rainbow bridges and, together with Star Light, wakes the Moonflower.

var character_id := "lumi"
var rig: UnicornRig
var player: Player
var ability := "rainbow_bridge"
var follow_distance := 2.2
var speed := 4.4
var frozen := false
var kill_y := -14.0

var _ability_busy := false
var _jump_cd := 0.0


func _ready() -> void:
	var def := Content.character(character_id)
	var comp: Dictionary = def.get("companion", {})
	ability = comp.get("ability", "rainbow_bridge")
	follow_distance = float(comp.get("follow_distance", 2.2))
	speed = float(comp.get("speed", 4.4))
	collision_layer = 0
	collision_mask = 1
	axis_lock_linear_z = true
	floor_snap_length = 0.45
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.0
	cs.shape = cap
	cs.position = Vector3(0, 0.55, 0)
	add_child(cs)
	rig = UnicornRig.new(character_id)
	add_child(rig)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	_jump_cd -= delta
	var axis := 0.0
	if not frozen and not _ability_busy and player:
		var want_x := player.global_position.x - player.facing * follow_distance
		var dx := want_x - global_position.x
		var dist_to_player := global_position.distance_to(player.global_position)
		if absf(dx) > 0.45:
			axis = clampf(dx * 1.5, -1.0, 1.0)
		var sprint := clampf((absf(dx) - 2.5) * 0.35, 0.0, 1.6)
		var target_v := axis * speed * (1.0 + sprint)
		velocity.x = move_toward(velocity.x, target_v, 30.0 * delta)
		# hop obstacles / follow the princess up ledges
		var need_up := player.global_position.y - global_position.y > 0.9 and absf(dx) < 3.5
		if is_on_floor() and _jump_cd <= 0.0 and ((is_on_wall() and absf(axis) > 0.1) or need_up):
			velocity.y = 10.2
			_jump_cd = 0.8
		if dist_to_player > 15.0 or global_position.y < kill_y:
			warp_to_player()
	else:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
	move_and_slide()
	global_position.z = 0.0
	if absf(velocity.x) > 0.2:
		rig.facing = signf(velocity.x)
	elif player and not _ability_busy:
		rig.facing = signf(player.global_position.x - global_position.x) if absf(player.global_position.x - global_position.x) > 0.3 else rig.facing
	rig.move_speed = absf(velocity.x)
	rig.grounded = is_on_floor()
	rig.vertical_speed = velocity.y
	rig.face_camera_amount = 0.6 if Dialogue.blocking else 0.0


func warp_to_player() -> void:
	if player == null:
		return
	var pos := player.safe_pos + Vector3(-player.facing * 1.6, 0.2, 0)
	Fx.sparkle_burst(get_parent(), global_position + Vector3(0, 0.8, 0), Color("#e0c8ff"), 16, 2.5, 0.28, 0.8)
	global_position = pos
	velocity = Vector3.ZERO
	Fx.sparkle_burst(get_parent(), pos + Vector3(0, 0.8, 0), Color("#e0c8ff"), 16, 2.5, 0.28, 0.8)


## Lumi's horn does its thing at `target`. Awaitable; caller activates the target afterwards.
func perform_ability(target: Interactable) -> void:
	_ability_busy = true
	var tx := target.global_position.x
	# trot over beside the target (or hop-warp if she is far)
	if absf(global_position.x - tx) > 4.0:
		Fx.sparkle_burst(get_parent(), global_position + Vector3(0, 0.8, 0), Color("#e0c8ff"), 12, 2.0, 0.25, 0.7)
		global_position = Vector3(tx - signf(tx - player.global_position.x) * 1.5, target.global_position.y + 0.3, 0)
		velocity = Vector3.ZERO
	rig.facing = signf(tx - global_position.x) if absf(tx - global_position.x) > 0.05 else rig.facing
	rig.set_emotion("determined")
	rig.play("horn_glow")
	Audio.sfx("horn_charge")
	await get_tree().create_timer(0.5).timeout
	var col := Interactable.power_color(target.power)
	var to := target.global_position + Vector3(0, target.fx_height, 0)
	MagicSwirl.play(get_parent(), rig.horn_world(), to, col, 0.8)
	Fx.sparkle_burst(get_parent(), rig.horn_world(), col, 16, 2.4, 0.26, 0.8)
	await get_tree().create_timer(0.85).timeout
	Audio.sfx("magic_flourish", 0.0, 1.1)
	Fx.sparkle_burst(get_parent(), to, col, 40, 4.5, 0.4, 1.3)
	rig.set_emotion("joyful")
	rig.play("happy_jump")
	_ability_busy = false
