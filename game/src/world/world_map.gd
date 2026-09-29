extends Node3D
## THE WORLD MAP - an illustrated storybook table with a little island per kingdom.
## Only reachable places glow and bob; sleeping ones wear clouds and a lock. One tap and Flutter flies you there.
## Which adventure a region starts depends on the character's stage in the lifecycle (data-driven from data/world + quests).

var cam: Camera3D
var islands: Dictionary = {}     # region id -> Node3D
var flutter: Flutter
var ui: CanvasLayer
var _focus_ids: Array[String] = []
var _focus_i := 0
var _busy := false
var _marker: Node3D
var _t := 0.0
var _crown: Hud.CrownWidget


func _ready() -> void:
	EnvKit.apply(self, "map_parchment")
	_build_table()
	_build_islands()
	_build_ui()
	Audio.play_music("map_theme", 1.4)
	Audio.set_ambience([])
	cam = Camera3D.new()
	cam.fov = 38.0
	add_child(cam)
	cam.current = true
	cam.global_position = Vector3(0, 19.0, 15.5)
	cam.look_at(Vector3(0, 0, 0.6), Vector3.UP)
	flutter = Flutter.new()
	add_child(flutter)
	flutter.global_position = Vector3(0, 3, 1)
	flutter.hold_at(Vector3(0.5, 1.8, 0))
	flutter.scale = Vector3.ONE * 1.6
	await get_tree().create_timer(0.7).timeout
	Dialogue.play_async("map_intro")
	if _marker:
		Hints.register_target("map_goal", _marker)
		Hints.watch_step({"id": "map_goal", "hint": {"voice": "map_intro", "voice_alt": "map_intro", "target": "map_goal"}})
		Events.hint_level_changed.connect(func(level, _t):
			if level >= 2 and is_instance_valid(_marker):
				flutter.hold_at(_marker.global_position + Vector3(0, 0.6, 0.3)))


func _build_table() -> void:
	# wooden table, big parchment with curled edges, soft border pattern
	Build.box(self, Vector3(40, 1.0, 26), Vector3(0, -1.1, 0), Mat.toon_grad(Color("#8a5a48"), Color("#b98a68"), -1.6, -0.6, {"outline": false, "gradient_amount": 1.0}))
	var parch := Mat.toon_grad(Color("#f1d9a8"), Color("#fff0cc"), -0.1, 0.1, {"outline": false, "rim_amount": 0.0, "gradient_amount": 1.0, "glitter": 0.15})
	Build.box(self, Vector3(20.0, 0.16, 12.6), Vector3(0, -0.08, 0.3), parch)
	for sx in [-1.0, 1.0]:
		Build.cyl(self, 0.26, 0.26, 12.7, Vector3(sx * 10.05, 0.02, 0.3), Mat.toon(Color("#f6e2b8"), {"outline": 0.008}), 14, Vector3(PI * 0.5, 0, 0))
	# blue sea patches + winding rivers (flat discs)
	var sea := Mat.toon(Color("#9fdcf0"), {"outline": false, "rim_amount": 0.0})
	Build.cyl(self, 5.0, 5.0, 0.03, Vector3(-4.6, 0.02, 2.4), sea, 32).scale = Vector3(1.2, 1, 0.9)
	Build.cyl(self, 4.2, 4.2, 0.03, Vector3(5.2, 0.02, 2.6), Mat.toon(Color("#c8ecff"), {"outline": false}), 32).scale = Vector3(1.1, 1, 0.8)
	# compass rose + dotted trails
	Build.torus(self, 0.65, 0.78, Vector3(-8.2, 0.05, 4.4), Mat.toon(Color("#c9975a"), {"outline": false}), Vector3.ZERO, 28)
	for i in 4:
		var a := float(i) * PI * 0.5
		Build.cone(self, 0.16, 1.1, Vector3(-8.2 + cos(a) * 0.9, 0.06, 4.4 + sin(a) * 0.9), Mat.toon(Color("#ff8fbf") if i % 2 == 0 else Color("#6ec6f5"), {"outline": false}), Vector3(PI * 0.5, 0, a + PI * 0.5 - PI * 0.5), 6)
	Fx.pollen(self, Vector3(0, 3.0, 0), Vector3(9, 2.5, 5), 50, Color(1, 0.95, 0.7, 0.8))
	# little clouds drifting in the frame corners
	for i in 6:
		var c := Build.sphere(self, 1.0, Vector3(-9.0 + i * 3.6, 2.2 + (i % 2) * 0.6, 6.0 + (i % 3)), Mat.toon(Color("#ffffff"), {"outline": false, "rim_amount": 0.3, "shade_tint": Color(0.9, 0.85, 1.0)}), Vector3(1.8, 0.7, 1.0), 10)


