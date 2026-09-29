class_name Interactable
extends Node3D
## Anything the princess can touch, push, or use magic on. Data-driven by id: quests listen for
## "interact:<id>" / "power:<power>:<id>" events, so levels never hard-code story flow.
##
##   kind  "touch"  triggers automatically when she walks close (hoofprints, zones of discovery)
##         "press"  she reaches for it (push a branch, pick a flower)
##         "magic"  needs a princess power: flower | animals | starlight | rainbow
##                  or a companion ability such as "rainbow_bridge" (Lumi's horn)
##         "coop"   princess + companion together (power name, e.g. "coop_shine")

static var all: Array[Interactable] = []

signal activated(power: String)

var id := ""
var kind := "touch"
var power := ""
var radius := 1.8
var one_shot := true
var enabled := true
var used := false
var requires_step := ""          # quest step id that must be reached before this is usable
var press_anim := "push"
var icon := ""                   # optional prompt icon override (e.g. "map", "horseshoe")
var fx_height := 0.8
var halo_height := 1.2
var aura_color := Color(1, 1, 1)
var show_aura := true
var hint_level := 0

var _halo: MeshInstance3D
var _aura: GPUParticles3D
var _t := 0.0


static func make(parent: Node, p_id: String, p_kind: String, p_power: String, pos: Vector3, p_radius: float = 1.8) -> Interactable:
	var i := Interactable.new()
	i.id = p_id
	i.kind = p_kind
	i.power = p_power
	i.radius = p_radius
	i.position = pos
	parent.add_child(i)
	return i


static func power_color(p: String) -> Color:
	match p:
		"flower": return Color("#ff8fbf")
		"animals": return Color("#ffb56a")
		"starlight", "coop_shine": return Color("#ffe27a")
		"rainbow", "rainbow_bridge": return Color("#b58cf2")
		_: return Color("#ffffff")


func _ready() -> void:
	all.append(self)
	name = "I_" + id
	Hints.register_target(id, self)
	Events.hint_level_changed.connect(_on_hint_level)
	aura_color = power_color(power) if kind != "touch" and kind != "press" else Color(1, 0.95, 0.8)
	_halo = Fx.glow_sprite(self, Vector3(0, halo_height, 0), Color(1, 0.95, 0.6, 0.0), 1.6, FxTex.star4())
	if show_aura and kind != "touch":
		_aura = Fx.aura(self, aura_color, 8, 0.45)
		_aura.position = Vector3(0, fx_height, 0)


func _exit_tree() -> void:
	all.erase(self)
	Hints.unregister_target(id, self)


func is_available() -> bool:
	if not enabled or (used and one_shot):
		return false
	if requires_step != "" and Quests.active() and not Quests.step_reached(requires_step):
		return false
	return true


## Icon shown in the prompt bubble.
func prompt_icon() -> String:
	if icon != "":
		return icon
	match kind:
		"press": return "hand"
		"magic", "coop": return power
		_: return "hand"


func supports(p: String) -> bool:
	return power == p


func activate(by_power: String = "") -> void:
	if not is_available():
		return
	used = true
	activated.emit(by_power)
	Events.interaction_done.emit(id, kind)
	if kind == "magic" or kind == "coop":
		Events.power_used.emit(power, id)
	if _aura:
		_aura.emitting = false
	_set_halo(0.0)


func reset() -> void:
	used = false
	enabled = true
	if _aura:
		_aura.emitting = true


func set_enabled(v: bool) -> void:
	enabled = v
	if _aura:
		_aura.emitting = v and not used


func _on_hint_level_changed_dummy() -> void:
	pass


func _on_hint_level(level: int, target: String) -> void:
	hint_level = level if target == id else 0
	if hint_level < 2:
		_set_halo(0.0)


func _set_halo(a: float) -> void:
	if _halo and _halo.material_override:
		var c: Color = (_halo.material_override as StandardMaterial3D).albedo_color
		c.a = a
		(_halo.material_override as StandardMaterial3D).albedo_color = c


func _process(delta: float) -> void:
	_t += delta
	if _halo == null:
		return
	if hint_level >= 2 and is_available():
		var pulse := 0.55 + 0.35 * sin(_t * 4.0)
		_set_halo(pulse * (1.0 if hint_level < 4 else 1.3))
		var s := 1.0 + 0.25 * sin(_t * 4.0) + (0.3 if hint_level >= 3 else 0.0)
		_halo.scale = Vector3.ONE * s * 1.4
		_halo.rotation.z += delta * 0.8
