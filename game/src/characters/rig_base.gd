class_name RigBase
extends Node3D
## Shared behaviour for every expressive character: emotion -> procedural face, blinking, look-at,
## one-shot animations, facing/yaw, and movement inputs from the controller.
##
## Subclasses build their meshes in `_build()` and animate in `_pose(delta)`.
## Dialogue drives rigs by id through Actors (Events.character_cue -> set_emotion / play).

signal oneshot_finished(anim_name: String)

const THREE_QUARTER := deg_to_rad(34.0)   # how far a character turns toward its travel direction

## Emotion presets -> face shader parameters.
const EMOTIONS := {
	"neutral":    {"smile": 0.35, "mouth_open": 0.0, "mouth_round": 0.0, "brow_raise": 0.0, "brow_tilt": 0.0, "happy": 0.0, "sparkle": 0.0, "wet": 0.0, "tears": 0.0, "eye_scale": 1.0, "blush": 0.45},
	"happy":      {"smile": 0.85, "mouth_open": 0.25, "mouth_round": 0.0, "brow_raise": 0.2, "brow_tilt": 0.0, "happy": 0.0, "sparkle": 0.25, "wet": 0.0, "tears": 0.0, "eye_scale": 1.02, "blush": 0.6},
	"joyful":     {"smile": 1.0, "mouth_open": 0.8, "mouth_round": 0.0, "brow_raise": 0.3, "brow_tilt": 0.0, "happy": 0.9, "sparkle": 0.0, "wet": 0.0, "tears": 0.0, "eye_scale": 1.0, "blush": 0.8},
	"excited":    {"smile": 0.95, "mouth_open": 0.7, "mouth_round": 0.0, "brow_raise": 0.55, "brow_tilt": 0.0, "happy": 0.0, "sparkle": 0.8, "wet": 0.2, "tears": 0.0, "eye_scale": 1.12, "blush": 0.75},
	"surprised":  {"smile": 0.0, "mouth_open": 0.75, "mouth_round": 1.0, "brow_raise": 1.0, "brow_tilt": 0.0, "happy": 0.0, "sparkle": 0.6, "wet": 0.0, "tears": 0.0, "eye_scale": 1.2, "blush": 0.4},
	"wonder":     {"smile": 0.35, "mouth_open": 0.55, "mouth_round": 0.8, "brow_raise": 0.85, "brow_tilt": 0.0, "happy": 0.0, "sparkle": 1.0, "wet": 0.25, "tears": 0.0, "eye_scale": 1.18, "blush": 0.5},
	"curious":    {"smile": 0.25, "mouth_open": 0.0, "mouth_round": 0.0, "brow_raise": 0.5, "brow_tilt": -0.25, "happy": 0.0, "sparkle": 0.3, "wet": 0.0, "tears": 0.0, "eye_scale": 1.05, "blush": 0.4},
	"worried":    {"smile": -0.35, "mouth_open": 0.0, "mouth_round": 0.0, "brow_raise": 0.35, "brow_tilt": 0.85, "happy": 0.0, "sparkle": 0.0, "wet": 0.6, "tears": 0.0, "eye_scale": 1.08, "blush": 0.3},
	"sad":        {"smile": -0.85, "mouth_open": 0.25, "mouth_round": 0.0, "brow_raise": 0.1, "brow_tilt": 1.0, "happy": 0.0, "sparkle": 0.0, "wet": 1.0, "tears": 1.0, "eye_scale": 1.1, "blush": 0.2},
	"determined": {"smile": 0.4, "mouth_open": 0.0, "mouth_round": 0.0, "brow_raise": -0.1, "brow_tilt": -0.7, "happy": 0.0, "sparkle": 0.2, "wet": 0.0, "tears": 0.0, "eye_scale": 1.0, "blush": 0.5},
	"hopeful":    {"smile": 0.3, "mouth_open": 0.0, "mouth_round": 0.0, "brow_raise": 0.6, "brow_tilt": 0.7, "happy": 0.0, "sparkle": 0.9, "wet": 0.8, "tears": 0.0, "eye_scale": 1.18, "blush": 0.55},
	"sleepy":     {"smile": 0.25, "mouth_open": 0.0, "mouth_round": 0.0, "brow_raise": -0.2, "brow_tilt": 0.0, "happy": 0.0, "sparkle": 0.0, "wet": 0.0, "tears": 0.0, "eye_scale": 1.0, "blush": 0.5, "sleepy": 0.85},
	"proud":      {"smile": 0.8, "mouth_open": 0.0, "mouth_round": 0.0, "brow_raise": 0.25, "brow_tilt": 0.0, "happy": 0.25, "sparkle": 0.3, "wet": 0.0, "tears": 0.0, "eye_scale": 1.0, "blush": 0.6},
	"giggle":     {"smile": 1.0, "mouth_open": 0.55, "mouth_round": 0.0, "brow_raise": 0.3, "brow_tilt": 0.0, "happy": 1.0, "sparkle": 0.0, "wet": 0.0, "tears": 0.0, "eye_scale": 1.0, "blush": 0.9},
	"whisper":    {"smile": 0.15, "mouth_open": 0.15, "mouth_round": 0.6, "brow_raise": 0.3, "brow_tilt": 0.3, "happy": 0.0, "sparkle": 0.3, "wet": 0.2, "tears": 0.0, "eye_scale": 1.05, "blush": 0.4},
}
const EMOTION_ALIASES := {
	"warm": "happy", "gentle": "neutral", "joy": "joyful", "eager": "excited", "shy": "hopeful", "love": "joyful",
}

