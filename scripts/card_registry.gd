class_name CardRegistry
extends RefCounted

static var _definitions: Dictionary = {}
static var _revelations: Dictionary = {}


static func register_definition(definition_id: StringName, data: Dictionary = {}) -> void:
	_definitions[definition_id] = data


## builder: Callable(AbilityBindContext) -> CompositionNode
static func register_revelation(
	definition_id: StringName,
	ability_id: StringName,
	builder: Callable
) -> void:
	if not _revelations.has(definition_id):
		_revelations[definition_id] = []
	(_revelations[definition_id] as Array).append(
		{
			"ability_id": ability_id,
			"builder": builder,
		}
	)


static func revelation_units_at(definition_id: StringName) -> Array:
	return (_revelations.get(definition_id, []) as Array).duplicate()


static func has_revelation(definition_id: StringName) -> bool:
	return not revelation_units_at(definition_id).is_empty()


## enter_hand 时点的物理 zone（显现唯一入口；与来源/方式无关）。
static func enter_hand_zone(definition_id: StringName) -> AhcEnums.Zone:
	var data: Dictionary = _definitions.get(definition_id, {})
	return data.get("enter_zone", AhcEnums.Zone.HAND) as AhcEnums.Zone


## 显现后仍在 limbo 时弃入的牌堆：`owner_discard` | `encounter_discard`。
static func limbo_discard_pile(definition_id: StringName) -> StringName:
	var data: Dictionary = _definitions.get(definition_id, {})
	return data.get("limbo_discard_pile", &"owner_discard") as StringName


static func has_keyword(definition_id: StringName, keyword: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	var keywords: Array = data.get("keywords", [])
	for kw in keywords:
		if kw == keyword:
			return true
	return false


static func card_type(definition_id: StringName) -> StringName:
	var data: Dictionary = _definitions.get(definition_id, {})
	return data.get("card_type", &"treachery") as StringName


static func spawn_spec(definition_id: StringName) -> SpawnInstructionSpec:
	var data: Dictionary = _definitions.get(definition_id, {})
	var spec = data.get("spawn_instruction", null)
	if spec is SpawnInstructionSpec:
		return spec
	return SpawnInstructionSpec.framework_default()


static func is_aloof(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("aloof", false):
		return true
	return has_keyword(definition_id, &"aloof")


static func is_hidden(definition_id: StringName) -> bool:
	## 卡牌是否带 **隐私（Hidden）** 关键词。见 docs/design/15-timing-entry-catalog.md §17.4.3。
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("hidden", false):
		return true
	return has_keyword(definition_id, &"hidden")


static func is_weakness(definition_id: StringName) -> bool:
	var data: Dictionary = _definitions.get(definition_id, {})
	if data.get("is_weakness", false):
		return true
	return has_keyword(definition_id, &"weakness")


static func enemy_stats(definition_id: StringName) -> Dictionary:
	var data: Dictionary = _definitions.get(definition_id, {})
	var stats: Variant = data.get("enemy", {})
	if stats is Dictionary:
		return stats
	return {}


static func prey_spec(definition_id: StringName) -> PreyInstructionSpec:
	var data: Dictionary = _definitions.get(definition_id, {})
	var spec = data.get("prey_instruction", null)
	if spec is PreyInstructionSpec:
		return spec
	return null
