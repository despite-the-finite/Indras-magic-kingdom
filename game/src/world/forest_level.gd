extends LevelBase
## THE LOST UNICORN - Enchanted Forest rescue adventure (Mode 1).
## Story flow comes from data/quests/lost_unicorn.json; this script builds the world and reacts visually.

var rabbit: RabbitRig
var lumi: UnicornRig
var branch_node: Node3D
var burrow_pos := Vector3.ZERO
var thorn_root: Node3D
var hollow_glow: Node3D
var wish_count := 0
var _bridge_built := false
var _caged := true
var _gap_guard: StaticBody3D

const GAP_X0 := 102.0
const GAP_X1 := 110.0


func _configure() -> void:
	preset = "day_forest"
	quest_id = "lost_unicorn"
	min_x = -2.0
	max_x = 158.0
	kill_y = -6.0
	spawn = Vector3(2.0, 0.3, 0)
	music_cue = "forest_explore"
	ambience = ["forest_birds", "forest_wind"]


func _build_world() -> void:
	terrain = Terrain.build(self, [
		{"x0": -14.0, "x1": GAP_X0, "pts": [[-14, 0.6], [-4, 0.0], [8, 0.15], [20, 0.45], [30, 0.1], [42, -0.1], [52, 0.2], [64, 0.7], [76, 0.9], [88, 0.4], [GAP_X0, 0.0]]},
		{"x0": GAP_X1, "x1": 172.0, "pts": [[GAP_X1, 0.0], [122, 0.3], [136, 0.1], [150, 0.5], [160, 0.2], [172, 0.5]]},
	], {"top_color": Color("#69b84c"), "top_color_far": Color("#2a8a5e"), "dirt_color": Color("#a8785e"), "dirt_dark": Color("#5a3a6a")})
	_decor()
	_story_objects()


