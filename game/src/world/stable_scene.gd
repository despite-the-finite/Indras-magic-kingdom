extends Node3D
## LUMI'S STABLE - Rescue & Care (Mode 2). Brush, feed, and hug Lumi; she reacts to everything.
## Care needs come from data/characters/lumi.json ("care.needs"); when all are met the friendship is sealed.

var char_id := "lumi"
var princess: PrincessRig
var lumi: UnicornRig
var cam: FollowCam
var ui: CanvasLayer
var tool_buttons: Dictionary = {}     # need id -> MagicButton
var pip_nodes: Dictionary = {}
var _hearts_ui: Control
var _busy := false
var _selected := ""
var _apple: Node3D
var _brush: Node3D
var _crown: Hud.CrownWidget
var _done_announced := false
var _lumi_home := Vector3(1.9, 0, 0)
var _princess_home := Vector3(-2.3, 0, 0)


func _ready() -> void:
	var env := EnvKit.apply(self, "stable_warm")
	_build_room()
	# actors
	princess = PrincessRig.new(GameState.appearance())
	add_child(princess)
	princess.position = _princess_home
	princess.facing = 1.0
	princess.face_camera_amount = 0.55
	lumi = UnicornRig.new(char_id)
	add_child(lumi)
	lumi.position = _lumi_home
	lumi.facing = -1.0
	lumi.face_camera_amount = 0.5
	cam = FollowCam.new()
	add_child(cam)
	cam.set_process(false)
	cam.global_position = Vector3(0.0, 2.0, 8.6)
	cam.look_at(Vector3(-0.1, 1.15, 0.0), Vector3.UP)
	cam.fov = 40.0
	_build_ui()
	Audio.play_music("stable_lullaby", 1.6)
	Audio.set_ambience(["stable_soft"])
	Events.hint_level_changed.connect(_on_hint)
	await get_tree().create_timer(0.5).timeout
	lumi.set_emotion("happy")
	princess.play("wave")
	_refresh_ui()
	if not GameState.care_complete(char_id):
		_set_next_hint()
	Hints.enabled = true


func _process(_delta: float) -> void:
	# a whisper of camera life
	var t := Time.get_ticks_msec() * 0.001
	cam.global_position = Vector3(sin(t * 0.3) * 0.15, 2.0 + sin(t * 0.23) * 0.05, 8.6)
	cam.look_at(Vector3(-0.1, 1.15, 0.0), Vector3.UP)


