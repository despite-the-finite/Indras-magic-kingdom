class_name Ident
extends CanvasLayer
## The Entropic Labs opening ident: plays full-screen before the first scene, like a studio logo.
## Any tap, click, key or pad button skips it. If the video can't load or stalls it gets out of the way.
## Emits `finished` once the logo is done (the caller swaps in the first scene), then fades itself out.

signal finished

const VIDEO := "res://assets/video/entropic_ident.ogv"
const BG := Color(0.039, 0.043, 0.051)   # the ident's own background, so the square video's edges vanish
const FADE := 0.45
const STALL := 4.0                        # seconds without playback progress before giving up

var _root: ColorRect
var _player: VideoStreamPlayer
var _done := false
var _last_pos := -1.0
var _still := 0.0


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = ColorRect.new()
	_root.color = BG
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP   # nothing underneath sees the skip tap
	add_child(_root)

	var stream: VideoStream = load(VIDEO) if ResourceLoader.exists(VIDEO) else null
	if stream == null:
		push_warning("[Ident] video missing, skipping")
		_finish.call_deferred(true)
		return

	# Square video, letterboxed into whatever the window is.
	var box := AspectRatioContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.ratio = 1.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)
	_player = VideoStreamPlayer.new()
	_player.stream = stream
	_player.expand = true
	_player.volume_db = -80.0
	_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_player)
	_player.finished.connect(_finish)
	_player.play()


func _process(delta: float) -> void:
	if _done or _player == null:
		return
	var pos := _player.stream_position
	if pos != _last_pos:
		_last_pos = pos
		_still = 0.0
	else:
		_still += delta
		if _still > STALL:
			_finish()


func _input(event: InputEvent) -> void:
	var skip: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventJoypadButton and event.pressed)
	if skip or event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()   # keys/buttons never leak to the game while the logo is up
	if skip:
		_finish()


func _finish(immediate := false) -> void:
	if _done:
		return
	_done = true
	if _player:
		_player.paused = true
	finished.emit()
	if immediate:
		queue_free()
		return
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, FADE).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(queue_free)
