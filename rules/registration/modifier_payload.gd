class_name ModifierPayload
extends RefCounted

var stat: AhcEnums.StatRef = AhcEnums.StatRef.SKILL_WILLPOWER
var op: AhcEnums.ModOp = AhcEnums.ModOp.ADD
var value: int = 0
var condition: Condition = null


static func add_skill(stat: AhcEnums.StatRef, amount: int) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.stat = stat
	p.op = AhcEnums.ModOp.ADD
	p.value = amount
	return p


static func add_resource_gain(amount: int, apply_condition: Condition = null) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.stat = AhcEnums.StatRef.RESOURCE_GAIN_AMOUNT
	p.op = AhcEnums.ModOp.ADD
	p.value = amount
	p.condition = apply_condition
	return p


static func reduce_initiation_resource_cost(
	amount: int,
	apply_condition: Condition = null
) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.stat = AhcEnums.StatRef.INITIATION_RESOURCE_COST
	p.op = AhcEnums.ModOp.SUB
	p.value = amount
	p.condition = apply_condition
	return p


static func reduce_initiation_action_cost(
	amount: int,
	apply_condition: Condition = null
) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.stat = AhcEnums.StatRef.INITIATION_ACTION_COST
	p.op = AhcEnums.ModOp.SUB
	p.value = amount
	p.condition = apply_condition
	return p
