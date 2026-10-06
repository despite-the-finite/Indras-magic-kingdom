extends Node
## Automated vertical-slice playthrough (dev only):
##   godot --headless --path game -- --playthrough [--from=rescue|care|friendship|ride]
## Drives the REAL game systems (quests, dialogue, magic, care, companion, mini adventure) with scripted input and
## asserts every state transition of the character lifecycle. Exit code 0 = everything completed.

var failures := 0
var steps_done := 0


func _ready() -> void:
	run.call_deferred()


func check(cond: bool, what: String) -> void:
	steps_done += 1
	if cond:
		print("  [ok]   ", what)
	else:
		failures += 1
		printerr("  [FAIL] ", what)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## wait for cond() with a wall-clock timeout (seconds); keeps skipping dialogue to save time
func _until(cond: Callable, timeout: float = 60.0, what: String = "") -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < timeout * 1000.0:
		if cond.call():
			return true
		if Dialogue.blocking:
			Dialogue.skip()
		await get_tree().process_frame
	printerr("  [timeout] ", what)
	_diagnose()
	return false


func _diagnose() -> void:
	var lvl := Router.current
	var msg := "    scene=%s quest=%s step=%s dialogue.blocking=%s speaking=%s" % [Router.current_id, Quests.quest_id, Quests.step_id(), Dialogue.blocking, Dialogue.speaking]
	if lvl is LevelBase and lvl.player:
		var p: Player = lvl.player
		msg += " player=(%.1f,%.1f) busy=%s frozen=%s locked=%s focus=%s" % [p.global_position.x, p.global_position.y, p.busy, p.frozen, p.controls_locked(), p.focus.id if p.focus else "-"]
	print(msg)


func _scene_ready(id: String) -> bool:
	await _frames(3)
	return await _until(func(): return Router.current_id == id and Router.current != null and not Router.busy, 30.0, "scene " + id)


func _find(id: String) -> Interactable:
	for i in Interactable.all:
		if i.id == id:
			return i
	return null


func _target_node(id: String) -> Node3D:
	var n: Variant = Hints._targets.get(id)
	return n if is_instance_valid(n) else null


func run() -> void:
	var args := DevTools.parse_args(OS.get_cmdline_user_args())
	var from := String(args.get("from", "intro"))
	print("=== PLAYTHROUGH: Indra's Magic Kingdom vertical slice (from=%s) ===" % from)
	Engine.time_scale = 5.0
	GameState.set_autosave(false)
	Settings.narration = true
	match from:
		"intro": DevTools.apply_preset("fresh")
		"rescue": DevTools.apply_preset("fresh")
		"care": DevTools.apply_preset("at_castle")
		"friendship": DevTools.apply_preset("quest_ready")
		"ride": DevTools.apply_preset("quest_done")
	if from == "intro":
		await _part_intro()
	if from in ["intro", "rescue"]:
		await _part_rescue()
	if from in ["intro", "rescue", "care"]:
		await _part_care()
	if from in ["intro", "rescue", "care", "friendship"]:
		await _part_friendship()
	await _part_ride()
	await _part_castle_inside()
	_part_voice()
	print("=== DONE: %d checks, %d failures, stars=%d ===" % [steps_done, failures, GameState.stars()])
	get_tree().quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- castle intro + map
func _part_intro() -> void:
	print("[1] castle introduction")
	Router.go_now("castle", {})
	await _scene_ready("castle")
	await _until(func(): return GameState.flag("castle_intro_done"), 120.0, "castle intro")
	check(GameState.flag("castle_intro_done"), "castle intro narrated")
	check(GameState.stage("lumi") == GameState.Stage.DISCOVERED, "Lumi is DISCOVERED (Flutter told us)")
	print("[2] world map")
	Router.go_now("map", {})
	await _scene_ready("map")
	check(Router.current.islands.has("enchanted_forest"), "map has the Enchanted Forest")


