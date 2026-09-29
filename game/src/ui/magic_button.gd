class_name MagicButton
extends Control
## Big, glossy, icon-first button with a springy press and a sparkle burst. Works with mouse, touch,
## keyboard and gamepad (focus ring). Non-readers: the icon *is* the label.

signal pressed
signal pressed_down
signal released

var icon := "star"
var top_color := UiKit.PINK
var bottom_color := UiKit.PINK_D
var round := true
var attention := false          # gently pulses a ring to invite a tap
var disabled := false
var hold_mode := false          # true: emits pressed_down/released continuously (movement buttons)
var icon_scale := 0.5
var sfx_id := "ui_tap"
var badge_icon := ""            # small overlay icon (e.g. lock)
var dim_locked := false
var _down := false
var _hover := false
var _t := 0.0
var _sparks: Array[UiKit.Spark] = []
var _scale_tween: Tween


func _init(p_icon: String = "star", p_size: Vector2 = Vector2(120, 120)) -> void:
	icon = p_icon
	custom_minimum_size = p_size
	size = p_size
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	pivot_offset = size * 0.5
	resized.connect(func(): pivot_offset = size * 0.5)


func set_colors(top: Color, bottom: Color) -> MagicButton:
	top_color = top
	bottom_color = bottom
	queue_redraw()
	return self


func _process(delta: float) -> void:
	_t += delta
	var need := attention or _sparks.size() > 0 or _down or has_focus()
	if not need:
		return
	for s in _sparks:
		s.life -= delta
		s.pos += s.vel * delta
		s.vel *= 1.0 - delta * 2.0
	_sparks = _sparks.filter(func(s): return s.life > 0.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	var is_press: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	var is_release: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed) or (event is InputEventScreenTouch and not event.pressed)
	if is_press:
		_press_down()
		accept_event()
	elif is_release and _down:
		var inside := Rect2(Vector2.ZERO, size).has_point(event.position) if event is InputEventMouseButton else true
		_release(inside)
		accept_event()
	elif event.is_action_pressed("ui_accept") and has_focus():
		_press_down()
		_release(true)
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hover = true
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hover = false
		if _down and not hold_mode:
			_release(false)
		queue_redraw()
	elif what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT:
		queue_redraw()


func _press_down() -> void:
	_down = true
	_spring(0.9, 0.06)
	pressed_down.emit()
	queue_redraw()


func _release(inside: bool) -> void:
	_down = false
	released.emit()
	if inside:
		_spring(1.0, 0.35, true)
		_burst()
		Audio.sfx(sfx_id, 0.0, 1.0, 0.05)
		pressed.emit()
	else:
		_spring(1.0, 0.2)
	queue_redraw()


func _spring(target: float, time: float, overshoot: bool = false) -> void:
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween()
	if overshoot:
		_scale_tween.tween_property(self, "scale", Vector2.ONE * 1.12, time * 0.35).set_trans(Tween.TRANS_SINE)
		_scale_tween.tween_property(self, "scale", Vector2.ONE, time * 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_scale_tween.tween_property(self, "scale", Vector2.ONE * target, time).set_trans(Tween.TRANS_SINE)


func _burst() -> void:
	for i in 10:
		var s := UiKit.Spark.new()
		var a := randf() * TAU
		s.pos = size * 0.5 + Vector2(cos(a), sin(a)) * size.x * 0.25
		s.vel = Vector2(cos(a), sin(a)) * randf_range(90.0, 230.0)
		s.max_life = randf_range(0.45, 0.8)
		s.life = s.max_life
		s.size = randf_range(6.0, 12.0)
		s.color = [Color("#fff0a0"), Color("#ffc4e0"), Color("#c7e6ff"), Color.WHITE][randi() % 4]
		_sparks.append(s)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var rad := int(minf(size.x, size.y) * (0.5 if round else 0.3))
	var pressed_off := 4.0 if _down else 0.0
	# shadow
	draw_style_box(UiKit.box(Color(0.35, 0.15, 0.45, 0.30), rad), Rect2(Vector2(2, 7 - pressed_off * 0.5), size - Vector2(4, 4)))
	# body (bottom colour) + lighter top slab + gloss
	var body_col := bottom_color
	if disabled:
		body_col = body_col.lerp(Color(0.6, 0.6, 0.7), 0.6)
	var border := top_color.lightened(0.35)
	draw_style_box(UiKit.box(body_col, rad, border, 4), Rect2(Vector2(0, pressed_off), size - Vector2(0, 6)))
	var top_col := top_color if not disabled else top_color.lerp(Color(0.7, 0.7, 0.8), 0.6)
	draw_style_box(UiKit.box(top_col, rad), Rect2(Vector2(4, 4 + pressed_off), Vector2(size.x - 8, size.y * 0.72)))
	draw_style_box(UiKit.box(Color(1, 1, 1, 0.28), rad), Rect2(Vector2(size.x * 0.14, 8 + pressed_off), Vector2(size.x * 0.72, size.y * 0.26)))
	# icon
	var c := size * 0.5 + Vector2(0, -2 + pressed_off)
	IconArt.draw(self, icon, c, minf(size.x, size.y) * icon_scale, 0.35 if disabled else 0.0)
	if badge_icon != "":
		IconArt.draw(self, badge_icon, size - Vector2(size.x * 0.22, size.y * 0.22), minf(size.x, size.y) * 0.2)
	# attention ring
	if attention:
		var k := fmod(_t * 0.9, 1.0)
		var rr := lerpf(0.5, 0.78, k)
		draw_arc(size * 0.5, size.x * rr, 0, TAU, 48, Color(1, 0.95, 0.6, (1.0 - k) * 0.85), 5.0, true)
	if has_focus():
		draw_arc(size * 0.5, size.x * 0.56, 0, TAU, 48, Color("#fff0a0"), 5.0, true)
	# sparks
	for s in _sparks:
		var f := s.life / s.max_life
		var col := s.color
		col.a = f
		var r := s.size * (0.5 + f)
		var p := PackedVector2Array([s.pos + Vector2(0, -r), s.pos + Vector2(r * 0.25, -r * 0.25), s.pos + Vector2(r, 0), s.pos + Vector2(r * 0.25, r * 0.25),
			s.pos + Vector2(0, r), s.pos + Vector2(-r * 0.25, r * 0.25), s.pos + Vector2(-r, 0), s.pos + Vector2(-r * 0.25, -r * 0.25)])
		draw_colored_polygon(p, col)
