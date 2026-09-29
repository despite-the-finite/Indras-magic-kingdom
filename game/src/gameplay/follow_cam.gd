class_name FollowCam
extends Camera3D
## Automatic 2.5D camera. The child never touches it: it follows with look-ahead, stays inside level bounds,
## and can be handed to authored cinematic moves (`cine_to`) and released again.

var target: Node3D
var distance := 6.9
var height := 1.15
var look_height := 1.75
var lead_amount := 1.6
var min_x := -1000.0
var max_x := 1000.0
var min_y := -100.0
var zoom_bias := 0.0          # negative = closer (used for dialogue close-ups)
var facing := 1.0

var _focus := Vector3.ZERO
var _cur_look := Vector3.ZERO
var _cine_pos := Vector3.ZERO
var _cine_look := Vector3.ZERO
var _cine_weight := 0.0
var _cine_tween: Tween
var _shake := 0.0
var _shake_t := 0.0
var _fov_punch := 0.0
var _base_fov := 42.0
var _initialised := false
var _sway_t := 0.0
var _dlg_shift := 0.0


func _ready() -> void:
	fov = _base_fov
	current = true
	near = 0.1
	far = 250.0


func snap_to_target() -> void:
	if target == null:
		return
	_focus = _desired_focus()
	_cur_look = _focus
	_initialised = true
	_apply(0.0)


func _desired_focus() -> Vector3:
	var p := target.global_position
	# during story dialogue the camera looks lower so the characters sit above the dialogue bar
	_dlg_shift = lerpf(_dlg_shift, 1.15 if Dialogue.blocking else 0.0, 0.06)
	return Vector3(clampf(p.x + facing * lead_amount, min_x, max_x), maxf(p.y, min_y) + look_height - _dlg_shift, 0.0)


func _process(delta: float) -> void:
	if target != null:
		if not _initialised:
			snap_to_target()
		var want := _desired_focus()
		_focus.x = lerpf(_focus.x, want.x, 1.0 - exp(-delta * 3.2))
		# vertical: only chase when the child is well off centre (avoids seasick bobbing on every hop)
		var dy := want.y - _focus.y
		if absf(dy) > 0.9:
			_focus.y += (dy - signf(dy) * 0.9) * (1.0 - exp(-delta * 4.0))
		else:
			_focus.y = lerpf(_focus.y, want.y, 1.0 - exp(-delta * 0.9))
	_apply(delta)


func _apply(delta: float) -> void:
	_sway_t += delta
	var dist := distance + zoom_bias
	var follow_pos := Vector3(_focus.x, _focus.y + height - look_height + 0.2, dist)
	# a whisper of parallax drift so the world always feels alive
	if not Settings.reduce_motion:
		follow_pos.x += sin(_sway_t * 0.35) * 0.12
		follow_pos.y += sin(_sway_t * 0.27) * 0.06
	var follow_look := _focus + Vector3(0, -0.15, 0)
	var pos := follow_pos.lerp(_cine_pos, _cine_weight)
	var look := follow_look.lerp(_cine_look, _cine_weight)
	_cur_look = _cur_look.lerp(look, 1.0 - exp(-delta * 10.0)) if delta > 0.0 else look
	if _shake > 0.0 and not Settings.reduce_motion:
		_shake_t += delta * 40.0
		pos += Vector3(sin(_shake_t * 1.3), cos(_shake_t * 1.7), 0) * _shake * 0.12
		_shake = maxf(0.0, _shake - delta * 2.5)
	global_position = pos
	look_at(_cur_look, Vector3.UP)
	fov = _base_fov + _fov_punch
	_fov_punch = lerpf(_fov_punch, 0.0, 1.0 - exp(-delta * 5.0))


# ---- effects ------------------------------------------------------------------
func shake(amount: float = 0.6) -> void:
	_shake = maxf(_shake, amount)


func punch(fov_delta: float = -3.0) -> void:
	if not Settings.reduce_motion:
		_fov_punch = fov_delta


func set_zoom(bias: float, time: float = 0.8) -> void:
	create_tween().tween_property(self, "zoom_bias", bias, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---- cinematics -----------------------------------------------------------------
## Glide to an authored camera position looking at `look`. Awaitable.
func cine_to(pos: Vector3, look: Vector3, duration: float = 1.5) -> void:
	if _cine_tween:
		_cine_tween.kill()
	if _cine_weight < 0.01:
		# start the authored move from where the camera currently is
		_cine_pos = global_position
		_cine_look = _cur_look
		_cine_weight = 1.0
		_cine_tween = create_tween().set_parallel(true)
		_cine_tween.tween_property(self, "_cine_pos", pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_cine_tween.tween_property(self, "_cine_look", look, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		_cine_tween = create_tween().set_parallel(true)
		_cine_tween.tween_property(self, "_cine_pos", pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_cine_tween.tween_property(self, "_cine_look", look, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _cine_tween.finished


## Slow orbit around a point (celebrations).
func cine_orbit(center: Vector3, radius: float, height_y: float, from_deg: float, to_deg: float, duration: float) -> void:
	if _cine_tween:
		_cine_tween.kill()
	_cine_pos = global_position
	_cine_look = _cur_look
	_cine_weight = 1.0
	_cine_tween = create_tween()
	var start := _cine_pos
	_cine_tween.tween_method(func(v: float):
		var a := deg_to_rad(v)
		_cine_pos = center + Vector3(sin(a) * radius, height_y, cos(a) * radius)
		_cine_look = center + Vector3(0, 0.6, 0), from_deg, to_deg, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cine_pos = start
	await _cine_tween.finished


func cine_release(blend_time: float = 1.2) -> void:
	if _cine_tween:
		_cine_tween.kill()
	_cine_tween = create_tween()
	_cine_tween.tween_property(self, "_cine_weight", 0.0, blend_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _cine_tween.finished


func in_cinematic() -> bool:
	return _cine_weight > 0.01
