extends LevelBase
## MOONFLOWER FOR MAMA - the Friendship Quest (Mode 3). Lumi is a companion here, and every puzzle needs both friends:
##   ledge too high      -> Lumi's horn makes a rainbow bridge
##   log too heavy       -> the princess's Flower Magic lifts it on giant flowers
##   dark hollow         -> the princess's Star Light lights the way
##   sleeping Moonflower -> Star Light + Lumi's horn, together

var lumi: UnicornRig
var log_node: Node3D
var moonflower: Node3D
var petals: Array[Node3D] = []
var star_orb: Node3D
var star_light: OmniLight3D
var cave_mushrooms: Array[ShaderMaterial] = []
var _dark := 0.0
var _cave_lit := false
var _base_key := 1.0
var _base_amb := 1.0
var _base_fog := Color()
var _rainbow_built := false

const CLIFF_X := 25.5
const CAVE_X0 := 78.0
const CAVE_X1 := 106.0
const FLOWER_X := 132.0


func _configure() -> void:
	preset = "moonlit_forest"
	quest_id = "moonflower_for_mama"
	min_x = -2.0
	max_x = 146.0
	kill_y = -8.0
	spawn = Vector3(2.0, 0.3, 0)
	with_companion = true
	music_cue = "forest_moonlit"
	ambience = ["night_crickets", "forest_wind"]


func _env_overrides() -> Dictionary:
	return {"moon_dir": Vector3(-0.42, 0.34, -0.85)}


func _build_world() -> void:
	terrain = Terrain.build(self, [
		{"x0": -14.0, "x1": CLIFF_X, "pts": [[-14, 0.4], [-4, 0.0], [10, 0.1], [CLIFF_X, 0.0]]},
		{"x0": CLIFF_X, "x1": 156.0, "pts": [[CLIFF_X, 3.2], [38, 3.4], [50, 3.2], [64, 3.4], [75, 3.0], [88, 3.2], [100, 3.5], [115, 3.3], [130, 3.6], [156, 3.4]]},
	], {"top_color": Color("#3f9a94"), "top_color_far": Color("#2a3f9a"), "dirt_color": Color("#6a5a9a"), "dirt_dark": Color("#2a1f5c")})
	_decor()
	_story_objects()
	var k: DirectionalLight3D = env.key
	_base_key = k.light_energy
	_base_amb = env.env.ambient_light_energy
	_base_fog = env.env.fog_light_color


func _place(x: float, z: float = 0.0, lift: float = 0.0) -> Vector3:
	return Vector3(x, terrain.height_at(x) + lift, z)


