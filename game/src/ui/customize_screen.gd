extends Node3D
## Princess creator: big picture cards, no reading, instant 3D preview with a happy reaction to every choice.

var princess: PrincessRig
var appearance: Dictionary = {}
var category := "skin"
var cam: Camera3D
var ui: CanvasLayer
var _grid: GridContainer
var _tabs: Dictionary = {}
var _cards: Array[OptionCard] = []
var _panel: Panel
var _t := 0.0


func _ready() -> void:
	appearance = GameState.appearance().duplicate(true)
	EnvKit.apply(self, "rainbow_sky", {"fog_density": 0.002})
	_build_stage()
	_build_ui()
	_select_category("skin")
	Audio.play_music("customize_theme", 1.2)
	Dialogue.play_async("customize_intro")


func _build_stage() -> void:
	# a pastel dais with sparkles under a rainbow
	var dais := Build.cyl(self, 1.8, 2.0, 0.3, Vector3(-1.8, -0.15, 0), Mat.toon_grad(Color("#f0d8ff"), Color("#fff0ff"), -0.15, 0.15, {"outline": 0.01, "rim_amount": 0.4, "gradient_amount": 1.0, "glitter": 0.3}), 40)
	Build.torus(self, 1.7, 1.95, Vector3(-1.8, 0.02, 0), Mat.glowing(Mat.GOLD, 0.6, {"outline": false}), Vector3.ZERO, 40)
	var floor := Build.cyl(self, 30.0, 30.0, 0.2, Vector3(0, -0.4, -8), Mat.toon(Color("#cfc0ff"), {"outline": false, "rim_amount": 0.0}), 40)
	var arc := MeshInstance3D.new()
	arc.mesh = Build.arc_ribbon(7.0, 1.8, 180.0, 64)
	arc.material_override = Mat.rainbow_material()
	arc.position = Vector3(-1.8, 0.0, -6.0)
	add_child(arc)
	for i in 14:
		var a := float(i) / 14.0 * TAU
		var cl := Build.sphere(self, 0.7 + (i % 3) * 0.25, Vector3(-1.8 + cos(a) * 11.0, 0.3 + sin(a * 2.0) * 0.3, -12.0 + sin(a) * 4.0), Mat.toon(Color("#f4eeff"), {"outline": false, "rim_amount": 0.2, "shade_tint": Color(0.75, 0.7, 1.0)}), Vector3(1.8, 0.7, 1.0), 10)
	Fx.pollen(self, Vector3(-1.8, 2.0, 0), Vector3(4, 2.5, 2), 60, Color(1, 0.95, 0.7, 0.9))
	Fx.aura(self, Color(1, 0.9, 0.7), 24, 1.2).position = Vector3(-1.8, 1.0, 0)
	princess = PrincessRig.new(appearance)
	add_child(princess)
	princess.position = Vector3(-1.8, 0, 0)
	princess.face_camera_amount = 1.0
	princess.set_emotion("happy")
	cam = Camera3D.new()
	cam.fov = 34.0
	add_child(cam)
	cam.current = true
	cam.global_position = Vector3(-0.2, 1.35, 5.6)
	cam.look_at(Vector3(-0.2, 1.0, 0.0), Vector3.UP)
	await get_tree().create_timer(0.6).timeout
	princess.play("wave")


func _process(delta: float) -> void:
	_t += delta
	princess.yaw_offset = sin(_t * 0.6) * 0.18


