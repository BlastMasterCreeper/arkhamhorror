class_name BuffSpec
extends RefCounted

var type: AhcEnums.BuffType = AhcEnums.BuffType.MODIFIER
var modifier: ModifierPayload = null
var restriction: RestrictionPayload = null
var listener: ListenerPayload = null
var keyword: StringName = &""
## CHARACTERISTIC：unique / victory / vengeance…；标量供 Victory X。
var characteristic: StringName = &""
var scalar: int = 0


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


static func keyword_buff(keyword: StringName) -> BuffSpec:
	var b := BuffSpec.new()
	b.type = AhcEnums.BuffType.KEYWORD
	b.keyword = keyword
	return b


static func characteristic_buff(characteristic: StringName, scalar: int = 0) -> BuffSpec:
	var b := BuffSpec.new()
	b.type = AhcEnums.BuffType.CHARACTERISTIC
	b.characteristic = characteristic
	b.scalar = scalar
	return b
