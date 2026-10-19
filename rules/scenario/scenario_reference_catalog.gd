class_name ScenarioReferenceCatalog
extends RefCounted

## 加载 / 缓存冒险参考卡定义（JSON-first；Script override 预留）。

const PATH_FMT := "res://data/scenarios/%s/reference.json"

static var _cache: Dictionary = {}


static func load_for_scenario(scenario_id: StringName) -> ScenarioReferenceDefinition:
	if scenario_id == &"":
		return null
	if _cache.has(scenario_id):
		return _cache[scenario_id] as ScenarioReferenceDefinition
	var path := PATH_FMT % String(scenario_id)
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var def := ScenarioReferenceDefinition.from_dict(parsed as Dictionary)
	_cache[scenario_id] = def
	return def


static func clear_cache() -> void:
	_cache.clear()
