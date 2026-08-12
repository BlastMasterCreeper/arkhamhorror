class_name TriggeredAbilityDescriptor
extends RefCounted

enum AbilityKind {
	FORCED,
	REACTION,
	FREE_TRIGGERED,
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
## Free：`during_your_turn` | `any_player_window`（空 = any）。
var window: StringName = &""


func is_player_initiated() -> bool:
	return (
		ability_kind == AbilityKind.REACTION
		or ability_kind == AbilityKind.FREE_TRIGGERED
	)


func provokes_aoo() -> bool:
	return ability_kind == AbilityKind.ACTION


func uses_timing_handler() -> bool:
	return (
		ability_kind == AbilityKind.FORCED
		or ability_kind == AbilityKind.REACTION
	)


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


static func free_triggered(
	controller_id: StringName,
	composition: CompositionNode,
	window: StringName = &"any_player_window",
	source_id: StringName = &"",
	definition_id: StringName = &""
) -> TriggeredAbilityDescriptor:
	var desc := TriggeredAbilityDescriptor.new()
	desc.id = StringName("free_%d" % Time.get_ticks_msec())
	desc.ability_kind = AbilityKind.FREE_TRIGGERED
	desc.controller_id = controller_id
	desc.composition = composition
	desc.window = window
	desc.source_id = source_id
	desc.definition_id = definition_id
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
	desc.window = unit.get("window", &"") as StringName
	desc.ability_kind = _parse_kind(unit.get("ability_kind", &"forced"))
	return desc


static func _parse_kind(raw: Variant) -> AbilityKind:
	var name := String(raw)
	match name:
		"reaction":
			return AbilityKind.REACTION
		"free", "fast":
			return AbilityKind.FREE_TRIGGERED
		"action":
			return AbilityKind.ACTION
		_:
			return AbilityKind.FORCED