# =============================================================================
# scenery
# =============================================================================
func _decor() -> void:
	ForestProps.backdrop(self, -14.0, 172.0, [Color("#a6b4f2"), Color("#8ac4d8"), Color("#66c6a0")])
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	# trees: back layer (tall) + mid layer
	var x := -12.0
	while x < 170.0:
		if not (x > GAP_X0 - 3.0 and x < GAP_X1 + 3.0):
			var kind := 1 if rng.randf() < 0.22 else 0
			ForestProps.tree(self, Vector3(x, terrain.height_at(x) - 0.1, rng.randf_range(-16.0, -8.0)), rng.randf_range(8.0, 12.0), kind, int(x))
		x += rng.randf_range(4.0, 7.0)
	x = -8.0
	while x < 168.0:
		if not (x > GAP_X0 - 2.0 and x < GAP_X1 + 2.0):
			ForestProps.tree(self, Vector3(x, terrain.height_at(x) - 0.1, rng.randf_range(-6.5, -4.0)), rng.randf_range(5.0, 7.0), 1 if rng.randf() < 0.3 else 0, int(x) + 7)
		x += rng.randf_range(13.0, 19.0)
	# giant flowers behind the lane
	var fcols := [Mat.PINK, Color("#c9a0ff"), Mat.SUN, Color("#ff9a7a"), Mat.SKY]
	x = -6.0
	var fi := 0
	while x < 168.0:
		if not (x > GAP_X0 - 2.0 and x < GAP_X1 + 2.0):
			ForestProps.giant_flower(self, Vector3(x, terrain.height_at(x) - 0.05, rng.randf_range(-4.5, -1.9)), rng.randf_range(2.6, 4.8), fcols[fi % fcols.size()], false)
			fi += 1
		x += rng.randf_range(9.0, 14.0)
	# mushrooms, ferns, rocks in the front planes
	x = -6.0
	while x < 168.0:
		if not (x > GAP_X0 - 1.0 and x < GAP_X1 + 1.0):
			var y := terrain.height_at(x)
			match int(rng.randf() * 4.0):
				0: ForestProps.mushroom(self, Vector3(x, y - 0.03, rng.randf_range(1.4, 3.0)), rng.randf_range(0.28, 0.55), [Mat.PINK, Color("#ff9a7a"), Color("#c9a0ff"), Mat.SKY][int(rng.randf() * 4.0)], false)
				1: ForestProps.fern(self, Vector3(x, y - 0.02, rng.randf_range(1.6, 3.4)), rng.randf_range(0.9, 1.5))
				2: ForestProps.rock(self, Vector3(x, y - 0.05, rng.randf_range(1.8, 3.2)), rng.randf_range(0.3, 0.55))
				3: ForestProps.fern(self, Vector3(x, y - 0.02, rng.randf_range(-2.4, -1.2)), rng.randf_range(1.0, 1.7))
		x += rng.randf_range(2.6, 5.0)
	# lush mid-ground bushes (some in blossom)
	x = -12.0
	while x < 170.0:
		if not (x > GAP_X0 - 2.0 and x < GAP_X1 + 2.0):
			var bl := Color(0, 0, 0, 0)
			if rng.randf() < 0.5:
				bl = [Mat.PINK, Color.WHITE, Mat.SUN][int(rng.randf() * 3.0)]
			ForestProps.bush(self, Vector3(x, terrain.height_at(x) - 0.05, rng.randf_range(-3.6, -1.6)), rng.randf_range(0.9, 1.7), [Color("#2f9a5a"), Color("#3fae6a"), Color("#2a8a6a")][int(rng.randf() * 3.0)], bl)
		x += rng.randf_range(2.2, 4.4)
	ForestProps.scatter_grass(self, terrain, -14.0, GAP_X0, 5.0, 11, Vector2(-5.0, 0.35), Color("#2fae5a"), Color("#8fdc6a"))
	ForestProps.scatter_grass(self, terrain, GAP_X1, 172.0, 5.0, 12, Vector2(-5.0, 0.35), Color("#2fae5a"), Color("#8fdc6a"))
	ForestProps.scatter_flowers(self, terrain, -14.0, GAP_X0, 1.6, 21)
	ForestProps.scatter_flowers(self, terrain, GAP_X1, 172.0, 1.6, 22)
	# golden light shafts + a foreground leaf frame at the top of the screen
	for cx in range(0, 170, 34):
		ForestProps.light_shafts(self, Vector3(cx + 10, 0, 0), 3, 16.0, Color(1, 0.93, 0.65, 0.13), cx + 5)
	var leaf_m := Mat.toon_grad(Color("#2f9a6a"), Color("#6fd48a"), -0.4, 0.6, {"rim_amount": 0.4, "gradient_amount": 1.0})
	x = -6.0
	while x < 170.0:
		var l := Build.sphere(self, 1.5, Vector3(x, rng.randf_range(7.4, 8.6), rng.randf_range(2.6, 4.2)), leaf_m, Vector3(2.4, 0.32, 1.1), 12)
		l.rotation = Vector3(0, rng.randf_range(-0.3, 0.3), rng.randf_range(-0.5, 0.5))
		x += rng.randf_range(6.0, 11.0)
	_river()
	_scenic_butterflies(rng)


func _river() -> void:
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(GAP_X1 - GAP_X0 + 2.0, 90.0)
	pm.subdivide_depth = 40
	pm.subdivide_width = 12
	water.mesh = pm
	water.material_override = Mat.water_material()
	water.position = Vector3((GAP_X0 + GAP_X1) * 0.5, -1.5, -36.0)
	add_child(water)
	# bank rocks + lily pads
	for sx in [GAP_X0 - 0.2, GAP_X1 + 0.2]:
		for k in 4:
			ForestProps.rock(self, Vector3(sx + (0.0 if sx < 105.0 else 0.0), -1.3, -1.5 + k * 1.4), 0.5 + 0.1 * k, Color("#a8a0d0"))
	for i in 5:
		var pad := Build.cyl(self, 0.42, 0.42, 0.04, Vector3(GAP_X0 + 1.5 + i * 1.5, -1.42, 1.5 + (i % 2) * 1.6), Mat.toon(Color("#5fd68a"), {"outline": false}), 14)
		pad.rotation.y = i
	# until the vine bridge grows, an invisible guard stops little feet at the river's edge: bumping into
	# "can't go" reads far better to a 4-year-old than falling in again and again
	_gap_guard = StaticBody3D.new()
	_gap_guard.name = "RiverGuard"
	_gap_guard.collision_layer = 1
	var gcs := CollisionShape3D.new()
	var gbs := BoxShape3D.new()
	gbs.size = Vector3(0.3, 2.6, 2.4)
	gcs.shape = gbs
	_gap_guard.add_child(gcs)
	_gap_guard.position = Vector3(GAP_X0 + 0.15, terrain.height_at(GAP_X0) + 1.3, 0)
	add_child(_gap_guard)
	# a broken bridge: stubs on each side
	var wood := Mat.toon(Color("#b98a68"), {"outline": 0.008})
	for k in 3:
		var p := Build.box(self, Vector3(0.6, 0.12, 2.0), Vector3(GAP_X0 - 0.4 - k * 0.7, terrain.height_at(GAP_X0 - 0.4 - k * 0.7) + 0.02, 0), wood)
		p.rotation.z = -0.06 * k
		var q := Build.box(self, Vector3(0.6, 0.12, 2.0), Vector3(GAP_X1 + 0.4 + k * 0.7, terrain.height_at(GAP_X1 + 0.4 + k * 0.7) + 0.02, 0), wood)
		q.rotation.z = 0.06 * k
	# floating plank in the water
	Build.box(self, Vector3(1.6, 0.1, 1.1), Vector3(105.5, -1.42, 0.6), wood, Vector3(0, 0.6, 0.06))


