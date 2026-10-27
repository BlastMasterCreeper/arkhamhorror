class_name AbilityResponsePreferences
extends RefCounted

## 会话级可选响应偏好（16 §7.1.3）：按 definition_id|ability_id（或 source 回退）索引。

var _modes: Dictionary = {}


func clear() -> void:
	_modes.clear()


func set_mode(
	mode: AhcEnums.AbilityResponseMode,
	definition_id: StringName = &"",
	ability_id: StringName = &"",
	source_id: StringName = &""
) -> void:
	var key := pref_key(definition_id, ability_id, source_id)
	if key == "":
		return
	_modes[key] = mode


func get_mode(
	definition_id: StringName = &"",
	ability_id: StringName = &"",
	source_id: StringName = &""
) -> AhcEnums.AbilityResponseMode:
	for key in candidate_keys(definition_id, ability_id, source_id):
		if _modes.has(key):
			return _modes[key] as AhcEnums.AbilityResponseMode
	return AhcEnums.AbilityResponseMode.ASK


func pref_key(
	definition_id: StringName,
	ability_id: StringName,
	source_id: StringName
) -> String:
	var keys := candidate_keys(definition_id, ability_id, source_id)
	if keys.is_empty():
		return ""
	return keys[0]


func candidate_keys(
	definition_id: StringName,
	ability_id: StringName,
	source_id: StringName
) -> Array[String]:
	var out: Array[String] = []
	if definition_id != &"" and ability_id != &"":
		out.append("%s|%s" % [definition_id, ability_id])
	if source_id != &"" and ability_id != &"":
		out.append("%s|%s" % [source_id, ability_id])
	if source_id != &"":
		out.append(str(source_id))
	if ability_id != &"":
		out.append(str(ability_id))
	return out


func mode_for_handler(handler: SequenceHandler) -> AhcEnums.AbilityResponseMode:
	if handler == null:
		return AhcEnums.AbilityResponseMode.ASK
	return get_mode(handler.definition_id, handler.ability_id, handler.source_id)