# =============================================================================
func _decor() -> void:
	ForestProps.backdrop(self, -14.0, 156.0, [Color("#4a4ab0"), Color("#3f4fa8"), Color("#356a9a")])
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var x := -12.0
	while x < 156.0:
		ForestProps.tree(self, Vector3(x, terrain.height_at(x) - 0.1, rng.randf_range(-15.0, -7.5)), rng.randf_range(8.0, 12.0), 2 + int(rng.randf() * 2.0), int(x))
		x += rng.randf_range(4.0, 7.0)
	x = -8.0
	while x < 154.0:
		if not (x > CAVE_X0 + 2.0 and x < CAVE_X1 - 2.0):
			ForestProps.tree(self, Vector3(x, terrain.height_at(x) - 0.1, rng.randf_range(-6.5, -4.0)), rng.randf_range(5.0, 7.0), 3, int(x) + 7)
		x += rng.randf_range(13.0, 19.0)
	# glowing flora everywhere: bells, mushrooms, giant moon-flowers
	x = -8.0
	var gi := 0
	while x < 154.0:
		var y := terrain.height_at(x)
		var col: Color = [Color("#7ad8ff"), Color("#c9a0ff"), Color("#ff9ad8"), Color("#9affd8")][gi % 4]
		match int(rng.randf() * 4.0):
			0: ForestProps.glow_bell(self, Vector3(x, y - 0.02, rng.randf_range(-1.6, 2.4)), col, rng.randf_range(0.6, 1.1))
			1: ForestProps.mushroom(self, Vector3(x, y - 0.03, rng.randf_range(1.2, 2.8)), rng.randf_range(0.3, 0.6), col, true)
			2: ForestProps.giant_flower(self, Vector3(x, y - 0.05, rng.randf_range(-4.5, -2.0)), rng.randf_range(2.8, 4.6), col, true)
			3: ForestProps.bush(self, Vector3(x, y - 0.05, rng.randf_range(-3.4, -1.6)), rng.randf_range(0.9, 1.5), Color("#2a7a8a"), col)
		gi += 1
		x += rng.randf_range(2.2, 4.2)
	var night_flowers := [Color("#7ad8ff"), Color("#c9a0ff"), Color.WHITE, Color("#ff9ad8")]
	ForestProps.scatter_grass(self, terrain, -14.0, CLIFF_X, 5.0, 31, Vector2(-5.0, 0.35), Color("#2a8a8a"), Color("#7ad0c0"))
	ForestProps.scatter_grass(self, terrain, CLIFF_X, 156.0, 5.0, 32, Vector2(-5.0, 0.35), Color("#2a8a8a"), Color("#7ad0c0"))
	ForestProps.scatter_flowers(self, terrain, -14.0, CLIFF_X, 1.4, 41, night_flowers)
	ForestProps.scatter_flowers(self, terrain, CLIFF_X, 156.0, 1.4, 42, night_flowers)
	# cliff dressing
	for i in 6:
		ForestProps.rock(self, Vector3(CLIFF_X - 1.0 - i * 0.2, 0.0, -1.5 + i * 0.9), 0.6, Color("#8a7ad0"))
	_cave()
	# foreground leaf frame (dark violet)
	var leaf_m := Mat.toon_grad(Color("#3a2f8a"), Color("#6a5ad0"), -0.4, 0.6, {"rim_amount": 0.4, "gradient_amount": 1.0})
	x = -6.0
	while x < 156.0:
		var l := Build.sphere(self, 1.5, Vector3(x, rng.randf_range(8.4, 9.6) + 3.0, rng.randf_range(2.6, 4.2)), leaf_m, Vector3(2.4, 0.32, 1.1), 12)
		l.rotation = Vector3(0, rng.randf_range(-0.3, 0.3), rng.randf_range(-0.5, 0.5))
		x += rng.randf_range(6.0, 11.0)
	# night butterflies (glowing)
	for i in 10:
		var b := Flutter.new()
		b.palette = [[Color("#7ad8ff"), Color("#c9a0ff"), Color("#ffffff")], [Color("#ff9ad8"), Color("#ffe27a"), Color("#c9a0ff")]][i % 2]
		b.speed = 1.6
		b.scale = Vector3.ONE * rng.randf_range(0.35, 0.5)
		add_child(b)
		var ax := rng.randf_range(0.0, 150.0)
		b.global_position = Vector3(ax, terrain.height_at(clampf(ax, -12.0, 154.0)) + 1.6, rng.randf_range(-2.0, 2.0))
		b.hold_at(b.global_position)
		var tw := b.create_tween().set_loops()
		tw.tween_callback(func(): b.guide_pos = Vector3(ax + rng.randf_range(-5.0, 5.0), terrain.height_at(clampf(ax, -12.0, 154.0)) + rng.randf_range(0.6, 2.4), rng.randf_range(-2.0, 2.0)))
		tw.tween_interval(rng.randf_range(2.0, 4.0))


func _cave() -> void:
	# rocky ceiling, back wall and stalactites frame the dark hollow; mushrooms glow dimly until Star Light arrives
	var rock := Mat.toon_grad(Color("#3a2f6a"), Color("#6a5aa8"), 0.0, 9.0, {"outline": false, "rim_amount": 0.3, "gradient_amount": 1.0})
	var cx := (CAVE_X0 + CAVE_X1) * 0.5
	for i in 9:
		var x := lerpf(CAVE_X0 - 3.0, CAVE_X1 + 3.0, float(i) / 8.0)
		Build.sphere(self, 3.4, Vector3(x, 8.6 + (i % 2) * 0.6, -0.5), rock, Vector3(1.6, 0.85, 2.6), 14)
		Build.sphere(self, 4.4, Vector3(x, 5.0, -8.0), rock, Vector3(1.5, 1.4, 1.0), 14)
	for i in 14:
		var x2 := lerpf(CAVE_X0, CAVE_X1, float(i) / 13.0)
		var h := 1.2 + (i % 3) * 0.6
		Build.cone(self, 0.35, h, Vector3(x2, 7.4 - h * 0.5, 0.5 + (i % 2) * 0.8), rock, Vector3(PI, 0, 0), 8)
	# dim mushrooms along the floor (they wake when the stars come)
	for i in 12:
		var x3 := lerpf(CAVE_X0 + 2.0, CAVE_X1 - 2.0, float(i) / 11.0)
		var col: Color = [Mat.PINK, Mat.SKY, Mat.LILAC, Mat.MINT][i % 4]
		var m := ForestProps.mushroom(self, Vector3(x3, terrain.height_at(x3) - 0.03, 1.0 + (i % 3) * 0.8), 0.4 + (i % 3) * 0.12, col, true)
		for c in m.get_children():
			if c is MeshInstance3D and c.material_override is ShaderMaterial:
				var sm := c.material_override as ShaderMaterial
				if sm.get_shader_parameter("emission_energy") != null and float(sm.get_shader_parameter("emission_energy")) > 0.1:
					sm.set_shader_parameter("emission_energy", 0.15)
					cave_mushrooms.append(sm)


