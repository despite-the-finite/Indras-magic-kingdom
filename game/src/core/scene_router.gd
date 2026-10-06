extends Node
## Scene routing with storybook transitions (clouds for travel, page-turn for menus).
## Scenes are Node scripts registered by id; each receives `Router.params` on _ready.

const SCENES := {
	"menu":           "res://src/ui/main_menu.gd",
	"customize":      "res://src/ui/customize_screen.gd",
	"castle":         "res://src/world/castle_hub.gd",
	"castle_inside":  "res://src/world/castle_inside.gd",
	"map":            "res://src/world/world_map.gd",
	"forest_rescue":  "res://src/world/forest_level.gd",
	"moonlit_forest": "res://src/world/moonlit_level.gd",
	"stable":         "res://src/world/stable_scene.gd",
	"rainbow_ride":   "res://src/minigames/rainbow_ride.gd",
	"dev_rigs":       "res://src/dev/rig_viewer.gd",
}

var params: Dictionary = {}
var current_id := ""
var current: Node = null
var busy := false

var _layer: CanvasLayer
var _rect: ColorRect
var _mat: ShaderMaterial


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/transition.gdshader")
	_mat.set_shader_parameter("progress", 0.0)
	_rect.material = _mat
	_rect.visible = false
	_layer.add_child(_rect)


func go(scene_id: String, p: Dictionary = {}, kind: String = "clouds") -> void:
	if busy:
		return
	if not SCENES.has(scene_id):
		push_error("[Router] unknown scene " + scene_id)
		return
	busy = true
	if current != null:
		await _cover(kind)
	params = p
	params["scene_id"] = scene_id
	_swap(scene_id)
	await get_tree().process_frame
	await get_tree().process_frame
	await _reveal(kind)
	busy = false


## Immediate switch without transition (used at boot and by dev tools).
func go_now(scene_id: String, p: Dictionary = {}) -> void:
	params = p
	params["scene_id"] = scene_id
	_swap(scene_id)


func _swap(scene_id: String) -> void:
	Dialogue.blocking = false
	Hints.stop()
	Quests.stop()
	if current and is_instance_valid(current):
		current.queue_free()
	var script: Script = load(SCENES[scene_id])
	var n: Node = script.new()
	n.name = scene_id.capitalize().replace(" ", "")
	current = n
	current_id = scene_id
	get_tree().root.add_child(n)
	get_tree().current_scene = n
	Events.scene_changed.emit(scene_id)


func _cover(kind: String) -> void:
	_mat.set_shader_parameter("mode", 0 if kind == "clouds" else 1)
	_mat.set_shader_parameter("progress", 0.0)
	_rect.visible = true
	Audio.sfx("whoosh_soft" if kind == "clouds" else "page_turn")
	var tw := create_tween()
	tw.tween_method(func(v): _mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.85 if kind == "clouds" else 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func _reveal(kind: String) -> void:
	var tw := create_tween()
	tw.tween_method(func(v): _mat.set_shader_parameter("progress", v), 1.0, 0.0, 0.9 if kind == "clouds" else 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	_rect.visible = false
