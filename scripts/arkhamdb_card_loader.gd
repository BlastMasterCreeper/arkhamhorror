class_name ArkhamDbCardLoader
extends RefCounted

const _AbilityCompiler = preload("res://scripts/arkhamdb_ability_compiler.gd")

## 将 `data/arkhamdb/imported/*.json` 载入 CardRegistry（Phase 1–3）。


static func load_imported_file(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("ArkhamDbCardLoader: cannot open %s" % path)
		return 0
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null or not parsed is Dictionary:
		push_warning("ArkhamDbCardLoader: invalid JSON %s" % path)
		return 0
	return load_imported_dict(parsed as Dictionary)


static func load_imported_dict(data: Dictionary) -> int:
	var count := 0
	for key in data.keys():
		if String(key).begins_with("_"):
			continue
		var entry: Variant = data[key]
		if entry is Dictionary:
			var def_id := StringName(String(key))
			CardRegistry.register_definition(def_id, _to_registry_dict(entry as Dictionary, def_id))
			count += 1
	return count


static func load_core_2026() -> int:
	var player := load_imported_file("res://data/arkhamdb/imported/core_2026.json")
	var encounter := load_imported_file("res://data/arkhamdb/imported/core_2026_encounter.json")
	return player + encounter


static func _to_registry_dict(src: Dictionary, definition_id: StringName) -> Dictionary:
	var keywords: Array = src.get("keywords", [])
	var kw_out: Array[StringName] = []
	for kw in keywords:
		kw_out.append(StringName(str(kw)))
	var out := {
		"card_type": StringName(str(src.get("card_type", "treachery"))),
		"title": str(src.get("title", "")),
		"resource_cost": int(src.get("resource_cost", 0)),
		"resource_cost_sentinel": StringName(str(src.get("resource_cost_sentinel", "none"))),
		"is_weakness": bool(src.get("is_weakness", false)),
		"hidden": bool(src.get("hidden", false)),
		"aloof": bool(src.get("aloof", false)),
		"hunter": "hunter" in keywords,
		"retaliate": "retaliate" in keywords,
		"alert": "alert" in keywords,
		"elusive": "elusive" in keywords,
		"massive": "massive" in keywords,
		"permanent": bool(src.get("permanent", false)),
		"victory": int(src.get("victory", 0)),
		"pack_code": StringName(str(src.get("pack_code", ""))),
		"faction_code": StringName(str(src.get("faction_code", ""))),
		"encounter_code": StringName(str(src.get("encounter_code", ""))),
		"text": str(src.get("text", "")),
		"keywords": kw_out,
	}
	if src.has("slot") and str(src.get("slot", "")) != "":
		out["slot"] = StringName(str(src.get("slot")))
	var traits: Array = src.get("traits", [])
	var trait_out: Array[StringName] = []
	for tr in traits:
		trait_out.append(StringName(str(tr)))
	out["traits"] = trait_out
	var hints: Array = src.get("ability_hints", [])
	var hint_out: Array[StringName] = []
	for h in hints:
		hint_out.append(StringName(str(h)))
	out["ability_hints"] = hint_out
	var skills: Variant = src.get("skills_icons", {})
	if skills is Dictionary:
		out["skills_icons"] = skills.duplicate()
	var enemy: Variant = src.get("enemy", {})
	if enemy is Dictionary and not enemy.is_empty():
		out["enemy"] = enemy.duplicate()
	var location: Variant = src.get("location", {})
	if location is Dictionary and not location.is_empty():
		out["location"] = location.duplicate()
	var segments: Variant = src.get("ability_segments", [])
	if segments is Array:
		out["ability_segments"] = segments.duplicate(true)
	var compiled: Variant = src.get("compiled_abilities", [])
	if compiled is Array:
		out["compiled_abilities"] = compiled.duplicate(true)
	ArkhamDbInstructionCompiler.apply_instructions(out, src)
	_AbilityCompiler.apply_to_registry(definition_id, src)
	return out
