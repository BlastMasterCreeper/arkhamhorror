class_name RegistrationTemplate
extends RefCounted

var controller_id: StringName = &""
var lifetime_kind: AhcEnums.LifetimeKind = AhcEnums.LifetimeKind.DURATION
var duration: AhcEnums.DurationAnchorKind = AhcEnums.DurationAnchorKind.THIS_TURN
var encounter_frame_id: StringName = &""
var buffs: Array[BuffSpec] = []


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


## E3 seq.encounter.check_peril：险境 Cannot → 三条 RESTRICTION，帧 pop 时 Unregister。
static func peril_encounter_frame(drawer_id: StringName, frame_id: StringName) -> RegistrationTemplate:
	var t := RegistrationTemplate.new()
	t.controller_id = &""
	t.lifetime_kind = AhcEnums.LifetimeKind.WHILE_ENCOUNTER_FRAME
	t.encounter_frame_id = frame_id
	t.buffs.append(
		BuffSpec.restriction_buff(RestrictionPayload.forbid_play_peril(drawer_id, frame_id))
	)
	t.buffs.append(
		BuffSpec.restriction_buff(RestrictionPayload.forbid_trigger_peril(drawer_id, frame_id))
	)
	t.buffs.append(
		BuffSpec.restriction_buff(RestrictionPayload.forbid_commit_peril(drawer_id, frame_id))
	)
	return t
