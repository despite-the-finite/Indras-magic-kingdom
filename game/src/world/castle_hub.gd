extends LevelBase
## THE CASTLE - the princess's home and the emotional centre of the game (Mode 2).
## It is a visual record of everything she has done: rescued friends move in, places wake up.
##
## State-driven: what you see and what Flutter hints at depends on GameState (character stage, unlocked features).

var castle_node: Node3D
var stable: Dictionary = {}
var lumi_w: Wanderer
var luna_w: Wanderer
var map_stand: Node3D
var map_card: Node3D
var ride_sign: Node3D
var lumi_pet: Interactable
var _busy_story := false

const STABLE_X := -16.0
const CASTLE_X := 24.0


func _configure() -> void:
	preset = "castle_day"
	min_x = -22.0
	max_x = 50.0
	kill_y = -6.0
	spawn = Vector3(float(Router.params.get("spawn_x", 8.0)), 0.3, 0)
	music_cue = "castle_theme"
	ambience = ["forest_birds", "garden_water"]


func _build_world() -> void:
	terrain = Terrain.build(self, [
		{"x0": -40.0, "x1": 70.0, "pts": [[-40, 0.5], [-24, 0.0], [-6, 0.1], [10, 0.0], [30, 0.1], [50, 0.0], [70, 0.6]]},
	], {"top_color": Color("#7fd060"), "top_color_far": Color("#3a9a6a"), "dirt_color": Color("#b58a78"), "dirt_dark": Color("#6a4a7a"), "path_color": Color("#e8cdd0")})
	_scenery()
	_places()


# =============================================================================
func _scenery() -> void:
	ForestProps.backdrop(self, -40.0, 70.0, [Color("#a0aef0"), Color("#88b8e8"), Color("#7cc8b8")])
	castle_node = CastleKit.castle(self, Vector3(CASTLE_X, -0.2, -31.0))
	castle_node.scale = Vector3.ONE * 1.75
	CastleKit.fountain(self, Vector3(CASTLE_X, 0.0, -4.6))
	# the garden gate on the lane: walk up to it and the castle doors open for her (see castle_inside.gd)
	CastleKit.garden_gate(self, Vector3(CASTLE_X, terrain.height_at(CASTLE_X), -1.7))
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var x := -38.0
	while x < 68.0:
		if absf(x - CASTLE_X) > 24.0 and absf(x - STABLE_X) > 6.5:
			ForestProps.tree(self, Vector3(x, terrain.height_at(x) - 0.1, rng.randf_range(-7.0, -4.5)), rng.randf_range(5.0, 7.0), 1 if rng.randf() < 0.45 else 0, int(x))
		if absf(x - CASTLE_X) > 3.0 and rng.randf() < 0.85:
			ForestProps.bush(self, Vector3(x + 1.2, terrain.height_at(x) - 0.05, rng.randf_range(-3.2, -1.8)), rng.randf_range(0.8, 1.4), [Color("#2f9a5a"), Color("#3fae6a")][int(rng.randf() * 2.0)], [Mat.PINK, Color.WHITE, Mat.SUN, Color(0, 0, 0, 0)][int(rng.randf() * 4.0)])
		x += rng.randf_range(5.0, 9.0)
	# tall trees far behind for depth
	x = -40.0
	while x < 70.0:
		if absf(x - CASTLE_X) > 26.0:
			ForestProps.tree(self, Vector3(x, terrain.height_at(x) - 0.1, rng.randf_range(-22.0, -13.0)), rng.randf_range(9.0, 13.0), 1 if rng.randf() < 0.4 else 0, int(x) + 3)
		x += rng.randf_range(4.5, 8.0)
	ForestProps.scatter_grass(self, terrain, -40.0, 70.0, 3.2, 51, Vector2(-8.0, 1.6), Color("#3fb05a"), Color("#a0e070"))
	ForestProps.scatter_flowers(self, terrain, -40.0, 70.0, 1.8, 52)
	# rose hedges lining the path and flower beds
	for i in 16:
		var hx := -30.0 + i * 5.2
		if absf(hx - CASTLE_X) < 3.5:
			continue
		var hb := ForestProps.bush(self, Vector3(hx, terrain.height_at(hx), 2.2), 0.55, Color("#2a9a5a"), Mat.PINK)
	for i in 8:
		ForestProps.giant_flower(self, Vector3(-30.0 + i * 12.0 + 3.0, 0.0, -5.5), rng.randf_range(2.4, 3.6), [Mat.PINK, Color("#c9a0ff"), Mat.SUN][i % 3], false)
	# lamp posts along the path
	for i in 9:
		var lx := -24.0 + i * 8.0
		Build.cyl(self, 0.06, 0.09, 2.6, Vector3(lx, terrain.height_at(lx) + 1.3, -1.9), Mat.toon(Color("#8a68d8"), {"outline": false}), 8)
		ForestProps.lantern(self, Vector3(lx, terrain.height_at(lx) + 2.7, -1.9), Color("#ffe6a0"))
	ForestProps.light_shafts(self, Vector3(CASTLE_X - 6, 0, 0), 4, 22.0, Color(1, 0.95, 0.75, 0.12), 8)
	# gentle butterflies
	for i in 10:
		var b := Flutter.new()
		b.palette = [[Mat.PINK, Mat.LILAC, Mat.SUN], [Mat.SKY, Mat.MINT, Mat.PINK]][i % 2]
		b.speed = 1.6
		b.scale = Vector3.ONE * rng.randf_range(0.35, 0.5)
		add_child(b)
		var ax := rng.randf_range(-20.0, 46.0)
		b.global_position = Vector3(ax, 1.8, rng.randf_range(-2.0, 2.5))
		b.hold_at(b.global_position)
		var tw := b.create_tween().set_loops()
		tw.tween_callback(func(): b.guide_pos = Vector3(ax + rng.randf_range(-5.0, 5.0), terrain.height_at(clampf(ax, -30.0, 60.0)) + rng.randf_range(0.6, 2.4), rng.randf_range(-2.0, 2.5)))
		tw.tween_interval(rng.randf_range(2.0, 4.0))