# =============================================================================
func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	# option panel
	_panel = Panel.new()
	_panel.add_theme_stylebox_override("panel", UiKit.card_style(36))
	_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_panel.anchor_left = 1.0
	_panel.offset_left = -640
	_panel.offset_right = -24
	_panel.offset_top = 28
	_panel.offset_bottom = -170
	root.add_child(_panel)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	_grid.position = Vector2(18, 18)
	_panel.add_child(_grid)
	# category tabs across the bottom
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 12)
	tabs.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tabs.anchor_left = 1.0
	tabs.offset_left = -1100
	tabs.offset_right = -24
	tabs.offset_top = -150
	tabs.offset_bottom = -20
	tabs.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(tabs)
	for c in Content.customization.categories:
		var b := MagicButton.new(String(c.icon), Vector2(94, 94))
		b.set_colors(Color("#ffd0ec"), UiKit.PINK_D)
		b.icon_scale = 0.5
		b.pressed.connect(_select_category.bind(String(c.id)))
		tabs.add_child(b)
		_tabs[c.id] = b
	# shuffle + done
	var shuffle := MagicButton.new("shuffle", Vector2(96, 96))
	shuffle.set_colors(Color("#e0d0ff"), UiKit.LILAC_D)
	shuffle.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	shuffle.position = Vector2(30, -130)
	shuffle.pressed.connect(_shuffle)
	root.add_child(shuffle)
	var done := MagicButton.new("check", Vector2(150, 150))
	done.set_colors(Color("#9af0c8"), UiKit.MINT_D)
	done.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	done.position = Vector2(300, 190)
	done.attention = true
	done.sfx_id = "ui_magic"
	done.pressed.connect(_done)
	root.add_child(done)
	var dlg := Hud.DialogueBar.new()
	root.add_child(dlg)


func _select_category(id: String) -> void:
	category = id
	for k in _tabs:
		_tabs[k].scale = Vector2.ONE * (1.15 if k == id else 1.0)
		_tabs[k].position.y = -8.0 if k == id else 0.0
	for c in _cards:
		c.queue_free()
	_cards.clear()
	var options: Array = Content.customization.options.get(id, [])
	for o in options:
		var card := OptionCard.new(id, o, appearance)
		card.selected = appearance.get(id, "") == o.id
		card.chosen.connect(_on_choose.bind(id, String(o.id)))
		_grid.add_child(card)
		_cards.append(card)
	Audio.sfx("page_flip", -6.0)


func _on_choose(cat: String, option_id: String) -> void:
	appearance[cat] = option_id
	princess.apply_appearance(appearance)
	for c in _cards:
		c.selected = c.option.id == option_id
		c.queue_redraw()
	# every choice gets a delighted reaction
	Fx.sparkle_burst(self, princess.global_position + Vector3(0, 1.0, 0.3), Color(1, 0.9, 0.7), 26, 3.0, 0.3, 1.0)
	match cat:
		"dress", "cape": princess.play("spin")
		"crown", "accessory": princess.play("wonder")
		"hair_style", "hair_color": princess.play("giggle")
		_: princess.play("happy")
	princess.set_emotion("joyful")
	Audio.sfx("sparkle_pick", -2.0, 1.0, 0.1)
	get_tree().create_timer(1.4).timeout.connect(func(): if is_instance_valid(princess): princess.set_emotion("happy"))


func _shuffle() -> void:
	for c in Content.customization.options:
		var opts: Array = Content.customization.options[c]
		appearance[c] = opts[randi() % opts.size()].id
	princess.apply_appearance(appearance)
	princess.play("spin")
	Fx.sparkle_burst(self, princess.global_position + Vector3(0, 1.0, 0.3), Color(1, 0.9, 0.7), 50, 4.0, 0.34, 1.2)
	Audio.sfx("magic_flourish")
	_select_category(category)


func _done() -> void:
	GameState.set_appearance(appearance)
	Audio.sfx("magic_flourish")
	princess.play("celebrate")
	Fx.star_shower(self, Vector3(-1.8, 4.0, 0), 50)
	await Dialogue.play("customize_done")
	Router.go("castle", {}, "page")