# ---------------------------------------------------------------- Mode 1
func _part_rescue() -> void:
	print("[3] Lost Unicorn adventure")
	Router.go_now("forest_rescue", {})
	await _scene_ready("forest_rescue")
	await _until(func(): return Quests.active(), 120.0, "quest start")
	var level: Node = Router.current
	var player: Player = level.player
	for s in Content.quest("lost_unicorn").steps:
		await _until(func(): return not Dialogue.blocking and not player.busy, 60.0, "player free before " + s.id)
		var before := Quests.step_id()
		check(before == s.id, "quest step reached: " + s.id)
		if s.id == "grow_bridge":
			# a child who runs at the river before the bridge exists must bump, not fall in
			player.teleport(Vector3(level.GAP_X0 - 2.5, level.ground_y(level.GAP_X0 - 2.5) + 0.3, 0))
			await _walk(player, 1.0, 1.4)
			check(player.global_position.y > -1.0 and not player._rescuing, "river edge holds before the bridge grows (x=%.1f y=%.1f)" % [player.global_position.x, player.global_position.y])
		await _solve(level, player, s)
		if s.id == "grow_bridge":
			await _until(func(): return level._bridge_built, 10.0, "bridge")
			await get_tree().create_timer(1.6).timeout
			# ...and once it has grown she can simply walk across
			player.teleport(Vector3(level.GAP_X0 - 2.0, level.ground_y(level.GAP_X0 - 2.0) + 0.3, 0))
			await _walk(player, 1.0, 2.8)
			check(player.global_position.x > level.GAP_X1 + 0.5 and player.global_position.y > -1.0 and not player._rescuing, "walked across the vine bridge (x=%.1f y=%.1f)" % [player.global_position.x, player.global_position.y])
	print("[4] rescue cinematic -> castle")
	await _until(func(): return Router.current_id == "castle", 120.0, "return to castle after rescue")
	check(GameState.stage("lumi") >= GameState.Stage.RESCUED, "Lumi RESCUED")
	check(GameState.stars() >= 3, "rescue stars awarded (%d)" % GameState.stars())
	await _scene_ready("castle")
	await _until(func(): return GameState.stage("lumi") >= GameState.Stage.AT_CASTLE and not Dialogue.speaking, 120.0, "Lumi arrives at castle")
	check(GameState.stage("lumi") == GameState.Stage.AT_CASTLE, "Lumi is AT_CASTLE")
	check(GameState.feature_unlocked("unicorn_stable"), "stable unlocked (castle visibly changes)")


## Hold a direction key for `seconds` of game time (the way a child leans on the arrow key).
func _walk(player: Player, dir: float, seconds: float) -> void:
	var action := "move_right" if dir > 0.0 else "move_left"
	Input.action_press(action)
	var t := 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()
	Input.action_release(action)
	await _frames(3)


## Walk to a quest step's target and use it the way a child would (walk close, press the magic button).
## `stand_at` overrides where she stands when she presses the button.
func _solve(level: Node, player: Player, s: Dictionary, stand_at: float = NAN) -> void:
	var before := Quests.step_id()
	var node := _target_node(String(s.target))
	if node == null:
		printerr("  no target node for step ", s.id)
		failures += 1
		return
	var it := _find(String(s.target))
	var tx := node.global_position.x
	var stand := tx - (1.5 if it != null and it.kind != "touch" else 0.0)
	if not is_nan(stand_at):
		stand = stand_at
	player.teleport(Vector3(stand, level.ground_y(stand) + 0.3, 0))
	if level.companion:
		level.companion.global_position = Vector3(stand - 2.0, level.ground_y(stand) + 0.3, 0)
		level.companion.velocity = Vector3.ZERO
	await _frames(6)
	if it != null and it.kind != "touch":
		await _until(func(): return not player.controls_locked() and player.focus != null, 10.0, "focus " + String(s.target))
		player.try_act()
	var ok := await _until(func(): return Quests.step_id() != before or not Quests.active(), 40.0, "solve " + String(s.id))
	check(ok, "solved: " + String(s.id))


