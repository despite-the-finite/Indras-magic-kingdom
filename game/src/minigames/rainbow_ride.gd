extends MiniAdventure
## RAINBOW RIDE WITH LUMI (Mode 4 mini adventure).
## The princess rides Lumi through a sparkling meadow. Lean left/right to slow or speed up, jump, gather stars,
## gallop over rainbow roads for a boost, hop tiny streams, bounce on flower bursts, and wave at butterflies.
## There is no losing: a splash just makes Lumi giggle.

const CHUNK := 16.0
const BASE_SPEED := 9.5
const GRAV := 26.0
const JUMP_V := 9.8

var lumi: UnicornRig
var princess: PrincessRig
var rider: Node3D
var terrain: Terrain
var env: Dictionary
var chunks: Dictionary = {}          # chunk index -> Node3D
var stars: Array[Dictionary] = []    # {node, pos, taken}
var pads: Array[Dictionary] = []
var streams: Array[Dictionary] = []
var roads: Array[Dictionary] = []
var butterflies: Array[Flutter] = []
var x := 0.0
var y := 0.0
var vy := 0.0
var speed := BASE_SPEED
var boost := 0.0
var splash_t := 0.0
var length := 950.0
var time_left := 100.0
var total_stars_spawned := 0
var _next_chunk := 0
var _finished := false
var _rng := RandomNumberGenerator.new()
var _star_label: Label
var _star_widget: Control
var _left_btn: MagicButton
var _right_btn: MagicButton
var _jump_btn: MagicButton
var _combo := 0
var _combo_t := 0.0
var _trail: GPUParticles3D
var _hold_dir := 0.0
var _finish_x := 0.0


func _setup() -> void:
	_rng.seed = int(Time.get_unix_time_from_system())
	length = float(def.get("duration_seconds", 100)) * BASE_SPEED * 0.92
	_finish_x = length
	env = EnvKit.apply(self, "rainbow_sky")
	terrain = Terrain.build(self, [{"x0": -30.0, "x1": length + 60.0, "pts": [[-30, 0.0], [length + 60.0, 0.0]]}], {"top_color": Color("#6cc84c"), "top_color_far": Color("#2a9a66"), "step": 1.0, "z_back": -60.0})
	ForestProps.backdrop(self, -30.0, 60.0, [Color("#a6b4f2"), Color("#8ac4d8"), Color("#66c6a0")])
	# cast
	lumi = UnicornRig.new("lumi")
	rider = Node3D.new()
	add_child(rider)
	rider.add_child(lumi)
	lumi.facing = 1.0
	lumi.set_emotion("excited")
	lumi.play("happy")
	princess = PrincessRig.new(GameState.appearance())
	lumi.body.add_child(princess)
	princess.position = Vector3(0, 0.74, -0.05)
	princess.scale = Vector3.ONE * 0.72
	princess.facing = 0.0
	princess.anim = "ride"
	princess.set_emotion("joyful")
	_trail = Fx.trail(rider, Color(1, 0.85, 0.98), 46)
	_trail.position = Vector3(-0.7, 0.4, 0)
	cam = FollowCam.new()
	cam.lead_amount = 3.2
	cam.distance = 8.4
	add_child(cam)
	cam.target = rider
	cam.snap_to_target()
	_build_ui()
	for i in 6:
		_spawn_chunk(_next_chunk)
		_next_chunk += 1
	await get_tree().create_timer(0.4).timeout
	Dialogue.play_async(String(def.get("intro_dialogue", "")))
	await get_tree().create_timer(2.2).timeout
	running = true
	Dialogue.play_async("princess_ride")
	if Router.params.has("finish"):        # dev: jump to the celebration/results screen
		collected = 41
		x = _finish_x - 3.0


