class_name AbilityUnitRef
extends RefCounted

## 译后序列 ↔ 原文能力单元的归属；不承载效果自然语言。
var flow_id: StringName = &""
var definition_id: StringName = &""
var ability_id: StringName = &""
var instance_id: StringName = &""


static func from_card_ability(
	p_flow_id: StringName,
	p_definition_id: StringName,
	p_ability_id: StringName,
	p_instance_id: StringName = &""
) -> AbilityUnitRef:
	var ref := AbilityUnitRef.new()
	ref.flow_id = p_flow_id
	ref.definition_id = p_definition_id
	ref.ability_id = p_ability_id
	ref.instance_id = p_instance_id
	return ref


static func from_framework(p_flow_id: StringName, p_ability_id: StringName = &"") -> AbilityUnitRef:
	var ref := AbilityUnitRef.new()
	ref.flow_id = p_flow_id
	ref.ability_id = p_ability_id
	return ref


func to_log_dict() -> Dictionary:
	return {
		"flow_id": flow_id,
		"definition_id": definition_id,
		"ability_id": ability_id,
		"instance_id": instance_id,
	}
