class_name RelationPayload
extends RefCounted

## RELATION Buff：成对/关系事实。

var kind: AhcEnums.RelationKind = AhcEnums.RelationKind.ENGAGEMENT
## ENGAGEMENT：敌人 subject ↔ 调查员 drawer。
var subject_id: StringName = &""
var drawer_id: StringName = &""


static func engagement(enemy_id: StringName, investigator_id: StringName) -> RelationPayload:
	var p := RelationPayload.new()
	p.kind = AhcEnums.RelationKind.ENGAGEMENT
	p.subject_id = enemy_id
	p.drawer_id = investigator_id
	return p