func _places() -> void:
	var unlocked := GameState.feature_unlocked("unicorn_stable")
	var want_open := unlocked and GameState.stage("lumi") >= GameState.Stage.AT_CASTLE
	# arriving from the rescue: the stable starts closed and OPENS during the cinematic
	if Router.params.get("arrival", "") == "lumi_rescued":
		want_open = false
	stable = CastleKit.stable(self, Vector3(STABLE_X, terrain.height_at(STABLE_X), -3.6), want_open)
	if not want_open:
		var lk := CastleKit.lock_icon(stable.node, Vector3(0, 1.7, 2.25))
		lk.name = "StableLock"
	var door := Interactable.make(self, "stable_door", "press", "", Vector3(STABLE_X, terrain.height_at(STABLE_X), 0.0), 3.4)
	door.icon = "horseshoe"
	door.halo_height = 2.4
	door.press_anim = "wave"
	door.one_shot = false
	door.enabled = want_open
	door.activated.connect(func(_p): _enter_stable())
	# the castle's front door: the whole inside is hers to explore
	var cd := Interactable.make(self, "castle_door", "press", "", Vector3(CASTLE_X, terrain.height_at(CASTLE_X), 0.0), 2.8)
	cd.icon = "castle"
	cd.halo_height = 3.0
	cd.press_anim = "wave"
	cd.one_shot = false
	cd.activated.connect(func(_p): _enter_castle())
	# the magic map
	map_stand = Build.pivot(self, Vector3(2.0, terrain.height_at(2.0), -1.0))
	var stone := Mat.toon_grad(Color("#c9a8e8"), Color("#f0e0ff"), 0.0, 1.2, {"outline": 0.01, "rim_amount": 0.4, "gradient_amount": 1.0})
	Build.cyl(map_stand, 0.35, 0.5, 1.0, Vector3(0, 0.5, 0), stone, 16)
	map_card = Build.pivot(map_stand, Vector3(0, 1.8, 0))
	var mq := MeshInstance3D.new()
	var mm := QuadMesh.new()
	mm.size = Vector2(1.1, 0.78)
	mq.mesh = mm
	mq.material_override = Mat.toon(Color("#ffe8b8"), {"two_sided": true, "emission_color": Color("#ffe0a0"), "emission_energy": 0.5, "glitter": 0.4, "outline": false})
	map_card.add_child(mq)
	Build.sphere(map_card, 0.12, Vector3(-0.45, 0.18, 0.02), Mat.glowing(Mat.PINK, 1.6), Vector3(1, 1, 0.3), 10)
	Build.torus(map_card, 0.13, 0.19, Vector3(0.3, -0.15, 0.02), Mat.glowing(Mat.SKY, 1.2), Vector3(PI * 0.5, 0, 0), 14)
	Fx.glow_sprite(map_card, Vector3(0, 0, -0.1), Color(1, 0.9, 0.6, 0.35), 1.6)
	Fx.aura(map_card, Color(1, 0.95, 0.7), 14, 0.7)
	var mi := Interactable.make(self, "magic_map", "press", "", Vector3(2.0, terrain.height_at(2.0), 0.0), 2.6)
	mi.icon = "map"
	mi.halo_height = 2.6
	mi.one_shot = false
	mi.press_anim = "wonder"
	mi.activated.connect(func(_p): Router.go("map"))
	# sleeping places (they wake up as friends are rescued)
	_sleeping_place("dragon_tower", Vector3(46.0, 0.0, -6.0))
	_sleeping_place("mermaid_lagoon", Vector3(36.0, 0.0, -4.0))
	_sleeping_place("fairy_garden", Vector3(-4.0, 0.0, -4.4))
	# Lumi's rainbow-ride signpost appears after her quest
	ride_sign = Build.pivot(self, Vector3(-10.0, terrain.height_at(-10.0), 1.0))
	ride_sign.visible = GameState.stage("lumi") >= GameState.Stage.QUEST_DONE
	Build.cyl(ride_sign, 0.08, 0.1, 2.2, Vector3(0, 1.1, 0), Mat.toon(Color("#b98a68"), {"outline": 0.01}), 8)
	Build.box(ride_sign, Vector3(1.6, 0.9, 0.12), Vector3(0, 2.2, 0), Mat.toon(Color("#fff0d8"), {"outline": 0.01}))
	var rb := MeshInstance3D.new()
	rb.mesh = Build.arc_ribbon(0.36, 0.22, 180.0, 24)
	rb.material_override = Mat.rainbow_material()
	rb.position = Vector3(0, 2.0, 0.08)
	ride_sign.add_child(rb)
	Fx.aura(ride_sign, Color(1, 0.9, 1), 12, 0.7).position = Vector3(0, 2.2, 0)
	var ri := Interactable.make(self, "ride_sign", "press", "", Vector3(-10.0, terrain.height_at(-10.0), 0.0), 2.4)
	ri.icon = "rainbow"
	ri.halo_height = 2.8
	ri.one_shot = false
	ri.enabled = ride_sign.visible
	ri.activated.connect(func(_p): Router.go("rainbow_ride"))