# ---------------------------------------------------------------- Mode 2 + 3 unlock
func _part_care() -> void:
	print("[5] care for Lumi")
	Router.go_now("stable", {})
	await _scene_ready("stable")
	var stable: Node = Router.current
	await get_tree().create_timer(1.5).timeout
	for need in Content.character("lumi").care.needs:
		for i in int(need.count):
			await _until(func(): return not stable._busy and not Dialogue.blocking, 60.0, "stable idle")
			stable._on_tool(String(need.id))
			await _frames(3)
		await _until(func(): return GameState.care_count("lumi", String(need.id)) >= int(need.count), 60.0, "care " + String(need.id))
		check(GameState.care_count("lumi", String(need.id)) >= int(need.count), "care need met: " + String(need.id))
	await _until(func(): return Router.current_id == "castle" and GameState.stage("lumi") >= GameState.Stage.FRIENDS, 120.0, "friends")
	check(GameState.stage("lumi") >= GameState.Stage.FRIENDS, "Lumi is FRIENDS")
	print("[6] Lumi asks for help")
	await _scene_ready("castle")
	await _until(func(): return GameState.stage("lumi") == GameState.Stage.QUEST_READY, 120.0, "quest ready")
	check(GameState.stage("lumi") == GameState.Stage.QUEST_READY, "Friendship Quest unlocked (QUEST_READY)")


# ---------------------------------------------------------------- Mode 3
func _part_friendship() -> void:
	print("[7] Friendship Quest: Moonflower for Mama")
	Router.go_now("moonlit_forest", {})
	await _scene_ready("moonlit_forest")
	await _until(func(): return Quests.active(), 120.0, "moon quest start")
	var level: Node = Router.current
	var player: Player = level.player
	check(level.companion != null, "Lumi joins as companion")
	for s in Content.quest("moonflower_for_mama").steps:
		await _until(func(): return not Dialogue.blocking and not player.busy, 90.0, "free before " + String(s.id))
		check(Quests.step_id() == s.id, "quest step reached: " + String(s.id))
		if s.id == "cross_ledge":
			# THE reported bug: she runs right up to the ledge, asks for the rainbow there, and must neither
			# fall through the cliff nor end up boxed in behind the bridge
			var edge: float = level.CLIFF_X
			player.teleport(Vector3(edge - 3.0, level.ground_y(edge - 3.0) + 0.3, 0))
			await _walk(player, 1.0, 1.6)
			check(player.global_position.y > -1.0 and player.global_position.x < edge and not player._rescuing, "cliff face is solid: no falling through the ledge (x=%.1f y=%.1f)" % [player.global_position.x, player.global_position.y])
			await _solve(level, player, s, player.global_position.x)
			await _until(func(): return not player.is_gliding() and not player.busy and not Dialogue.blocking, 30.0, "rainbow settles")
			var on_bridge: float = level.rainbow_y(player.global_position.x)
			check(player.global_position.y >= on_bridge - 0.3, "rainbow lifted her onto the bridge instead of trapping her (y=%.2f bridge=%.2f)" % [player.global_position.y, on_bridge])
			await _walk(player, 1.0, 2.4)
			check(player.global_position.x > edge + 1.5 and player.global_position.y > 2.5 and not player._rescuing, "walked up the rainbow onto the ledge (x=%.1f y=%.1f)" % [player.global_position.x, player.global_position.y])
			check(level.companion.global_position.y > -1.0, "Lumi did not fall either")
			continue
		await _solve(level, player, s)
	await _until(func(): return Router.current_id == "castle" and GameState.stage("lumi") == GameState.Stage.QUEST_DONE, 180.0, "finale -> castle")
	check(GameState.stage("lumi") == GameState.Stage.QUEST_DONE, "Friendship Quest complete (QUEST_DONE)")
	check(GameState.has_power("rainbow"), "Rainbow Magic gained")
	check(GameState.minigame_unlocked("rainbow_ride"), "Rainbow Ride unlocked")
	await _scene_ready("castle")
	await _until(func(): return not Dialogue.speaking, 120.0, "mama scene")


