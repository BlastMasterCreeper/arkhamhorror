class_name RegistrationTemplate
extends RefCounted

## Registration **只**挂Registration 载荷。Gain 见 `GainTemplate` / `GainedCharacteristicStore`。

var controller_id: StringName = &""
var lifetime_kind: AhcEnums.LifetimeKind = AhcEnums.LifetimeKind.DURATION
var duration: AhcEnums.DurationAnchorKind = AhcEnums.DurationAnchorKind.THIS_TURN
var encounter_frame_id: StringName = &""
var drawn_card_id: StringName = &""
var payloads: Array[RegistrationPayload] = []
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
	t.payloads.append(RegistrationPayload.of_modifier(payload))
	return t


static func lasting_gate(
	controller_id: StringName,
	duration: AhcEnums.DurationAnchorKind,
	payload: GatePayload
) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = controller_id
	t.lifetime_kind = AhcEnums.LifetimeKind.DURATION
	t.duration = duration
	t.payloads.append(RegistrationPayload.of_gate(payload))
	return t


## @deprecated 使用 lasting_gate。
static func lasting_restriction(
	controller_id: StringName,
	duration: AhcEnums.DurationAnchorKind,
	payload: GatePayload
) -> RegistrationTemplate:
	return lasting_gate(controller_id, duration, payload)


static func delayed_listener(
	controller_id: StringName,
	payload: ListenerPayload
) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = controller_id
	t.lifetime_kind = AhcEnums.LifetimeKind.UNTIL_FIRED
	t.payloads.append(RegistrationPayload.of_listener(payload))
	return t


## DIRECTIVE · SKIP_AOO：行动开始 Register；INIT_2B 入口读取后卸掉。
static func skip_aoo_for_action(controller_id: StringName) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = controller_id
	t.lifetime_kind = AhcEnums.LifetimeKind.UNTIL_FIRED
	t.payloads.append(RegistrationPayload.of_directive(DirectivePayload.skip_aoo(controller_id)))
	return t


## @deprecated 使用 skip_aoo_for_action
static func skip_aoo_until_fired(controller_id: StringName) -> RegistrationTemplate:
	return skip_aoo_for_action(controller_id)


## DIRECTIVE · SUPPRESS_AUTO_ENGAGE。
static func suppress_auto_engage_until_fired(enemy_id: StringName) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = &""
	t.lifetime_kind = AhcEnums.LifetimeKind.UNTIL_FIRED
	t.drawn_card_id = enemy_id
	t.payloads.append(RegistrationPayload.of_directive(DirectivePayload.suppress_auto_engage(enemy_id)))
	return t


## STATUS · 交战成对。
static func engagement_pair(enemy_id: StringName, investigator_id: StringName) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = investigator_id
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_IN_PLAY
	t.drawn_card_id = enemy_id
	t.payloads.append(
		RegistrationPayload.of_status(StatusPayload.engagement(enemy_id, investigator_id))
	)
	return t


## GATE · 险境 FORBID_*。
static func peril_drawn_card_resolving(drawer_id: StringName, card_id: StringName) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = &""
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_DRAWN_CARD_RESOLVING
	t.drawn_card_id = card_id
	t.payloads.append(RegistrationPayload.of_gate(GatePayload.forbid_play_peril(drawer_id, card_id)))
	t.payloads.append(RegistrationPayload.of_gate(GatePayload.forbid_trigger_peril(drawer_id, card_id)))
	t.payloads.append(RegistrationPayload.of_gate(GatePayload.forbid_commit_peril(drawer_id, card_id)))
	return t


## GATE · 隐私 FORBID_LEAVE_HAND。
static func hidden_in_hand(controller_id: StringName, card_id: StringName) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = controller_id
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_HIDDEN_IN_HAND
	t.drawn_card_id = card_id
	t.payloads.append(
		RegistrationPayload.of_gate(GatePayload.forbid_leave_hand(card_id, controller_id))
	)
	return t


## @deprecated Gain 已迁 `GainTemplate` / `GainedCharacteristicStore`。
static func gained_keyword_drawn_card_resolving(
	card_id: StringName,
	keyword: StringName
) -> GainTemplate:
	return GainTemplate.keyword_drawn_card_resolving(card_id, keyword)


## @deprecated 使用 peril_drawn_card_resolving
static func peril_encounter_frame(drawer_id: StringName, frame_id: StringName) -> RegistrationTemplate:
	return peril_drawn_card_resolving(drawer_id, frame_id)
