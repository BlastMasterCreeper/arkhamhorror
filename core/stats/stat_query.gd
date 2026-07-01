class_name StatQuery
extends RefCounted

var key: AhcEnums.StatKey = AhcEnums.StatKey.TURN_ACTION_SPEND_COUNT
var op: AhcEnums.StatCompareOp = AhcEnums.StatCompareOp.GE
var operand: int = 0


static func turn_action_spend_count_ge(count: int) -> StatQuery:
	var q := StatQuery.new()
	q.key = AhcEnums.StatKey.TURN_ACTION_SPEND_COUNT
	q.op = AhcEnums.StatCompareOp.GE
	q.operand = count
	return q


static func turn_action_spend_empty() -> StatQuery:
	var q := StatQuery.new()
	q.key = AhcEnums.StatKey.TURN_ACTION_SPEND_EMPTY
	q.op = AhcEnums.StatCompareOp.EQ
	q.operand = 0
	return q


func snapshot_key(scope: StatScope) -> StringName:
	return scope.projection_key(key)


func interest_token(scope: StatScope) -> StringName:
	return scope.interest_token(key)


func evaluate_value(value: Variant) -> bool:
	match key:
		AhcEnums.StatKey.TURN_ACTION_SPEND_COUNT:
			var n := int(value)
			match op:
				AhcEnums.StatCompareOp.GE:
					return n >= operand
				AhcEnums.StatCompareOp.EQ:
					return n == operand
				AhcEnums.StatCompareOp.LE:
					return n <= operand
		AhcEnums.StatKey.TURN_ACTION_SPEND_EMPTY:
			return int(value) == 0
	return true
