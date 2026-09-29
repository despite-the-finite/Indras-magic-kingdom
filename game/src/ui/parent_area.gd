class_name ParentArea
extends CanvasLayer
## Grown-ups only. A simple parent gate (a multiplication question a 4-6 year old cannot answer or read),
## then volume, narration/subtitles, graphics quality, accessibility, privacy info, and reset progress.
## No ads. No purchases. No network. Nothing here is reachable during normal play.

signal closed

var _root: Control
var _card: Panel
var _a := 0
var _b := 0
var _entry := ""
var _answer_label: Label
var _q_label: Label
var _reset_hold := 0.0
var _reset_btn: MagicButton
var _reset_ring: Control
var _holding_reset := false


func _ready() -> void:
	layer = 60
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.22, 0.1, 0.32, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_show_gate()


func _process(delta: float) -> void:
	if _holding_reset:
		_reset_hold += delta
		if _reset_ring:
			_reset_ring.queue_redraw()
		if _reset_hold >= 2.5:
			_holding_reset = false
			_reset_hold = 0.0
			GameState.reset_progress()
			Audio.sfx("chime_up")
			_show_panel()


func _clear_card() -> void:
	if _card:
		_card.queue_free()
	_card = Panel.new()
	_card.add_theme_stylebox_override("panel", UiKit.card_style(36))
	_root.add_child(_card)


func _close_btn() -> MagicButton:
	var b := MagicButton.new("close", Vector2(64, 64))
	b.set_colors(Color("#ffd0e0"), Color("#e0708f"))
	b.position = Vector2(_card.size.x - 76, 12)
	b.pressed.connect(func():
		closed.emit()
		queue_free())
	_card.add_child(b)
	return b


# ---- gate -------------------------------------------------------------------------
func _show_gate() -> void:
	_clear_card()
	UiKit.center(_card, Vector2(700, 560))
	_card.size = Vector2(700, 560)
	_close_btn()
	_a = randi_range(3, 9)
	_b = randi_range(6, 9)
	_entry = ""
	var head := UiKit.label("Grown-ups only", 40, UiKit.PLUM, true)
	head.position = Vector2(30, 20)
	_card.add_child(head)
	_q_label = UiKit.label("What is %d × %d ?" % [_a, _b], 44, UiKit.INK)
	_q_label.position = Vector2(30, 92)
	_card.add_child(_q_label)
	_answer_label = UiKit.label("", 60, UiKit.PINK_D, true)
	_answer_label.position = Vector2(30, 150)
	_card.add_child(_answer_label)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.position = Vector2(46, 250)
	_card.add_child(grid)
	for d in [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]:
		var nb := _num_button(str(d))
		nb.pressed.connect(func():
			if _entry.length() < 3:
				_entry += str(d)
				_answer_label.text = _entry)
		grid.add_child(nb)
	var ok := MagicButton.new("check", Vector2(96, 96))
	ok.set_colors(UiKit.MINT, UiKit.MINT_D)
	ok.position = Vector2(560, 150)
	ok.pressed.connect(func():
		if _entry == str(_a * _b):
			_show_panel()
		else:
			_entry = ""
			_answer_label.text = ""
			Audio.sfx("ui_soft", 0.0, 0.7))
	_card.add_child(ok)


func _num_button(text: String) -> Control:
	var b := MagicButton.new("sparkle", Vector2(104, 104))
	b.set_colors(Color("#e8dcff"), UiKit.LILAC_D)
	b.icon_scale = 0.0
	var l := UiKit.label(text, 54, UiKit.PLUM, true)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(l)
	return b