# =============================================================================
# room
# =============================================================================
func _build_room() -> void:
	var wood_floor := Mat.toon_grad(Color("#c9986a"), Color("#e8b888"), -1.0, 1.0, {"outline": false, "rim_amount": 0.0, "gradient_amount": 1.0})
	var floor := Build.box(self, Vector3(22.0, 0.4, 12.0), Vector3(0, -0.2, 0), wood_floor)
	# plank lines
	for i in 14:
		Build.box(self, Vector3(22.0, 0.01, 0.04), Vector3(0, 0.005, -5.0 + i * 0.75), Mat.toon(Color("#a87a50"), {"outline": false}))
	var wall := Mat.toon_grad(Color("#e8b8a0"), Color("#ffe0c8"), 0.0, 7.0, {"outline": false, "rim_amount": 0.1, "gradient_amount": 1.0, "shade_tint": Color(0.8, 0.5, 0.7)})
	Build.box(self, Vector3(22.0, 8.0, 0.4), Vector3(0, 4.0, -5.5), wall)
	for i in 22:
		Build.box(self, Vector3(0.05, 8.0, 0.05), Vector3(-10.5 + i, 4.0, -5.28), Mat.toon(Color("#c8987a"), {"outline": false}))
	# beams
	var beam_m := Mat.toon(Color("#8a5a48"), {"outline": 0.008})
	for i in 5:
		Build.box(self, Vector3(0.5, 0.5, 11.0), Vector3(-8.0 + i * 4.0, 7.4, 0.5), beam_m)
	Build.box(self, Vector3(22.0, 0.5, 0.5), Vector3(0, 7.4, -5.0), beam_m)
	# arched window with a soft sky
	var frame := Mat.toon(Color("#8a5a48"), {"outline": 0.01})
	Build.box(self, Vector3(3.4, 3.6, 0.3), Vector3(-4.2, 4.2, -5.25), frame)
	Build.box(self, Vector3(3.0, 3.2, 0.32), Vector3(-4.2, 4.2, -5.25), Mat.glowing(Color("#ffd8c0"), 1.1, {"outline": false}))
	Build.cyl(self, 1.5, 1.5, 0.3, Vector3(-4.2, 5.8, -5.25), frame, 20, Vector3(PI * 0.5, 0, 0))
	Build.cyl(self, 1.3, 1.3, 0.32, Vector3(-4.2, 5.8, -5.25), Mat.glowing(Color("#ffd8c0"), 1.1, {"outline": false}), 20, Vector3(PI * 0.5, 0, 0))
	Build.box(self, Vector3(0.14, 3.2, 0.36), Vector3(-4.2, 4.2, -5.22), frame)
	Build.box(self, Vector3(3.0, 0.14, 0.36), Vector3(-4.2, 4.2, -5.22), frame)
	# a big rainbow window on the right
	var arc := MeshInstance3D.new()
	arc.mesh = Build.arc_ribbon(1.6, 0.6, 180.0, 40)
	arc.material_override = Mat.rainbow_material()
	arc.position = Vector3(5.0, 3.2, -5.2)
	add_child(arc)
	# hay bed
	var hay := Mat.toon_grad(Color("#e8b850"), Color("#ffe288"), 0.0, 1.0, {"outline": 0.01, "rim_amount": 0.3, "gradient_amount": 1.0})
	Build.sphere(self, 1.0, Vector3(4.6, 0.3, -1.6), hay, Vector3(2.4, 0.5, 1.5), 16)
	Build.sphere(self, 0.6, Vector3(5.6, 0.6, -1.8), hay, Vector3(1.6, 0.6, 1.2), 12)
	for i in 4:
		Build.cyl(self, 0.6, 0.6, 1.0, Vector3(-7.0 + i * 0.4, 0.5 + (i % 2) * 0.9, -3.5), hay, 14, Vector3(0, 0, PI * 0.5))
	# apple bucket + brush rack + toys
	var bucket := Build.cyl(self, 0.5, 0.42, 0.7, Vector3(-6.6, 0.35, 1.2), Mat.toon(Color("#b98a68"), {"outline": 0.01}), 16)
	for i in 6:
		Build.sphere(self, 0.17, Vector3(-6.6 + cos(i * 1.0) * 0.25, 0.8 + (i % 2) * 0.05, 1.2 + sin(i * 1.0) * 0.25), Mat.toon([Color("#ff6f8f"), Color("#ffb04a"), Color("#a684ff"), Color("#66dd99")][i % 4], {"outline": 0.006, "rim_amount": 0.5}), Vector3.ONE, 10)
	# lanterns and garland
	for lx in [-7.0, -2.0, 3.0, 8.0]:
		var l := ForestProps.lantern(self, Vector3(lx, 6.4, -1.0), Color("#ffd890"))
		var ol := OmniLight3D.new()
		ol.light_color = Color(1, 0.82, 0.55)
		ol.light_energy = 0.55
		ol.omni_range = 9.0
		ol.position = Vector3(lx, 6.0, 0.5)
		add_child(ol)
	for i in 30:
		var t := float(i) / 29.0
		var gx := lerpf(-10.0, 10.0, t)
		var gy := 6.7 - sin(t * PI) * 0.8
		Build.sphere(self, 0.1, Vector3(gx, gy, -4.7), Mat.toon([Mat.PINK, Color.WHITE, Mat.SUN, Mat.LILAC][i % 4], {"outline": false}), Vector3.ONE, 8)
		Build.sphere(self, 0.08, Vector3(gx + 0.15, gy + 0.02, -4.65), Mat.toon(Mat.LEAF, {"outline": false}), Vector3(1.4, 0.7, 1), 6)
	# floating warm sparkles
	Fx.pollen(self, Vector3(0, 3.0, 0), Vector3(8, 2.5, 3), 44, Color(1, 0.9, 0.6, 0.8))
	Fx.fireflies(self, Vector3(0, 3.0, -1), Vector3(8, 2.5, 3), 24, Color(1, 0.95, 0.6))
	ForestProps.light_shafts(self, Vector3(-4.2, 0, 0), 2, 3.0, Color(1, 0.88, 0.6, 0.16), 21)


