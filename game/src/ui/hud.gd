class_name Hud
extends CanvasLayer
## In-level HUD. Icon-first and minimal: crown progress (no numbers), one big magic button, jump,
## move arrows for touch, a prompt bubble above whatever she can use, and story dialogue with portraits.

signal home_requested
signal map_requested

var player: Player
var cam: Camera3D

var _crown: CrownWidget
var _magic_btn: MagicButton
var _jump_btn: MagicButton
var _left_btn: MagicButton
var _right_btn: MagicButton
var _home_btn: MagicButton
var _prompt: PromptBubble
var _dialogue: DialogueBar
var _pause: Control
var _fly_layer: Control
var _root: Control
var _hint_btn: MagicButton


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_crown = CrownWidget.new()
	_crown.position = Vector2(22, 18)
	_root.add_child(_crown)

	_home_btn = MagicButton.new("home", Vector2(84, 84))
	_home_btn.set_colors(UiKit.LILAC, UiKit.LILAC_D)
	_home_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_home_btn.position = Vector2(-106, 18)
	_home_btn.pressed.connect(_open_pause)
	_root.add_child(_home_btn)

	_magic_btn = MagicButton.new("magic", Vector2(168, 168))
	_magic_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_magic_btn.position = Vector2(-198, -198)
	_magic_btn.icon_scale = 0.46
	_magic_btn.set_colors(Color("#ffb0e0"), UiKit.PINK_D)
	_magic_btn.sfx_id = "ui_magic"
	_magic_btn.pressed.connect(func(): if player: player.try_act())
	_root.add_child(_magic_btn)

	_jump_btn = MagicButton.new("up", Vector2(116, 116))
	_jump_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_jump_btn.position = Vector2(-352, -150)
	_jump_btn.set_colors(UiKit.SKY, UiKit.SKY_D)
	_jump_btn.hold_mode = true
	_jump_btn.sfx_id = "ui_soft"
	_jump_btn.pressed_down.connect(func(): Input.action_press("jump"); Input.action_release("jump"))
	_root.add_child(_jump_btn)

	_left_btn = MagicButton.new("left", Vector2(128, 128))
	_left_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_left_btn.position = Vector2(24, -166)
	_left_btn.set_colors(UiKit.MINT, UiKit.MINT_D)
	_left_btn.hold_mode = true
	_left_btn.pressed_down.connect(func(): Input.action_press("move_left"))
	_left_btn.released.connect(func(): Input.action_release("move_left"))
	_root.add_child(_left_btn)
	_right_btn = MagicButton.new("right", Vector2(128, 128))
	_right_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_right_btn.position = Vector2(170, -166)
	_right_btn.set_colors(UiKit.MINT, UiKit.MINT_D)
	_right_btn.hold_mode = true
	_right_btn.pressed_down.connect(func(): Input.action_press("move_right"))
	_right_btn.released.connect(func(): Input.action_release("move_right"))
	_root.add_child(_right_btn)

	_prompt = PromptBubble.new()
	_root.add_child(_prompt)

	_dialogue = DialogueBar.new()
	_root.add_child(_dialogue)

	_fly_layer = Control.new()
	_fly_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fly_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fly_layer)

	Events.star_earned.connect(_on_star_earned)
	Events.stars_changed.connect(func(_t, _d): _crown.refresh())


func _process(_delta: float) -> void:
	var touch := Settings.touch_controls or InputRouter.last_device == "touch"
	_left_btn.visible = touch
	_right_btn.visible = touch
	_jump_btn.visible = true
	_magic_btn.visible = not Dialogue.blocking
	_jump_btn.visible = not Dialogue.blocking
	_left_btn.visible = touch and not Dialogue.blocking
	_right_btn.visible = touch and not Dialogue.blocking
	if player == null:
		return
	var f := player.nearest_prompt()
	if f:
		var icon := f.prompt_icon()
		_magic_btn.icon = "magic" if f.kind == "touch" else ("hand" if f.kind == "press" else icon)
		_magic_btn.attention = true
		if cam and not cam.is_position_behind(f.global_position + Vector3(0, f.halo_height + 0.6, 0)):
			_prompt.show_at(cam.unproject_position(f.global_position + Vector3(0, f.halo_height + 0.9, 0)), icon)
		else:
			_prompt.hide_prompt()
	else:
		_magic_btn.icon = "magic"
		_magic_btn.attention = false
		_prompt.hide_prompt()
	_magic_btn.queue_redraw()


