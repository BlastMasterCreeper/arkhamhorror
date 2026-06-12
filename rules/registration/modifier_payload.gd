class_name ModifierPayload
extends RefCounted

var stat: AhcEnums.StatRef = AhcEnums.StatRef.SKILL_WILLPOWER
var op: AhcEnums.ModOp = AhcEnums.ModOp.ADD
var value: int = 0


static func add_skill(stat: AhcEnums.StatRef, amount: int) -> ModifierPayload:
	var p := ModifierPayload.new()
	p.stat = stat
	p.op = AhcEnums.ModOp.ADD
	p.value = amount
	return p