func _region_state(rid: String) -> String:
	## "open_rescue" | "open_friendship" | "resting" | "sleeping" | "home"
	if rid == "castle":
		return "home"
	if rid == "enchanted_forest":
		var st := GameState.stage("lumi")
		if st <= GameState.Stage.DISCOVERED:
			return "open_rescue"
		if st == GameState.Stage.QUEST_READY:
			return "open_friendship"
		return "resting"
	return "sleeping"


func _build_islands() -> void:
	for rid in Content.regions:
		var r: Dictionary = Content.regions[rid]
		var n := Build.pivot(self, Vector3(r.map_pos[0] * 1.9, 0.0, r.map_pos[1] * 1.55))
		var pal: Array = r.palette
		var state := _region_state(rid)
		var base_c := Color(pal[0])
		var top := Mat.toon_grad(base_c.darkened(0.15), base_c.lightened(0.15), 0.0, 0.5, {"outline": 0.012, "rim_amount": 0.4, "gradient_amount": 1.0})
		Build.cyl(n, 1.85, 2.0, 0.35, Vector3(0, 0.17, 0), Mat.toon(Color("#c9a880"), {"outline": 0.012}), 30)
		Build.cyl(n, 1.7, 1.85, 0.16, Vector3(0, 0.42, 0), top, 30)
		_decorate(n, rid, pal)
		if state == "sleeping" or state == "resting":
			# cloud blanket + lock
			for i in 5:
				var a := float(i) / 5.0 * TAU
				Build.sphere(n, 0.85, Vector3(cos(a) * 0.9, 1.05, sin(a) * 0.7), Mat.toon(Color("#ffffff"), {"outline": false, "rim_amount": 0.35, "shade_tint": Color(0.85, 0.8, 1.0)}), Vector3(1.2, 0.8, 1.0), 10)
			Build.sphere(n, 1.0, Vector3(0, 1.3, 0), Mat.toon(Color("#ffffff"), {"outline": false, "rim_amount": 0.35, "shade_tint": Color(0.85, 0.8, 1.0)}), Vector3(1.3, 0.8, 1.1), 10)
			if state == "sleeping":
				CastleKit.lock_icon(n, Vector3(0, 2.1, 0.9)).scale = Vector3.ONE * 1.5
		islands[rid] = n
		# make the reachable places gently bob + wear a big sparkly marker
		if state.begins_with("open"):
			Fx.aura(n, Color(1, 0.95, 0.6), 22, 1.5).position = Vector3(0, 1.2, 0)
			_marker = Build.pivot(n, Vector3(0, 3.4, 0))
			var st := MeshInstance3D.new()
			st.mesh = Build.star_mesh(0.5, 0.22, 0.16)
			st.material_override = Mat.glowing(Mat.SUN, 2.4, {"outline": 0.01})
			_marker.add_child(st)
			Fx.glow_sprite(_marker, Vector3.ZERO, Color(1, 0.9, 0.5, 0.7), 3.0)
			if state == "open_friendship":
				var moon := MeshInstance3D.new()
				moon.mesh = Build.crescent(0.4, 0.18, 0.1)
				moon.material_override = Mat.glowing(Color("#fff0a0"), 1.6)
				moon.position = Vector3(0.9, 0.3, 0)
				_marker.add_child(moon)
			_focus_ids.append(rid)
		elif state == "home":
			_focus_ids.append(rid)


