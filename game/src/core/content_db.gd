extends Node
## Loads every data-driven definition (characters, quests, dialogue, mini adventures, world) from res://data.
## Adding content = adding JSON. No gameplay code needs to change.

const DATA := "res://data"

var characters: Dictionary = {}     # id -> definition
var quests: Dictionary = {}         # id -> definition
var minigames: Dictionary = {}      # id -> definition
var regions: Dictionary = {}        # id -> definition (world map)
var castle_features: Dictionary = {}# id -> definition
var customization: Dictionary = {}
var progression: Dictionary = {}
var sequences: Dictionary = {}      # dialogue sequence id -> Array[line]
var lines: Dictionary = {}          # line id -> line (with resolved defaults)
var voices: Dictionary = {}         # character id -> voice key

var errors: PackedStringArray = []


func _ready() -> void:
	reload()


func reload() -> void:
	characters.clear(); quests.clear(); minigames.clear(); regions.clear()
	castle_features.clear(); sequences.clear(); lines.clear(); errors.clear()
	for f in _files("characters"):
		var d := _read(f)
		if d.has("id"): characters[d.id] = d
	for f in _files("quests"):
		var d := _read(f)
		if d.has("id"): quests[d.id] = d
	for f in _files("minigames"):
		var d := _read(f)
		if d.has("id"): minigames[d.id] = d
	var world := _read(DATA + "/world/world.json")
	for r in world.get("regions", []):
		regions[r.id] = r
	for c in world.get("castle_features", []):
		castle_features[c.id] = c
	customization = _read(DATA + "/customization.json")
	progression = _read(DATA + "/progression.json")
	for f in _files("dialogue"):
		_load_dialogue(_read(f), f)
	validate()


# ---- accessors --------------------------------------------------------------
func character(id: String) -> Dictionary: return characters.get(id, {})
func quest(id: String) -> Dictionary: return quests.get(id, {})
func sequence(id: String) -> Array: return sequences.get(id, [])
func line(id: String) -> Dictionary: return lines.get(id, {})
func minigame(id: String) -> Dictionary: return minigames.get(id, {})


func character_color(id: String) -> Color:
	var c: Dictionary = character(id)
	return Color.html(c.get("ui_color", "#ff9ad5"))


# ---- loading helpers --------------------------------------------------------
func _files(sub: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(DATA + "/" + sub)
	if dir == null:
		return out
	for f in dir.get_files():
		# exported builds may list ".remap"/".import" variants; only accept plain json
		if f.ends_with(".json"):
			out.append(DATA + "/" + sub + "/" + f)
	out.sort()
	return out


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("missing data file: " + path)
		return {}
	var txt := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("bad JSON (expected object): " + path)
		return {}
	return parsed


func _load_dialogue(d: Dictionary, path: String) -> void:
	var defaults: Dictionary = d.get("defaults", {})
	for seq_id in d.get("sequences", {}):
		var arr: Array = []
		for raw in d.sequences[seq_id]:
			var ln: Dictionary = defaults.duplicate()
			ln.merge(raw, true)
			ln["sequence"] = seq_id
			if not ln.has("id"):
				errors.append("%s: line without id in sequence %s" % [path, seq_id])
				continue
			if lines.has(ln.id):
				errors.append("duplicate dialogue id: " + ln.id)
			lines[ln.id] = ln
			arr.append(ln)
		sequences[seq_id] = arr


## Cross-reference check. Run by the smoke test; also logged at startup.
func validate() -> void:
	for id in quests:
		var q: Dictionary = quests[id]
		if q.has("character") and not characters.has(q.character):
			errors.append("quest %s references unknown character %s" % [id, q.character])
		for step in q.get("steps", []):
			for key in ["dialogue_on_start", "dialogue_on_complete"]:
				if step.has(key) and not sequences.has(step[key]):
					errors.append("quest %s step %s: unknown dialogue %s" % [id, step.get("id", "?"), step[key]])
			var hint: Dictionary = step.get("hint", {})
			if hint.has("voice") and not sequences.has(hint.voice):
				errors.append("quest %s step %s: unknown hint sequence %s" % [id, step.get("id", "?"), hint.voice])
	for id in characters:
		var c: Dictionary = characters[id]
		for key in ["ask_dialogue"]:
			var fq: Dictionary = c.get("friendship_quest", {})
			if fq.has(key) and not sequences.has(fq[key]):
				errors.append("character %s: unknown dialogue %s" % [id, fq[key]])
		var fq2: Dictionary = c.get("friendship_quest", {})
		if fq2.has("quest") and not quests.has(fq2.quest):
			errors.append("character %s: unknown friendship quest %s" % [id, fq2.quest])
		var rq: Dictionary = c.get("rescue", {})
		if rq.has("quest") and not quests.has(rq.quest):
			errors.append("character %s: unknown rescue quest %s" % [id, rq.quest])
		for mg in c.get("mini_adventures", []):
			if not minigames.has(mg):
				errors.append("character %s: unknown mini adventure %s" % [id, mg])
	for e in errors:
		push_warning("[Content] " + e)