func _scenic_butterflies(rng: RandomNumberGenerator) -> void:
	for i in 12:
		var b := Flutter.new()
		b.palette = [[Mat.PINK, Mat.LILAC, Mat.SUN], [Mat.SKY, Mat.MINT, Mat.PINK], [Mat.SUN, Color("#ff9a7a"), Mat.LILAC]][i % 3]
		b.speed = 1.6
		b.scale = Vector3.ONE * rng.randf_range(0.35, 0.55)
		add_child(b)
		var ax := rng.randf_range(0.0, 165.0)
		b.global_position = Vector3(ax, 1.8, rng.randf_range(-2.0, 2.5))
		b.hold_at(b.global_position)
		var tw := b.create_tween().set_loops()
		tw.tween_callback(func(): b.guide_pos = Vector3(ax + rng.randf_range(-5.0, 5.0), terrain.height_at(clampf(ax, -12.0, 168.0)) + rng.randf_range(0.6, 2.4), rng.randf_range(-2.0, 2.5)))
		tw.tween_interval(rng.randf_range(2.0, 4.0))


# =============================================================================
# story objects
# =============================================================================
func _place(x: float, z: float = 0.0, lift: float = 0.0) -> Vector3:
	return Vector3(x, terrain.height_at(x) + lift, z)


