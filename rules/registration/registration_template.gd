class_name RegistrationTemplate
extends RefCounted

var controller_id: StringName = &""
var lifetime_kind: AhcEnums.LifetimeKind = AhcEnums.LifetimeKind.DURATION
var duration: AhcEnums.DurationAnchorKind = AhcEnums.DurationAnchorKind.THIS_TURN
var encounter_frame_id: StringName = &""
var drawn_card_id: StringName = &""
var buffs: Array[BuffSpec] = []
var stat_queries: Array = []


static func lasting_modifier(
	controller_id: StringName,
	duration: AhcEnums.DurationAnchorKind,
	payload: ModifierPayload
) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = controller_id
	t.lifetime_kind = AhcEnums.LifetimeKind.DURATION
	t.duration = duration
	t.buffs.append(BuffSpec.modifier_buff(payload))
	return t


## 敌人攻击对你造成的伤害 −N（印刷量先修）。
static func reduce_enemy_damage_this_turn(
	controller_id: StringName,
	amount: int = 1
) -> RegistrationTemplate:
	return lasting_modifier(
		controller_id,
		AhcEnums.DurationAnchorKind.THIS_TURN,
		ModifierPayload.reduce_enemy_damage(amount)
	)


## 本次攻击 +N 伤害（无名改量）；常挂 THIS_SKILL_TEST。
static func attack_damage_bonus_this_test(
	controller_id: StringName,
	amount: int = 1
) -> RegistrationTemplate:
	return lasting_modifier(
		controller_id,
		AhcEnums.DurationAnchorKind.THIS_SKILL_TEST,
		ModifierPayload.attack_damage_bonus(amount)
	)


## 本次发现 +N 线索（消费式选一 leg）；常挂 THIS_SKILL_TEST（如推理）。
static func discover_bonus_this_test(
	controller_id: StringName,
	amount: int = 1
) -> RegistrationTemplate:
	return lasting_modifier(
		controller_id,
		AhcEnums.DurationAnchorKind.THIS_SKILL_TEST,
		ModifierPayload.discover_bonus(amount)
	)


## 调查 shroud −N（标量 MOD-Q-SHROUD）。
static func reduce_shroud_this_turn(
	controller_id: StringName,
	amount: int = 1
) -> RegistrationTemplate:
	return lasting_modifier(
		controller_id,
		AhcEnums.DurationAnchorKind.THIS_TURN,
		ModifierPayload.reduce_shroud(amount)
	)


static func lasting_restriction(
	controller_id: StringName,
	duration: AhcEnums.DurationAnchorKind,
	payload: RestrictionPayload
) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = controller_id
	t.lifetime_kind = AhcEnums.LifetimeKind.DURATION
	t.duration = duration
	t.buffs.append(BuffSpec.restriction_buff(payload))
	return t


static func delayed_listener(
	controller_id: StringName,
	payload: ListenerPayload
) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = controller_id
	t.lifetime_kind = AhcEnums.LifetimeKind.UNTIL_FIRED
	t.buffs.append(BuffSpec.listener_buff(payload))
	return t


## 限制类 SKIP_AOO：行动开始 Register；INIT_2B 入口读取后卸掉。
## 非 LISTENER（无 Catalog emit）；非 Cancel/Ignore。
static func skip_aoo_for_action(controller_id: StringName) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = controller_id
	## 与延时 LISTENER 的 UNTIL_FIRED 同枚举，语义是「入口读完即卸」，不是 listener 开火。
	t.lifetime_kind = AhcEnums.LifetimeKind.UNTIL_FIRED
	t.buffs.append(BuffSpec.restriction_buff(RestrictionPayload.skip_aoo(controller_id)))
	return t


## @deprecated 使用 skip_aoo_for_action
static func skip_aoo_until_fired(controller_id: StringName) -> RegistrationTemplate:
	return skip_aoo_for_action(controller_id)


