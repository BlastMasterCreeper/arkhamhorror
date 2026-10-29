class_name RegistrationPayload
extends RefCounted

## Registration 壳内的载荷（按 RegistrationKind 分型）。
## Gain 见 `GainedCharacteristicSpec`（不进 Registration）。

var type: AhcEnums.RegistrationKind = AhcEnums.RegistrationKind.MODIFIER
var modifier: ModifierPayload = null
var gate: GatePayload = null
var directive: DirectivePayload = null
var status: StatusPayload = null
var listener: ListenerPayload = null


static func of_modifier(payload: ModifierPayload) -> RegistrationPayload:
	var b := RegistrationPayload.new()
	b.type = AhcEnums.RegistrationKind.MODIFIER
	b.modifier = payload
	return b


static func of_gate(payload: GatePayload) -> RegistrationPayload:
	var b := RegistrationPayload.new()
	b.type = AhcEnums.RegistrationKind.GATE
	b.gate = payload
	return b


## @deprecated 使用 of_gate。
static func of_restriction(payload: GatePayload) -> RegistrationPayload:
	return of_gate(payload)


static func of_directive(payload: DirectivePayload) -> RegistrationPayload:
	var b := RegistrationPayload.new()
	b.type = AhcEnums.RegistrationKind.DIRECTIVE
	b.directive = payload
	return b


static func of_status(payload: StatusPayload) -> RegistrationPayload:
	var b := RegistrationPayload.new()
	b.type = AhcEnums.RegistrationKind.STATUS
	b.status = payload
	return b


static func of_listener(payload: ListenerPayload) -> RegistrationPayload:
	var b := RegistrationPayload.new()
	b.type = AhcEnums.RegistrationKind.LISTENER
	b.listener = payload
	return b
