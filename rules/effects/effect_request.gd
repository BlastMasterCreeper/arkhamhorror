class_name EffectRequest
extends RefCounted

var op: AhcEnums.EffectOp = AhcEnums.EffectOp.CUSTOM
var source_id: StringName = &""
var controller_id: StringName = &""
var targets: Array = []
var amount: int = 0
var options: Dictionary = {}


static func draw_cards(controller_id: StringName, amount: int = 1) -> EffectRequest:
	var request := EffectRequest.new()
	request.op = AhcEnums.EffectOp.DRAW_CARDS
	request.controller_id = controller_id
	request.amount = amount
	return request


static func gain_resource(controller_id: StringName, amount: int = 1) -> EffectRequest:
	var request := EffectRequest.new()
	request.op = AhcEnums.EffectOp.GAIN_RESOURCE
	request.controller_id = controller_id
	request.amount = amount
	return request