## 限制类 SUPPRESS_AUTO_ENGAGE：效果移入前 Register；auto-engage 入口读取后卸掉。
static func suppress_auto_engage_until_fired(enemy_id: StringName) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = &""
	t.lifetime_kind = AhcEnums.LifetimeKind.UNTIL_FIRED
	t.drawn_card_id = enemy_id
	t.buffs.append(BuffSpec.restriction_buff(RestrictionPayload.suppress_auto_engage(enemy_id)))
	return t


## 交战状态：WHILE_IN_PLAY（敌人离场卸）；真实交战与视为交战共用。
## `forbid_clues_while_engaged`：同 Register 挂发现/花费线索禁止（01121b）；脱离时一并卸。
static func engagement_pair(
	enemy_id: StringName,
	investigator_id: StringName,
	forbid_clues_while_engaged: bool = false
) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = investigator_id
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_IN_PLAY
	t.drawn_card_id = enemy_id
	t.buffs.append(
		BuffSpec.restriction_buff(RestrictionPayload.engagement(enemy_id, investigator_id))
	)
	if forbid_clues_while_engaged:
		t.buffs.append(
			BuffSpec.restriction_buff(
				RestrictionPayload.forbid_discover_clue(investigator_id, enemy_id)
			)
		)
		t.buffs.append(
			BuffSpec.restriction_buff(
				RestrictionPayload.forbid_spend_clue(investigator_id, enemy_id)
			)
		)
	return t


## 冷漠 FORBID_ATTACK：WHILE_IN_PLAY（敌人离场卸）；未交战时拦 Fight。
static func aloof_forbid_attack(enemy_id: StringName) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = &""
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_IN_PLAY
	t.drawn_card_id = enemy_id
	t.buffs.append(
		BuffSpec.restriction_buff(RestrictionPayload.forbid_attack_aloof(enemy_id))
	)
	return t


## Assign（分摊）约束：WHILE_IN_PLAY（资产离场卸）；DamageAssigner 原流程读取。
static func assign_constraint_while_in_play(
	payload: RestrictionPayload
) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = payload.drawer_id
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_IN_PLAY
	t.drawn_card_id = payload.subject_id if payload.subject_id != &"" else payload.drawn_card_id
	t.buffs.append(BuffSpec.restriction_buff(payload))
	return t


## G2 peril Register：`WHILE_DRAWN_CARD_RESOLVING(card_id)` — G4 完 Unregister；不跨 Surge。
static func peril_drawn_card_resolving(drawer_id: StringName, card_id: StringName) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = &""
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING
	t.drawn_card_id = card_id
	t.buffs.append(
		BuffSpec.restriction_buff(RestrictionPayload.forbid_play_peril(drawer_id, card_id))
	)
	t.buffs.append(
		BuffSpec.restriction_buff(RestrictionPayload.forbid_trigger_peril(drawer_id, card_id))
	)
	t.buffs.append(
		BuffSpec.restriction_buff(RestrictionPayload.forbid_commit_peril(drawer_id, card_id))
	)
	return t


## E4 隐私 Register：`WHILE_HIDDEN_IN_HAND(card_id)` — 卡面能力合法离手时 Unregister。
static func hidden_in_hand(controller_id: StringName, card_id: StringName) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = controller_id
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_HIDDEN_IN_HAND
	t.drawn_card_id = card_id
	t.buffs.append(
		BuffSpec.restriction_buff(RestrictionPayload.forbid_leave_hand(card_id, controller_id))
	)
	return t


## G3 动态 keyword · `WHILE_DRAWN_CARD_RESOLVING(card_id)` — G5 evaluate 后 Unregister；G4 peril 不清除。
static func gained_keyword_drawn_card_resolving(
	card_id: StringName,
	keyword: StringName
) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = &""
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING
	t.drawn_card_id = card_id
	t.buffs.append(BuffSpec.keyword_buff(keyword))
	return t


## @deprecated 使用 peril_drawn_card_resolving
static func peril_encounter_frame(drawer_id: StringName, frame_id: StringName) -> RegistrationTemplate:
	return peril_drawn_card_resolving(drawer_id, frame_id)