# =============================================================================
# UI
# =============================================================================
func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	_crown = Hud.CrownWidget.new()
	_crown.position = Vector2(22, 18)
	root.add_child(_crown)
	var home := MagicButton.new("castle", Vector2(96, 96))
	home.set_colors(UiKit.LILAC, UiKit.LILAC_D)
	home.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	home.position = Vector2(-120, 18)
	home.pressed.connect(func(): Router.go("castle"))
	root.add_child(home)
	# friendship hearts (fill as each need is met)
	_hearts_ui = Control.new()
	_hearts_ui.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hearts_ui.position = Vector2(-150, 22)
	_hearts_ui.custom_minimum_size = Vector2(300, 80)
	_hearts_ui.size = Vector2(300, 80)
	_hearts_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hearts_ui.draw.connect(_draw_hearts)
	root.add_child(_hearts_ui)
	# tool bar
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 54)
	bar.position = Vector2(-300, -220)
	bar.size = Vector2(600, 200)
	root.add_child(bar)
	var needs: Array = Content.character(char_id).get("care", {}).get("needs", [])
	var colors := {"brush": [Color("#ffb0e0"), UiKit.PINK_D], "feed": [Color("#ffd27a"), Color("#e0902a")], "hug": [Color("#ff9ab8"), Color("#d9528f")]}
	for n in needs:
		var b := MagicButton.new(String(n.tool), Vector2(168, 168))
		var cc: Array = colors.get(n.id, [UiKit.PINK, UiKit.PINK_D])
		b.set_colors(cc[0], cc[1])
		b.icon_scale = 0.5
		b.pressed.connect(_on_tool.bind(String(n.id)))
		var wrap := VBoxContainer.new()
		wrap.add_theme_constant_override("separation", 6)
		wrap.add_child(b)
		var pips := Control.new()
		pips.custom_minimum_size = Vector2(168, 30)
		pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.draw.connect(_draw_pips.bind(pips, String(n.id), int(n.count)))
		wrap.add_child(pips)
		bar.add_child(wrap)
		tool_buttons[n.id] = b
		pip_nodes[n.id] = pips
	var dlg := Hud.DialogueBar.new()
	root.add_child(dlg)


func _draw_pips(c: Control, need: String, total: int) -> void:
	var have := GameState.care_count(char_id, need)
	var w := 26.0
	var start := (c.size.x - total * w) * 0.5
	for i in total:
		var p := Vector2(start + i * w + w * 0.5, 15)
		if i < have:
			IconArt.draw(c, "heart", p, 11)
		else:
			c.draw_circle(p, 8, Color(0.75, 0.68, 0.85, 0.55))


func _draw_hearts() -> void:
	var total: int = Content.character(char_id).get("care", {}).get("needs", []).size()
	var have := GameState.friendship_hearts(char_id)
	var x0: float = (_hearts_ui.size.x - total * 84.0) * 0.5
	_hearts_ui.draw_style_box(UiKit.box(Color(1, 0.96, 0.9, 0.85), 40, Color("#ffd9a0"), 4, 8), Rect2(Vector2(x0 - 12, 0), Vector2(total * 84.0 + 24, 76)))
	for i in total:
		var p := Vector2(x0 + i * 84.0 + 42, 38)
		if i < have:
			IconArt.draw(_hearts_ui, "heart", p, 28)
		else:
			_hearts_ui.draw_circle(p, 22, Color(0.75, 0.68, 0.85, 0.5))


func _refresh_ui() -> void:
	_hearts_ui.queue_redraw()
	for k in pip_nodes:
		pip_nodes[k].queue_redraw()


