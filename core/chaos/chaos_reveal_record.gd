class_name ChaosRevealRecord
extends RefCounted

## 检定/调查作用域内一次「揭示」账本行（可已归袋）。
## Cancel → 视为从未抽到；Ignore → 仍抽到/揭示，但不 resolve（无修饰/符号效果）。

var token: ChaosToken = null
var kind: AhcEnums.ChaosTokenKind = AhcEnums.ChaosTokenKind.NUMERIC
var source: StringName = &"skill_test" ## skill_test | ability
var scope_id: StringName = &""
var canceled: bool = false
var ignored: bool = false
var physically_returned: bool = false


func was_revealed() -> bool:
	## 未 Cancel：含已 Ignore（Grimoire：ignored 仍 drawn）。
	return not canceled


func was_resolved() -> bool:
	## 计入 ST.4/ST.5 与 if_revealed（FAQ 2.5 resolved）。
	return not canceled and not ignored


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