func _sleeping_place(id: String, pos: Vector3) -> void:
	var y := terrain.height_at(pos.x)
	var n := Build.pivot(self, Vector3(pos.x, y, pos.z))
	match id:
		"dragon_tower":
			CastleKit.tower(n, Vector3.ZERO, 2.0, 9.5, Color("#b06ad8"), Color("#ff7fb6"))
		"mermaid_lagoon":
			var sand := Mat.toon(Color("#f6e0b8"), {"outline": false})
			Build.cyl(n, 3.2, 3.5, 0.5, Vector3(0, 0.15, 0), Mat.toon(Color("#c9a8e8"), {"outline": 0.01}), 26)
			Build.cyl(n, 2.8, 2.8, 0.1, Vector3(0, 0.4, 0), sand, 26)
			for k in 6:
				Build.sphere(n, 0.16, Vector3(cos(k) * 1.6, 0.5, sin(k) * 1.0), Mat.glowing(Color("#ffd0f0"), 0.8, {"outline": false}), Vector3(1, 0.6, 1), 8)
		"fairy_garden":
			Build.cyl(n, 2.2, 2.4, 0.4, Vector3(0, 0.1, 0), Mat.toon(Color("#8a6a58"), {"outline": 0.01}), 24)
			for k in 7:
				var a := float(k) / 7.0 * TAU
				Build.sphere(n, 0.09, Vector3(cos(a) * 1.4, 0.35, sin(a) * 1.0), Mat.toon(Color("#5fc98a"), {"outline": false}), Vector3(1, 0.6, 1), 8)
	CastleKit.lock_icon(n, Vector3(0, 3.2 if id == "dragon_tower" else 1.5, 2.0))