func _build_ui() -> void:
	_star_widget = Control.new()
	_star_widget.position = Vector2(22, 18)
	_star_widget.size = Vector2(240, 84)
	_star_widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_star_widget.draw.connect(func():
		_star_widget.draw_style_box(UiKit.box(Color(1, 0.96, 0.9, 0.88), 42, Color("#ffd9a0"), 4, 8), Rect2(Vector2.ZERO, Vector2(240, 84)))
		IconArt.draw(_star_widget, "star", Vector2(48, 42), 28)
		# progress toward the three Magic Stars (no reading needed)
		var frac := clampf(float(collected) / maxf(float(int(def.get("reward", {}).get("stars_per", 20))) * 3.0, 1.0), 0.0, 1.0)
		_star_widget.draw_style_box(UiKit.box(Color(0.8, 0.72, 0.9, 0.5), 10), Rect2(Vector2(90, 34), Vector2(130, 18)))
		_star_widget.draw_style_box(UiKit.box(Color("#ffc94d"), 10), Rect2(Vector2(90, 34), Vector2(maxf(130.0 * frac, 18.0), 18)))
		for k in 3:
			IconArt.draw(_star_widget, "star", Vector2(90 + (k + 1) * 130.0 / 3.0 - 14, 26), 8))
	ui_root.add_child(_star_widget)
	_star_label = UiKit.label("", 26, UiKit.INK)
	_star_label.position = Vector2(92, 48)
	_star_widget.add_child(_star_label)
	_left_btn = MagicButton.new("left", Vector2(128, 128))
	_left_btn.set_colors(UiKit.MINT, UiKit.MINT_D)
	_left_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_left_btn.position = Vector2(24, -158)
	_left_btn.hold_mode = true
	_left_btn.pressed_down.connect(func(): _hold_dir = -1.0)
	_left_btn.released.connect(func(): _hold_dir = 0.0)
	ui_root.add_child(_left_btn)
	_right_btn = MagicButton.new("right", Vector2(128, 128))
	_right_btn.set_colors(UiKit.MINT, UiKit.MINT_D)
	_right_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_right_btn.position = Vector2(170, -158)
	_right_btn.hold_mode = true
	_right_btn.pressed_down.connect(func(): _hold_dir = 1.0)
	_right_btn.released.connect(func(): _hold_dir = 0.0)
	ui_root.add_child(_right_btn)
	_jump_btn = MagicButton.new("up", Vector2(168, 168))
	_jump_btn.set_colors(Color("#ffb0e0"), UiKit.PINK_D)
	_jump_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_jump_btn.position = Vector2(-198, -198)
	_jump_btn.pressed_down.connect(_jump)
	_jump_btn.hold_mode = true
	ui_root.add_child(_jump_btn)
	var dlg := Hud.DialogueBar.new()
	ui_root.add_child(dlg)


# =============================================================================
# input / motion
# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") or event.is_action_pressed("magic"):
		_jump()
	elif event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			var p: Vector2 = event.position
			var w := get_viewport().get_visible_rect().size
			if p.y < w.y * 0.72 and p.x > w.x * 0.2 and p.x < w.x * 0.8:
				_jump()


func _jump() -> void:
	if not running or y > 0.05 and vy > -0.5:
		return
	if y <= 0.05:
		vy = JUMP_V
		Audio.sfx("jump", -2.0, 1.15)
		lumi.set_emotion("excited")
		Fx.sparkle_burst(self, rider.global_position + Vector3(0, 0.2, 0), Color(1, 0.9, 0.95), 8, 1.6, 0.24, 0.6)


