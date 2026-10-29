class_name StatusPayload
extends RefCounted

## STATUS：站得住的查询断言（交战等可脱离物理场面）。

var kind: AhcEnums.StatusKind = AhcEnums.StatusKind.ENGAGEMENT
## ENGAGEMENT：敌人 subject ↔ 调查员 drawer。
var subject_id: StringName = &""
var drawer_id: StringName = &""


static func engagement(enemy_id: StringName, investigator_id: StringName) -> StatusPayload:
	var p := StatusPayload.new()
	p.kind = AhcEnums.StatusKind.ENGAGEMENT
	p.subject_id = enemy_id
	p.drawer_id = investigator_id
	return p
