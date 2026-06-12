class_name BuffSpec
extends RefCounted

var type: AhcEnums.BuffType = AhcEnums.BuffType.MODIFIER
var modifier: ModifierPayload = null
var restriction: RestrictionPayload = null
var listener: ListenerPayload = null


static func modifier_buff(payload: ModifierPayload) -> BuffSpec:
	var b := BuffSpec.new()
	b.type = AhcEnums.BuffType.MODIFIER
	b.modifier = payload
	return b


static func restriction_buff(payload: RestrictionPayload) -> BuffSpec:
	var b := BuffSpec.new()
	b.type = AhcEnums.BuffType.RESTRICTION
	b.restriction = payload
	return b


static func listener_buff(payload: ListenerPayload) -> BuffSpec:
	var b := BuffSpec.new()
	b.type = AhcEnums.BuffType.LISTENER
	b.listener = payload
	return b
