extends Node
## Runs the active quest from its JSON definition. Steps advance when a matching event key arrives.
##
## Event keys:  interact:<id>   power:<power>:<target>   zone:<id>   custom:<name>
## A step also completes if its key was already seen before the step started (prevents soft-locks).

var quest_id := ""
var quest: Dictionary = {}
var step_index := -1
var _seen: Dictionary = {}
var _advancing := false


func _ready() -> void:
	Events.interaction_done.connect(func(id, _k): notify("interact:" + id))
	Events.power_used.connect(func(power, target): notify("power:%s:%s" % [power, target]))
	Events.zone_entered.connect(func(id): notify("zone:" + id))
	Events.custom_event.connect(func(n): notify("custom:" + n))


func active() -> bool:
	return quest_id != ""


func start(id: String) -> void:
	quest = Content.quest(id)
	if quest.is_empty():
		push_warning("[Quests] unknown quest " + id)
		return
	quest_id = id
	step_index = -1
	_seen.clear()
	GameState.set_quest_status(id, "active")
	Events.quest_started.emit(id)
	_begin_step(0)


func stop() -> void:
	quest_id = ""
	quest = {}
	step_index = -1
	_seen.clear()
	Hints.stop()


func current_step() -> Dictionary:
	var steps: Array = quest.get("steps", [])
	if step_index < 0 or step_index >= steps.size():
		return {}
	return steps[step_index]


func step_id() -> String:
	return current_step().get("id", "")


func step_reached(id: String) -> bool:
	## true if `id` is the current step or an earlier (completed) one
	var steps: Array = quest.get("steps", [])
	for i in steps.size():
		if steps[i].id == id:
			return i <= step_index
	return false


func notify(key: String) -> void:
	if not active():
		return
	_seen[key] = true
	if _advancing:
		return
	var step := current_step()
	if step.is_empty():
		return
	if key in step.get("complete_on", []):
		_complete_step()


func _begin_step(i: int) -> void:
	var steps: Array = quest.get("steps", [])
	if i >= steps.size():
		_finish()
		return
	step_index = i
	var step: Dictionary = steps[i]
	Events.quest_step_started.emit(quest_id, step.id)
	if step.has("dialogue_on_start"):
		await Dialogue.play(step.dialogue_on_start)
	# Robustness: completed already (player did it early)?
	for key in step.get("complete_on", []):
		if _seen.has(key):
			_complete_step()
			return
	Hints.watch_step(step)


func _complete_step() -> void:
	if _advancing:
		return
	_advancing = true
	var step := current_step()
	Hints.stop()
	Events.quest_step_completed.emit(quest_id, step.id)
	if step.has("star"):
		var s: Dictionary = step.star
		GameState.add_stars(int(s.get("amount", 1)), Vector3.ZERO, s.get("reason", "step"))
	if step.has("dialogue_on_complete"):
		await Dialogue.play(step.dialogue_on_complete)
	_advancing = false
	_begin_step(step_index + 1)


func _finish() -> void:
	var id := quest_id
	GameState.set_quest_status(id, "done")
	Events.quest_completed.emit(id)
	Hints.stop()
	# Level scripts decide what happens visually next; state changes (stage, stars) are applied by the level's
	# completion handler through Lifecycle helpers below so the moment can be staged as a cinematic.