# =============================================================================
# story
# =============================================================================
func _after_ready() -> void:
	Events.dialogue_line_started.connect(_on_line)
	var stage := GameState.stage("lumi")
	if stage >= GameState.Stage.AT_CASTLE or Router.params.get("arrival", "") == "lumi_rescued":
		_spawn_lumi()
	var arrival := String(Router.params.get("arrival", ""))
	if Router.params.has("skipintro"):
		_set_goal_hint()
		return
	await get_tree().create_timer(0.7).timeout
	match arrival:
		"lumi_rescued":
			await _after_rescue()
		"care_done":
			await _lumi_asks_help()
		"moonflower_done":
			await _mama_arrives()
		"from_inside":
			pass
		_:
			if not GameState.flag("castle_intro_done"):
				await _first_visit()
	_set_goal_hint()
	# the first time she is free in the garden, tell her the castle itself can be explored (once ever)
	if arrival == "" and GameState.stage("lumi") >= GameState.Stage.AT_CASTLE and not GameState.dialogue_seen("castle_explore_tip_01"):
		await get_tree().create_timer(1.0).timeout
		Dialogue.play_async("castle_explore_tip")


func _spawn_lumi() -> void:
	var lumi := UnicornRig.new("lumi")
	lumi_w = Wanderer.new()
	lumi_w.rig = lumi
	lumi_w.terrain = terrain
	lumi_w.x_min = -20.0
	lumi_w.x_max = 44.0
	lumi_w.greet_target = player
	lumi_w.position = Vector3(STABLE_X + 3.0 if Router.params.get("arrival", "") != "lumi_rescued" else 12.0, 0, 0.6)
	lumi_w.z_lane = 0.6
	add_child(lumi_w)      # Wanderer parents its rig in _ready
	lumi.set_emotion("happy")
	# petting: tap Lumi for a hug and hearts
	var pet := Interactable.make(self, "lumi_pet", "press", "", Vector3.ZERO, 2.0)
	pet.icon = "heart"
	pet.one_shot = false
	pet.press_anim = "pet"
	pet.halo_height = 2.0
	pet.activated.connect(func(_p):
		lumi.set_emotion("joyful")
		lumi.play("hug")
		lumi_w._timer = 3.0
		Fx.heart_burst(self, lumi_w.global_position + Vector3(0, 1.4, 0), 8)
		Audio.sfx("happy_chime", -3.0))
	lumi_pet = pet


func _first_visit() -> void:
	_busy_story = true
	flutter.global_position = Vector3(CASTLE_X, 14.0, 2.0)
	flutter.hold_at(Vector3(CASTLE_X, 10.0, 2.0))
	await Dialogue.play("castle_intro")
	GameState.set_flag("castle_intro_done", true)
	GameState.advance_stage("lumi", GameState.Stage.DISCOVERED)
	flutter.follow(player)
	_busy_story = false


func _after_rescue() -> void:
	_busy_story = true
	lumi_w.set_process(false)
	lumi_w.rig.face_toward(1.0)
	await Dialogue.play("castle_after_rescue")
	GameState.advance_stage("lumi", GameState.Stage.AT_CASTLE)
	GameState.unlock_feature("unicorn_stable")
	lumi_w.set_process(true)
	await Dialogue.play("care_intro")
	_busy_story = false


func _lumi_asks_help() -> void:
	_busy_story = true
	# Lumi bounds over to the princess and asks for help: this unlocks the Friendship Quest
	lumi_w.set_process(false)
	var lumi := lumi_w.rig
	lumi_w.global_position = Vector3(player.global_position.x - 7.0, lumi_w.global_position.y, 0.6)
	var tw := create_tween()
	tw.tween_property(lumi_w, "position:x", player.global_position.x + 1.7, 1.4).set_trans(Tween.TRANS_SINE)
	lumi.move_speed = 4.4
	lumi.facing = 1.0
	await tw.finished
	lumi.move_speed = 0.0
	lumi.face_toward(player.global_position.x - lumi_w.global_position.x)
	await Dialogue.play("lumi_asks_help")
	GameState.advance_stage("lumi", GameState.Stage.QUEST_READY)
	lumi_w.set_process(true)
	_busy_story = false


func _mama_arrives() -> void:
	_busy_story = true
	lumi_w.set_process(false)
	var luna := UnicornRig.new("luna")
	luna_w = Wanderer.new()
	luna_w.rig = luna
	luna_w.terrain = terrain
	luna_w.position = Vector3(CASTLE_X - 16.0, 0, 0.6)
	luna_w.z_lane = 0.6
	luna_w.set_process(false)
	add_child(luna_w)
	# the princess and Lumi walk to the gate where Mama is waiting
	player.frozen = true
	var lumi := lumi_w.rig
	lumi_w.global_position.x = player.global_position.x - 1.8
	luna_w.position.x = player.global_position.x + 5.0
	luna.facing = -1.0
	luna.set_emotion("gentle")
	await Dialogue.play("mama_arrives")
	Fx.sparkle_burst(self, player.global_position + Vector3(0, 2.0, 0), Color(1, 0.9, 1), 60, 4.5, 0.4, 1.4)
	if player.rig:
		player.rig.play("cheer")
	ride_sign.visible = true
	Audio.sfx("rainbow_make")
	var ri := Interactable.all.filter(func(i): return i.id == "ride_sign")
	for r in ri:
		r.enabled = true
	await get_tree().create_timer(1.6).timeout
	await Dialogue.play("rainbow_ride_unlocked")
	player.frozen = false
	lumi_w.set_process(true)
	luna_w.set_process(true)
	luna_w.x_min = CASTLE_X - 18.0
	luna_w.x_max = CASTLE_X + 12.0
	_busy_story = false


