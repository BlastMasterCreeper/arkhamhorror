class_name InitiationIntent
extends RefCounted

enum Kind {
	ABILITY,
	PLAY_CARD,
}

var kind: Kind = Kind.ABILITY
var controller_id: StringName = &""
var card_id: StringName = &""
var source_id: StringName = &""
var ability_id: StringName = &""
var composition: CompositionNode = null
var resource_cost: int = 0
var action_cost: int = 0
var modified_resource_cost: int = 0
var modified_action_cost: int = 0
var provokes_aoo: bool = false
var aoo_action_type: AhcEnums.ActionType = AhcEnums.ActionType.ACTIVATE


static func create(controller_id: StringName, composition: CompositionNode) -> InitiationIntent:
	return ability(controller_id, composition)


static func ability(controller_id: StringName, composition: CompositionNode) -> InitiationIntent:
	var intent := InitiationIntent.new()
	intent.kind = Kind.ABILITY
	intent.controller_id = controller_id
	intent.composition = composition
	return intent


static func action_ability(
	controller_id: StringName,
	composition: CompositionNode,
	action_cost: int = 1,
	aoo_action_type: AhcEnums.ActionType = AhcEnums.ActionType.ACTIVATE
) -> InitiationIntent:
	var intent := ability(controller_id, composition)
	intent.provokes_aoo = true
	intent.action_cost = action_cost
	intent.aoo_action_type = aoo_action_type
	return intent


static func play_card(
	controller_id: StringName,
	card_id: StringName,
	resource_cost: int = 0,
	action_cost: int = 0,
	composition: CompositionNode = null
) -> InitiationIntent:
	var intent := InitiationIntent.new()
	intent.kind = Kind.PLAY_CARD
	intent.controller_id = controller_id
	intent.card_id = card_id
	intent.composition = composition
	intent.resource_cost = resource_cost
	intent.action_cost = action_cost
	intent.provokes_aoo = true
	intent.aoo_action_type = AhcEnums.ActionType.ACTIVATE
	return intent