func _story_objects() -> void:
	# --- the ledge + Lumi's rainbow ---
	var li := Interactable.make(self, "ledge_rainbow", "magic", "rainbow_bridge", _place(21.5), 5.0)
	li.fx_height = 1.6
	li.halo_height = 2.4
	li.activated.connect(func(_p): _make_rainbow())
	# --- fallen log ---
	log_node = Build.pivot(self, _place(58.0))
	var bark := Mat.toon_grad(Color("#5a3a6a"), Color("#8a6a9a"), -1.5, 1.5, {"outline": 0.012, "rim_amount": 0.3, "gradient_amount": 1.0, "shade_tint": Color(0.4, 0.3, 0.8)})
	Build.cyl(log_node, 1.5, 1.5, 12.0, Vector3(0, 1.5, -1.0), bark, 22, Vector3(PI * 0.5, 0, 0))
	# tree rings on the cut end facing the camera
	for i in 4:
		Build.torus(log_node, 1.3 - i * 0.3, 1.36 - i * 0.3 + 0.03, Vector3(0, 1.5, 5.02 + i * 0.001), Mat.toon(Color("#c8a0d8"), {"outline": false}), Vector3(PI * 0.5, 0, 0), 24)
	Build.cyl(log_node, 1.42, 1.42, 0.02, Vector3(0, 1.5, 5.0), Mat.toon(Color("#d8b8e0"), {"outline": false}), 22, Vector3(PI * 0.5, 0, 0))
	Build.sphere(log_node, 1.6, Vector3(0, 3.0, 1.0), Mat.toon(Color("#3fbfa8"), {"outline": false, "rim_amount": 0.0}), Vector3(1.0, 0.25, 2.6), 12)
	var lsb := StaticBody3D.new()
	lsb.collision_layer = 1
	var lcs := CollisionShape3D.new()
	var lbs := BoxShape3D.new()
	lbs.size = Vector3(3.0, 3.0, 2.6)
	lcs.shape = lbs
	lsb.add_child(lcs)
	lsb.position = Vector3(0, 1.5, 0)
	log_node.add_child(lsb)
	var fi := Interactable.make(self, "fallen_log", "magic", "flower", _place(54.0), 4.6)
	fi.fx_height = 1.4
	fi.halo_height = 2.0
	fi.activated.connect(func(_p): _lift_log())
	# --- dark hollow ---
	var di := Interactable.make(self, "dark_hollow", "magic", "starlight", _place(CAVE_X0 + 3.0), 6.0)
	di.fx_height = 1.6
	di.halo_height = 2.4
	di.activated.connect(func(_p): _light_cave())
	# --- the sleeping Moonflower ---
	_build_moonflower()
	var mi := Interactable.make(self, "moonflower", "coop", "coop_shine", _place(FLOWER_X - 1.6), 3.6)
	mi.fx_height = 1.3
	mi.halo_height = 2.2
	mi.activated.connect(func(_p): _bloom())
	# --- Lumi's "hint of ability" for the Hint system: the rainbow icon glows on her horn ---
	Events.quest_completed.connect(func(id): if id == quest_id: _finale())
	Events.dialogue_line_started.connect(_on_line)
	Events.quest_step_started.connect(_on_step_started)