# ---- settings panel ------------------------------------------------------------------
func _show_panel() -> void:
	_clear_card()
	UiKit.center(_card, Vector2(1020, 640))
	_card.size = Vector2(1020, 640)
	_close_btn()
	var head := UiKit.label("Parent Area", 40, UiKit.PLUM, true)
	head.position = Vector2(30, 16)
	_card.add_child(head)
	var y := 86.0
	for row in [["Overall volume", "master"], ["Music", "music"], ["Voices", "voice"], ["Sound effects", "sfx"]]:
		var l := UiKit.label(row[0], 26, UiKit.INK)
		l.position = Vector2(34, y)
		_card.add_child(l)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = float(Settings.get(row[1]))
		s.position = Vector2(250, y + 6)
		s.custom_minimum_size = Vector2(320, 30)
		s.size = Vector2(320, 30)
		var key: String = row[1]
		s.value_changed.connect(func(v):
			Settings.set(key, v)
			Settings.save_settings()
			Audio.sfx("chime_soft", -8.0))
		_card.add_child(s)
		y += 54.0
	# toggles
	var ty := 86.0
	for t in [["Narration (spoken words)", "narration"], ["Subtitles for early readers", "subtitles"], ["Reduce motion & shake", "reduce_motion"], ["On-screen touch buttons", "touch_controls"]]:
		var l2 := UiKit.label(t[0], 26, UiKit.INK)
		l2.position = Vector2(600, ty)
		_card.add_child(l2)
		var key2: String = t[1]
		var tb := MagicButton.new("check" if Settings.get(key2) else "close", Vector2(60, 60))
		tb.position = Vector2(930, ty - 10)
		tb.set_colors(UiKit.MINT if Settings.get(key2) else Color("#ffd0e0"), UiKit.MINT_D if Settings.get(key2) else Color("#e0708f"))
		tb.pressed.connect(func():
			Settings.set(key2, not Settings.get(key2))
			Settings.save_settings()
			_show_panel())
		_card.add_child(tb)
		ty += 62.0
	# quality
	var ql := UiKit.label("Graphics", 26, UiKit.INK)
	ql.position = Vector2(34, 320)
	_card.add_child(ql)
	for q in 3:
		var qb := MagicButton.new(["star", "sparkle", "crown"][q], Vector2(70, 70))
		qb.position = Vector2(250 + q * 90, 300)
		var on := Settings.quality == q
		qb.set_colors(UiKit.GOLD if on else Color("#e8dcff"), UiKit.GOLD_D if on else UiKit.LILAC_D)
		qb.pressed.connect(func():
			Settings.quality = q
			Settings.save_settings()
			_show_panel())
		_card.add_child(qb)
	var qhint := UiKit.label("low  ·  medium  ·  high", 20, Color(0.45, 0.32, 0.55))
	qhint.position = Vector2(250, 378)
	_card.add_child(qhint)
	# privacy
	var pv := UiKit.label("Privacy: this game has no ads, no in-app purchases and no tracking. It never connects to the internet. Progress is stored only on this device.", 22, Color(0.4, 0.28, 0.5))
	pv.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.position = Vector2(34, 430)
	pv.size = Vector2(560, 90)
	_card.add_child(pv)
	# reset progress: press and hold
	var rl := UiKit.label("Reset story progress (hold the button)", 24, UiKit.INK)
	rl.position = Vector2(620, 380)
	_card.add_child(rl)
	_reset_btn = MagicButton.new("close", Vector2(110, 110))
	_reset_btn.set_colors(Color("#ffb0c0"), Color("#d04a6a"))
	_reset_btn.position = Vector2(700, 430)
	_reset_btn.pressed_down.connect(func(): _holding_reset = true; _reset_hold = 0.0)
	_reset_btn.released.connect(func(): _holding_reset = false; _reset_hold = 0.0; _reset_ring.queue_redraw())
	_reset_btn.hold_mode = true
	_card.add_child(_reset_btn)
	_reset_ring = Control.new()
	_reset_ring.position = _reset_btn.position
	_reset_ring.size = _reset_btn.size
	_reset_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reset_ring.draw.connect(func():
		if _reset_hold > 0.0:
			_reset_ring.draw_arc(_reset_ring.size * 0.5, 62, -PI * 0.5, -PI * 0.5 + TAU * (_reset_hold / 2.5), 40, Color("#fff0a0"), 8, true))
	_card.add_child(_reset_ring)
	var ver := UiKit.label("Indra's Magic Kingdom - vertical slice", 18, Color(0.55, 0.45, 0.65))
	ver.position = Vector2(34, 600)
	_card.add_child(ver)
