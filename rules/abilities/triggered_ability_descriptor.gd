class_name TriggeredAbilityDescriptor
extends RefCounted

enum AbilityKind {
	FORCED,
	REACTION,
	FREE,
	ACTION,
}

var id: StringName = &""
var match_kind: StringName = &""
var phase: AhcEnums.SequencePhase = AhcEnums.SequencePhase.AFTER
var ability_kind: AbilityKind = AbilityKind.FORCED
var controller_id: StringName = &""
var source_id: StringName = &""
var definition_id: StringName = &""
var composition: CompositionNode = null
var resource_cost: int = 0
var action_cost: int = 0
var optional: bool = false


func is_player_initiated() -> bool:
	return ability_kind == AbilityKind.REACTION


func provokes_aoo() -> bool:
	return ability_kind == AbilityKind.ACTION


static func forced(
	match_kind: StringName,
	phase: AhcEnums.SequencePhase,
	controller_id: StringName,
	composition: CompositionNode,
	source_id: StringName = &"",
	definition_id: StringName = &""
) -> TriggeredAbilityDescriptor:
	var desc := TriggeredAbilityDescriptor.new()
	desc.id = StringName("trig_%s_%d" % [match_kind, Time.get_ticks_msec()])
	desc.match_kind = match_kind
	desc.phase = phase
	desc.ability_kind = AbilityKind.FORCED
	desc.controller_id = controller_id
	desc.composition = composition
	desc.source_id = source_id
	desc.definition_id = definition_id
	return desc


static func reaction(
	match_kind: StringName,
	phase: AhcEnums.SequencePhase,
	controller_id: StringName,
	composition: CompositionNode,
	source_id: StringName = &"",
	definition_id: StringName = &""
) -> TriggeredAbilityDescriptor:
	var desc := forced(
		match_kind, phase, controller_id, composition, source_id, definition_id
	)
	desc.ability_kind = AbilityKind.REACTION
	return desc


static func from_registry_unit(
	unit: Dictionary,
	controller_id: StringName,
	card_id: StringName,
	definition_id: StringName,
	bind: AbilityBindContext
) -> TriggeredAbilityDescriptor:
	var builder: Callable = unit.get("builder", Callable())
	var composition: CompositionNode = null
	if builder.is_valid():
		composition = builder.call(bind)
	var desc := TriggeredAbilityDescriptor.new()
	desc.id = unit.get("ability_id", &"") as StringName
	desc.match_kind = unit.get("match_kind", &"") as StringName
	desc.phase = int(unit.get("phase", AhcEnums.SequencePhase.AFTER)) as AhcEnums.SequencePhase
	desc.controller_id = controller_id
	desc.source_id = card_id
	desc.definition_id = definition_id
	desc.composition = composition
	desc.resource_cost = int(unit.get("resource_cost", 0))
	desc.action_cost = int(unit.get("action_cost", 0))
	desc.optional = bool(unit.get("optional", false))
	desc.ability_kind = _parse_kind(unit.get("ability_kind", &"forced"))
	return desc


static func _parse_kind(raw: Variant) -> AbilityKind:
	var name := String(raw)
	match name:
		"reaction":
			return AbilityKind.REACTION
		"free":
			return AbilityKind.FREE
		"action":
			return AbilityKind.ACTION
		_:
			return AbilityKind.FORCED
