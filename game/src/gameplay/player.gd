class_name Player
extends CharacterBody3D
## The princess. Forgiving 2.5D controller: coyote time, jump buffering, click/tap-to-walk, tap an object to
## walk there and use it, and no way to fail: falling always ends with Flutter carrying her back to safety.

signal act_started
signal fell

const SPEED := 4.9
const JUMP_V := 8.9
const GRAVITY := 24.0
const COYOTE := 0.16
const JUMP_BUFFER := 0.16

var rig: PrincessRig
var cam: FollowCam
var flutter: Flutter
var magic: MagicSystem
var frozen := false
var busy := false
var facing := 1.0
var safe_pos := Vector3.ZERO
var current_power := "flower"
var focus: Interactable
var kill_y := -14.0
var ride_mode := false

var _coyote := 0.0
var _jump_buf := 0.0
var _safe_timer := 0.0
var _rescuing := false
var _click_x: Variant = null
var _click_target: Interactable
var _last_grounded := true
var _step_t := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	axis_lock_linear_z = true
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(52.0)
	floor_stop_on_slope = true
	safe_pos = global_position
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.3
	cs.shape = cap
	cs.position = Vector3(0, 0.66, 0)
	add_child(cs)
	rig = PrincessRig.new(GameState.appearance())
	add_child(rig)
	Events.crown_level_changed.connect(func(l): rig.set_crown_level(l))
	var powers := GameState.powers()
	if powers.size() > 0:
		current_power = powers[0]


func controls_locked() -> bool:
	return frozen or busy or _rescuing or Dialogue.blocking or (cam != null and cam.in_cinematic())


func _unhandled_input(event: InputEvent) -> void:
	if controls_locked():
		return
	if event.is_action_pressed("jump"):
		_jump_buf = JUMP_BUFFER
	if event.is_action_pressed("magic"):
		try_act()
	if event.is_action_pressed("cycle_power"):
		cycle_power()
	var tap: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
	if tap and cam:
		_on_tap(event.position)


func _on_tap(screen_pos: Vector2) -> void:
	var o := cam.project_ray_origin(screen_pos)
	var n := cam.project_ray_normal(screen_pos)
	if absf(n.z) < 0.001:
		return
	var t := -o.z / n.z
	var world := o + n * t
	# tapped an interactable? walk over and use it
	var best: Interactable = null
	var best_d := 1.6
	for i in Interactable.all:
		if not i.is_available() or i.kind == "touch":
			continue
		var d := Vector2(i.global_position.x - world.x, (i.global_position.y + i.halo_height * 0.6) - world.y).length()
		if d < best_d:
			best_d = d
			best = i
	if best:
		_click_target = best
		_click_x = best.global_position.x
		return
	_click_target = null
	if world.y > global_position.y + 2.0 and absf(world.x - global_position.x) < 1.2:
		_jump_buf = JUMP_BUFFER
		return
	_click_x = world.x


func cycle_power() -> void:
	var powers := GameState.powers()
	if powers.size() < 2:
		return
	var i := powers.find(current_power)
	current_power = powers[(i + 1) % powers.size()]
	Audio.sfx("ui_tap", -3.0, 1.2)


