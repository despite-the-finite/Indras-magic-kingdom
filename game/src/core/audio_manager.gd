extends Node
## Audio: buses, adaptive music with crossfades, one-shot SFX with pooling, ambience layers, and voice-over.
##
## Every lookup is by *id* and tolerant of missing files, so the game runs (silently) before any audio exists.
##   music    res://assets/audio/music/<cue>.(ogg|mp3|wav)
##   sfx      res://assets/audio/sfx/<id>.(ogg|mp3|wav)
##   ambient  res://assets/audio/ambient/<id>.(ogg|mp3|wav)
##   voice    res://assets/audio/vo/<line_id>.(mp3|ogg|wav)   <- ElevenLabs-generated, cached in the project
##            res://assets/audio/vo/_ph/<line_id>.wav          <- placeholder speech (tools/voice/generate.mjs --placeholder)
##            otherwise the device's own text-to-speech reads the line aloud (Windows SAPI, macOS, browsers' Web Speech),
##            so a child who cannot read always hears every word even before any recording exists.

const EXTS := ["ogg", "mp3", "wav"]
const SFX_POOL := 14

## Per-character text-to-speech colouring: pitch (0..2) and rate (1 = normal) applied to the chosen system voice.
const TTS_CAST := {
	"narrator": {"pitch": 1.0, "rate": 0.9},
	"princess": {"pitch": 1.3, "rate": 1.0},
	"lumi":     {"pitch": 1.5, "rate": 1.02},
	"clover":   {"pitch": 1.45, "rate": 1.08},
	"luna":     {"pitch": 0.85, "rate": 0.9},
}
## Preferred system voices, best first (female, clear, English). Anything else English is still fine.
const TTS_PREFERRED := ["zira", "aria", "jenny", "hazel", "susan", "samantha", "karen", "moira", "google uk english female",
	"google us english", "female", "en-us", "en-gb", "english"]

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_front: AudioStreamPlayer
var _current_cue := ""
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _voice: AudioStreamPlayer
var _ambient: Dictionary = {}      # id -> AudioStreamPlayer
var _cache: Dictionary = {}        # path -> stream (or null when missing)
var _music_tween: Tween
var _duck_tween: Tween
var _warned: Dictionary = {}
var _tts_enabled := false          # project setting on + not headless
var _tts_voices: Array = []        # system voices (Dictionary id/name/language)
var _tts_cast: Dictionary = {}     # character -> system voice id
var _tts_speaking := false
var _tts_utterance := 0
var _tts_next_probe := 0.0         # browsers deliver their voice list late; keep looking for a while
var _tts_callbacks_set := false

signal voice_finished


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_music_a = _mk_player("Music")
	_music_b = _mk_player("Music")
	_music_front = _music_a
	for i in SFX_POOL:
		_sfx_players.append(_mk_player("SFX"))
	_voice = _mk_player("Voice")
	_voice.finished.connect(func(): voice_finished.emit())
	Settings.changed.connect(apply_settings)
	apply_settings()
	_setup_tts()


