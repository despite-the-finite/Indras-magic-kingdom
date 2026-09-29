extends Node
## Layered guidance for non-readers. Curiosity first, then gently increasing help.
##
##  L1  spoken hint            (narrator voice line)
##  L2  visual hint            (target glows brighter, princess looks toward it)
##  L3  environmental guidance (Flutter the butterfly flies toward the target, second spoken hint)
##  L4  direct assistance      (a sparkling trail briefly shows the way)
##
## The timer only runs during free play, runs slower while the child is actively exploring,
## faster when she is idle, and resets whenever she makes progress. HintSystem is generic: it emits
## Events.hint_level_changed and level scenes respond (target glow, Flutter, trail).

const THRESHOLDS := [14.0, 28.0, 44.0, 62.0]   # "effective seconds without progress" for L1..L4
const REPEAT_L4 := 22.0

var enabled := false
var level := 0
var target_id := ""
var step: Dictionary = {}
var _clock := 0.0
var _targets: Dictionary = {}     # id -> Node3D
var _last_l4 := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# any deliberate action counts as progress
	Events.power_used.connect(func(_p, _t): reset_progress())
	Events.interaction_done.connect(func(_i, _k): reset_progress())
	Events.zone_entered.connect(func(_z): reset_progress())


# ---- target registry (Interactables and Zones register themselves) ---------
func register_target(id: String, node: Node3D) -> void:
	_targets[id] = node


func unregister_target(id: String, node: Node3D) -> void:
	if _targets.get(id) == node:
		_targets.erase(id)


func target_node() -> Node3D:
	var n: Variant = _targets.get(target_id)
	return n if is_instance_valid(n) else null


# ---- control ---------------------------------------------------------------
func watch_step(quest_step: Dictionary) -> void:
	step = quest_step
	var hint: Dictionary = quest_step.get("hint", {})
	target_id = hint.get("target", quest_step.get("target", ""))
	enabled = true
	_set_level(0)
	_clock = 0.0


func stop() -> void:
	enabled = false
	_set_level(0)
	step = {}
	target_id = ""


func reset_progress() -> void:
	_clock = 0.0
	if level != 0:
		_set_level(0)


func nudge() -> void:
	## Player asked for help (tapped Flutter / the hint button): jump straight to the next level.
	if not enabled:
		return
	_clock = maxf(_clock, THRESHOLDS[mini(level, THRESHOLDS.size() - 1)] + 0.1)


func _process(delta: float) -> void:
	if not enabled or Dialogue.blocking:
		return
	var rate := 1.0
	var idle := InputRouter.idle_seconds()
	if idle < 2.5:
		rate = 0.55      # actively exploring: be patient
	elif idle > 6.0:
		rate = 1.4       # sitting still: be quicker to help
	_clock += delta * rate
	var want := 0
	for i in THRESHOLDS.size():
		if _clock >= THRESHOLDS[i]:
			want = i + 1
	if want > level:
		_set_level(want)
	elif level == 4 and _clock - _last_l4 > REPEAT_L4:
		_last_l4 = _clock
		Events.hint_level_changed.emit(4, target_id)   # re-show trail


func _set_level(l: int) -> void:
	level = l
	if l == 4:
		_last_l4 = _clock
	Events.hint_level_changed.emit(l, target_id)
	var hint: Dictionary = step.get("hint", {})
	match l:
		1:
			if hint.has("voice"):
				Dialogue.play_async(hint.voice)
		3:
			if hint.has("voice_alt"):
				Dialogue.play_async(hint.voice_alt)
