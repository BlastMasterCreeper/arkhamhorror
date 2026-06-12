class_name RegistrationTemplate
extends RefCounted

var controller_id: StringName = &""
var lifetime_kind: AhcEnums.LifetimeKind = AhcEnums.LifetimeKind.DURATION
var duration: AhcEnums.DurationAnchorKind = AhcEnums.DurationAnchorKind.THIS_TURN
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