# =============================================================================
# care actions
# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
	if tap and _selected != "" and not _busy:
		var head := cam.unproject_position(lumi.head_world())
		var body := cam.unproject_position(lumi.global_position + Vector3(0, 0.7, 0))
		var pos: Vector2 = event.position
		if pos.distance_to(head) < 110.0 or pos.distance_to(body) < 150.0:
			_on_tool(_selected)
	if event.is_action_pressed("cycle_power"):
		var keys := tool_buttons.keys()
		var i := keys.find(_selected)
		_selected = keys[(i + 1) % keys.size()]
		_mark_selected()
	if event.is_action_pressed("magic") and _selected != "" and not _busy:
		_on_tool(_selected)
	if event.is_action_pressed("home"):
		Router.go("castle")


func _mark_selected() -> void:
	for k in tool_buttons:
		tool_buttons[k].scale = Vector2.ONE * (1.08 if k == _selected else 1.0)


func _on_tool(need: String) -> void:
	if _busy or Dialogue.blocking:
		return
	_selected = need
	_mark_selected()
	match need:
		"brush": await _do_brush()
		"feed": await _do_feed()
		"hug": await _do_hug()
	_refresh_ui()


func _walk_princess_to(x: float) -> void:
	princess.face_toward(x - princess.position.x)
	princess.move_speed = 3.6
	var tw := create_tween()
	tw.tween_property(princess, "position:x", x, absf(x - princess.position.x) / 3.6).set_trans(Tween.TRANS_SINE)
	await tw.finished
	princess.move_speed = 0.0
	princess.face_toward(lumi.position.x - princess.position.x)


func _after_action(need: String) -> void:
	var done := GameState.record_care(char_id, need)
	Events.custom_event.emit("care_" + need)
	_refresh_ui()
	Hints.reset_progress()
	if done:
		var seq: String = Content.character(char_id).get("care", {}).get("need_dialogue", {}).get(need, "")
		if seq != "":
			await Dialogue.play(seq)
		Audio.sfx("chime_up")
		Fx.heart_burst(self, lumi.head_world() + Vector3(0, 0.6, 0), 10)
	if GameState.care_complete(char_id) and not _done_announced:
		_done_announced = true
		await _friends_forever()
	else:
		_set_next_hint()


func _do_brush() -> void:
	_busy = true
	await _walk_princess_to(lumi.position.x - 1.5)
	if _brush == null:
		_brush = Build.pivot(self, Vector3.ZERO)
		var b := Build.box(_brush, Vector3(0.5, 0.12, 0.22), Vector3.ZERO, Mat.toon(Color("#ff8fbf"), {"outline": 0.008}))
		Build.box(_brush, Vector3(0.2, 0.06, 0.16), Vector3(0.0, -0.09, 0), Mat.toon(Color("#fff0f8"), {"outline": false}))
		Build.cyl(_brush, 0.03, 0.03, 0.5, Vector3(-0.3, 0.2, 0), Mat.toon(Color("#c98a5e"), {"outline": 0.006}), 8, Vector3(0, 0, 0.5))
	_brush.visible = true
	princess.play("brush")
	lumi.set_emotion("joyful")
	lumi.play("brush_enjoy")
	Audio.sfx("brush", -2.0)
	var start := lumi.global_position + Vector3(-0.2, 1.15, 0.4)
	var tw := create_tween().set_loops(3)
	tw.tween_method(func(k): _brush.global_position = start + Vector3(k * 1.1, -abs(k - 0.5) * 0.15, 0.0), 0.0, 1.0, 0.16)
	tw.tween_method(func(k): _brush.global_position = start + Vector3(1.1 - k * 1.1, 0.0, 0.0), 0.0, 1.0, 0.16)
	for i in 6:
		await get_tree().create_timer(0.17).timeout
		Fx.sparkle_burst(self, lumi.global_position + Vector3(-0.5 + i * 0.25, 1.1, 0.5), [Mat.PINK, Mat.LILAC, Mat.SKY][i % 3], 6, 1.5, 0.26, 0.9)
	tw.kill()
	_brush.visible = false
	await get_tree().create_timer(0.3).timeout
	await _after_action("brush")
	await _return_princess()
	_busy = false