func _set_goal_hint() -> void:
	var target := "magic_map"
	var voice := "castle_hint_map"
	match GameState.stage("lumi"):
		GameState.Stage.AT_CASTLE:
			if not GameState.care_complete("lumi"):
				target = "stable_door"
				voice = "hint_castle_stable"
		GameState.Stage.QUEST_DONE:
			target = "ride_sign"
			voice = "hint_ride"
	Hints.watch_step({"id": "castle_goal", "hint": {"voice": voice, "voice_alt": voice, "target": target}})
	# the stable door only works once Lumi lives there
	for i in Interactable.all:
		if i.id == "stable_door":
			i.enabled = GameState.feature_unlocked("unicorn_stable") and GameState.stage("lumi") >= GameState.Stage.AT_CASTLE


func _on_line(line: Dictionary) -> void:
	match String(line.get("camera", "")):
		"castle_reveal":
			var start := Vector3(CASTLE_X - 4.0, 5.0, 24.0)
			await cam.cine_to(start, Vector3(CASTLE_X, 6.0, -9.0), 0.01)
			await get_tree().create_timer(1.6).timeout
			cam.cine_release(3.4)
		"flutter_arrives":
			flutter.guide_to(player.global_position + Vector3(1.0, 1.4, 0.5))
			await get_tree().create_timer(2.6).timeout
			flutter.follow(player)
		"stable_reveal":
			await cam.cine_to(Vector3(STABLE_X + 2.0, 3.6, 12.0), Vector3(STABLE_X, 2.2, -3.6), 1.6)
			_open_stable()
			await get_tree().create_timer(2.2).timeout
			cam.cine_release(2.0)
		"rainbow_gift":
			var arc := MeshInstance3D.new()
			arc.mesh = Build.arc_ribbon(5.0, 1.0, 180.0, 56)
			var mat := Mat.rainbow_material()
			mat.set_shader_parameter("reveal", 0.0)
			arc.material_override = mat
			arc.position = player.global_position + Vector3(0, 0.0, -1.0)
			add_child(arc)
			create_tween().tween_method(func(v): mat.set_shader_parameter("reveal", v), 0.0, 1.05, 2.0)
			GameState.grant_power("rainbow")


func _open_stable() -> void:
	Audio.sfx("door_open")
	var dl: Node3D = stable.door_l
	var dr: Node3D = stable.door_r
	create_tween().tween_property(dl, "rotation:y", deg_to_rad(-105.0), 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(dr, "rotation:y", deg_to_rad(105.0), 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	(stable.glow as Node3D).visible = true
	var lk: Node = stable.node.get_node_or_null("StableLock")
	if lk:
		lk.queue_free()
	var pos: Vector3 = (stable.node as Node3D).global_position + Vector3(0, 1.8, 2.4)
	Fx.sparkle_burst(self, pos, Color(1, 0.9, 0.6), 70, 5.0, 0.4, 1.6)
	Fx.flower_burst(self, pos + Vector3(0, 1.0, 0), [], 40)
	Audio.sfx("magic_flourish")
	for i in Interactable.all:
		if i.id == "stable_door":
			i.enabled = true


func _enter_stable() -> void:
	if _busy_story or not GameState.feature_unlocked("unicorn_stable"):
		return
	Router.go("stable", {}, "clouds")


func _enter_castle() -> void:
	if _busy_story:
		return
	Audio.sfx("door_open")
	Router.go("castle_inside", {}, "clouds")


func _level_process() -> void:
	if lumi_pet and lumi_w and is_instance_valid(lumi_w):
		lumi_pet.global_position = lumi_w.global_position
	if map_card:
		map_card.position.y = 1.8 + sin(Time.get_ticks_msec() * 0.002) * 0.12
		map_card.rotation.y = sin(Time.get_ticks_msec() * 0.0009) * 0.35
