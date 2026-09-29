extends Node
## Single source of truth for player progress + the character lifecycle.
##
## CHARACTER LIFECYCLE (the architectural spine of the game):
##   UNKNOWN -> DISCOVERED -> RESCUED -> AT_CASTLE -> FRIENDS -> QUEST_READY -> QUEST_DONE(resident)
## Each transition is driven by data (res://data/characters/*.json) and announced via Events.

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

enum Stage { UNKNOWN, DISCOVERED, RESCUED, AT_CASTLE, FRIENDS, QUEST_READY, QUEST_DONE }
const STAGE_NAMES := ["unknown", "discovered", "rescued", "at_castle", "friends", "quest_ready", "quest_done"]

var data: Dictionary = {}
var slot_active := false           # true once a profile exists in memory
var _autosave := true


func _ready() -> void:
	new_game(false)


# ---------------------------------------------------------------------------
# lifecycle of a profile
# ---------------------------------------------------------------------------
func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"created": false,
		"appearance": Content.customization.get("default_appearance", {}).duplicate(true) if Content.customization.size() > 0 else {},
		"stars": 0,
		"powers": ["flower", "animals", "starlight"],
		"characters": {},
		"quests": {},
		"castle": {"features": []},
		"dialogue_seen": {},
		"minigames": {},
		"flags": {},
		"secrets": [],
	}


func new_game(save_now: bool = true) -> void:
	data = default_data()
	slot_active = false
	if save_now:
		save()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[GameState] corrupt save, ignoring")
		return false
	data = _migrate(parsed)
	slot_active = true
	return true


func save() -> void:
	if not _autosave:
		return
	var tmp := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("[GameState] cannot write save")
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	# atomic-ish replace so a crash never leaves a half-written save
	var d := DirAccess.open("user://")
	if d:
		if d.file_exists("save.json"):
			d.remove("save.json")
		d.rename("save.json.tmp", "save.json")


func reset_progress() -> void:
	var appearance: Dictionary = data.get("appearance", {})
	new_game(false)
	data.appearance = appearance   # keep the princess she made; only the story resets
	data.created = true
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	save()


func set_autosave(v: bool) -> void:
	_autosave = v


func _migrate(d: Dictionary) -> Dictionary:
	var base := default_data()
	for k in base:
		if not d.has(k):
			d[k] = base[k]
	d["version"] = SAVE_VERSION
	return d


# ---------------------------------------------------------------------------
# appearance
# ---------------------------------------------------------------------------
func appearance() -> Dictionary:
	return data.appearance


func set_appearance(a: Dictionary) -> void:
	data.appearance = a.duplicate(true)
	data.created = true
	slot_active = true
	save()


# ---------------------------------------------------------------------------
# stars & crown
# ---------------------------------------------------------------------------
func stars() -> int:
	return int(data.stars)


func add_stars(n: int, world_pos: Vector3 = Vector3.ZERO, reason: String = "") -> void:
	if n <= 0:
		return
	var old_level := crown_level()
	data.stars = int(data.stars) + n
	Events.star_earned.emit(n, world_pos, reason)
	Events.stars_changed.emit(int(data.stars), n)
	var lvl := crown_level()
	if lvl != old_level:
		Events.crown_level_changed.emit(lvl)
	save()


## Crown evolves visibly: 0 plain -> 1 lit stars -> 2 gems -> 3 sparkles -> 4 butterflies -> 5 rainbow
func crown_level() -> int:
	var thresholds: Array = Content.progression.get("crown_thresholds", [0, 1, 4, 8, 14, 22])
	var lvl := 0
	for i in thresholds.size():
		if stars() >= int(thresholds[i]):
			lvl = i
	return lvl


func crown_progress() -> Dictionary:
	## {level, into, needed} for a "next jewel" ring in the HUD (no numbers shown to the child)
	var thresholds: Array = Content.progression.get("crown_thresholds", [0, 1, 4, 8, 14, 22])
	var lvl := crown_level()
	if lvl >= thresholds.size() - 1:
		return {"level": lvl, "into": 1, "needed": 1}
	var lo := int(thresholds[lvl]); var hi := int(thresholds[lvl + 1])
	return {"level": lvl, "into": stars() - lo, "needed": hi - lo}


# ---------------------------------------------------------------------------
# powers
# ---------------------------------------------------------------------------
func has_power(p: String) -> bool:
	return p in data.powers


func grant_power(p: String) -> void:
	if not has_power(p):
		data.powers.append(p)
		Events.power_unlocked.emit(p)
		save()


