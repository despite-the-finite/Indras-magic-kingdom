extends Node
## Registry of live character rigs so dialogue/quests can animate characters by id:
##   Events.character_cue("lumi", "happy_jump", "excited")  ->  the Lumi rig plays it.

var _rigs: Dictionary = {}     # character_id -> rig
var speaking_id := ""           # character whose line is currently playing (rigs flap their mouth)


func _ready() -> void:
	Events.character_cue.connect(_on_cue)
	Events.dialogue_line_started.connect(func(l): speaking_id = l.get("character", ""))
	Events.dialogue_line_finished.connect(func(_l): speaking_id = "")


func register(id: String, rig: Node) -> void:
	_rigs[id] = rig


func unregister(id: String, rig: Node) -> void:
	if _rigs.get(id) == rig:
		_rigs.erase(id)


func rig(id: String) -> Node:
	var r: Variant = _rigs.get(id)
	return r if is_instance_valid(r) else null


func _on_cue(id: String, anim: String, emotion: String) -> void:
	var r := rig(id)
	if r == null:
		return
	if emotion != "" and r.has_method("set_emotion"):
		r.set_emotion(emotion)
	if anim != "" and r.has_method("play"):
		r.play(anim)
