class_name DirectivePayload
extends RefCounted

## DIRECTIVE Buff：改已入手续的走法（原流程读后分支）。

var kind: AhcEnums.DirectiveKind = AhcEnums.DirectiveKind.SKIP_AOO
var drawer_id: StringName = &""
var subject_id: StringName = &""
## SKILL_REDIRECT：from / to 技能维（StatRef 或 skill name）。
var redirect_from: int = -1
var redirect_to: int = -1


static func skip_aoo(controller_id: StringName = &"") -> DirectivePayload:
	var p := DirectivePayload.new()
	p.kind = AhcEnums.DirectiveKind.SKIP_AOO
	p.drawer_id = controller_id
	return p


static func suppress_auto_engage(enemy_id: StringName) -> DirectivePayload:
	var p := DirectivePayload.new()
	p.kind = AhcEnums.DirectiveKind.SUPPRESS_AUTO_ENGAGE
	p.subject_id = enemy_id
	return p


static func skill_redirect(from_stat: int, to_stat: int) -> DirectivePayload:
	var p := DirectivePayload.new()
	p.kind = AhcEnums.DirectiveKind.SKILL_REDIRECT
	p.redirect_from = from_stat
	p.redirect_to = to_stat
	return p
