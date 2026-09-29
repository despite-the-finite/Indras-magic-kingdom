class_name LevelBase
extends Node3D
## Shared plumbing for every side-scrolling place: environment, camera, player, companion, HUD, Flutter,
## hint responses (glow / butterfly / trail), zones, cinematics and level exits.
## Subclasses override _configure(), _build_world(), and hook quest events.

var scene_id := ""
var quest_id := ""
var preset := "day_forest"
var env: Dictionary = {}
var terrain: Terrain
var player: Player
var cam: FollowCam
var hud: Hud
var flutter: Flutter
var magic: MagicSystem
var companion: Companion
var spawn := Vector3(2, 0.2, 0)
var min_x := -2.0
var max_x := 100.0
var kill_y := -8.0
var with_companion := false
var zones: Array[Dictionary] = []
var music_cue := "forest_explore"
var ambience: Array = ["forest_birds", "forest_wind"]
var ambient_follow: Node3D
var _trail_active := false


# ---- to override -----------------------------------------------------------------
func _configure() -> void:
	pass


func _build_world() -> void:
	pass


func _after_ready() -> void:
	pass


# ---------------------------------------------------------------------------------
func _ready() -> void:
	scene_id = String(Router.params.get("scene_id", ""))
	_configure()
	if Router.params.has("spawn_x"):
		spawn.x = float(Router.params.spawn_x)
	env = EnvKit.apply(self, preset, _env_overrides())
	_build_world()
	_spawn_actors()
	_connect_hints()
	Audio.play_music(music_cue, 2.0)
	Audio.set_ambience(ambience)
	hud.home_requested.connect(func(): Router.go("castle"))
	hud.map_requested.connect(func(): Router.go("map"))
	_after_ready()


func _env_overrides() -> Dictionary:
	return {}


func ground_y(x: float) -> float:
	return terrain.height_at(x) if terrain else 0.0


func _spawn_actors() -> void:
	cam = FollowCam.new()
	cam.min_x = min_x
	cam.max_x = max_x
	add_child(cam)
	player = Player.new()
	player.kill_y = kill_y
	add_child(player)
	player.global_position = spawn
	player.safe_pos = spawn
	player.cam = cam
	cam.target = player
	magic = MagicSystem.new()
	magic.level = self
	add_child(magic)
	player.magic = magic
	flutter = Flutter.new()
	add_child(flutter)
	flutter.global_position = spawn + Vector3(-2, 3, 1)
	flutter.follow(player)
	player.flutter = flutter
	if with_companion and GameState.is_at_castle("lumi"):
		companion = Companion.new()
		companion.character_id = "lumi"
		companion.player = player
		companion.kill_y = kill_y
		add_child(companion)
		companion.global_position = spawn + Vector3(-2.2, 0.2, 0)
		magic.companion = companion
	hud = Hud.new()
	hud.player = player
	hud.cam = cam
	add_child(hud)
	cam.snap_to_target()
	# ambient sparkle that follows the child
	ambient_follow = Node3D.new()
	add_child(ambient_follow)
	Fx.fireflies(ambient_follow, Vector3(0, 1.6, -1.0), Vector3(14, 2.2, 5), 34, Color(1, 0.95, 0.55))
	Fx.pollen(ambient_follow, Vector3(0, 2.0, 0.0), Vector3(12, 3.0, 5), 36)


func _process(_delta: float) -> void:
	if player == null:
		return
	ambient_follow.global_position = Vector3(cam.global_position.x, 0, 0)
	# zones
	for z in zones:
		if not z.fired and player.global_position.x >= z.x0 and player.global_position.x <= z.x1:
			z.fired = true
			Events.zone_entered.emit(z.id)
	_level_process()


func _level_process() -> void:
	pass


## A discovery zone: quests listen for "zone:<id>". Also registers a hint target so Flutter can lead there.
func add_zone(id: String, x0: float, x1: float) -> void:
	zones.append({"id": id, "x0": x0, "x1": x1, "fired": false})
	var marker := Node3D.new()
	marker.position = Vector3((x0 + x1) * 0.5, ground_y((x0 + x1) * 0.5), 0)
	add_child(marker)
	Hints.register_target(id, marker)


# ---- hints: L2 glow (target does it), L2 look, L3 Flutter, L4 trail --------------------
func _connect_hints() -> void:
	Events.hint_level_changed.connect(_on_hint_level)


func _on_hint_level(level: int, target_id: String) -> void:
	var node := Hints.target_node()
	match level:
		0:
			_trail_active = false
			if flutter and player:
				flutter.follow(player)
		2:
			if node and player:
				player.rig.look_at_world(node.global_position + Vector3(0, 1.0, 0))
				if not player.controls_locked():
					player.rig.play("curious")
		3:
			if node and flutter:
				flutter.guide_to(node.global_position)
				Audio.sfx("chime_soft")
		4:
			if node:
				_show_trail(node.global_position)


func _show_trail(target_pos: Vector3) -> void:
	if _trail_active and false:
		return
	_trail_active = true
	var from := player.global_position + Vector3(0, 0.3, 0)
	var steps := 16
	var col := Color(1, 0.85, 0.95)
	for i in steps:
		var t := float(i + 1) / steps
		var p := from.lerp(target_pos, t)
		p.y = lerpf(from.y, target_pos.y, t) + 0.35 + sin(t * PI) * 0.4
		var delay := 0.05 * i
		get_tree().create_timer(delay).timeout.connect(func():
			if is_instance_valid(self):
				Fx.sparkle_burst(self, p, col, 5, 0.6, 0.3, 1.0))
	Audio.sfx("chime_trail")


# ---- helpers ----------------------------------------------------------------------
func earn_stars(amount: int, world_pos: Vector3, reason: String) -> void:
	GameState.add_stars(amount, world_pos, reason)


func next_scene(id: String, params: Dictionary = {}, kind: String = "clouds") -> void:
	Router.go(id, params, kind)


func look_wide_intro(center: Vector3, wide_offset: Vector3 = Vector3(6, 5.5, 14), glide: float = 3.2) -> void:
	## opening shot: high & wide, then settles into follow cam
	var start := center + wide_offset
	await cam.cine_to(start, center + Vector3(6, 1.5, 0), 0.01)
	await get_tree().create_timer(0.4).timeout
	cam.cine_release(glide)


func spawn_big_star(pos: Vector3) -> Node3D:
	var n := Build.pivot(self, pos)
	var mi := MeshInstance3D.new()
	mi.mesh = Build.star_mesh(0.5, 0.22, 0.16)
	mi.material_override = Mat.glowing(Mat.SUN, 2.4, {"outline": 0.01, "glitter": 0.5})
	n.add_child(mi)
	Fx.glow_sprite(n, Vector3.ZERO, Color(1, 0.9, 0.5, 0.7), 3.2)
	Fx.aura(n, Color(1, 0.95, 0.6), 24, 0.7)
	var tw := n.create_tween().set_loops()      # bound to the star so it dies with it
	tw.tween_property(mi, "rotation:y", TAU, 2.5).from(0.0)
	return n
