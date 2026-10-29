class_name RestrictionPayload
extends GatePayload

## @deprecated 使用 GatePayload（GATE）。保留类名以免旧引用瞬间全炸。


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


## @deprecated 使用 DirectivePayload.skip_aoo。
static func skip_aoo(controller_id: StringName = &"") -> DirectivePayload:
	return DirectivePayload.skip_aoo(controller_id)


## @deprecated 使用 DirectivePayload.suppress_auto_engage。
static func suppress_auto_engage(enemy_id: StringName) -> DirectivePayload:
	return DirectivePayload.suppress_auto_engage(enemy_id)


## @deprecated 使用 StatusPayload.engagement。
static func engagement(enemy_id: StringName, investigator_id: StringName) -> StatusPayload:
	return StatusPayload.engagement(enemy_id, investigator_id)
