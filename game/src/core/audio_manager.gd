extends Node
## Audio: buses, adaptive music with crossfades, one-shot SFX with pooling, ambience layers, and voice-over.
##
## Every lookup is by *id* and tolerant of missing files, so the game runs (silently) before any audio exists.
##   music    res://assets/audio/music/<cue>.(ogg|mp3|wav)
##   sfx      res://assets/audio/sfx/<id>.(ogg|mp3|wav)
##   ambient  res://assets/audio/ambient/<id>.(ogg|mp3|wav)
##   voice    res://assets/audio/vo/<line_id>.(mp3|ogg|wav)   <- ElevenLabs-generated, cached in the project
##            res://assets/audio/vo/_ph/<line_id>.wav          <- placeholder speech (tools/voice/generate.mjs --placeholder)

const EXTS := ["ogg", "mp3", "wav"]
const SFX_POOL := 14

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


## Plays a dialogue line's voice. Returns its duration in seconds
## (real audio length, or a reading-time estimate when no audio exists yet).
func play_voice(line: Dictionary) -> float:
	_voice.stop()
	var text: String = line.get("text", "")
	var est := maxf(1.5, 0.7 + float(text.split(" ").size()) * 0.34)
	if not Settings.narration:
		return est
	var s := voice_stream(line.get("id", ""))
	if s == null:
		return est
	_voice.stream = s
	_voice.pitch_scale = 1.0
	_voice.play()
	duck_music(-6.0, 0.15, s.get_length() + 0.2)
	return s.get_length()


func stop_voice() -> void:
	_voice.stop()


func voice_playing() -> bool:
	return _voice.playing
