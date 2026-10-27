class_name RestrictionEvaluator
extends RefCounted

enum Intent {
	DRAW,
	PLAY,
	TRIGGER,
	COMMIT_TO_TEST,
	LEAVE_HAND,
	DISCOVER_CLUE,
	SPEND_CLUE,
	FIGHT,
}


static func blocks_draw(controller_id: StringName, store: RegistrationStore) -> bool:
	return block_reason(Intent.DRAW, controller_id, store) != &""


static func blocks_play(actor_id: StringName, store: RegistrationStore) -> bool:
	return block_reason(Intent.PLAY, actor_id, store) != &""


static func blocks_trigger(actor_id: StringName, store: RegistrationStore) -> bool:
	return block_reason(Intent.TRIGGER, actor_id, store) != &""


static func blocks_leave_hand(card_id: StringName, store: RegistrationStore) -> bool:
	return block_reason(Intent.LEAVE_HAND, &"", store, null, card_id) != &""


static func blocks_discover_clue(investigator_id: StringName, store: RegistrationStore) -> bool:
	return block_reason(Intent.DISCOVER_CLUE, investigator_id, store) != &""


static func blocks_spend_clue(investigator_id: StringName, store: RegistrationStore) -> bool:
	return block_reason(Intent.SPEND_CLUE, investigator_id, store) != &""


static func blocks_fight(
	investigator_id: StringName,
	enemy_id: StringName,
	store: RegistrationStore
) -> bool:
	return block_reason(Intent.FIGHT, investigator_id, store, null, &"", enemy_id) != &""


static func block_reason(
	intent: Intent,
	actor_id: StringName,
	store: RegistrationStore,
	skill_test: SkillTestContext = null,
	leave_hand_card_id: StringName = &"",
	target_enemy_id: StringName = &""
) -> StringName:
	if store == null:
		return &""
	for reg in store.all_registrations():
		for buff in reg.buffs:
			if buff.type != AhcEnums.BuffType.RESTRICTION or buff.restriction == null:
				continue
			var reason := _matches(
				buff.restriction,
				reg,
				intent,
				actor_id,
				skill_test,
				leave_hand_card_id,
				target_enemy_id,
				store
			)
			if reason != &"":
				return reason
	return &""


static func commit_block_error(reason: StringName) -> String:
	return api_error(reason)


static func api_error(reason: StringName) -> String:
	if reason == &"restriction_forbid_commit_to_test":
		return "peril_no_assist"
	## 冷漠 Fight 拦截：对外仍报 aloof（与既有 ACT-06 等对齐）。
	if reason == &"restriction_forbid_attack":
		return "aloof"
	if reason != &"":
		return String(reason)
	return ""


static func _matches(
	payload: RestrictionPayload,
	reg: Registration,
	intent: Intent,
	actor_id: StringName,
	skill_test: SkillTestContext,
	leave_hand_card_id: StringName = &"",
	target_enemy_id: StringName = &"",
	store: RegistrationStore = null
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
		AhcEnums.RestrictionKind.FORBID_LEAVE_HAND:
			if intent != Intent.LEAVE_HAND:
				return &""
			if leave_hand_card_id == &"" or payload.drawn_card_id != leave_hand_card_id:
				return &""
			return &"restriction_forbid_leave_hand"
		AhcEnums.RestrictionKind.FORBID_DISCOVER_CLUE:
			if intent != Intent.DISCOVER_CLUE:
				return &""
			if payload.drawer_id != &"" and payload.drawer_id != actor_id:
				return &""
			return &"restriction_forbid_discover_clue"
		AhcEnums.RestrictionKind.FORBID_SPEND_CLUE:
			if intent != Intent.SPEND_CLUE:
				return &""
			if payload.drawer_id != &"" and payload.drawer_id != actor_id:
				return &""
			return &"restriction_forbid_spend_clue"
		AhcEnums.RestrictionKind.FORBID_ATTACK:
			if intent != Intent.FIGHT:
				return &""
			var enemy_id: StringName = payload.subject_id
			if enemy_id == &"":
				enemy_id = reg.drawn_card_id
			if enemy_id == &"":
				return &""
			if target_enemy_id != &"" and enemy_id != target_enemy_id:
				return &""
			## 已与任何人交战 → 可 Fight（冷漠仅拦未交战）。
			if store != null and store.engagement_partner(enemy_id) != &"":
				return &""
			return &"restriction_forbid_attack"
	return &""