func _tick(delta: float) -> void:
	# speed: lean right to gallop faster, left to slow down; boosts and splashes modify it
	var axis := Input.get_axis("move_left", "move_right") + _hold_dir
	axis = clampf(axis, -1.0, 1.0)
	var target := BASE_SPEED + axis * 4.5 + boost
	if splash_t > 0.0:
		target *= 0.55
		splash_t -= delta
	speed = lerpf(speed, target, 1.0 - exp(-delta * 3.0))
	boost = maxf(0.0, boost - delta * 3.0)
	x += speed * delta
	# vertical
	if y > 0.0 or vy > 0.0:
		vy -= GRAV * delta
		y += vy * delta
		if y <= 0.0:
			y = 0.0
			vy = 0.0
			lumi.grounded = true
			Audio.sfx("land", -6.0)
	rider.position = Vector3(x, terrain.height_at(clampf(x, -29.0, length + 59.0)) + y, 0)
	lumi.move_speed = speed
	lumi.grounded = y <= 0.01
	lumi.vertical_speed = vy
	lumi.play("gallop")
	# streaming content
	var ci := int(x / CHUNK)
	while _next_chunk < ci + 6 and float(_next_chunk) * CHUNK < length + 40.0:
		_spawn_chunk(_next_chunk)
		_next_chunk += 1
	for k in chunks.keys():
		if k < ci - 3:
			chunks[k].queue_free()
			chunks.erase(k)
	_check_stars()
	_check_special()
	_combo_t -= delta
	if _combo_t <= 0.0:
		_combo = 0
	time_left = maxf(0.0, (length - x) / BASE_SPEED)
	_star_label.text = ""
	_star_widget.queue_redraw()
	# scatter butterflies as we pass
	for b in butterflies:
		if is_instance_valid(b) and absf(b.global_position.x - x) < 5.0 and b.mode != Flutter.Mode.GUIDE:
			b.guide_pos = b.global_position + Vector3(_rng.randf_range(-2.0, 3.0), 3.0 + _rng.randf() * 2.0, _rng.randf_range(-3.0, 1.0))
			b.mode = Flutter.Mode.GUIDE
			b.speed = 5.0
			Audio.sfx("flutter", -8.0, 1.0 + _rng.randf() * 0.4)
	if x >= _finish_x and not _finished:
		_finished = true
		_finish_line()


# =============================================================================
# world streaming
# =============================================================================
func _spawn_chunk(idx: int) -> void:
	var n := Node3D.new()      # chunk root stays at the origin: children use absolute world x
	add_child(n)
	chunks[idx] = n
	var r := _rng
	var x0 := idx * CHUNK
	if idx >= 2 and float(idx) * CHUNK < length - 20.0:
		# 1 main feature per chunk (+ stars). Never two hazards back to back.
		var pattern := r.randi() % 6
		match pattern:
			0: _stars_arc(n, x0 + 3.0, 8.0, 2.2)
			1: _stream(n, x0 + 6.0, 3.2)
			2: _rainbow_road(n, x0 + 1.0, 13.0)
			3: _flower_pad(n, x0 + 6.0)
			4: _stars_line(n, x0 + 2.0, 12.0, 0.9)
			5: _stars_arc(n, x0 + 4.0, 8.0, 1.6); _stars_line(n, x0 + 3.0, 10.0, 0.5)
	_decor_chunk(n, idx)


