class_name RestrictionEvaluator
extends RefCounted

## GATE Buff 消费：Intent 合法性。类名暂留；语义是门禁不是笼统 restriction。

enum Intent {
	DRAW,
	PLAY,
	TRIGGER,
	COMMIT_TO_TEST,
	LEAVE_HAND,
}


static func blocks_draw(controller_id: StringName, store: RegistrationStore) -> bool:
	return block_reason(Intent.DRAW, controller_id, store) != &""


static func blocks_play(actor_id: StringName, store: RegistrationStore) -> bool:
	return block_reason(Intent.PLAY, actor_id, store) != &""


static func blocks_trigger(actor_id: StringName, store: RegistrationStore) -> bool:
	return block_reason(Intent.TRIGGER, actor_id, store) != &""


static func blocks_leave_hand(card_id: StringName, store: RegistrationStore) -> bool:
	return block_reason(Intent.LEAVE_HAND, &"", store, null, card_id) != &""


static func block_reason(
	intent: Intent,
	actor_id: StringName,
	store: RegistrationStore,
	skill_test: SkillTestContext = null,
	leave_hand_card_id: StringName = &""
) -> StringName:
	if store == null:
		return &""
	for reg in store.all_registrations():
		for buff in reg.buffs:
			if buff.type != AhcEnums.BuffType.GATE or buff.gate == null:
				continue
			var reason := _matches(
				buff.gate, reg, intent, actor_id, skill_test, leave_hand_card_id
			)
			if reason != &"":
				return reason
	return &""


static func commit_block_error(reason: StringName) -> String:
	return api_error(reason)


static func api_error(reason: StringName) -> String:
	if reason == &"restriction_forbid_commit_to_test":
		return "peril_no_assist"
	if reason != &"":
		return String(reason)
	return ""


static func _matches(
	payload: GatePayload,
	reg: Registration,
	intent: Intent,
	actor_id: StringName,
	skill_test: SkillTestContext,
	leave_hand_card_id: StringName = &""
) -> StringName:
	match payload.kind:
		AhcEnums.GateKind.FORBID_DRAW:
			if intent != Intent.DRAW:
				return &""
			if reg.controller_id != actor_id and reg.controller_id != &"":
				return &""
			return &"restriction_forbid_draw"
		AhcEnums.GateKind.FORBID_PLAY:
			if intent != Intent.PLAY:
				return &""
			if actor_id == payload.drawer_id:
				return &""
			return &"restriction_forbid_play"
		AhcEnums.GateKind.FORBID_TRIGGER:
			if intent != Intent.TRIGGER:
				return &""
			if actor_id == payload.drawer_id:
				return &""
			return &"restriction_forbid_trigger"
		AhcEnums.GateKind.FORBID_COMMIT_TO_TEST:
			if intent != Intent.COMMIT_TO_TEST:
				return &""
			if skill_test == null:
				return &""
			if actor_id == payload.drawer_id:
				return &""
			if skill_test.performing_investigator != payload.drawer_id:
				return &""
			return &"restriction_forbid_commit_to_test"
		AhcEnums.GateKind.FORBID_LEAVE_HAND:
			if intent != Intent.LEAVE_HAND:
				return &""
			if leave_hand_card_id == &"" or payload.drawn_card_id != leave_hand_card_id:
				return &""
			return &"restriction_forbid_leave_hand"
	return &""