# =============================================================================
class OptionCard extends Control:
	signal chosen
	var category := ""
	var option: Dictionary = {}
	var app: Dictionary = {}
	var selected := false
	var _hover := false

	func _init(cat: String, opt: Dictionary, appearance: Dictionary) -> void:
		category = cat
		option = opt
		app = appearance
		custom_minimum_size = Vector2(134, 134)
		size = Vector2(134, 134)
		focus_mode = Control.FOCUS_ALL
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		var press: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed) or event.is_action_pressed("ui_accept")
		if press:
			chosen.emit()
			var tw := create_tween()
			pivot_offset = size * 0.5
			tw.tween_property(self, "scale", Vector2.ONE * 0.92, 0.06)
			tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			accept_event()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hover = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hover = false
			queue_redraw()
		elif what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT:
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var border := Color("#ffd9a0")
		var fill := Color("#fff8ec")
		if selected:
			border = UiKit.PINK
			fill = Color("#ffe6f3")
		elif _hover or has_focus():
			border = Color("#ffc0dd")
		draw_style_box(UiKit.box(fill, 30, border, 6 if selected else 4, 6 if selected else 3), r)
		var c := size * 0.5
		var s := 46.0
		match category:
			"skin": _skin(c, s)
			"hair_color": _color_dot(c, s, Color(option.color))
			"boots": _boot_icon(c, s, Color(option.color))
			"face": _face_eyes(c, s)
			"hair_style": _hair_thumb(c, s)
			"dress": _dress_thumb(c, s)
			"crown": _crown_thumb(c, s)
			"cape": _cape_thumb(c, s)
			"accessory": _acc_thumb(c, s)
		if selected:
			IconArt.draw(self, "check", Vector2(size.x - 24, 24), 13)

	func _skin(c: Vector2, s: float) -> void:
		var col := Color(option.color)
		draw_circle(c, s, col.darkened(0.25))
		draw_circle(c, s - 4, col)
		draw_circle(c + Vector2(-s * 0.3, -s * 0.3), s * 0.16, col.lightened(0.35))
		draw_circle(c + Vector2(-s * 0.3, s * 0.05), s * 0.1, Color("#3a1f4a"))
		draw_circle(c + Vector2(s * 0.3, s * 0.05), s * 0.1, Color("#3a1f4a"))
		draw_arc(c + Vector2(0, s * 0.12), s * 0.3, deg_to_rad(30), deg_to_rad(150), 10, Color("#c04a68"), 4, true)

	func _color_dot(c: Vector2, s: float, col: Color) -> void:
		draw_circle(c, s, col.darkened(0.3))
		draw_circle(c, s - 5, col)
		draw_arc(c, s * 0.6, deg_to_rad(200), deg_to_rad(290), 10, col.lightened(0.5), 5, true)

	func _boot_icon(c: Vector2, s: float, col: Color) -> void:
		var p := PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.9), c + Vector2(s * 0.2, -s * 0.9), c + Vector2(s * 0.2, s * 0.1), c + Vector2(s * 0.95, s * 0.35), c + Vector2(s * 0.95, s * 0.8), c + Vector2(-s * 0.4, s * 0.8)])
		draw_colored_polygon(p, col)
		var q := p.duplicate()
		q.append(p[0])
		draw_polyline(q, col.darkened(0.3), 3, true)
		draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.9), Vector2(s * 0.6, s * 0.22)), Color("#fff4e0"))

	func _face_eyes(c: Vector2, s: float) -> void:
		draw_circle(c, s * 0.95, Color("#ffd2b0"))
		for sx in [-1.0, 1.0]:
			var e := c + Vector2(sx * s * 0.36, -s * 0.05)
			draw_circle(e, s * 0.28, Color("#2a1638"))
			draw_circle(e, s * 0.24, Color(option.eye))
			draw_circle(e, s * 0.12, Color("#1c0d28"))
			draw_circle(e + Vector2(-s * 0.08, -s * 0.09), s * 0.08, Color.WHITE)
			if option.get("freckles", false):
				for k in 3:
					draw_circle(e + Vector2(sx * (k * s * 0.08 - s * 0.05), s * 0.45 + (k % 2) * s * 0.05), s * 0.028, Color("#b0705a"))
		draw_arc(c + Vector2(0, s * 0.3), s * 0.28, deg_to_rad(30), deg_to_rad(150), 10, Color("#c04a68"), 4, true)

	func _hair_thumb(c: Vector2, s: float) -> void:
		var hc := Color(Content.customization.options.hair_color[0].color)
		for o in Content.customization.options.hair_color:
			if o.id == app.get("hair_color", "chestnut"):
				hc = Color(o.color)
		var skin := Color("#ffd2b0")
		var id: String = option.id
		match id:
			"long":
				draw_rect(Rect2(c + Vector2(-s * 0.85, -s * 0.2), Vector2(s * 1.7, s * 1.0)), hc)
				draw_circle(c + Vector2(0, -s * 0.15), s * 0.85, hc)
			"pigtails":
				draw_circle(c + Vector2(-s * 0.95, s * 0.05), s * 0.32, hc)
				draw_circle(c + Vector2(s * 0.95, s * 0.05), s * 0.32, hc)
				draw_line(c + Vector2(-s * 0.95, s * 0.2), c + Vector2(-s * 0.95, s * 0.85), hc, s * 0.34, true)
				draw_line(c + Vector2(s * 0.95, s * 0.2), c + Vector2(s * 0.95, s * 0.85), hc, s * 0.34, true)
				draw_circle(c + Vector2(0, -s * 0.15), s * 0.8, hc)
			"bun":
				draw_circle(c + Vector2(0, -s * 0.95), s * 0.4, hc)
				draw_circle(c + Vector2(0, -s * 0.1), s * 0.85, hc)
			"puffs":
				draw_circle(c + Vector2(-s * 0.6, -s * 0.85), s * 0.45, hc)
				draw_circle(c + Vector2(s * 0.6, -s * 0.85), s * 0.45, hc)
				draw_circle(c + Vector2(0, -s * 0.1), s * 0.85, hc)
			"curls":
				for k in 11:
					var a := float(k) / 11.0 * TAU
					draw_circle(c + Vector2(cos(a), sin(a)) * s * 0.85 + Vector2(0, -s * 0.1), s * 0.3, hc)
				draw_circle(c + Vector2(0, -s * 0.1), s * 0.8, hc)
			"braid":
				draw_circle(c + Vector2(0, -s * 0.15), s * 0.85, hc)
				for k in 5:
					draw_circle(c + Vector2(s * 0.75 + (k % 2) * 4, s * 0.1 + k * s * 0.22), s * 0.18, hc)
		draw_circle(c + Vector2(0, s * 0.15), s * 0.6, skin)
		draw_circle(c + Vector2(-s * 0.22, s * 0.12), s * 0.07, Color("#3a1f4a"))
		draw_circle(c + Vector2(s * 0.22, s * 0.12), s * 0.07, Color("#3a1f4a"))
		draw_arc(c + Vector2(0, s * 0.3), s * 0.2, deg_to_rad(30), deg_to_rad(150), 8, Color("#c04a68"), 3, true)

	func _dress_thumb(c: Vector2, s: float) -> void:
		var c1 := Color(option.c1)
		var c2 := Color(option.c2)
		var t: String = option.type
		match t:
			"gown":
				var p := PackedVector2Array([c + Vector2(-s * 0.32, -s), c + Vector2(s * 0.32, -s), c + Vector2(s * 0.26, -s * 0.15), c + Vector2(s * 1.0, s * 0.9), c + Vector2(-s * 1.0, s * 0.9), c + Vector2(-s * 0.26, -s * 0.15)])
				draw_colored_polygon(p, c1)
				draw_line(c + Vector2(-s * 1.0, s * 0.86), c + Vector2(s * 1.0, s * 0.86), c2, s * 0.2, true)
				draw_line(c + Vector2(-s * 0.28, -s * 0.15), c + Vector2(s * 0.28, -s * 0.15), c2, s * 0.14, true)
			"tutu":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.32, -s), c + Vector2(s * 0.32, -s), c + Vector2(s * 0.28, -s * 0.1), c + Vector2(-s * 0.28, -s * 0.1)]), c1)
				for k in 3:
					draw_style_box(UiKit.box(c2 if k % 2 == 0 else c1.lerp(c2, 0.5), 16), Rect2(c + Vector2(-s * (0.55 + k * 0.22), -s * 0.1 + k * s * 0.28), Vector2(s * (1.1 + k * 0.44), s * 0.36)))
			"pants":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.55, -s), c + Vector2(s * 0.55, -s), c + Vector2(s * 0.65, -s * 0.1), c + Vector2(-s * 0.65, -s * 0.1)]), c1)
				draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.1), Vector2(s * 0.5, s * 1.0)), c2)
				draw_rect(Rect2(c + Vector2(s * 0.05, -s * 0.1), Vector2(s * 0.5, s * 1.0)), c2)
				draw_line(c + Vector2(-s * 0.65, -s * 0.1), c + Vector2(s * 0.65, -s * 0.1), Color("#8a5a3c"), s * 0.14, true)

	func _crown_thumb(c: Vector2, s: float) -> void:
		var gold := Color("#ffc94d")
		match String(option.id):
			"tiara":
				draw_arc(c + Vector2(0, s * 0.5), s * 0.9, deg_to_rad(205), deg_to_rad(335), 20, gold, s * 0.16, true)
				for k in 5:
					var a := deg_to_rad(215.0 + k * 27.5)
					var p := c + Vector2(0, s * 0.5) + Vector2(cos(a), sin(a)) * s * 0.9
					draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.08, 0), p + Vector2(0, -s * (0.25 if k != 2 else 0.42)), p + Vector2(s * 0.08, 0)]), gold)
				draw_circle(c + Vector2(0, -s * 0.15), s * 0.11, Color("#ff7fb6"))
			"crown":
				IconArt.draw(self, "crown", c, s * 0.9)
			"flowers":
				for k in 6:
					var a := float(k) / 6.0 * TAU
					var p := c + Vector2(cos(a), sin(a)) * s * 0.65
					for j in 5:
						var pa := float(j) / 5.0 * TAU
						draw_circle(p + Vector2(cos(pa), sin(pa)) * s * 0.12, s * 0.1, [Color("#ff7fb6"), Color("#ffffff"), Color("#ffe066")][k % 3])
					draw_circle(p, s * 0.07, Color("#ffd85a"))
			"star_circlet":
				draw_arc(c + Vector2(0, s * 0.6), s * 0.9, deg_to_rad(205), deg_to_rad(335), 20, gold, s * 0.12, true)
				IconArt.draw(self, "star", c + Vector2(0, -s * 0.15), s * 0.55)
			"moon_tiara":
				draw_arc(c + Vector2(0, s * 0.6), s * 0.9, deg_to_rad(205), deg_to_rad(335), 20, gold, s * 0.12, true)
				IconArt.draw(self, "moon", c + Vector2(0, -s * 0.1), s * 0.55)

	func _cape_thumb(c: Vector2, s: float) -> void:
		if option.id == "none":
			IconArt.draw(self, "close", c, s * 0.7)
			return
		var col := Color(option.color)
		var p := PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.9), c + Vector2(s * 0.4, -s * 0.9), c + Vector2(s * 0.95, s * 0.6), c + Vector2(s * 0.4, s * 0.85), c + Vector2(0, s * 0.7), c + Vector2(-s * 0.4, s * 0.85), c + Vector2(-s * 0.95, s * 0.6)])
		draw_colored_polygon(p, col)
		var q := p.duplicate()
		q.append(p[0])
		draw_polyline(q, col.darkened(0.3), 3, true)
		draw_circle(c + Vector2(0, -s * 0.8), s * 0.12, Color("#ffc94d"))

	func _acc_thumb(c: Vector2, s: float) -> void:
		match String(option.id):
			"wand_star": IconArt.draw(self, "wand", c, s * 0.95)
			"wand_heart":
				draw_line(c + Vector2(-s * 0.7, s * 0.7), c + Vector2(s * 0.15, -s * 0.15), Color("#fff4e0"), s * 0.18, true)
				IconArt.draw(self, "heart", c + Vector2(s * 0.32, -s * 0.32), s * 0.5)
			"wings":
				for sx in [-1.0, 1.0]:
					draw_circle(c + Vector2(sx * s * 0.5, -s * 0.25), s * 0.5, Color("#bfe6ff"))
					draw_circle(c + Vector2(sx * s * 0.42, s * 0.4), s * 0.32, Color("#e0d0ff"))
			"butterfly": IconArt.draw(self, "butterfly", c, s * 0.85)
			"necklace":
				draw_arc(c + Vector2(0, -s * 0.5), s * 0.85, deg_to_rad(20), deg_to_rad(160), 20, Color("#ffc94d"), 4, true)
				IconArt.draw(self, "star", c + Vector2(0, s * 0.42), s * 0.36)
