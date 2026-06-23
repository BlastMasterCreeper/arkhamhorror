class_name RestrictionEvaluator
extends RefCounted

enum Intent {
	DRAW,
	PLAY,
	TRIGGER,
	COMMIT_TO_TEST,
}


static func blocks_draw(controller_id: StringName, store: RegistrationStore) -> bool:
	return block_reason(Intent.DRAW, controller_id, store) != &""


static func block_reason(
	intent: Intent,
	actor_id: StringName,
	store: RegistrationStore,
	skill_test: SkillTestContext = null
) -> StringName:
	if store == null:
		return &""
	for reg in store.all_registrations():
		for buff in reg.buffs:
			if buff.type != AhcEnums.BuffType.RESTRICTION or buff.restriction == null:
				continue
			var reason := _matches(buff.restriction, reg, intent, actor_id, skill_test)
			if reason != &"":
				return reason
	return &""


static func commit_block_error(reason: StringName) -> String:
	if reason == &"restriction_forbid_commit_to_test":
		return "peril_no_assist"
	return String(reason)


static func _matches(
	payload: RestrictionPayload,
	reg: Registration,
	intent: Intent,
	actor_id: StringName,
	skill_test: SkillTestContext
) -> StringName:
	match payload.kind:
		AhcEnums.RestrictionKind.FORBID_DRAW:
			if intent != Intent.DRAW:
				return &""
			if reg.controller_id != actor_id and reg.controller_id != &"":
				return &""
			return &"restriction_forbid_draw"
		AhcEnums.RestrictionKind.FORBID_PLAY:
			if intent != Intent.PLAY:
				return &""
			if actor_id == payload.drawer_id:
				return &""
			return &"restriction_forbid_play"
		AhcEnums.RestrictionKind.FORBID_TRIGGER:
			if intent != Intent.TRIGGER:
				return &""
			if actor_id == payload.drawer_id:
				return &""
			return &"restriction_forbid_trigger"
		AhcEnums.RestrictionKind.FORBID_COMMIT_TO_TEST:
			if intent != Intent.COMMIT_TO_TEST:
				return &""
			if skill_test == null:
				return &""
			if actor_id == payload.drawer_id:
				return &""
			if skill_test.performing_investigator != payload.drawer_id:
				return &""
			return &"restriction_forbid_commit_to_test"
	return &""
