extends Node
## Indirection between gameplay code and art. Procedural stand-ins are used until a real model exists.
##
##   Assets.model("res://assets/models/props/oak_tree.glb")  -> Node3D instance, or null if not authored yet.
##
## Drop a .glb at the path named in data/characters/*.json ("visual.model") or in an asset manifest and the
## game uses it automatically; the procedural version is only a fallback. See docs/ASSET_PIPELINE.md.

var _cache: Dictionary = {}


func has_model(path: String) -> bool:
	return path != "" and ResourceLoader.exists(path)


func model(path: String) -> Node3D:
	if not has_model(path):
		return null
	if not _cache.has(path):
		_cache[path] = load(path)
	var res: Variant = _cache[path]
	if res is PackedScene:
		return (res as PackedScene).instantiate() as Node3D
	return null
