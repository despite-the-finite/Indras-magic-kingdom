extends Node3D
## Title screen: a living storybook vista (castle on a hill, drifting light, the princess waving) and one huge Play button.
## A tiny gear in the corner opens the Parent Area behind a parent gate.

var cam: Camera3D
var princess: PrincessRig
var lumi: UnicornRig
var ui: CanvasLayer
var play_btn: MagicButton
var _t := 0.0
var _title: Control
var _parent_layer: Node


func _ready() -> void:
	var env := EnvKit.apply(self, "castle_day", {"cloud_cover": 0.7, "fog_density": 0.0025})
	_build_vista()
	_build_ui()
	Audio.play_music("title_theme", 1.5)
	Audio.set_ambience(["forest_birds"])
	if Router.params.has("parent"):
		_open_parent()
	else:
		# a non-reader needs to be *told* where to start
		await get_tree().create_timer(1.4).timeout
		if is_inside_tree() and _parent_layer == null:
			Dialogue.play_async("menu_intro")


func _build_vista() -> void:
	var terr := Terrain.build(self, [
		{"x0": -30.0, "x1": 30.0, "pts": [[-30, 1.2], [-14, 0.5], [-4, 0.0], [6, 0.0], [16, 0.4], [30, 1.6]]},
	], {"top_color": Color("#69b84c"), "top_color_far": Color("#2a8a5e"), "path_color": Color(0, 0, 0, 0)})
	ForestProps.backdrop(self, -30.0, 30.0, [Color("#a0aef0"), Color("#88b8e8"), Color("#7cc8b8")])
	var castle := CastleKit.castle(self, Vector3(12.0, 0.6, -78.0))
	castle.scale = Vector3.ONE * 1.6
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 12:
		var x := -22.0 + i * 4.0 + rng.randf_range(-1.0, 1.0)
		if absf(x - 2.0) < 6.0:
			continue
		ForestProps.tree(self, Vector3(x, terr.height_at(x) - 0.1, rng.randf_range(-12.0, -5.0)), rng.randf_range(5.0, 8.5), 1 if i % 3 == 0 else 0, i)
	for i in 10:
		ForestProps.giant_flower(self, Vector3(-14.0 + i * 3.0, terr.height_at(-14.0 + i * 3.0), rng.randf_range(-4.5, -2.0)), rng.randf_range(2.2, 4.0), [Mat.PINK, Color("#c9a0ff"), Mat.SUN][i % 3], false)
	ForestProps.scatter_grass(self, terr, -30.0, 30.0, 3.5, 3, Vector2(-7.0, 2.5), Color("#3fb05a"), Color("#a0e070"))
	ForestProps.scatter_flowers(self, terr, -30.0, 30.0, 1.6, 4)
	ForestProps.light_shafts(self, Vector3(0, 0, 0), 4, 18.0, Color(1, 0.95, 0.75, 0.15), 6)
	for i in 8:
		var b := Flutter.new()
		b.palette = [[Mat.PINK, Mat.LILAC, Mat.SUN], [Mat.SKY, Mat.MINT, Mat.PINK]][i % 2]
		b.speed = 1.6
		b.scale = Vector3.ONE * rng.randf_range(0.4, 0.6)
		add_child(b)
		b.global_position = Vector3(rng.randf_range(-8.0, 8.0), rng.randf_range(1.0, 3.0), rng.randf_range(-2.0, 2.0))
		b.hold_at(b.global_position)
		var tw := b.create_tween().set_loops()
		tw.tween_callback(func(): b.guide_pos = Vector3(rng.randf_range(-9.0, 9.0), rng.randf_range(0.8, 3.2), rng.randf_range(-2.0, 2.0)))
		tw.tween_interval(rng.randf_range(2.0, 3.5))
	Fx.fireflies(self, Vector3(0, 2, 0), Vector3(12, 2.5, 4), 30, Color(1, 0.95, 0.6))
	Fx.pollen(self, Vector3(0, 2.5, 0), Vector3(12, 3, 4), 40)
	# the star of the show
	princess = PrincessRig.new(GameState.appearance())
	add_child(princess)
	princess.position = Vector3(-1.9, terr.height_at(-1.9), 1.0)
	princess.face_camera_amount = 0.6
	princess.facing = 1.0
	lumi = UnicornRig.new("lumi")
	add_child(lumi)
	lumi.position = Vector3(1.4, terr.height_at(1.4), 0.4)
	lumi.facing = -1.0
	lumi.face_camera_amount = 0.6
	cam = Camera3D.new()
	cam.fov = 40.0
	add_child(cam)
	cam.current = true
	cam.global_position = Vector3(0, 1.7, 7.0)
	cam.look_at(Vector3(0.0, 2.0, 0.0), Vector3.UP)
	await get_tree().create_timer(0.8).timeout
	princess.set_emotion("happy")
	princess.play("wave")
	lumi.set_emotion("happy")
	lumi.play("happy")


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	_title = TitleLogo.new()
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.position = Vector2(-380, 20)
	_title.size = Vector2(760, 260)
	root.add_child(_title)
	play_btn = MagicButton.new("play", Vector2(210, 210))
	play_btn.set_colors(Color("#ffb0e0"), UiKit.PINK_D)
	play_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	play_btn.position = Vector2(-105, -250)
	play_btn.attention = true
	play_btn.icon_scale = 0.42
	play_btn.sfx_id = "ui_magic"
	play_btn.pressed.connect(_on_play)
	root.add_child(play_btn)
	play_btn.grab_focus()
	var gear := MagicButton.new("gear", Vector2(64, 64))
	gear.set_colors(Color("#d8ccf0"), Color("#9a86c8"))
	gear.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	gear.position = Vector2(-84, -84)
	gear.modulate.a = 0.75
	gear.pressed.connect(_open_parent)
	root.add_child(gear)