func _mk_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _setup_buses() -> void:
	for bus_name in ["Music", "SFX", "Voice", "Ambient"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if AudioServer.get_bus_effect_count(sfx_idx) == 0:
		var rv := AudioEffectReverb.new()
		rv.room_size = 0.35
		rv.wet = 0.12
		rv.dry = 0.95
		AudioServer.add_bus_effect(sfx_idx, rv)


func apply_settings() -> void:
	_set_bus("Master", Settings.master)
	_set_bus("Music", Settings.music)
	_set_bus("SFX", Settings.sfx)
	_set_bus("Voice", Settings.voice)
	_set_bus("Ambient", Settings.ambient)


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(idx, linear <= 0.001)


# ---------------------------------------------------------------------------
# loading
# ---------------------------------------------------------------------------
func _find(folder: String, id: String) -> AudioStream:
	var key := folder + "/" + id
	if _cache.has(key):
		return _cache[key]
	var stream: AudioStream = null
	for e in EXTS:
		var p := "res://assets/audio/%s/%s.%s" % [folder, id, e]
		if ResourceLoader.exists(p):
			stream = load(p)
			break
	_cache[key] = stream
	if stream == null and not _warned.has(key):
		_warned[key] = true
		if OS.is_debug_build():
			print("[Audio] (no file yet) ", key)
	return stream


func _loopify(s: AudioStream) -> AudioStream:
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		if w.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			var bytes := 2 if w.format == AudioStreamWAV.FORMAT_16_BITS else 1
			var ch := 2 if w.stereo else 1
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = int(w.data.size() / (bytes * ch))
	elif s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	elif s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = true
	return s


# ---------------------------------------------------------------------------
# music
# ---------------------------------------------------------------------------
func play_music(cue: String, fade: float = 1.6) -> void:
	if cue == _current_cue:
		return
	_current_cue = cue
	Events.music_cue.emit(cue)
	var stream := _find("music", cue) if cue != "" else null
	var incoming := _music_b if _music_front == _music_a else _music_a
	var outgoing := _music_front
	if _music_tween:
		_music_tween.kill()
	if not outgoing.playing and stream == null:
		return
	_music_tween = create_tween().set_parallel(true)
	if outgoing.playing:
		_music_tween.tween_property(outgoing, "volume_db", -60.0, fade)
		_music_tween.chain().tween_callback(outgoing.stop)
	if stream:
		incoming.stream = _loopify(stream)
		incoming.volume_db = -60.0
		incoming.play()
		_music_tween.tween_property(incoming, "volume_db", 0.0, fade)
		_music_front = incoming


func stop_music(fade: float = 1.0) -> void:
	play_music("", fade)


func current_music() -> String:
	return _current_cue


## Short emotional stinger on top of (ducked) music. Returns duration.
func sting(id: String, duck_db: float = -9.0) -> float:
	var s := _find("sfx", id)
	if s == null:
		return 0.0
	duck_music(duck_db, 0.15, s.get_length() * 0.9)
	sfx(id)
	return s.get_length()


func duck_music(db: float, attack: float = 0.2, hold: float = 1.5) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx < 0:
		return
	if _duck_tween:
		_duck_tween.kill()
	var base := linear_to_db(maxf(Settings.music, 0.0001))
	_duck_tween = create_tween()
	_duck_tween.tween_method(func(v): AudioServer.set_bus_volume_db(idx, v), AudioServer.get_bus_volume_db(idx), base + db, attack)
	_duck_tween.tween_interval(hold)
	_duck_tween.tween_method(func(v): AudioServer.set_bus_volume_db(idx, v), base + db, base, 0.8)


# ---------------------------------------------------------------------------
# sfx
# ---------------------------------------------------------------------------
func sfx(id: String, volume_db: float = 0.0, pitch: float = 1.0, pitch_var: float = 0.0) -> AudioStreamPlayer:
	var s := _find("sfx", id)
	if s == null:
		return null
	var p := _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % SFX_POOL
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch * (1.0 + randf_range(-pitch_var, pitch_var))
	p.play()
	return p


func sfx_duration(id: String) -> float:
	var s := _find("sfx", id)
	return s.get_length() if s else 0.0


# ---------------------------------------------------------------------------
# ambience (looped layers, crossfaded)
# ---------------------------------------------------------------------------
func set_ambience(ids: Array, fade: float = 2.0) -> void:
	for id in _ambient.keys():
		if not ids.has(id):
			var p: AudioStreamPlayer = _ambient[id]
			var tw := create_tween()
			tw.tween_property(p, "volume_db", -60.0, fade)
			tw.tween_callback(p.queue_free)
			_ambient.erase(id)
	for id in ids:
		if _ambient.has(id):
			continue
		var s := _find("ambient", id)
		if s == null:
			continue
		var p2 := _mk_player("Ambient")
		p2.stream = _loopify(s)
		p2.volume_db = -60.0
		p2.play()
		create_tween().tween_property(p2, "volume_db", -3.0, fade)
		_ambient[id] = p2


# ---------------------------------------------------------------------------
# voice
# ---------------------------------------------------------------------------
func voice_stream(line_id: String) -> AudioStream:
	var s := _find("vo", line_id)
	if s == null:
		s = _find("vo/_ph", line_id)
	return s


## Plays a dialogue line's voice. Returns its (expected) duration in seconds:
## the real recording's length, the reading-time estimate for text-to-speech (the dialogue system keeps
## waiting while `voice_playing()` stays true), or the estimate alone when narration is switched off.
func play_voice(line: Dictionary) -> float:
	stop_voice()
	var text: String = line.get("text", "")
	var words := float(text.split(" ", false).size())
	var est := maxf(1.5, 0.7 + words * 0.34)
	if not Settings.narration:
		return est
	var s := voice_stream(line.get("id", ""))
	if s != null:
		_voice.stream = s
		_voice.pitch_scale = 1.0
		_voice.play()
		duck_music(-6.0, 0.15, s.get_length() + 0.2)
		return s.get_length()
	if _tts_say(String(line.get("character", "narrator")), text):
		var tts_est := maxf(1.6, 0.8 + words * 0.42)
		duck_music(-6.0, 0.15, tts_est + 0.4)
		return tts_est
	return est


func stop_voice() -> void:
	_voice.stop()
	if _tts_speaking:
		_tts_speaking = false
		DisplayServer.tts_stop()


func voice_playing() -> bool:
	return _voice.playing or _tts_speaking


# ---------------------------------------------------------------------------
# text-to-speech fallback (no files needed)
# ---------------------------------------------------------------------------
func _setup_tts() -> void:
	_tts_enabled = bool(ProjectSettings.get_setting("audio/general/text_to_speech", false)) and DisplayServer.get_name() != "headless"
	if not _tts_enabled:
		return
	_probe_tts_voices()


func _probe_tts_voices() -> void:
	_tts_next_probe = Time.get_ticks_msec() / 1000.0 + 2.0
	var voices: Array = DisplayServer.tts_get_voices()
	if voices.is_empty():
		return
	_tts_voices = voices
	_cast_tts_voices()
	if not _tts_callbacks_set:
		_tts_callbacks_set = true
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _on_tts_done)
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, _on_tts_done)
	if OS.is_debug_build():
		print("[Audio] text-to-speech ready: %d voices, cast=%s" % [voices.size(), _tts_cast])


