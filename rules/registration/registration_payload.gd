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
	var p := RegistrationPayload.new()
	p.type = AhcEnums.RegistrationKind.MODIFIER
	p.modifier = payload
	return p


static func of_gate(payload: GatePayload) -> RegistrationPayload:
	var p := RegistrationPayload.new()
	p.type = AhcEnums.RegistrationKind.GATE
	p.gate = payload
	return p


## @deprecated 使用 of_gate。
static func of_restriction(payload: GatePayload) -> RegistrationPayload:
	return of_gate(payload)


static func of_directive(payload: DirectivePayload) -> RegistrationPayload:
	var p := RegistrationPayload.new()
	p.type = AhcEnums.RegistrationKind.DIRECTIVE
	p.directive = payload
	return p


static func of_status(payload: StatusPayload) -> RegistrationPayload:
	var p := RegistrationPayload.new()
	p.type = AhcEnums.RegistrationKind.STATUS
	p.status = payload
	return p


static func of_listener(payload: ListenerPayload) -> RegistrationPayload:
	var p := RegistrationPayload.new()
	p.type = AhcEnums.RegistrationKind.LISTENER
	p.listener = payload
	return p
