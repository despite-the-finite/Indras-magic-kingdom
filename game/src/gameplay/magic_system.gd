class_name MagicSystem
extends Node
## sparkles -> swirling particles -> environmental reaction -> musical flourish -> character reaction.
## The player never chooses spells from a menu: the magic button uses whatever the focused object needs.

var level: Node3D
var companion: Companion


func cast_at(player: Player, target: Interactable) -> void:
	var p := target.power
	# princess powers
	var princess_power := p in ["flower", "animals", "starlight", "rainbow"]
	if target.kind == "magic" and princess_power and not GameState.has_power(p):
		Audio.sfx("ui_tap", -4.0, 0.7)
		return
	if target.kind == "magic" and not princess_power:
		# companion ability (e.g. rainbow_bridge)
		if companion == null:
			return
		await _cast_companion(player, target)
		return
	if target.kind == "coop":
		await _cast_coop(player, target)
		return
	await _cast_princess(player, target, p)


func _cast_princess(player: Player, target: Interactable, p: String) -> void:
	player.busy = true
	player.current_power = p
	player.face_toward(target.global_position.x - player.global_position.x)
	player.rig.play("cast")
	player.rig.set_emotion("determined")
	Audio.sfx("magic_charge", -2.0)
	var col := Interactable.power_color(p)
	var to := target.global_position + Vector3(0, target.fx_height, 0)
	MagicSwirl.play(level, player.rig.wand_tip_world(), to, col, 0.7)
	Fx.sparkle_burst(level, player.rig.wand_tip_world(), col, 14, 2.0, 0.22, 0.7)
	await get_tree().create_timer(0.62).timeout
	# reaction + flourish
	Audio.sfx("magic_flourish_" + p if _has_sfx("magic_flourish_" + p) else "magic_flourish")
	Fx.sparkle_burst(level, to, col, 34, 4.2, 0.38, 1.2)
	if p == "flower":
		Fx.flower_burst(level, to, [Mat.PINK, Mat.SUN, Mat.LILAC, Color.WHITE], 24)
	elif p == "animals":
		Fx.heart_burst(level, to + Vector3(0, 0.4, 0), 7)
	if player.cam:
		player.cam.punch(-2.5)
	target.activate(p)
	player.rig.set_emotion("joyful")
	player.rig.play("happy")
	await get_tree().create_timer(0.55).timeout
	player.rig.set_emotion("happy")
	player.busy = false


func _cast_companion(player: Player, target: Interactable) -> void:
	player.busy = true
	player.face_toward(target.global_position.x - player.global_position.x)
	player.rig.play("wonder")
	await companion.perform_ability(target)
	target.activate(target.power)
	player.rig.play("celebrate")
	player.rig.set_emotion("joyful")
	await get_tree().create_timer(0.8).timeout
	player.busy = false


func _cast_coop(player: Player, target: Interactable) -> void:
	player.busy = true
	player.face_toward(target.global_position.x - player.global_position.x)
	player.rig.play("cast")
	var to := target.global_position + Vector3(0, target.fx_height, 0)
	Audio.sfx("magic_charge", -2.0)
	MagicSwirl.play(level, player.rig.wand_tip_world(), to, Interactable.power_color("starlight"), 0.9)
	if companion:
		companion.rig.play("horn_glow")
		companion.rig.face_toward(to.x - companion.global_position.x)
		MagicSwirl.play(level, companion.rig.horn_world(), to, Color("#c8a0ff"), 0.9)
	await get_tree().create_timer(0.95).timeout
	Audio.sfx("magic_flourish")
	Fx.sparkle_burst(level, to, Color("#fff0a0"), 44, 5.0, 0.4, 1.4)
	if player.cam:
		player.cam.punch(-3.5)
	target.activate(target.power)
	player.rig.set_emotion("joyful")
	player.rig.play("celebrate")
	await get_tree().create_timer(0.8).timeout
	player.busy = false


## Ambient cast when nothing is targeted: pure delight (tiny flowers, sparkles, hearts).
func cast_ambient(player: Player) -> void:
	player.busy = true
	var p := player.current_power
	var col := Interactable.power_color(p)
	player.rig.play("cast")
	Audio.sfx("magic_charge", -6.0, 1.15)
	var ahead := player.global_position + Vector3(player.facing * 1.6, 0.6, 0)
	MagicSwirl.play(level, player.rig.wand_tip_world(), ahead, col, 0.45)
	await get_tree().create_timer(0.42).timeout
	Audio.sfx("magic_flourish", -8.0, 1.2)
	Fx.sparkle_burst(level, ahead, col, 18, 2.6, 0.28, 0.9)
	match p:
		"flower":
			Fx.flower_burst(level, ahead, [], 14)
			_grow_blossom(ahead)
		"animals":
			Fx.heart_burst(level, ahead + Vector3(0, 0.3, 0), 5)
		"starlight":
			var glow := Fx.glow_sprite(level, ahead + Vector3(0, 0.5, 0), Color(1, 0.95, 0.6, 0.8), 2.4)
			var tw := create_tween()
			tw.tween_interval(1.4)
			tw.tween_property(glow, "scale", Vector3.ZERO, 0.8)
			tw.tween_callback(glow.queue_free)
		"rainbow":
			pass
	Events.custom_event.emit("ambient_cast")
	await get_tree().create_timer(0.35).timeout
	player.busy = false


func _grow_blossom(pos: Vector3) -> void:
	# a permanent little flower that pops up from the ground
	var ray := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 2, 0), pos + Vector3(0, -4, 0), 1)
	var hit := level.get_world_3d().direct_space_state.intersect_ray(ray)
	var gp: Vector3 = hit.position if hit.size() > 0 else Vector3(pos.x, 0, 0)
	var f := ForestProps.flower(level, gp, [Mat.PINK, Mat.SUN, Mat.LILAC, Color.WHITE][randi() % 4], 0.6)
	f.scale = Vector3.ZERO
	create_tween().tween_property(f, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _has_sfx(id: String) -> bool:
	return ResourceLoader.exists("res://assets/audio/sfx/%s.wav" % id) or ResourceLoader.exists("res://assets/audio/sfx/%s.ogg" % id)