func _on_step_started(_q: String, step: String) -> void:
	if companion == null:
		return
	match step:
		"lift_log":
			companion.rig.play("hopeful")
			companion.rig.set_emotion("worried")
		"light_the_dark":
			companion.rig.set_emotion("whisper")


func _after_ready() -> void:
	if companion == null:
		# safety: the friendship quest needs Lumi; fall back to a fresh companion when testing directly
		companion = Companion.new()
		companion.character_id = "lumi"
		companion.player = player
		add_child(companion)
		companion.global_position = spawn + Vector3(-2.2, 0.2, 0)
		magic.companion = companion
	lumi = companion.rig
	# darkness tracking needs the base values before we start dimming
	if Router.params.has("skipintro"):
		Quests.start(quest_id)
		return
	await get_tree().create_timer(0.6).timeout
	await Dialogue.play(String(Content.quest(quest_id).get("intro_dialogue", "")))
	Quests.start(quest_id)


func _on_line(line: Dictionary) -> void:
	match String(line.get("camera", "")):
		"moonlit_reveal":
			look_wide_intro(_place(4.0), Vector3(8, 6.0, 15), 3.4)
		"bloom_orbit":
			cam.cine_orbit(moonflower.global_position + Vector3(0, 0.8, 0), 6.5, 2.4, -20.0, 40.0, 6.0)


# =============================================================================
# puzzle reactions
# =============================================================================
func _make_rainbow() -> void:
	if _rainbow_built:
		return
	_rainbow_built = true
	Audio.sfx("rainbow_make")
	var x0 := 19.5
	var x1 := 27.4
	var pts: Array[Vector3] = []
	var n := 24
	for i in n + 1:
		var t := float(i) / n
		pts.append(Vector3(lerpf(x0, x1, t), 0.06 + smoothstep(0.0, 1.0, t) * 3.2, 0))
	var mesh := MeshExtra.path_ribbon(pts, 2.4)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := Mat.rainbow_material()
	mat.set_shader_parameter("reveal", 0.0)
	mat.set_shader_parameter("intensity", 1.35)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	# a second, taller decorative arch behind it
	var arch := MeshInstance3D.new()
	arch.mesh = Build.arc_ribbon(6.0, 1.3, 180.0, 56)
	var mat2 := Mat.rainbow_material()
	mat2.set_shader_parameter("reveal", 0.0)
	mat2.set_shader_parameter("alpha", 0.55)
	arch.material_override = mat2
	arch.position = Vector3(23.0, 0.0, -3.0)
	add_child(arch)
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v): mat.set_shader_parameter("reveal", v), 0.0, 1.05, 1.5)
	tw.tween_method(func(v): mat2.set_shader_parameter("reveal", v), 0.0, 1.05, 2.2)
	# collision follows the curve
	for i in n:
		var a := pts[i]
		var b := pts[i + 1]
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		var len := a.distance_to(b)
		bs.size = Vector3(len + 0.08, 0.3, 2.4)
		cs.shape = bs
		sb.add_child(cs)
		sb.position = (a + b) * 0.5 - Vector3(0, 0.15, 0)
		sb.rotation.z = atan2(b.y - a.y, b.x - a.x)
		add_child(sb)
	for i in 8:
		var p := pts[int(float(i) / 7.0 * n)]
		get_tree().create_timer(0.18 * i).timeout.connect(func(): Fx.sparkle_burst(self, p + Vector3(0, 0.4, 0), Color(1, 0.9, 1), 10, 2.0, 0.28, 0.9))