func _story_objects() -> void:
	# --- hoofprints trail ---
	for i in 3:
		var hx := 14.0 + i * 16.0
		var hp := ForestProps.hoofprints(self, _place(hx, 0.3))
		var it := Interactable.make(self, "hoofprints_%d" % (i + 1), "touch", "", _place(hx, 0.3), 2.6)
		it.show_aura = false
		it.halo_height = 0.6
	Events.interaction_done.connect(_on_interaction)
	Events.power_used.connect(_on_power)
	Events.dialogue_line_started.connect(_on_line)
	Events.quest_completed.connect(_on_quest_completed)
	Events.zone_entered.connect(_on_zone)
	Events.dialogue_finished.connect(_on_dialogue_finished)

	# --- secret hollow tree (Star Light) ---
	var tp := _place(38.0, -1.7)
	var big := ForestProps.tree(self, tp, 7.0, 0, 3)
	big.scale = Vector3(1.5, 1.0, 1.5)
	var hole := Build.sphere(big, 0.5, Vector3(0.05, 1.3, 0.42), Mat.toon(Color("#1c1030"), {"outline": false, "rim_amount": 0.0, "shade_strength": 0.0}), Vector3(0.8, 1.25, 0.45), 14)
	hollow_glow = Build.pivot(big, Vector3(0.05, 1.3, 0.62))
	var hi := Interactable.make(self, "hollow_tree", "magic", "starlight", _place(38.0, 0.0), 3.0)
	hi.fx_height = 1.3
	hi.halo_height = 1.6
	hi.activated.connect(func(_p): _reveal_hollow())
	if GameState.secret_found("forest_hollow"):
		hi.used = true

	# --- rabbit + burrow + branch ---
	var rp := _place(57.2, 0.5)
	rabbit = RabbitRig.new()
	add_child(rabbit)
	rabbit.global_position = rp
	rabbit.facing = 1.0
	rabbit.set_emotion("worried")
	var ri := Interactable.make(self, "rabbit", "magic", "animals", _place(57.2, 0.0), 2.4)
	ri.fx_height = 0.5
	ri.halo_height = 1.1
	burrow_pos = _place(60.6, -0.4)
	var mound := Build.sphere(self, 0.9, burrow_pos + Vector3(0, 0.15, 0), Mat.toon(Color("#b58a6a"), {"outline": false}), Vector3(1.3, 0.55, 1.0), 14)
	Build.sphere(self, 0.4, burrow_pos + Vector3(-0.1, 0.35, 0.72), Mat.toon(Color("#1c1030"), {"outline": false, "shade_strength": 0.0, "rim_amount": 0.0}), Vector3(1.0, 1.1, 0.4), 12)
	branch_node = Build.pivot(self, burrow_pos + Vector3(-0.15, 0.4, 0.95))
	var bark := Mat.toon_grad(Color("#8a5a4e"), Color("#c09070"), -0.4, 0.4, {"outline": 0.01, "rim_amount": 0.2})
	Build.cyl(branch_node, 0.26, 0.3, 2.6, Vector3.ZERO, bark, 12, Vector3(0, 0, deg_to_rad(70)))
	Build.cyl(branch_node, 0.12, 0.16, 1.2, Vector3(0.5, 0.75, 0), bark, 10, Vector3(0, 0, deg_to_rad(-10)))
	for k in 5:
		Build.sphere(branch_node, 0.38, Vector3(-0.8 - k * 0.15, 0.4 + k * 0.28, 0.1 * k), Mat.toon(Color("#5fc98a"), {"outline": false, "rim_amount": 0.4}), Vector3(1.2, 0.5, 0.9), 10)
	var bi := Interactable.make(self, "branch", "press", "", _place(59.2, 0.0), 2.2)
	bi.requires_step = "move_branch"
	bi.halo_height = 0.9
	bi.press_anim = "push"

	# --- bouncy mushroom playground with wishing orbs ---
	var mush := [[69.0, 0.9, Mat.PINK], [75.0, 1.0, Color("#c9a0ff")], [81.5, 1.05, Mat.SKY], [87.5, 0.9, Color("#ff9a7a")]]
	for m in mush:
		ForestProps.bouncy_mushroom(self, _place(m[0], 0.0, -0.05), m[1], m[2])
	ForestProps.log_platform(self, _place(72.0, 0.0, 3.3), 3.0, 0.32)
	ForestProps.log_platform(self, _place(84.5, 0.0, 3.6), 3.0, 0.32)
	var orbs := [Vector3(69.0, 4.3, 0), Vector3(72.0, 5.0, 0), Vector3(75.0, 5.2, 0), Vector3(81.5, 5.4, 0), Vector3(84.5, 5.4, 0)]
	for i in orbs.size():
		_wish_orb(i, _place(orbs[i].x, 0.0, 0.0) + Vector3(0, orbs[i].y - 0.0, 0))

	# --- the river gap: Flower Magic grows a vine bridge ---
	var gi := Interactable.make(self, "river_gap", "magic", "flower", _place(GAP_X0 - 1.2, 0.0), 4.4)
	gi.fx_height = 0.6
	gi.halo_height = 1.6
	gi.activated.connect(func(_p): _grow_bridge())

	# --- Lumi trapped in thorns ---
	var lp := _place(150.0, 0.0)
	lumi = UnicornRig.new("lumi")
	add_child(lumi)
	lumi.global_position = lp
	lumi.facing = -1.0
	lumi.play("trapped")
	lumi.set_emotion("sad")
	thorn_root = MeshExtra.thorn_ring(self, 1.35, 2.5, Mat.toon(Color("#5a3a7a"), {"outline": 0.01, "rim_color": Color("#c090ff"), "rim_amount": 0.5}), Mat.glowing(Color("#9a4ad0"), 0.6, {"outline": false}), 5)
	thorn_root.global_position = lp
	var ti := Interactable.make(self, "thorn_cage", "magic", "flower", _place(147.4, 0.0), 4.2)
	ti.fx_height = 1.2
	ti.halo_height = 1.8
	add_zone("lumi_call", 118.0, 122.0)
	Hints.register_target("lumi_zone", _zone_marker(120.0))
	add_zone("lumi_end", 140.0, 143.0)


