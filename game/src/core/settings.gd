extends Node
## Parent-controlled settings. Stored separately from save data so "reset progress" never wipes them.

signal changed

const PATH := "user://settings.cfg"

var master := 0.9
var music := 0.7
var sfx := 0.9
var voice := 1.0
var ambient := 0.8
var narration := true
var subtitles := true
var quality := 2            # 0 low, 1 medium, 2 high
var reduce_motion := false  # no camera shake / flashes
var touch_controls := false # show on-screen buttons (auto-on for touch devices)


func _ready() -> void:
	# browsers and tablets: start on medium (a parent can raise it); desktop starts on high
	if OS.has_feature("web") or OS.has_feature("mobile"):
		quality = 1
	load_settings()
	if DisplayServer.is_touchscreen_available():
		touch_controls = true
	apply_render_quality()


func apply_render_quality() -> void:
	var vp := get_tree().root
	vp.msaa_3d = Viewport.MSAA_4X if quality >= 2 else (Viewport.MSAA_2X if quality == 1 and not OS.has_feature("web") else Viewport.MSAA_DISABLED)


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	for k in ["master", "music", "sfx", "voice", "ambient", "narration", "subtitles", "quality", "reduce_motion", "touch_controls"]:
		if cf.has_section_key("settings", k):
			set(k, cf.get_value("settings", k))


func save_settings() -> void:
	var cf := ConfigFile.new()
	for k in ["master", "music", "sfx", "voice", "ambient", "narration", "subtitles", "quality", "reduce_motion", "touch_controls"]:
		cf.set_value("settings", k, get(k))
	cf.save(PATH)
	apply_render_quality()
	changed.emit()


func particle_scale() -> float:
	return [0.45, 0.75, 1.0][clampi(quality, 0, 2)]


func shadows_enabled() -> bool:
	return quality >= 1


func glow_enabled() -> bool:
	return quality >= 1