func powers() -> Array:
	return data.powers


# ---------------------------------------------------------------------------
# characters (lifecycle)
# ---------------------------------------------------------------------------
func _char(id: String) -> Dictionary:
	if not data.characters.has(id):
		data.characters[id] = {"stage": Stage.UNKNOWN, "care": {}, "friendship": 0, "minigame_plays": 0}
	return data.characters[id]


func stage(id: String) -> int:
	return int(_char(id).stage)


func stage_name(id: String) -> String:
	return STAGE_NAMES[stage(id)]


func set_stage(id: String, new_stage: int) -> void:
	var c := _char(id)
	var old := int(c.stage)
	if new_stage == old:
		return
	c.stage = new_stage
	Events.character_stage_changed.emit(id, old, new_stage)
	save()


func advance_stage(id: String, at_least: int) -> void:
	if stage(id) < at_least:
		set_stage(id, at_least)


func is_at_castle(id: String) -> bool:
	return stage(id) >= Stage.AT_CASTLE


func is_resident(id: String) -> bool:
	return stage(id) >= Stage.QUEST_DONE


## Which characters currently live in the castle (for populating the hub / mini adventures)
func castle_residents() -> Array:
	var out: Array = []
	for id in Content.characters:
		if is_at_castle(id):
			out.append(id)
	return out


# ---- care -----------------------------------------------------------------
func care_count(id: String, need: String) -> int:
	return int(_char(id).care.get(need, 0))


## Registers one care action. Returns true if the need just became satisfied.
func record_care(id: String, need: String) -> bool:
	var c := _char(id)
	var def := Content.character(id)
	var target := 1
	for n in def.get("care", {}).get("needs", []):
		if n.id == need:
			target = int(n.get("count", 1))
	var before := int(c.care.get(need, 0))
	c.care[need] = before + 1
	var done := before < target and before + 1 >= target
	save()
	return done


func care_complete(id: String) -> bool:
	var def := Content.character(id)
	for n in def.get("care", {}).get("needs", []):
		if care_count(id, n.id) < int(n.get("count", 1)):
			return false
	return true


func friendship_hearts(id: String) -> int:
	## 0..N hearts = number of satisfied care needs (child sees hearts, not numbers)
	var def := Content.character(id)
	var h := 0
	for n in def.get("care", {}).get("needs", []):
		if care_count(id, n.id) >= int(n.get("count", 1)):
			h += 1
	return h


# ---------------------------------------------------------------------------
# quests
# ---------------------------------------------------------------------------
func quest_status(id: String) -> String:
	return String(data.quests.get(id, {}).get("status", "new"))   # new / active / done


func set_quest_status(id: String, status: String) -> void:
	if not data.quests.has(id):
		data.quests[id] = {}
	data.quests[id].status = status
	save()


# ---------------------------------------------------------------------------
# castle
# ---------------------------------------------------------------------------
func feature_unlocked(id: String) -> bool:
	return id in data.castle.features


func unlock_feature(id: String) -> void:
	if not feature_unlocked(id):
		data.castle.features.append(id)
		Events.castle_feature_unlocked.emit(id)
		save()


# ---------------------------------------------------------------------------
# misc
# ---------------------------------------------------------------------------
func flag(name: String, default: Variant = false) -> Variant:
	return data.flags.get(name, default)


func set_flag(name: String, value: Variant = true) -> void:
	data.flags[name] = value
	save()


func dialogue_seen(line_id: String) -> bool:
	return data.dialogue_seen.has(line_id)


func mark_dialogue_seen(line_id: String) -> void:
	data.dialogue_seen[line_id] = true


func secret_found(id: String) -> bool:
	return id in data.secrets


func add_secret(id: String) -> void:
	if not secret_found(id):
		data.secrets.append(id)
		save()


func record_minigame(id: String, stars_collected: int) -> void:
	var m: Dictionary = data.minigames.get(id, {"plays": 0, "best": 0})
	m.plays = int(m.plays) + 1
	m.best = maxi(int(m.best), stars_collected)
	data.minigames[id] = m
	save()


func minigame_unlocked(id: String) -> bool:
	## Unlocked when a character that lists this mini adventure has completed the quest stage required.
	for cid in Content.characters:
		var c: Dictionary = Content.characters[cid]
		if id in c.get("mini_adventures", []):
			if stage(cid) >= int(c.get("mini_adventure_unlock_stage", Stage.QUEST_DONE)):
				return true
	return false
