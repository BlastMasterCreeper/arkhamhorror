class_name DirectivePayload
extends RefCounted

## DIRECTIVE 载荷：原流程读取后改道（非 Intent 拦截）。

var kind: AhcEnums.DirectiveKind = AhcEnums.DirectiveKind.SKIP_AOO
var drawer_id: StringName = &""
var drawn_card_id: StringName = &""
var subject_id: StringName = &""
var redirect_from: int = -1
var redirect_to: int = -1
var assign_op: AhcEnums.AssignConstraintOp = AhcEnums.AssignConstraintOp.INCLUDE_CANDIDATE
var assign_affliction: StringName = &"either"
var assign_direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.NON_DIRECT
var assign_expand_scope: StringName = &"self_deals"
var assign_trait: StringName = &""
var assign_amount: int = 1
var assign_if_able: bool = true


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


static func assign_include_candidate(
	subject_card_id: StringName,
	controller_id: StringName,
	affliction: StringName = &"either",
	direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.BOTH,
	expand_scope: StringName = &"self_deals"
) -> DirectivePayload:
	var p := DirectivePayload.new()
	p.kind = AhcEnums.DirectiveKind.ASSIGN_CONSTRAINT
	p.assign_op = AhcEnums.AssignConstraintOp.INCLUDE_CANDIDATE
	p.subject_id = subject_card_id
	p.drawer_id = controller_id
	p.drawn_card_id = subject_card_id
	p.assign_affliction = affliction
	p.assign_direct_scope = direct_scope
	p.assign_expand_scope = expand_scope
	return p


static func assign_prior_fill(
	subject_card_id: StringName,
	controller_id: StringName,
	affliction: StringName = &"horror",
	direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.NON_DIRECT
) -> DirectivePayload:
	var p := DirectivePayload.new()
	p.kind = AhcEnums.DirectiveKind.ASSIGN_CONSTRAINT
	p.assign_op = AhcEnums.AssignConstraintOp.PRIOR_FILL
	p.subject_id = subject_card_id
	p.drawer_id = controller_id
	p.drawn_card_id = subject_card_id
	p.assign_affliction = affliction
	p.assign_direct_scope = direct_scope
	return p


static func assign_min_to_subject(
	subject_card_id: StringName,
	controller_id: StringName,
	amount: int = 1,
	affliction: StringName = &"damage",
	direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.NON_DIRECT,
	if_able: bool = true
) -> DirectivePayload:
	var p := DirectivePayload.new()
	p.kind = AhcEnums.DirectiveKind.ASSIGN_CONSTRAINT
	p.assign_op = AhcEnums.AssignConstraintOp.MIN_TO_SUBJECT
	p.subject_id = subject_card_id
	p.drawer_id = controller_id
	p.drawn_card_id = subject_card_id
	p.assign_affliction = affliction
	p.assign_direct_scope = direct_scope
	p.assign_amount = maxi(amount, 1)
	p.assign_if_able = if_able
	return p


static func assign_max_to_match(
	controller_id: StringName,
	trait_name: StringName,
	amount: int = 1,
	affliction: StringName = &"either",
	direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.BOTH
) -> DirectivePayload:
	var p := DirectivePayload.new()
	p.kind = AhcEnums.DirectiveKind.ASSIGN_CONSTRAINT
	p.assign_op = AhcEnums.AssignConstraintOp.MAX_TO_MATCH
	p.drawer_id = controller_id
	p.assign_trait = trait_name
	p.assign_amount = maxi(amount, 0)
	p.assign_affliction = affliction
	p.assign_direct_scope = direct_scope
	return p


static func assign_grant_capacity(
	subject_card_id: StringName,
	controller_id: StringName,
	amount: int = 1,
	affliction: StringName = &"either",
	direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.BOTH
) -> DirectivePayload:
	var p := DirectivePayload.new()
	p.kind = AhcEnums.DirectiveKind.ASSIGN_CONSTRAINT
	p.assign_op = AhcEnums.AssignConstraintOp.GRANT_CAPACITY
	p.subject_id = subject_card_id
	p.drawer_id = controller_id
	p.drawn_card_id = subject_card_id
	p.assign_amount = maxi(amount, 0)
	p.assign_affliction = affliction
	p.assign_direct_scope = direct_scope
	return p
