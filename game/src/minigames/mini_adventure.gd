class_name MiniAdventure
extends Node3D
## Base class for Mode 4 activities (2-5 minutes, replayable, no losing). A mini adventure is declared in
## data/minigames/<id>.json (which characters it features, music, intro/outro dialogue, reward) and only has to
## implement _setup() / _tick(). Rescued friends appear in it because the def lists `requires_characters`.

var def: Dictionary = {}
var mini_id := ""
var cam: FollowCam
var ui: CanvasLayer
var ui_root: Control
var collected := 0
var running := false
var _results: Control


func _ready() -> void:
	mini_id = String(Router.params.get("scene_id", ""))
	def = Content.minigame(mini_id)
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ui_root)
	var home := MagicButton.new("castle", Vector2(84, 84))
	home.set_colors(UiKit.LILAC, UiKit.LILAC_D)
	home.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	home.position = Vector2(-106, 18)
	home.pressed.connect(func(): Router.go("castle"))
	ui_root.add_child(home)
	_setup()
	Audio.play_music(String(def.get("music", "")), 1.2)


func _setup() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	if running:
		_tick(delta)


## Shows the celebration + stars earned + "again / home". `score_ratio` 0..1 decides how many Magic Stars (max from def).
func finish(score_ratio: float) -> void:
	running = false
	var max_stars := int(def.get("reward", {}).get("max_magic_stars", 3))
	var earned_now := clampi(int(floor(score_ratio * (max_stars + 0.999))), 0, max_stars)
	var rec: Dictionary = GameState.data.minigames.get(mini_id, {})
	var already := int(rec.get("awarded", 0))
	var new_stars := maxi(0, earned_now - already)
	GameState.record_minigame(mini_id, collected)
	GameState.data.minigames[mini_id]["awarded"] = maxi(already, earned_now)
	GameState.save()
	_show_results(earned_now, new_stars)


func _show_results(earned: int, new_stars: int) -> void:
	_results = Control.new()
	_results.set_anchors_preset(Control.PRESET_FULL_RECT)
	_results.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(_results)
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", UiKit.card_style(44))
	UiKit.center(panel, Vector2(640, 380))
	panel.modulate.a = 0.0
	_results.add_child(panel)
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.5)
	var max_stars := int(def.get("reward", {}).get("max_magic_stars", 3))
	var row := Control.new()
	row.size = Vector2(640, 150)
	row.position = Vector2(0, 40)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	for i in max_stars:
		var st := StarSlot.new(i < earned)
		st.position = Vector2(320 - max_stars * 90 + i * 180 + 25, 0)
		st.size = Vector2(130, 130)
		row.add_child(st)
		if i < earned:
			st.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_interval(0.5 + i * 0.5)
			tw.tween_property(st, "modulate:a", 1.0, 0.2)
			tw.tween_callback(func(): Audio.sfx("star_get", -2.0, 1.0 + i * 0.15))
	var again := MagicButton.new("rainbow", Vector2(150, 150))
	again.set_colors(Color("#ffd0f0"), UiKit.PINK_D)
	again.position = Vector2(140, 200)
	again.attention = true
	again.pressed.connect(func(): Router.go(mini_id, {}, "clouds"))
	panel.add_child(again)
	var home := MagicButton.new("castle", Vector2(150, 150))
	home.set_colors(UiKit.LILAC, UiKit.LILAC_D)
	home.position = Vector2(350, 200)
	home.pressed.connect(func(): Router.go("castle"))
	panel.add_child(home)
	if new_stars > 0:
		await get_tree().create_timer(0.5 + earned * 0.5).timeout
		GameState.add_stars(new_stars, Vector3.ZERO, "mini_adventure")


class StarSlot extends Control:
	var filled := false

	func _init(f: bool) -> void:
		filled = f
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if filled:
			IconArt.draw(self, "star", size * 0.5, 58)
		else:
			draw_arc(size * 0.5, 44, 0, TAU, 32, Color(0.75, 0.68, 0.85, 0.7), 6, true)
