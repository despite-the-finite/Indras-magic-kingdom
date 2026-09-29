class_name DevTools
## Developer conveniences: CLI args, progress presets, headless smoke check and screenshot capture.
## None of this ships in the player-facing flow (it only runs when flags are passed).

static func parse_args(raw: PackedStringArray) -> Dictionary:
	var out := {}
	for a in raw:
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			out[kv[0]] = kv[1] if kv.size() > 1 else true
	return out


## Progress presets so any part of the game can be reached/tested directly.
static func apply_preset(name: String) -> void:
	GameState.set_autosave(false)   # dev presets never overwrite a real save
	GameState.new_game(false)
	var d := GameState.data
	d.created = true
	match name:
		"fresh":
			pass
		"rescued":            # just freed Lumi
			GameState.set_stage("lumi", GameState.Stage.RESCUED)
			d.stars = 4
		"at_castle":          # Lumi lives in the stable, no care yet
			GameState.set_stage("lumi", GameState.Stage.AT_CASTLE)
			GameState.unlock_feature("unicorn_stable")
			d.stars = 4
		"cared":              # care done, friendship ready for the ask
			GameState.set_stage("lumi", GameState.Stage.AT_CASTLE)
			GameState.unlock_feature("unicorn_stable")
			for n in Content.character("lumi").care.needs:
				d.characters.lumi.care[n.id] = int(n.count)
			d.stars = 4
		"quest_ready":
			GameState.set_stage("lumi", GameState.Stage.QUEST_READY)
			GameState.unlock_feature("unicorn_stable")
			for n in Content.character("lumi").care.needs:
				d.characters.lumi.care[n.id] = int(n.count)
			d.stars = 4
		"quest_done":
			GameState.set_stage("lumi", GameState.Stage.QUEST_DONE)
			GameState.unlock_feature("unicorn_stable")
			GameState.grant_power("rainbow")
			for n in Content.character("lumi").care.needs:
				d.characters.lumi.care[n.id] = int(n.count)
			d.stars = 10
		"crown5":
			d.stars = 30
	GameState.slot_active = true


static func attach_playthrough(tree: SceneTree) -> void:
	var n := Node.new()
	n.set_script(load("res://src/dev/playthrough.gd"))
	n.name = "Playthrough"
	tree.root.add_child.call_deferred(n)


static func attach_shot(tree: SceneTree, args: Dictionary) -> void:
	var n := Node.new()
	n.set_script(load("res://src/dev/shot_node.gd"))
	n.set("path", String(args.shot))
	n.set("delay", float(args.get("shot-delay", 2.5)))
	n.set("quit_after", not args.has("shot-stay"))
	tree.root.add_child.call_deferred(n)


## `godot --headless --path game -- --check` : validates content and boots every core system.
static func run_smoke_check() -> void:
	var ok := true
	print("[check] characters=%d quests=%d sequences=%d lines=%d minigames=%d" % [
		Content.characters.size(), Content.quests.size(), Content.sequences.size(), Content.lines.size(), Content.minigames.size()])
	if Content.errors.size() > 0:
		ok = false
		for e in Content.errors:
			printerr("[check] CONTENT ERROR: ", e)
	# every hint step must reference a known sequence with audio path convention
	for qid in Content.quests:
		for step in Content.quests[qid].get("steps", []):
			var h: Dictionary = step.get("hint", {})
			for key in ["voice", "voice_alt"]:
				if h.has(key) and Content.sequence(h[key]).is_empty():
					ok = false
					printerr("[check] missing hint sequence: ", h[key])
	for qid in Content.quests:
		var q: Dictionary = Content.quests[qid]
		if not Router.SCENES.has(q.get("level", "")):
			ok = false
			printerr("[check] quest %s has unknown level %s" % [qid, q.get("level", "")])
	print("[check] ", "PASSED" if ok else "FAILED")
	Engine.get_main_loop().quit(0 if ok else 1)