func _after_ready() -> void:
	GameState.advance_stage("lumi", GameState.Stage.DISCOVERED)
	Events.dialogue_started.connect(func(s): if s == "lumi_crying": _pan_to_lumi())
	if Router.params.has("skipintro"):
		Quests.start(quest_id)
		return
	await get_tree().create_timer(0.6).timeout
	await Dialogue.play(String(Content.quest(quest_id).get("intro_dialogue", "")))
	Quests.start(quest_id)


func _zone_marker(x: float) -> Node3D:
	var m := Node3D.new()
	m.position = Vector3(x, ground_y(x), 0)
	add_child(m)
	return m


func _wish_orb(i: int, pos: Vector3) -> void:
	var n := Build.pivot(self, pos)
	Build.sphere(n, 0.17, Vector3.ZERO, Mat.glowing(Color("#ffe6f8"), 2.2, {"pulse": 0.7, "outline": false}), Vector3.ONE, 12)
	Fx.glow_sprite(n, Vector3.ZERO, Color(1, 0.8, 0.95, 0.6), 0.9)
	Fx.aura(n, Color(1, 0.9, 1.0), 6, 0.3)
	var bob := n.create_tween().set_loops()
	bob.tween_property(n, "position:y", pos.y + 0.25, 1.2 + i * 0.1).set_trans(Tween.TRANS_SINE)
	bob.tween_property(n, "position:y", pos.y - 0.05, 1.2 + i * 0.1).set_trans(Tween.TRANS_SINE)
	var it := Interactable.make(self, "wish_%d" % i, "touch", "", pos, 1.1)
	it.show_aura = false
	it.activated.connect(func(_p):
		Audio.sfx("wish_pick", -2.0, 1.0 + wish_count * 0.12)
		Fx.sparkle_burst(self, n.global_position, Color(1, 0.85, 0.95), 16, 2.6, 0.3, 0.9)
		Fx.heart_burst(self, n.global_position, 3)
		n.queue_free()
		wish_count += 1
		if wish_count == orbs_total():
			Audio.sfx("chime_up")
			earn_stars(1, n.global_position, "wishes"))


func orbs_total() -> int:
	return 5


# =============================================================================
# reactions
# =============================================================================
func _on_interaction(id: String, _kind: String) -> void:
	match id:
		"hoofprints_1":
			flutter.celebrate()
			Fx.sparkle_burst(self, _place(14.0, 0.3, 0.5), Color(1, 0.8, 0.95), 24, 3.0, 0.3, 1.0)
		"hoofprints_2":
			Dialogue.play_async("trail_progress_bark")
			Fx.sparkle_burst(self, _place(30.0, 0.3, 0.5), Color(1, 0.8, 0.95), 24, 3.0, 0.3, 1.0)
		"hoofprints_3":
			Fx.sparkle_burst(self, _place(46.0, 0.3, 0.5), Color(1, 0.8, 0.95), 24, 3.0, 0.3, 1.0)
		"branch":
			_move_branch()


func _on_power(power: String, target: String) -> void:
	match target:
		"rabbit":
			rabbit.face_toward(player.global_position.x - rabbit.global_position.x)
			rabbit.play("happy_hop")
			rabbit.set_emotion("happy")
			Audio.sfx("rabbit_squeak", -2.0)
		"thorn_cage":
			_thorns_bloom()


func _on_zone(id: String) -> void:
	if id == "lumi_end":
		Events.custom_event.emit("near_lumi")