## One-shot animation names -> duration in seconds. Anything else is treated as a looping state.
var oneshots: Dictionary = {}

var face_mat: ShaderMaterial
var emotion := "neutral"
var anim := "idle"
var anim_t := 0.0
var _oneshot := ""
var _oneshot_t := 0.0
var _time := 0.0

## Movement inputs written by a controller (or a cinematic).
var move_speed := 0.0      # horizontal speed in m/s (signed by facing not needed)
var vertical_speed := 0.0
var grounded := true
var facing := 1.0          # +1 right, -1 left
var face_camera_amount := 0.0   # 0 = 3/4 toward travel dir, 1 = squarely toward the camera
var yaw_offset := 0.0

var _face_state: Dictionary = {}
var _face_target: Dictionary = {}
var _blink_timer := 2.5
var _blink_t := -1.0
var _look_target := Vector2.ZERO
var _look_now := Vector2.ZERO
var _look_world: Variant = null
var _look_timer := 0.0
var _land_squash := 0.0
var _was_grounded := true

var character_id := ""


func _ready() -> void:
	_build()
	_face_state = EMOTIONS["neutral"].duplicate()
	_face_target = _face_state.duplicate()
	if character_id != "":
		Actors.register(character_id, self)
	set_emotion("neutral")


func _exit_tree() -> void:
	if character_id != "":
		Actors.unregister(character_id, self)


# ---- to override -------------------------------------------------------------
func _build() -> void:
	pass


func _pose(_delta: float) -> void:
	pass


# ---- public api --------------------------------------------------------------
func set_emotion(e: String) -> void:
	e = EMOTION_ALIASES.get(e, e)
	if not EMOTIONS.has(e):
		return
	emotion = e
	_face_target = EMOTIONS[e].duplicate()
	if not _face_target.has("sleepy"):
		_face_target["sleepy"] = 0.0


func play(anim_name: String) -> void:
	if oneshots.has(anim_name):
		_oneshot = anim_name
		_oneshot_t = 0.0
		anim_t = 0.0
	else:
		if anim_name != anim:
			anim = anim_name
			anim_t = 0.0


func is_playing_oneshot() -> bool:
	return _oneshot != ""


func current_oneshot() -> String:
	return _oneshot


func oneshot_progress() -> float:
	if _oneshot == "":
		return 0.0
	return clampf(_oneshot_t / float(oneshots[_oneshot]), 0.0, 1.0)


func look_at_world(p: Variant) -> void:
	_look_world = p
	_look_timer = 2.5


