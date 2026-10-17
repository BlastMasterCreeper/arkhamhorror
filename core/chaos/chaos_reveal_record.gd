class_name ChaosRevealRecord
extends RefCounted

## 检定/调查作用域内一次「揭示」账本行（可已归袋；Cancel 整枚后无效）。

var token: ChaosToken = null
var kind: AhcEnums.ChaosTokenKind = AhcEnums.ChaosTokenKind.NUMERIC
var source: StringName = &"skill_test" ## skill_test | ability
var scope_id: StringName = &""
var canceled: bool = false
var physically_returned: bool = false


static func from_token(
	token: ChaosToken,
	source: StringName,
	scope_id: StringName
) -> ChaosRevealRecord:
	var rec := ChaosRevealRecord.new()
	rec.token = token
	rec.kind = token.kind if token != null else AhcEnums.ChaosTokenKind.NUMERIC
	rec.source = source
	rec.scope_id = scope_id
	return rec