func _on_line(line: Dictionary) -> void:
	match String(line.get("camera", "")):
		"forest_reveal":
			look_wide_intro(_place(4.0), Vector3(8, 6.5, 15), 3.6)
		"rescue_orbit":
			cam.cine_orbit(lumi.global_position + Vector3(0, 0.6, 0), 6.5, 2.2, 8.0, 68.0, 6.0)
		"star_rise":
			var star := spawn_big_star(lumi.global_position + Vector3(0, 1.0, 0.5))
			star.scale = Vector3.ZERO
			var tw := create_tween()
			tw.tween_property(star, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(star, "position:y", star.position.y + 2.2, 1.6).set_trans(Tween.TRANS_SINE)
			tw.tween_interval(0.5)
			tw.tween_callback(func():
				earn_stars(3, star.global_position, "rescue")
				Fx.star_shower(self, star.global_position + Vector3(0, 2.0, 0), 60)
				star.queue_free())
			Audio.sfx("star_get")
			cam.punch(-4.0)


func _on_dialogue_finished(seq: String) -> void:
	if seq == "lumi_crying":
		cam.cine_release(1.6)


func _pan_to_lumi() -> void:
	cam.cine_to(Vector3(146.0, ground_y(146.0) + 3.6, 13.0), lumi.global_position + Vector3(0, 1.0, 0), 1.8)


# ---- secret hollow -------------------------------------------------------------------
func _reveal_hollow() -> void:
	GameState.add_secret("forest_hollow")
	var pos := hollow_glow.global_position
	var gs := Fx.glow_sprite(self, pos + Vector3(0, 0, 0.2), Color(1, 0.92, 0.55, 0.9), 2.8)
	Fx.aura(hollow_glow, Color(1, 0.92, 0.6), 22, 0.6)
	Fx.sparkle_burst(self, pos, Color(1, 0.92, 0.6), 40, 4.0, 0.36, 1.4)
	var star := spawn_big_star(pos + Vector3(0, 0.0, 0.8))
	star.scale = Vector3.ONE * 0.4
	Audio.sfx("secret_found")
	Dialogue.play_async("forest_secret_found")
	var tw := create_tween()
	tw.tween_property(star, "position", star.position + Vector3(-0.3, 1.6, 0.6), 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		earn_stars(1, star.global_position, "secret")
		star.queue_free())
	# a ring of glowing mushrooms pops up
	for i in 6:
		var a := float(i) / 6.0 * PI + 0.2
		var mp := pos + Vector3(cos(a) * 1.3 - 0.4, -1.0, 0.3 + sin(a) * 0.6)
		var m := ForestProps.mushroom(self, Vector3(mp.x, ground_y(mp.x) - 0.05, mp.z), 0.42, [Mat.PINK, Mat.SKY, Mat.LILAC][i % 3], true)
		m.scale = Vector3.ZERO
		create_tween().tween_property(m, "scale", Vector3.ONE, 0.6).set_delay(0.1 * i).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---- rabbit's branch -------------------------------------------------------------------
func _move_branch() -> void:
	Fx.sparkle_burst(self, branch_node.global_position, Color("#d8b090"), 18, 2.4, 0.3, 0.9)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(branch_node, "position", branch_node.position + Vector3(3.4, -0.2, 0.9), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(branch_node, "rotation:z", -0.5, 1.1)
	tw.tween_property(branch_node, "rotation:y", 0.6, 1.1)
	await get_tree().create_timer(0.7).timeout
	rabbit.play("happy_hop")
	rabbit.set_emotion("joyful")
	var hop := create_tween()
	hop.tween_property(rabbit, "global_position", rabbit.global_position + Vector3(2.3, 0, 0), 0.9).set_trans(Tween.TRANS_SINE)
	rabbit.move_speed = 3.0
	await hop.finished
	rabbit.move_speed = 0.0
	rabbit.facing = 1.0
	rabbit.play("point")     # points toward the river
	Fx.heart_burst(self, rabbit.global_position + Vector3(0, 0.9, 0), 6)


# ---- vine bridge -------------------------------------------------------------------------
func _grow_bridge() -> void:
	if _bridge_built:
		return
	_bridge_built = true
	Audio.sfx("vine_grow")
	var root := Build.pivot(self, Vector3.ZERO)
	var vine := Mat.toon_grad(Color("#3fae6a"), Color("#8fe89a"), -0.2, 0.3, {"outline": 0.008, "rim_amount": 0.4, "glitter": 0.15})
	var wood := Mat.toon(Color("#c8a078"), {"outline": 0.008})
	var n := 14
	var x0 := GAP_X0 - 0.9
	var x1 := GAP_X1 + 0.9
	var y0 := ground_y(GAP_X0)
	for i in n:
		var t := float(i) / (n - 1)
		var x := lerpf(x0, x1, t)
		var seg := Build.pivot(root, Vector3(x, y0 - 0.02, 0))
		seg.scale = Vector3.ZERO
		# plank made of woven vine pieces
		Build.capsule(seg, 0.13, 2.3, Vector3.ZERO, vine, Vector3(PI * 0.5, 0, 0))
		Build.capsule(seg, 0.1, 2.2, Vector3(0.2, 0.04, 0), wood, Vector3(PI * 0.5, 0, 0.1))
		# rails
		for sz in [-1.1, 1.1]:
			Build.sphere(seg, 0.16, Vector3(0, 0.75 + 0.1 * sin(t * PI), sz), vine, Vector3(1.4, 1.0, 1.0), 10)
			Build.capsule(seg, 0.05, 0.75, Vector3(0, 0.38, sz), vine)
			if i % 2 == 0:
				var f := ForestProps.flower(seg, Vector3(0.1, 0.78, sz), [Mat.PINK, Mat.SUN, Color.WHITE, Mat.LILAC][(i / 2) % 4], 0.7)
				f.scale = Vector3.ZERO
				var ft := f.create_tween()
				ft.tween_interval(0.8 + i * 0.06)
				ft.tween_property(f, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var tw := seg.create_tween()
		tw.tween_interval(i * 0.07)
		tw.tween_property(seg, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): Fx.sparkle_burst(self, seg.global_position + Vector3(0, 0.4, 0), Color(0.7, 1, 0.75), 6, 1.6, 0.25, 0.7))
	# collision appears with the growth
	await get_tree().create_timer(1.2).timeout
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(x1 - x0 + 0.8, 0.3, 2.4)
	cs.shape = bs
	sb.add_child(cs)
	sb.position = Vector3((x0 + x1) * 0.5, y0 - 0.17, 0)
	add_child(sb)
	if _gap_guard and is_instance_valid(_gap_guard):
		_gap_guard.queue_free()
		_gap_guard = null
	Audio.sfx("chime_up", -2.0)
	Fx.flower_burst(self, Vector3(106.0, y0 + 0.6, 0), [], 30)
	Events.custom_event.emit("bridge_grown")


# ---- thorns bloom & rescue ------------------------------------------------------------------
func _thorns_bloom() -> void:
	if not _caged:
		return
	_caged = false
	Audio.sfx("bloom_big")
	var lp := lumi.global_position
	for i in thorn_root.get_child_count():
		var c := thorn_root.get_child(i)
		if c is Node3D:
			var tw := create_tween()
			tw.tween_interval(0.03 * i)
			tw.tween_property(c, "scale", Vector3.ZERO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	for i in 9:
		var a := float(i) / 9.0 * TAU
		var f := ForestProps.giant_flower(self, lp + Vector3(cos(a) * 1.5, 0, sin(a) * 0.9), 1.4 + (i % 3) * 0.4, [Mat.PINK, Mat.SUN, Mat.LILAC, Color.WHITE][i % 4], true)
		f.scale = Vector3.ZERO
		create_tween().tween_property(f, "scale", Vector3.ONE, 0.8).set_delay(0.12 * i).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Fx.flower_burst(self, lp + Vector3(0, 1.4, 0), [], 60)
	Fx.sparkle_burst(self, lp + Vector3(0, 1.2, 0), Color(1, 0.9, 0.9), 60, 5.0, 0.4, 1.4)
	lumi.play("shimmy")
	lumi.set_emotion("surprised")
	cam.shake(0.5)


func _on_quest_completed(id: String) -> void:
	if id == quest_id:
		_rescue_cinematic()


func _rescue_cinematic() -> void:
	player.frozen = true
	Hints.stop()
	Audio.play_music("rescue_swell", 0.8)
	Audio.sting("rescue_sting")
	await get_tree().create_timer(1.0).timeout
	lumi.face_toward(player.global_position.x - lumi.global_position.x)
	lumi.set_emotion("joyful")
	lumi.play("happy_jump")
	player.rig.play("celebrate")
	Fx.sparkle_burst(self, lumi.global_position + Vector3(0, 1.0, 0), Color(1, 0.85, 1), 50, 4.0, 0.36, 1.4)
	# Lumi trots over and hugs the princess
	var tw := create_tween()
	tw.tween_property(lumi, "global_position", player.global_position + Vector3(1.4, 0, 0), 1.4).set_trans(Tween.TRANS_SINE)
	lumi.move_speed = 3.0
	await tw.finished
	lumi.move_speed = 0.0
	player.rig.play("hug")
	lumi.play("hug")
	Fx.heart_burst(self, (player.global_position + lumi.global_position) * 0.5 + Vector3(0, 1.6, 0), 12)
	await Dialogue.play("lumi_rescued")
	Audio.play_music("celebration", 0.6)
	await get_tree().create_timer(2.2).timeout
	GameState.advance_stage("lumi", GameState.Stage.RESCUED)
	await cam.cine_release(0.1)
	next_scene("castle", {"arrival": "lumi_rescued"})