func _lift_log() -> void:
	Audio.sfx("bloom_big")
	var base := log_node.global_position
	# giant flowers grow underneath and carry the log up
	for i in 3:
		var f := ForestProps.giant_flower(self, base + Vector3(-1.4 + i * 1.4, -0.05, 0.6 + (i % 2) * 0.3), 4.2, [Mat.PINK, Color("#c9a0ff"), Mat.SUN][i], true)
		f.scale = Vector3(1, 0.05, 1)
		var tw := create_tween()
		tw.tween_interval(0.15 * i)
		tw.tween_property(f, "scale", Vector3.ONE, 1.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var lift := create_tween()
	lift.tween_interval(0.35)
	lift.tween_property(log_node, "position:y", log_node.position.y + 4.4, 1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.flower_burst(self, base + Vector3(0, 1.5, 3.0), [], 50)
	Fx.sparkle_burst(self, base + Vector3(0, 2.0, 3.0), Color(1, 0.8, 0.95), 40, 4.0, 0.36, 1.2)
	cam.shake(0.4)
	if companion:
		companion.rig.set_emotion("joyful")
		companion.rig.play("happy_jump")


func _light_cave() -> void:
	if _cave_lit:
		return
	_cave_lit = true
	Audio.sfx("starlight_cast")
	star_orb = Build.pivot(self, player.global_position + Vector3(0, 2.4, 0.4))
	Fx.glow_sprite(star_orb, Vector3.ZERO, Color(1, 0.95, 0.65, 0.95), 1.8)
	var sm := MeshInstance3D.new()
	sm.mesh = Build.star_mesh(0.22, 0.1, 0.08)
	sm.material_override = Mat.glowing(Mat.SUN, 3.0, {"outline": false})
	star_orb.add_child(sm)
	Fx.aura(star_orb, Color(1, 0.95, 0.6), 18, 0.4)
	star_light = OmniLight3D.new()
	star_light.light_color = Color(1, 0.92, 0.65)
	star_light.light_energy = 2.4
	star_light.omni_range = 16.0
	star_light.omni_attenuation = 1.2
	star_orb.add_child(star_light)
	var tw := create_tween()
	for m in cave_mushrooms:
		tw.parallel().tween_method(func(v): m.set_shader_parameter("emission_energy", v), 0.15, 2.0, 1.8)
	Fx.sparkle_burst(self, star_orb.global_position, Color(1, 0.95, 0.65), 50, 4.0, 0.4, 1.4)


func _level_process() -> void:
	# darkness in the hollow: dims the whole scene until the child lights it with Star Light
	var inside := player.global_position.x > CAVE_X0 - 4.0 and player.global_position.x < CAVE_X1
	var target := 0.0
	if inside:
		target = 0.62 if _cave_lit else 0.9
	_dark = lerpf(_dark, target, 1.0 - exp(-get_process_delta_time() * 2.5))
	var k: DirectionalLight3D = env.key
	k.light_energy = _base_key * (1.0 - _dark * 0.9)
	env.env.ambient_light_energy = _base_amb * (1.0 - _dark * 0.82)
	env.env.fog_light_color = _base_fog.lerp(Color("#0a0620"), _dark * 0.8)
	if star_orb and is_instance_valid(star_orb):
		var want := player.global_position + Vector3(player.facing * 0.8, 2.5 + sin(Time.get_ticks_msec() * 0.003) * 0.2, 0.5)
		star_orb.global_position = star_orb.global_position.lerp(want, 1.0 - exp(-get_process_delta_time() * 2.0))
		star_light.light_energy = lerpf(2.4, 0.8, 1.0 - _dark)   # gentler in the open


func _build_moonflower() -> void:
	var px := FLOWER_X
	var y := ground_y(px)
	var ped := Build.pivot(self, Vector3(px, y, 0))
	var stone := Mat.toon_grad(Color("#8a7ac0"), Color("#d0c8f8"), 0.0, 1.0, {"outline": 0.01, "rim_amount": 0.4, "gradient_amount": 1.0})
	Build.cyl(ped, 1.5, 1.7, 0.5, Vector3(0, 0.25, 0), stone, 24)
	Build.cyl(ped, 1.2, 1.4, 0.3, Vector3(0, 0.62, 0), stone, 24)
	for i in 6:
		var a := float(i) / 6.0 * TAU
		Build.cyl(ped, 0.13, 0.17, 1.6, Vector3(cos(a) * 1.9, 0.8, sin(a) * 1.2 - 0.3), stone, 10)
		Build.sphere(ped, 0.2, Vector3(cos(a) * 1.9, 1.7, sin(a) * 1.2 - 0.3), Mat.glowing(Color("#c8e6ff"), 1.5, {"pulse": 0.5, "outline": false}), Vector3.ONE, 10)
	# moonbeam from the sky
	var beam := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(3.4, 13.0)
	beam.mesh = q
	beam.material_override = Mat.additive(Color(0.7, 0.85, 1.0, 0.26), FxTex.beam())
	beam.position = Vector3(0, 6.5, -0.4)
	ped.add_child(beam)
	# the flower itself: a closed bud that will open
	moonflower = Build.pivot(ped, Vector3(0, 0.8, 0))
	Build.capsule(moonflower, 0.05, 0.9, Vector3(0, 0.3, 0), Mat.toon(Color("#5ad8b0"), {"outline": 0.008}))
	var head := Build.pivot(moonflower, Vector3(0, 0.8, 0))
	var pm := Mat.toon_grad(Color("#c8d8ff"), Color("#ffffff"), 0.0, 0.7, {"outline": 0.008, "two_sided": true, "emission_color": Color("#b0c8ff"), "emission_energy": 0.5, "pulse": 0.4, "glitter": 0.4, "gradient_amount": 1.0, "rim_color": Color.WHITE, "rim_amount": 0.8})
	for i in 8:
		var a2 := float(i) / 8.0 * TAU
		var pv := Build.pivot(head, Vector3.ZERO)
		pv.rotation.y = a2
		var p := Build.sphere(pv, 0.4, Vector3(0.0, 0.32, 0.0), pm, Vector3(0.45, 1.0, 0.18), 12)
		p.rotation.z = 0.0
		pv.rotation.x = 0.0
		petals.append(pv)
	Build.sphere(head, 0.14, Vector3(0, 0.05, 0), Mat.glowing(Color("#ffe6a0"), 1.2), Vector3.ONE, 12)
	Fx.aura(moonflower, Color(0.75, 0.9, 1.0), 10, 0.5)
	# bud closed: petals tilted upright/inward
	for pv in petals:
		pv.scale = Vector3(1, 1, 1)
	_set_flower_open(0.0)


func _set_flower_open(k: float) -> void:
	# k=0 closed bud .. 1 fully open. Petals fan outward from the vertical.
	for i in petals.size():
		petals[i].rotation.z = 0.0
		var pv := petals[i]
		# rotate around the local X after yaw so petals lean out
		pv.rotation = Vector3(0.0, float(i) / petals.size() * TAU, 0.0)
		var lean := lerpf(0.05, 1.25, k)
		pv.basis = Basis(Vector3.UP, float(i) / petals.size() * TAU) * Basis(Vector3(0, 0, 1), lean)
		pv.scale = Vector3.ONE * lerpf(0.75, 1.5, k)


func _bloom() -> void:
	Audio.sfx("bloom_big")
	var tw := create_tween()
	tw.tween_method(_set_flower_open, 0.0, 1.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	Fx.fireflies(self, moonflower.global_position + Vector3(0, 1.0, 0), Vector3(2.4, 1.6, 1.4), 40, Color(0.8, 0.92, 1.0))
	Fx.glow_sprite(moonflower, Vector3(0, 0.8, 0.4), Color(0.75, 0.9, 1.0, 0.7), 4.2)
	Fx.star_shower(self, moonflower.global_position + Vector3(0, 4.0, 0), 70)
	if companion:
		companion.rig.set_horn_energy(3.0)


# =============================================================================
# finale: Lumi takes the Moonflower home
# =============================================================================
func _finale() -> void:
	player.frozen = true
	Hints.stop()
	Audio.play_music("rescue_swell", 0.8)
	Audio.sting("rescue_sting")
	await get_tree().create_timer(1.0).timeout
	player.rig.play("cheer")
	if companion:
		companion.frozen = true
	await Dialogue.play("moonflower_blooms")
	# Lumi carries a little Moonflower (it appears on her horn side)
	if companion:
		var small := Build.pivot(companion.rig.head, Vector3(0.25, 0.25, 0.3))
		Fx.glow_sprite(small, Vector3.ZERO, Color(0.75, 0.9, 1.0, 0.8), 0.9)
		Build.sphere(small, 0.1, Vector3.ZERO, Mat.glowing(Color("#d8e8ff"), 2.0), Vector3.ONE, 10)
	earn_stars(3, moonflower.global_position + Vector3(0, 1.4, 0), "friendship_quest")
	Fx.star_shower(self, player.global_position + Vector3(0, 4.0, 0), 60)
	await get_tree().create_timer(2.6).timeout
	GameState.set_stage("lumi", GameState.Stage.QUEST_DONE)
	GameState.grant_power("rainbow")
	GameState.unlock_feature("unicorn_stable")
	await cam.cine_release(0.1)
	next_scene("castle", {"arrival": "moonflower_done"})
