class_name InitiationIntent
extends RefCounted

var controller_id: StringName = &""
var composition: CompositionNode = null


static func create(controller_id: StringName, composition: CompositionNode) -> InitiationIntent:
	var intent := InitiationIntent.new()
	intent.controller_id = controller_id
	intent.composition = composition
	return intent