func _physics_process(delta: float) -> void:
	if _rescuing:
		return
	var locked := controls_locked()
	var axis := 0.0
	if not locked:
		axis = Input.get_axis("move_left", "move_right")
		if absf(axis) > 0.01:
			_click_x = null
			_click_target = null
		elif _click_x != null:
			var dx: float = float(_click_x) - global_position.x
			var stop_dist := 0.12
			if _click_target:
				stop_dist = maxf(_click_target.radius * 0.55, 0.35)
			if absf(dx) > stop_dist:
				axis = clampf(dx * 1.6, -1.0, 1.0)
			else:
				_click_x = null
				if _click_target and _click_target.is_available():
					var tgt := _click_target
					_click_target = null
					face_toward(tgt.global_position.x - global_position.x)
					try_act()
	# gravity + jumping
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		_coyote -= delta
	else:
		_coyote = COYOTE
	_jump_buf -= delta
	if not locked and _jump_buf > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_V
		_jump_buf = 0.0
		_coyote = 0.0
		Audio.sfx("jump", -4.0, 1.0, 0.05)
		Fx.sparkle_burst(get_parent(), global_position + Vector3(0, 0.1, 0), Color(1, 0.9, 0.95), 8, 1.4, 0.2, 0.6)
	# horizontal
	var target_v := axis * SPEED
	var accel := 34.0 if is_on_floor() else 16.0
	velocity.x = move_toward(velocity.x, target_v, accel * delta)
	velocity.z = 0.0
	if absf(axis) > 0.05:
		facing = signf(axis)
	move_and_slide()
	global_position.z = 0.0
	# footsteps
	if is_on_floor() and absf(velocity.x) > 1.0:
		_step_t -= delta * absf(velocity.x) / SPEED
		if _step_t <= 0.0:
			_step_t = 0.33
			Audio.sfx("step_grass", -8.0, 1.0, 0.12)
	if is_on_floor() and not _last_grounded:
		Audio.sfx("land", -6.0, 1.0, 0.05)
	_last_grounded = is_on_floor()

	# safe spot tracking for gentle rescues
	if is_on_floor() and absf(velocity.y) < 0.1:
		_safe_timer += delta
		if _safe_timer > 0.5:
			safe_pos = global_position
	else:
		_safe_timer = 0.0
	if global_position.y < kill_y:
		_rescue_fall()

	# rig inputs
	rig.facing = facing
	rig.move_speed = absf(velocity.x)
	rig.vertical_speed = velocity.y
	rig.grounded = is_on_floor()
	rig.face_camera_amount = 0.85 if (Dialogue.blocking or (cam and cam.in_cinematic())) else 0.0
	if cam:
		cam.facing = lerpf(cam.facing, facing, 1.0 - exp(-delta * 2.0))
	_update_focus()


func face_toward(dx: float) -> void:
	if absf(dx) > 0.01:
		facing = signf(dx)
		rig.facing = facing


# ---- interaction ----------------------------------------------------------------
func _update_focus() -> void:
	var best: Interactable = null
	var best_d := 1e9
	for i in Interactable.all:
		if not i.is_available():
			continue
		var dx: float = absf(i.global_position.x - global_position.x)
		var dy: float = i.global_position.y - global_position.y
		if dx > i.radius or dy < -2.2 or dy > 3.2:
			continue
		if i.kind == "touch":
			if not controls_locked():
				i.activate("touch")
			continue
		if dx < best_d:
			best_d = dx
			best = i
	focus = best


func nearest_prompt() -> Interactable:
	return focus if not controls_locked() else null


func try_act() -> void:
	if controls_locked() or _rescuing:
		return
	act_started.emit()
	if focus and focus.is_available():
		match focus.kind:
			"press":
				_do_press(focus)
			"magic", "coop":
				magic.cast_at(self, focus)
	else:
		magic.cast_ambient(self)


func _do_press(target: Interactable) -> void:
	busy = true
	face_toward(target.global_position.x - global_position.x)
	rig.play(target.press_anim)
	Audio.sfx("push", -2.0)
	await get_tree().create_timer(0.7).timeout
	target.activate("press")
	await get_tree().create_timer(0.35).timeout
	busy = false


func teleport(pos: Vector3) -> void:
	global_position = pos
	safe_pos = pos
	velocity = Vector3.ZERO
	if cam:
		cam.snap_to_target()


# ---- gentle fall recovery -------------------------------------------------------
func _rescue_fall() -> void:
	if _rescuing:
		return
	_rescuing = true
	fell.emit()
	velocity = Vector3.ZERO
	rig.play("fall")
	Audio.sfx("whoosh", -2.0)
	if flutter:
		flutter.mode = Flutter.Mode.CARRY
		flutter.follow_target = self
		flutter.global_position = global_position + Vector3(-2.0, 3.5, 0.5)
	await get_tree().create_timer(0.45).timeout
	var start := global_position + Vector3(0, 4.0, 0)
	global_position = start
	var end := safe_pos + Vector3(0, 0.05, 0)
	var tw := create_tween()
	tw.tween_method(func(k: float):
		var p := start.lerp(end, k)
		p.y += sin(k * PI) * 2.2
		global_position = p
		Fx.sparkle_burst(get_parent(), p + Vector3(0, 0.6, 0), Color(1, 0.85, 0.95), 2, 0.6, 0.2, 0.5), 0.0, 1.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	global_position = end
	velocity = Vector3.ZERO
	if cam:
		cam.snap_to_target()
	rig.play("giggle")
	rig.set_emotion("giggle")
	Audio.sfx("chime_soft")
	Dialogue.play_async("princess_fall_rescued")
	if flutter:
		flutter.celebrate()
		flutter.follow(self)
	await get_tree().create_timer(0.6).timeout
	rig.set_emotion("happy")
	_rescuing = false
