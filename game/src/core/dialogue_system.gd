extends Node
## Plays data-driven dialogue sequences (res://data/dialogue/*.json).
## Code never contains spoken text; it only asks for a sequence id:   await Dialogue.play("lumi_asks_help")
##
## Each line drives: voice audio, subtitle UI, and the speaking character's animation/emotion via Events.character_cue.

var blocking := false     # true while a story sequence is playing (player input is frozen)
var speaking := false     # true while any line (including hints/barks) is playing
var _skip := false
var _queue_busy := false


func is_busy() -> bool:
	return speaking


## Story dialogue: freezes gameplay, awaitable.
func play(sequence_id: String, opts: Dictionary = {}) -> void:
	var seq: Array = Content.sequence(sequence_id)
	if seq.is_empty():
		push_warning("[Dialogue] unknown sequence: " + sequence_id)
		return
	while speaking:
		await get_tree().process_frame  # never talk over ourselves
	var is_blocking: bool = opts.get("blocking", true)
	speaking = true
	blocking = is_blocking
	Events.dialogue_started.emit(sequence_id)
	for ln in seq:
		if ln.get("once", false) and GameState.dialogue_seen(ln.id):
			continue
		await _play_line(ln, opts)
	speaking = false
	blocking = false
	Events.dialogue_finished.emit(sequence_id)


## Non-blocking (hints, barks). Silently dropped if something is already being said.
func play_async(sequence_id: String) -> bool:
	if speaking or Content.sequence(sequence_id).is_empty():
		return false
	play(sequence_id, {"blocking": false})
	return true


func skip() -> void:
	_skip = true


func _play_line(ln: Dictionary, opts: Dictionary) -> void:
	_skip = false
	Events.dialogue_line_started.emit(ln)
	Events.character_cue.emit(ln.get("character", "narrator"), ln.get("animation", ""), ln.get("emotion", ""))
	var dur := Audio.play_voice(ln)
	var wait := dur + float(opts.get("line_gap", 0.35))
	var t := 0.0
	while t < wait:
		await get_tree().process_frame
		t += get_process_delta_time()
		if _skip and t > 0.55:
			break
	Audio.stop_voice()
	GameState.mark_dialogue_seen(ln.id)
	Events.dialogue_line_finished.emit(ln)
