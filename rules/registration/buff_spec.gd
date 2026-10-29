class_name BuffSpec
extends RefCounted

## 行为 Buff 按根本特质分型。Gain 见 `GainedCharacteristicSpec`（不进本类）。

var type: AhcEnums.BuffType = AhcEnums.BuffType.MODIFIER
var modifier: ModifierPayload = null
var gate: GatePayload = null
var directive: DirectivePayload = null
var relation: RelationPayload = null
var listener: ListenerPayload = null


## @deprecated 使用 gate。
func get_restriction() -> GatePayload:
	return gate


static func modifier_buff(payload: ModifierPayload) -> BuffSpec:
	var b := BuffSpec.new()
	b.type = AhcEnums.BuffType.MODIFIER
	b.modifier = payload
	return b


static func gate_buff(payload: GatePayload) -> BuffSpec:
	var b := BuffSpec.new()
	b.type = AhcEnums.BuffType.GATE
	b.gate = payload
	return b


## @deprecated 使用 gate_buff。
static func restriction_buff(payload: GatePayload) -> BuffSpec:
	return gate_buff(payload)


static func directive_buff(payload: DirectivePayload) -> BuffSpec:
	var b := BuffSpec.new()
	b.type = AhcEnums.BuffType.DIRECTIVE
	b.directive = payload
	return b


static func relation_buff(payload: RelationPayload) -> BuffSpec:
	var b := BuffSpec.new()
	b.type = AhcEnums.BuffType.RELATION
	b.relation = payload
	return b


static func listener_buff(payload: ListenerPayload) -> BuffSpec:
	var b := BuffSpec.new()
	b.type = AhcEnums.BuffType.LISTENER
	b.listener = payload
	return b
