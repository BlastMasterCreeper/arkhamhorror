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