func _decor_chunk(n: Node3D, idx: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = idx * 7919 + 13
	var x0 := idx * CHUNK
	for k in 3:
		var tx := x0 + r.randf_range(0.0, CHUNK)
		ForestProps.tree(n, Vector3(tx, -0.1, r.randf_range(-9.0, -4.0)), r.randf_range(5.0, 8.0), 1 if r.randf() < 0.35 else 0, idx * 10 + k)
	for k in 2:
		ForestProps.giant_flower(n, Vector3(x0 + r.randf_range(0.0, CHUNK), 0.0, r.randf_range(-4.0, -2.0)), r.randf_range(2.4, 4.2), [Mat.PINK, Color("#c9a0ff"), Mat.SUN, Mat.SKY][r.randi() % 4], false)
	for k in 3:
		ForestProps.bush(n, Vector3(x0 + r.randf_range(0.0, CHUNK), 0.0, r.randf_range(-3.0, -1.8)), r.randf_range(0.8, 1.4), Color("#2f9a5a"), [Mat.PINK, Color.WHITE, Color(0, 0, 0, 0)][r.randi() % 3])
	for k in 2:
		ForestProps.mushroom(n, Vector3(x0 + r.randf_range(0.0, CHUNK), 0.0, r.randf_range(1.6, 3.4)), r.randf_range(0.3, 0.6), [Mat.PINK, Color("#c9a0ff"), Mat.SKY][r.randi() % 3], false)
	var mm := ForestProps.scatter_grass(n, terrain, x0, x0 + CHUNK, 5.0, idx * 3 + 1, Vector2(-5.0, 3.0), Color("#3fb05a"), Color("#a0e070"))
	var fl := ForestProps.scatter_flowers(n, terrain, x0, x0 + CHUNK, 1.4, idx * 3 + 2)
	# butterflies drifting over the meadow
	for k in 2:
		var b := Flutter.new()
		b.palette = [[Mat.PINK, Mat.LILAC, Mat.SUN], [Mat.SKY, Mat.MINT, Mat.PINK], [Mat.SUN, Color("#ff9a7a"), Mat.LILAC]][r.randi() % 3]
		b.speed = 1.6
		b.scale = Vector3.ONE * r.randf_range(0.45, 0.65)
		n.add_child(b)
		b.global_position = Vector3(x0 + r.randf_range(2.0, CHUNK), r.randf_range(1.0, 2.5), r.randf_range(-2.0, 2.0))
		b.hold_at(b.global_position)
		butterflies.append(b)
	butterflies = butterflies.filter(func(b): return is_instance_valid(b))


func _star_node(parent: Node3D, pos: Vector3) -> void:
	var s := Build.pivot(parent, Vector3.ZERO)
	s.global_position = pos
	var mi := MeshInstance3D.new()
	mi.mesh = Build.star_mesh(0.34, 0.15, 0.1)
	mi.material_override = Mat.glowing(Mat.SUN, 1.8, {"outline": 0.008, "glitter": 0.4})
	s.add_child(mi)
	Fx.glow_sprite(s, Vector3.ZERO, Color(1, 0.9, 0.5, 0.5), 1.1)
	stars.append({"node": s, "pos": pos, "taken": false})
	total_stars_spawned += 1


func _stars_arc(n: Node3D, x0: float, width: float, height: float) -> void:
	var count := 7
	for i in count:
		var t := float(i) / (count - 1)
		_star_node(n, Vector3(x0 + t * width, 0.8 + sin(t * PI) * height, 0))


func _stars_line(n: Node3D, x0: float, width: float, h: float) -> void:
	var count := 6
	for i in count:
		_star_node(n, Vector3(x0 + float(i) / (count - 1) * width, h, 0))


func _stream(n: Node3D, sx: float, w: float) -> void:
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, 24.0)
	pm.subdivide_depth = 8
	pm.subdivide_width = 4
	water.mesh = pm
	var m := Mat.water_material()
	water.material_override = m
	water.position = Vector3(sx, 0.03, -8.0)
	n.add_child(water)
	streams.append({"x0": sx - w * 0.5, "x1": sx + w * 0.5, "hit": false})
	# stones + a sparkle line above so it reads as "hop me"
	Fx.aura(water, Color(0.8, 0.95, 1.0), 10, 1.0).position = Vector3(0, 0.6, 8.0)
	for i in 4:
		_star_node(n, Vector3(sx - 1.3 + i * 0.9, 1.4 + sin(float(i) / 3.0 * PI) * 1.0, 0))


func _rainbow_road(n: Node3D, rx: float, w: float) -> void:
	var road := MeshInstance3D.new()
	var pts: Array[Vector3] = []
	for i in 13:
		pts.append(Vector3(rx + float(i) / 12.0 * w, 0.05, 0))
	road.mesh = MeshExtra.path_ribbon(pts, 3.4)
	var mat := Mat.rainbow_material()
	mat.set_shader_parameter("intensity", 1.4)
	mat.set_shader_parameter("alpha", 0.98)
	road.material_override = mat
	n.add_child(road)
	roads.append({"x0": rx, "x1": rx + w})
	Fx.aura(road, Color(1, 0.9, 1), 12, 1.6).position = Vector3(rx + w * 0.5, 0.8, 0)
	for i in 5:
		_star_node(n, Vector3(rx + 2.0 + i * 2.0, 0.9, 0))


func _flower_pad(n: Node3D, px: float) -> void:
	var pad := Build.pivot(n, Vector3(px, 0.0, 0))
	var fm := Mat.glowing(Color("#ff8fd2"), 1.6, {"pulse": 0.8, "outline": 0.01})
	for i in 8:
		var a := float(i) / 8.0 * TAU
		var p := Build.sphere(pad, 0.34, Vector3(cos(a) * 0.5, 0.18, sin(a) * 0.5), fm, Vector3(1.0, 0.35, 0.7), 10)
		p.rotation.y = -a
	Build.sphere(pad, 0.22, Vector3(0, 0.22, 0), Mat.glowing(Color("#ffe066"), 1.6), Vector3(1, 0.6, 1), 10)
	Fx.aura(pad, Color(1, 0.7, 0.95), 12, 0.7).position = Vector3(0, 0.5, 0)
	pads.append({"x": px, "node": pad, "used": false})
	for i in 5:
		var t := float(i) / 4.0
		_star_node(n, Vector3(px + 1.2 + t * 4.2, 3.0 + sin(t * PI) * 1.6, 0))