# ---------------------------------------------------------------- Mode 4
func _part_ride() -> void:
	print("[8] Rainbow Ride mini adventure")
	Router.go_now("rainbow_ride", {})
	await _scene_ready("rainbow_ride")
	var ride: Node = Router.current
	await _until(func(): return ride.running, 60.0, "ride running")
	await get_tree().create_timer(3.0).timeout
	check(ride.x > 5.0, "the ride moves (x=%.1f)" % ride.x)
	ride.x = ride._finish_x - 4.0
	await _until(func(): return ride._results != null, 90.0, "ride results")
	check(ride._results != null, "ride ends with a celebration and results")
	check(GameState.data.minigames.has("rainbow_ride"), "mini adventure recorded")


# ---------------------------------------------------------------- the castle interior
func _part_castle_inside() -> void:
	print("[9] inside the castle")
	Router.go_now("castle", {"skipintro": true})
	await _scene_ready("castle")
	check(_find("castle_door") != null, "the garden gate leads inside the castle")
	Router.go_now("castle_inside", {"skipintro": true})
	await _scene_ready("castle_inside")
	var level: Node = Router.current
	var player: Player = level.player
	for id in ["front_door", "music_box", "painting", "throne", "mirror", "bed", "toy_box", "oven", "cookie_jar"]:
		check(_find(id) != null, "room toy exists: " + id)
	check(level.lumi_w != null, "Lumi wanders the halls once she lives here")
	# walk the whole hallway: four rooms, no walls in the way, no falling
	player.teleport(Vector3(3.0, 0.3, 0))
	await _walk(player, 1.0, 12.5)
	check(player.global_position.x > level.ROOM_W * 3.0 + 2.0 and player.global_position.x < level.ROOM_W * 4.0 and player.global_position.y > -1.0, "walked through every doorway to the kitchen and stopped at its wall (x=%.1f)" % player.global_position.x)
	await _use(level, player, "oven")
	await _until(func(): return level.cake_baked, 20.0, "cake")
	check(level.cake_baked, "baked a rainbow cake")
	await _use(level, player, "throne")
	await _until(func(): return level.throne_used and not player.frozen and not player.is_gliding(), 40.0, "throne")
	check(level.throne_used and absf(player.global_position.z) < 0.01 and player.global_position.y > -0.5, "sat on the throne and came back to the floor (y=%.2f)" % player.global_position.y)
	await _use(level, player, "bed")
	await _until(func(): return level.naps > 0 and not player.frozen and not player.is_gliding(), 40.0, "nap")
	check(level.naps > 0 and absf(player.global_position.z) < 0.01, "took a nap and woke up on the floor")
	var stars_before := GameState.stars()
	await _use(level, player, "painting")
	await _until(func(): return GameState.stars() > stars_before, 20.0, "secret star")
	check(GameState.secret_found("castle_painting"), "found the secret behind the painting")
	await _use(level, player, "front_door")
	await _until(func(): return Router.current_id == "castle", 30.0, "back to the garden")
	check(Router.current_id == "castle", "the front door leads back to the garden")


func _use(level: Node, player: Player, id: String) -> void:
	var it := _find(id)
	if it == null:
		failures += 1
		printerr("  missing interactable ", id)
		return
	await _until(func(): return not player.controls_locked() and not level._story_busy, 30.0, "free for " + id)
	player.teleport(Vector3(it.global_position.x - 0.8, 0.3, 0))
	await _frames(6)
	await _until(func(): return player.focus == it, 10.0, "focus " + id)
	player.try_act()
	await _frames(3)


# ---------------------------------------------------------------- voice
func _part_voice() -> void:
	print("[10] every line has a voice path")
	var est: float = Audio.play_voice({"id": "no_such_line", "character": "narrator", "text": "Hello little princess, shall we go?"})
	check(est > 1.0, "a line without a recording still gets a spoken-length wait (%.1fs)" % est)
	check(bool(ProjectSettings.get_setting("audio/general/text_to_speech", false)), "text-to-speech is enabled in the project")
	check(InputMap.action_has_event("jump", _key(KEY_UP)), "the UP arrow jumps")
	check(InputMap.action_has_event("jump", _key(KEY_SPACE)), "space still jumps")


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e
