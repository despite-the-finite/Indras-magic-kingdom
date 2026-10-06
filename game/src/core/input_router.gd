extends Node
## Registers every input action in code (keyboard, gamepad, mouse/touch share the same actions)
## and tracks idle time + last-used device for the hint system and HUD.
##
## Actions:  move_left move_right move_up move_down  jump  magic  cycle_power  home  skip
## (jump = Up arrow / W / Space / pad A, so "press up to jump" is true on every device)

var _last_input_msec := 0
var last_device := "keyboard"     # keyboard | mouse | touch | gamepad


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_input_msec = Time.get_ticks_msec()
	_add("move_left",  [_key(KEY_LEFT), _key(KEY_A), _btn(JOY_BUTTON_DPAD_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_add("move_right", [_key(KEY_RIGHT), _key(KEY_D), _btn(JOY_BUTTON_DPAD_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_add("move_up",    [_key(KEY_UP), _key(KEY_W), _btn(JOY_BUTTON_DPAD_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add("move_down",  [_key(KEY_DOWN), _key(KEY_S), _btn(JOY_BUTTON_DPAD_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	# jump is the UP arrow first (what a small child reaches for), then W / Space / pad A / d-pad up
	_add("jump",       [_key(KEY_UP), _key(KEY_W), _key(KEY_SPACE), _btn(JOY_BUTTON_A), _btn(JOY_BUTTON_DPAD_UP)])
	_add("magic",      [_key(KEY_E), _key(KEY_ENTER), _key(KEY_KP_ENTER), _key(KEY_F), _btn(JOY_BUTTON_X)])
	_add("cycle_power",[_key(KEY_Q), _key(KEY_TAB), _btn(JOY_BUTTON_Y)])
	_add("home",       [_key(KEY_ESCAPE), _btn(JOY_BUTTON_START)])
	_add("skip",       [_key(KEY_SPACE), _key(KEY_ENTER), _key(KEY_UP), _btn(JOY_BUTTON_A)])


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		last_device = "keyboard"; _touch_activity()
	elif event is InputEventMouseButton and event.pressed:
		last_device = "mouse"; _touch_activity()
	elif event is InputEventScreenTouch and event.pressed:
		last_device = "touch"; _touch_activity()
	elif event is InputEventJoypadButton and event.pressed:
		last_device = "gamepad"; _touch_activity()
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.4:
		last_device = "gamepad"; _touch_activity()
	elif event is InputEventMouseMotion and event.velocity.length() > 250.0:
		_touch_activity()

	# tap/skip advances story dialogue (DialogueSystem ignores it for the first second of a line, so a
	# child drumming on the screen still hears what she needs to hear)
	if Dialogue.blocking:
		var tapped: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
		if tapped or event.is_action_pressed("skip"):
			Dialogue.skip()


func _touch_activity() -> void:
	_last_input_msec = Time.get_ticks_msec()


func idle_seconds() -> float:
	return float(Time.get_ticks_msec() - _last_input_msec) / 1000.0


# ---- helpers ---------------------------------------------------------------
func _add(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.35)
	for e in events:
		InputMap.action_add_event(action, e)


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


func _btn(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	return e


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e