func face_toward(dir: float) -> void:
	if absf(dir) > 0.01:
		facing = signf(dir)


func wave_hello() -> void:
	play("wave")


# ---- frame update -------------------------------------------------------------
func _process(delta: float) -> void:
	_time += delta
	anim_t += delta
	if _oneshot != "":
		_oneshot_t += delta
		if _oneshot_t >= float(oneshots[_oneshot]):
			var done := _oneshot
			_oneshot = ""
			oneshot_finished.emit(done)
	# landing squash
	if grounded and not _was_grounded:
		_land_squash = 1.0
	_was_grounded = grounded
	_land_squash = maxf(0.0, _land_squash - delta * 5.5)
	_update_yaw(delta)
	_pose(delta)
	_update_face(delta)


func _update_yaw(delta: float) -> void:
	var target := facing * THREE_QUARTER * (1.0 - face_camera_amount * 0.72) + yaw_offset
	# springy turn (slight overshoot feels alive)
	rotation.y = lerp_angle(rotation.y, target, 1.0 - exp(-delta * 11.0))


func squash_amount() -> float:
	return _land_squash


func _update_face(delta: float) -> void:
	if face_mat == null:
		return
	var k := 1.0 - exp(-delta * 12.0)
	for key in _face_target:
		_face_state[key] = lerpf(float(_face_state.get(key, 0.0)), float(_face_target[key]), k)
	# blinking
	_blink_timer -= delta
	var blink := 0.0
	if _blink_timer <= 0.0 and _blink_t < 0.0:
		_blink_t = 0.0
	if _blink_t >= 0.0:
		_blink_t += delta
		blink = sin(clampf(_blink_t / 0.16, 0.0, 1.0) * PI)
		if _blink_t > 0.16:
			_blink_t = -1.0
			_blink_timer = randf_range(2.0, 5.0)
	var sleepy: float = _face_state.get("sleepy", 0.0)
	blink = maxf(blink, sleepy)
	# eye gaze
	_look_timer -= delta
	if _look_world != null and _look_timer > 0.0:
		var local: Vector3 = to_local(_look_world)
		_look_target = Vector2(clampf(local.x * 0.6, -1.0, 1.0), clampf((local.y - 1.0) * 0.5, -1.0, 1.0))
	elif int(_time * 0.7) % 5 == 0:
		_look_target = Vector2(sin(_time * 0.9) * 0.35, cos(_time * 0.6) * 0.2)
	else:
		_look_target = Vector2.ZERO
	_look_now = _look_now.lerp(_look_target, 1.0 - exp(-delta * 7.0))

	var s := _face_state
	face_mat.set_shader_parameter("smile", s.get("smile", 0.3))
	var talk := 0.0
	if character_id != "" and Actors.speaking_id == character_id:
		talk = 0.22 + 0.4 * absf(sin(_time * 13.0)) * (0.6 + 0.4 * sin(_time * 5.3))
	face_mat.set_shader_parameter("mouth_open", maxf(s.get("mouth_open", 0.0), talk))
	face_mat.set_shader_parameter("mouth_round", s.get("mouth_round", 0.0))
	face_mat.set_shader_parameter("brow_raise", s.get("brow_raise", 0.0))
	face_mat.set_shader_parameter("brow_tilt", s.get("brow_tilt", 0.0))
	face_mat.set_shader_parameter("happy", s.get("happy", 0.0))
	face_mat.set_shader_parameter("sparkle", s.get("sparkle", 0.0))
	face_mat.set_shader_parameter("wet", s.get("wet", 0.0))
	face_mat.set_shader_parameter("tears", s.get("tears", 0.0))
	face_mat.set_shader_parameter("blush", s.get("blush", 0.45))
	face_mat.set_shader_parameter("eye_size", s.get("eye_scale", 1.0) * _base_eye_size())
	face_mat.set_shader_parameter("blink", clampf(blink, 0.0, 1.0))
	face_mat.set_shader_parameter("look", _look_now)


func _base_eye_size() -> float:
	return 1.0