func crown_target() -> Vector2:
	return _crown.global_position + Vector2(56, 44)


# ---- star reward: flies from the world into the crown ---------------------------
func _on_star_earned(amount: int, world_pos: Vector3, _reason: String) -> void:
	var from := get_viewport().get_visible_rect().size * 0.5
	if world_pos != Vector3.ZERO and cam and not cam.is_position_behind(world_pos):
		from = cam.unproject_position(world_pos)
	for i in amount:
		var s := StarFly.new()
		_fly_layer.add_child(s)
		s.global_position = from + Vector2(randf_range(-30, 30), randf_range(-20, 20)) - Vector2(30, 30)
		s.launch(crown_target() - Vector2(30, 30), float(i) * 0.28)


func _open_pause() -> void:
	if _pause:
		return
	_pause = Control.new()
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0.1, 0.35, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.add_child(dim)
	var box := HBoxContainer.new()
	UiKit.center(box, Vector2(660, 200))
	box.add_theme_constant_override("separation", 40)
	var b_play := MagicButton.new("play", Vector2(190, 190))
	b_play.set_colors(UiKit.MINT, UiKit.MINT_D)
	b_play.pressed.connect(_close_pause)
	var b_home := MagicButton.new("castle", Vector2(190, 190))
	b_home.set_colors(UiKit.PINK, UiKit.PINK_D)
	b_home.pressed.connect(func(): _close_pause(); home_requested.emit())
	var b_map := MagicButton.new("map", Vector2(190, 190))
	b_map.set_colors(UiKit.LILAC, UiKit.LILAC_D)
	b_map.pressed.connect(func(): _close_pause(); map_requested.emit())
	for b in [b_play, b_home, b_map]:
		box.add_child(b)
	_pause.add_child(box)
	_root.add_child(_pause)
	b_play.grab_focus()
	get_tree().paused = false


func _close_pause() -> void:
	if _pause:
		_pause.queue_free()
		_pause = null


# ---------------------------------------------------------------------------
class PromptBubble extends Control:
	var _icon := "magic"
	var _t := 0.0
	var _on := false
	var _pos := Vector2.ZERO

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func show_at(p: Vector2, icon: String) -> void:
		_pos = p
		_icon = icon
		_on = true
		queue_redraw()

	func hide_prompt() -> void:
		if _on:
			_on = false
			queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if _on:
			queue_redraw()

	func _draw() -> void:
		if not _on:
			return
		var bob := sin(_t * 5.0) * 6.0
		var c := _pos + Vector2(0, bob)
		draw_circle(c + Vector2(0, 4), 46, Color(0.35, 0.15, 0.45, 0.25))
		draw_circle(c, 44, Color("#ffd9a0"))
		draw_circle(c, 39, UiKit.CREAM)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-12, 36), c + Vector2(12, 36), c + Vector2(0, 56)]), Color("#ffd9a0"))
		draw_colored_polygon(PackedVector2Array([c + Vector2(-9, 35), c + Vector2(9, 35), c + Vector2(0, 50)]), UiKit.CREAM)
		IconArt.draw(self, _icon, c, 26)


class StarFly extends Control:
	var _t := 0.0
	var _delay := 0.0
	var _from := Vector2.ZERO
	var _to := Vector2.ZERO
	var _mid := Vector2.ZERO
	var _launched := false

	func _init() -> void:
		size = Vector2(60, 60)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		modulate.a = 0.0

	func launch(target: Vector2, delay: float) -> void:
		_from = global_position
		_to = target
		_mid = _from.lerp(_to, 0.4) + Vector2(0, -160)
		_delay = delay
		_launched = true
		Audio.sfx("star_get", -2.0, 1.0 + delay * 0.4)

	func _process(delta: float) -> void:
		if not _launched:
			return
		_t += delta
		var k := clampf((_t - _delay) / 1.5, 0.0, 1.0)
		if k <= 0.0:
			return
		modulate.a = 1.0
		# ease out then in: pop up big, hover, zip to the crown
		var hover := smoothstep(0.0, 0.35, k)
		var zip := smoothstep(0.55, 1.0, k)
		var p := _from.lerp(_mid, hover).lerp(_to, zip)
		global_position = p
		scale = Vector2.ONE * (0.6 + 1.4 * sin(hover * PI * 0.5) - 1.2 * zip)
		pivot_offset = size * 0.5
		rotation = sin(k * TAU) * 0.2
		queue_redraw()
		if k >= 1.0:
			queue_free()

	func _draw() -> void:
		draw_circle(size * 0.5, 30, Color(1, 0.9, 0.5, 0.25))
		IconArt.draw(self, "star", size * 0.5, 26)


