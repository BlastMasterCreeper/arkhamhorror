class_name RestrictionPayload
extends RefCounted

## @deprecated 使用 GatePayload / DirectivePayload / StatusPayload。

var kind: AhcEnums.RestrictionKind = AhcEnums.GateKind.FORBID_DRAW
var drawer_id: StringName = &""
var drawn_card_id: StringName = &""
var encounter_frame_id: StringName = &""
var subject_id: StringName = &""
var assign_op: AhcEnums.AssignConstraintOp = AhcEnums.AssignConstraintOp.INCLUDE_CANDIDATE
var assign_affliction: StringName = &"either"
var assign_direct_scope: AhcEnums.AssignDirectScope = AhcEnums.AssignDirectScope.NON_DIRECT
var assign_expand_scope: StringName = &"self_deals"
var assign_trait: StringName = &""
var assign_amount: int = 1
var assign_if_able: bool = true


static func forbid_draw() -> GatePayload:
	return GatePayload.forbid_draw()


static func forbid_play_peril(drawer_id: StringName, drawn_card_id: StringName) -> GatePayload:
	return GatePayload.forbid_play_peril(drawer_id, drawn_card_id)


static func forbid_trigger_peril(drawer_id: StringName, drawn_card_id: StringName) -> GatePayload:
	return GatePayload.forbid_trigger_peril(drawer_id, drawn_card_id)


static func forbid_commit_peril(drawer_id: StringName, drawn_card_id: StringName) -> GatePayload:
	return GatePayload.forbid_commit_peril(drawer_id, drawn_card_id)


static func forbid_leave_hand(card_id: StringName, controller_id: StringName = &"") -> GatePayload:
	return GatePayload.forbid_leave_hand(card_id, controller_id)


static func skip_aoo(controller_id: StringName = &"") -> DirectivePayload:
	return DirectivePayload.skip_aoo(controller_id)


static func suppress_auto_engage(enemy_id: StringName) -> DirectivePayload:
	return DirectivePayload.suppress_auto_engage(enemy_id)


static func engagement(enemy_id: StringName, investigator_id: StringName) -> StatusPayload:
	return StatusPayload.engagement(enemy_id, investigator_id)


static func forbid_discover_clue(investigator_id: StringName, enemy_id: StringName) -> GatePayload:
	return GatePayload.forbid_discover_clue(investigator_id, enemy_id)


static func forbid_spend_clue(investigator_id: StringName, enemy_id: StringName) -> GatePayload:
	return GatePayload.forbid_spend_clue(investigator_id, enemy_id)


static func forbid_attack(enemy_id: StringName) -> GatePayload:
	return GatePayload.forbid_attack(enemy_id)