func _process(delta: float) -> void:
	_t += delta
	if cam:
		cam.global_position = Vector3(sin(_t * 0.25) * 0.5, 1.7 + sin(_t * 0.2) * 0.08, 7.0)
		cam.look_at(Vector3(0.0, 2.0, 0.0), Vector3.UP)


func _on_play() -> void:
	if GameState.data.get("created", false):
		Router.go("castle", {}, "page")
	else:
		Router.go("customize", {}, "page")


func _open_parent() -> void:
	if _parent_layer:
		return
	_parent_layer = ParentArea.new()
	_parent_layer.closed.connect(func(): _parent_layer = null)
	add_child(_parent_layer)


# ---------------------------------------------------------------------------
class TitleLogo extends Control:
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var f := UiKit.title_font()
		var bob := sin(_t * 1.5) * 4.0
		var cx := size.x * 0.5
		# crown above the logo
		IconArt.draw(self, "crown", Vector2(cx - 210, 52 + bob), 38)
		for i in 5:
			var a := _t * 1.4 + i * 1.3
			var p := Vector2(cx - 210 + cos(a) * 60, 52 + bob + sin(a * 1.3) * 30)
			IconArt.draw(self, "sparkle", p, 8 + 4.0 * sin(a * 2.0))
		# tagline ribbon behind the text (so it reads over any background)
		draw_style_box(UiKit.box(Color("#a860d8"), 20, Color("#ffd9a0"), 3, 6), Rect2(Vector2(cx - 230, 232 + bob), Vector2(460, 34)))
		# layered text: outline, shadow, gold face
		_text("Indra's", Vector2(cx, 130 + bob), 92, Color("#7a3fa8"), Color("#ffd86a"), Color("#ffb04a"))
		_text("Magic Kingdom", Vector2(cx, 224 + bob), 82, Color("#7a3fa8"), Color("#ffe6a0"), Color("#ffc94d"))
		# tagline ribbon
		var tag_w := UiKit.body_font().get_string_size("Kindness changes kingdoms", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string(UiKit.body_font(), Vector2(cx - tag_w * 0.5, 257 + bob), "Kindness changes kingdoms", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#fff4e0"))

	func _text(s: String, at: Vector2, sz: int, outline: Color, top: Color, bottom: Color) -> void:
		var f := UiKit.title_font()
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		var p := Vector2(at.x - w * 0.5, at.y)
		draw_string_outline(f, p + Vector2(0, 6), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 26, Color(0.25, 0.1, 0.35, 0.35))
		draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 22, outline)
		draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, bottom)
		draw_string(f, p + Vector2(0, -sz * 0.045), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, top)