# ---------------------------------------------------------------------------
class CrownWidget extends Control:
	## Shows the crown with its earned jewels. The ring fills toward the next jewel.

	func _init() -> void:
		custom_minimum_size = Vector2(150, 96)
		size = Vector2(150, 96)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func refresh() -> void:
		queue_redraw()

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var lvl := GameState.crown_level()
		var prog := GameState.crown_progress()
		draw_style_box(UiKit.box(Color(1, 0.96, 0.9, 0.86), 44, Color("#ffd9a0"), 4, 8), Rect2(Vector2(0, 6), Vector2(150, 84)))
		var c := Vector2(52, 50)
		# progress ring toward next jewel
		draw_arc(c, 40, 0, TAU, 40, Color(0.8, 0.7, 0.9, 0.35), 7, true)
		var f := float(prog.into) / maxf(float(prog.needed), 1.0)
		draw_arc(c, 40, -PI * 0.5, -PI * 0.5 + TAU * f, 40, Color("#ffc94d"), 7, true)
		IconArt.draw(self, "crown", c + Vector2(0, 2), 26)
		# jewels earned so far (one per crown level)
		for i in 5:
			var p := Vector2(104 + (i % 3) * 14 - 4, 34 + (i / 3) * 24)
			var lit := i < lvl
			var cols := [Mat.PINK, Mat.SKY, Mat.MINT, Mat.LILAC, Mat.SUN]
			draw_circle(p, 8, Color(0.75, 0.68, 0.85, 0.5) if not lit else cols[i].lightened(0.1))
			if lit:
				draw_circle(p + Vector2(-2, -2), 2.5, Color(1, 1, 1, 0.9))


# ---------------------------------------------------------------------------
class DialogueBar extends Control:
	var _portrait: Portrait
	var _label: Label
	var _panel: Control
	var _card: Panel
	var _active := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _ready() -> void:
		_panel = Control.new()
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_panel.offset_top = -148
		_panel.offset_bottom = -16
		_panel.offset_left = 120
		_panel.offset_right = -120
		add_child(_panel)
		_card = Panel.new()
		_card.add_theme_stylebox_override("panel", UiKit.card_style(40))
		_card.position = Vector2(48, 12)
		_card.size = Vector2(700, 108)
		_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel.add_child(_card)
		_portrait = Portrait.new(116)
		_portrait.position = Vector2(0, 4)
		_panel.add_child(_portrait)
		_label = UiKit.label("", 30, UiKit.INK)
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.position = Vector2(138, 14)
		_label.size = Vector2(700, 96)
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_panel.add_child(_label)
		_panel.modulate.a = 0.0
		_panel.visible = false
		Events.dialogue_line_started.connect(_on_line)
		Events.dialogue_line_finished.connect(func(_l): _hide())
		Events.dialogue_finished.connect(func(_s): _hide())

	func _on_line(line: Dictionary) -> void:
		var hint: bool = line.get("kind", "") == "hint"
		_active = true
		_panel.visible = true
		_label.text = String(line.get("text", "")) if Settings.subtitles else ""
		_portrait.speaking = true
		_portrait.set_character(line.get("character", "narrator"), line.get("emotion", "neutral"))
		# panel width follows the viewport
		var w := get_viewport_rect().size.x - 240.0
		_label.size.x = w - 190.0
		_card.size = Vector2(w - 48.0, 108.0)
		create_tween().tween_property(_panel, "modulate:a", 1.0, 0.18)

	func _hide() -> void:
		if Dialogue.speaking:
			# another line is about to start; keep the bar up
			await get_tree().process_frame
			if Dialogue.speaking:
				return
		_portrait.speaking = false
		var tw := create_tween()
		tw.tween_property(_panel, "modulate:a", 0.0, 0.25)
		tw.tween_callback(func(): if not Dialogue.speaking: _panel.visible = false)
