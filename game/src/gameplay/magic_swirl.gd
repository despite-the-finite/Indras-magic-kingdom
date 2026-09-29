class_name MagicSwirl
extends Node3D
## Sparkles gather at the wand, spiral toward the target, and burst. Spectacular but cheap: ~24 additive quads.

var from_pos := Vector3.ZERO
var to_pos := Vector3.ZERO
var color := Color(1, 0.8, 0.9)
var duration := 0.7
var count := 26
var _sprites: Array[MeshInstance3D] = []
var _phase: Array[float] = []
var _delay: Array[float] = []
var _t := 0.0


static func play(parent: Node, from: Vector3, to: Vector3, col: Color, dur: float = 0.7) -> MagicSwirl:
	var s := MagicSwirl.new()
	s.from_pos = from
	s.to_pos = to
	s.color = col
	s.duration = dur
	s.count = int(26 * Settings.particle_scale())
	parent.add_child(s)
	return s


func _ready() -> void:
	for i in count:
		var tex: Texture2D = FxTex.star4() if i % 3 != 0 else FxTex.glow()
		var col := color.lerp(Color.WHITE, randf() * 0.5)
		col.a = 0.9
		var sp := Fx.glow_sprite(self, from_pos, col, randf_range(0.18, 0.34), tex)
		_sprites.append(sp)
		_phase.append(randf() * TAU)
		_delay.append(randf() * 0.35)


func _process(delta: float) -> void:
	_t += delta
	var total := duration + 0.4
	var dir := (to_pos - from_pos)
	var side := Vector3(-dir.y, dir.x, 0).normalized()
	if side.length() < 0.01:
		side = Vector3.UP
	for i in _sprites.size():
		var k := clampf((_t - _delay[i] * duration * 0.6) / duration, 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k)
		var base := from_pos.lerp(to_pos, e)
		var swirl_r := sin(k * PI) * 0.55
		var a := _phase[i] + k * 9.0
		var off := side * cos(a) * swirl_r + Vector3(0, 0, sin(a) * swirl_r * 0.6) + Vector3(0, sin(a) * swirl_r * 0.5, 0)
		_sprites[i].position = base + off
		var fade := 1.0 - smoothstep(0.85, 1.0, k)
		var sc := (0.6 + 0.6 * sin(k * PI)) * fade
		_sprites[i].scale = Vector3.ONE * maxf(sc, 0.001)
	if _t > total:
		queue_free()