func tts_available() -> bool:
	return _tts_enabled and not _tts_voices.is_empty()


func _voice_score(v: Dictionary) -> int:
	## Higher = nicer for a bedtime-story game. English first, then our preferred names, then anything.
	var name := String(v.get("name", "")).to_lower()
	var lang := String(v.get("language", "")).to_lower()
	var score := 0
	if lang.begins_with("en"):
		score += 100
	for i in TTS_PREFERRED.size():
		if name.contains(TTS_PREFERRED[i]):
			score += 50 - i
			break
	if name.contains("male") and not name.contains("female"):
		score -= 20
	return score


func _cast_tts_voices() -> void:
	var ranked := _tts_voices.duplicate()
	ranked.sort_custom(func(a, b): return _voice_score(a) > _voice_score(b))
	var ids: Array = []
	for v in ranked:
		ids.append(String(v.get("id", "")))
	if ids.is_empty():
		return
	# narrator gets the best voice; the characters take the next ones so the cast sounds like different people,
	# and pitch/rate differences (TTS_CAST) keep them apart even on a device with a single voice
	_tts_cast = {
		"narrator": ids[0],
		"princess": ids[1 % ids.size()],
		"lumi": ids[2 % ids.size()] if ids.size() > 2 else ids[1 % ids.size()],
		"clover": ids[1 % ids.size()],
		"luna": ids[0],
	}


func _tts_say(character: String, text: String) -> bool:
	if not _tts_enabled or text.strip_edges() == "":
		return false
	if _tts_voices.is_empty():
		if Time.get_ticks_msec() / 1000.0 >= _tts_next_probe:
			_probe_tts_voices()
		if _tts_voices.is_empty():
			return false
	var cast: Dictionary = TTS_CAST.get(character, TTS_CAST["narrator"])
	var voice_id: String = _tts_cast.get(character, _tts_cast.get("narrator", ""))
	var vol := int(clampf(Settings.voice * Settings.master, 0.0, 1.0) * 100.0)
	if vol <= 0:
		return false
	_tts_utterance += 1
	_tts_speaking = true
	DisplayServer.tts_speak(text, voice_id, vol, float(cast.pitch), float(cast.rate), _tts_utterance, true)
	return true


func _on_tts_done(id: int) -> void:
	if id == _tts_utterance:
		_tts_speaking = false
		voice_finished.emit()