# =============================================================================
# interactions
# =============================================================================
func _check_stars() -> void:
	var lp := rider.global_position + Vector3(0, 1.1, 0)
	for s in stars:
		if s.taken:
			continue
		var p: Vector3 = s.pos
		if absf(p.x - lp.x) > 1.4:
			continue
		if lp.distance_to(p) < 1.5:
			s.taken = true
			collected += 1
			_combo += 1
			_combo_t = 1.2
			var node: Node3D = s.node
			if is_instance_valid(node):
				Fx.sparkle_burst(self, p, Color(1, 0.95, 0.5), 12, 2.5, 0.28, 0.7)
				node.queue_free()
			Audio.sfx("star_get", -4.0, 1.0 + minf(_combo, 8) * 0.06)
			lumi.set_emotion("joyful")
	stars = stars.filter(func(s): return not s.taken and is_instance_valid(s.node))


func _check_special() -> void:
	# streams: a splash if we are low over one
	for st in streams:
		if not st.hit and x > st.x0 and x < st.x1 and y < 0.35:
			st.hit = true
			splash_t = 0.6
			Audio.sfx("splash", -2.0)
			Fx.sparkle_burst(self, rider.global_position + Vector3(0, 0.3, 0), Color(0.7, 0.9, 1.0), 26, 3.0, 0.3, 0.9)
			lumi.set_emotion("giggle")
			lumi.play("shimmy")
			get_tree().create_timer(1.0).timeout.connect(func(): if is_instance_valid(lumi): lumi.set_emotion("excited"))
	# rainbow roads: speed boost + sparkles
	for r in roads:
		if x > r.x0 and x < r.x1 and y < 0.4:
			if boost < 4.5:
				boost = 4.5
			if int(x * 6.0) % 3 == 0:
				Fx.sparkle_burst(self, rider.global_position + Vector3(-0.6, 0.3, 0), Color(1, 0.85, 1), 3, 1.0, 0.22, 0.6)
			if not r.has("sfx"):
				r["sfx"] = true
				Audio.sfx("rainbow_make", -3.0)
	# flower pads: bounce + burst
	for p in pads:
		if not p.used and absf(x - p.x) < 0.9 and y < 0.6:
			p.used = true
			vy = 14.5
			Audio.sfx("boing", -2.0)
			Fx.flower_burst(self, Vector3(p.x, 0.5, 0), [], 34)
			Fx.sparkle_burst(self, Vector3(p.x, 0.6, 0), Color(1, 0.8, 0.95), 26, 3.5, 0.32, 1.0)
			lumi.play("happy_jump")


func _finish_line() -> void:
	var fx := _finish_x
	Audio.sting("rescue_sting")
	Fx.star_shower(self, Vector3(fx + 6.0, 8.0, 0), 70)
	var arc := MeshInstance3D.new()
	arc.mesh = Build.arc_ribbon(6.0, 1.6, 180.0, 56)
	arc.material_override = Mat.rainbow_material()
	arc.position = Vector3(fx + 4.0, 0.0, -1.0)
	add_child(arc)
	var tw := create_tween()
	tw.tween_property(self, "speed", 0.0, 1.8)
	await get_tree().create_timer(1.6).timeout
	speed = 0.0
	lumi.move_speed = 0.0
	lumi.play("happy_jump")
	lumi.set_emotion("joyful")
	princess.anim = "idle"
	princess.play("celebrate")
	Fx.sparkle_burst(self, rider.global_position + Vector3(0, 1.4, 0), Color(1, 0.9, 0.7), 80, 5.0, 0.4, 1.6)
	await Dialogue.play(String(def.get("outro_dialogue", "")))
	var ratio := clampf(float(collected) / (float(int(def.get("reward", {}).get("stars_per", 20))) * 3.0), 0.0, 1.0)
	finish(ratio)


func _process(delta: float) -> void:
	super._process(delta)
	if not running and not _finished and lumi:
		lumi.play("idle")