func _decorate(n: Node3D, rid: String, pal: Array) -> void:
	match rid:
		"castle":
			var c := CastleKit.castle(n, Vector3(0, 0.5, -0.2))
			c.scale = Vector3.ONE * 0.11
		"enchanted_forest":
			for i in 5:
				var a := float(i) / 5.0 * TAU
				var t := ForestProps.tree(n, Vector3(cos(a) * 0.9, 0.5, sin(a) * 0.6), 1.6, 1 if i % 2 == 0 else 0, i)
				t.scale = Vector3.ONE * 0.62
			ForestProps.giant_flower(n, Vector3(0.1, 0.5, 0.3), 1.2, Mat.PINK, false)
		"dragon_mountain":
			for i in 3:
				Build.cone(n, 0.9 - i * 0.2, 1.8 - i * 0.3, Vector3(-0.5 + i * 0.6, 0.5 + (1.8 - i * 0.3) * 0.5, -0.2 + (i % 2) * 0.4), Mat.toon(Color("#b8a0d0"), {"outline": 0.01}), Vector3.ZERO, 8)
			Build.sphere(n, 0.25, Vector3(0.1, 0.55, 0.6), Mat.glowing(Color("#ff7a5a"), 1.4, {"outline": false}), Vector3(1.4, 0.3, 1.0), 8)
		"mermaid_lagoon":
			Build.cyl(n, 1.3, 1.3, 0.06, Vector3(0, 0.52, 0.0), Mat.toon(Color("#5fd0f0"), {"outline": false}), 24)
			for i in 4:
				Build.sphere(n, 0.18, Vector3(cos(i * 1.6) * 0.8, 0.6, sin(i * 1.6) * 0.6), Mat.toon(Color("#ffd0e8"), {"outline": 0.008}), Vector3(1, 0.7, 1), 8)
		"rainbow_islands":
			var rb := MeshInstance3D.new()
			rb.mesh = Build.arc_ribbon(0.9, 0.5, 180.0, 24)
			rb.material_override = Mat.rainbow_material()
			rb.position = Vector3(0, 0.5, 0)
			n.add_child(rb)
		"snowflake_kingdom":
			for i in 4:
				Build.cone(n, 0.4, 1.2, Vector3(-0.7 + i * 0.5, 1.1, (i % 2) * 0.4 - 0.2), Mat.toon(Color("#e6f4ff"), {"outline": 0.008, "rim_amount": 0.6}), Vector3.ZERO, 8)
		"moonlight_kingdom":
			for i in 4:
				var t := ForestProps.tree(n, Vector3(-0.7 + i * 0.5, 0.5, (i % 2) * 0.4 - 0.2), 1.4, 3, i)
				t.scale = Vector3.ONE * 0.5
			var m := MeshInstance3D.new()
			m.mesh = Build.crescent(0.35, 0.16, 0.08)
			m.material_override = Mat.glowing(Color("#fff0a0"), 1.6)
			m.position = Vector3(0.6, 2.0, -0.4)
			n.add_child(m)


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
	var back := MagicButton.new("castle", Vector2(96, 96))
	back.set_colors(UiKit.LILAC, UiKit.LILAC_D)
	back.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	back.position = Vector2(-120, 18)
	back.pressed.connect(func(): if not _busy: Router.go("castle"))
	root.add_child(back)
	var dlg := Hud.DialogueBar.new()
	root.add_child(dlg)


func _process(delta: float) -> void:
	_t += delta
	for rid in islands:
		var open := _region_state(rid).begins_with("open")
		var n: Node3D = islands[rid]
		n.position.y = (0.18 + sin(_t * 1.6 + n.position.x) * 0.16) if open else sin(_t * 0.8 + n.position.x) * 0.05
	if _marker:
		_marker.position.y = 3.4 + sin(_t * 3.0) * 0.25
		_marker.rotation.y += delta * 1.4


func _unhandled_input(event: InputEvent) -> void:
	if _busy or Dialogue.blocking:
		return
	var tap: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
	if tap:
		var best := ""
		var bd := 170.0
		for rid in islands:
			var sp := cam.unproject_position((islands[rid] as Node3D).global_position + Vector3(0, 1.0, 0))
			var d := sp.distance_to(event.position)
			if d < bd:
				bd = d
				best = rid
		if best != "":
			_pick(best)
	elif event.is_action_pressed("move_right") or event.is_action_pressed("move_left"):
		_focus_i = (_focus_i + (1 if event.is_action_pressed("move_right") else -1) + _focus_ids.size()) % maxi(_focus_ids.size(), 1)
		Audio.sfx("ui_soft")
		flutter.hold_at((islands[_focus_ids[_focus_i]] as Node3D).global_position + Vector3(0, 2.4, 0))
	elif event.is_action_pressed("magic") or event.is_action_pressed("jump"):
		if _focus_ids.size() > 0:
			_pick(_focus_ids[_focus_i])
	elif event.is_action_pressed("home"):
		Router.go("castle")


func _pick(rid: String) -> void:
	var state := _region_state(rid)
	var n: Node3D = islands[rid]
	flutter.hold_at(n.global_position + Vector3(0, 2.4, 0))
	match state:
		"home":
			_travel(rid, "castle", {})
		"open_rescue":
			_travel(rid, "forest_rescue", {})
		"open_friendship":
			_travel(rid, "moonlit_forest", {})
		"resting":
			Audio.sfx("ui_soft", 0.0, 0.8)
			Dialogue.play_async("hint_castle_stable")
			Fx.sparkle_burst(self, n.global_position + Vector3(0, 1.5, 0), Color(1, 0.9, 1), 14, 2.0, 0.3, 0.9)
		_:
			Audio.sfx("ui_soft", 0.0, 0.7)
			Dialogue.play_async("map_locked_bark")
			Fx.sparkle_burst(self, n.global_position + Vector3(0, 1.8, 0.6), Color(0.8, 0.85, 1), 14, 2.0, 0.3, 0.9)


func _travel(rid: String, scene: String, params: Dictionary) -> void:
	_busy = true
	Audio.sfx("magic_flourish")
	var n: Node3D = islands[rid]
	Fx.sparkle_burst(self, n.global_position + Vector3(0, 1.5, 0), Color(1, 0.9, 0.6), 60, 5.0, 0.4, 1.4)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(cam, "global_position", n.global_position + Vector3(0, 6.5, 7.0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(0.9).timeout
	Router.go(scene, params, "clouds")
