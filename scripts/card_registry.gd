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