func _do_feed() -> void:
	_busy = true
	await _walk_princess_to(lumi.position.x - 2.2)
	princess.play("feed")
	if _apple == null:
		_apple = Build.pivot(self, Vector3.ZERO)
		var m := Mat.toon(Color("#ff7f9f"), {"outline": 0.01, "rim_amount": 0.6, "glitter": 0.3})
		Build.sphere(_apple, 0.2, Vector3(-0.1, 0, 0), m, Vector3.ONE, 14)
		Build.sphere(_apple, 0.2, Vector3(0.1, 0, 0), m, Vector3.ONE, 14)
		Build.cyl(_apple, 0.015, 0.015, 0.14, Vector3(0, 0.2, 0), Mat.toon(Color("#8a5a3c"), {}), 6)
		Build.sphere(_apple, 0.06, Vector3(0.1, 0.24, 0), Mat.toon(Mat.MINT, {}), Vector3(1.5, 0.5, 1), 8)
		Fx.glow_sprite(_apple, Vector3.ZERO, Color(1, 0.8, 0.95, 0.6), 0.9)
	_apple.visible = true
	_apple.scale = Vector3.ONE
	var from := princess.global_position + Vector3(0.7, 0.95, 0.3)
	var to := lumi.head_world() + Vector3(-0.35, -0.35, 0.3)
	_apple.global_position = from
	Audio.sfx("whoosh", -6.0, 1.4)
	var tw := create_tween()
	tw.tween_method(func(k: float): _apple.global_position = from.lerp(to, k) + Vector3(0, sin(k * PI) * 0.7, 0), 0.0, 1.0, 0.7)
	await tw.finished
	_apple.visible = false
	lumi.set_emotion("joyful")
	lumi.play("eat")
	Audio.sfx("munch", -2.0)
	Fx.sparkle_burst(self, to, Color(1, 0.8, 0.9), 16, 2.0, 0.26, 0.8)
	for c in [Color("#ff6f8f"), Color("#ffe066"), Color("#66dd99"), Color("#5cb8ff")]:
		Fx.sparkle_burst(self, to + Vector3(0, 0.1, 0.1), c, 4, 1.4, 0.22, 0.9)
	await get_tree().create_timer(1.1).timeout
	await _after_action("feed")
	await _return_princess()
	_busy = false


func _do_hug() -> void:
	_busy = true
	await _walk_princess_to(lumi.position.x - 1.35)
	princess.play("hug")
	lumi.set_emotion("joyful")
	lumi.play("hug")
	princess.set_emotion("joyful")
	Audio.sfx("hug_chime")
	await get_tree().create_timer(0.5).timeout
	Fx.heart_burst(self, (princess.global_position + lumi.global_position) * 0.5 + Vector3(0, 1.8, 0), 12)
	await get_tree().create_timer(1.3).timeout
	await _after_action("hug")
	princess.set_emotion("happy")
	await _return_princess()
	_busy = false


func _return_princess() -> void:
	await _walk_princess_to(_princess_home.x)
	princess.face_toward(1.0)


# =============================================================================
# friendship sealed
# =============================================================================
func _friends_forever() -> void:
	_busy = true
	Hints.stop()
	Audio.sting("rescue_sting")
	lumi.set_emotion("joyful")
	lumi.play("happy_jump")
	princess.play("celebrate")
	Fx.star_shower(self, Vector3(0, 6.0, 0), 50)
	await Dialogue.play(String(Content.character(char_id).get("care", {}).get("all_done_dialogue", "")))
	await Dialogue.play("care_best_friends")
	GameState.advance_stage(char_id, GameState.Stage.FRIENDS)
	await get_tree().create_timer(1.2).timeout
	Router.go("castle", {"arrival": "care_done"})


# =============================================================================
# guidance
# =============================================================================
func _set_next_hint() -> void:
	var needs: Array = Content.character(char_id).get("care", {}).get("needs", [])
	for n in needs:
		if GameState.care_count(char_id, n.id) < int(n.count):
			Hints.watch_step({"id": "care_" + n.id, "hint": {"voice": "care_hint_" + n.id, "voice_alt": "care_hint_" + n.id, "target": "tool_" + n.id}})
			return
	Hints.stop()


func _on_hint(level: int, target: String) -> void:
	for k in tool_buttons:
		tool_buttons[k].attention = level >= 2 and target == "tool_" + k
