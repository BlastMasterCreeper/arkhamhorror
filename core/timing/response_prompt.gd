class_name ResponsePrompt
extends RefCounted

## 单次 [reaction] 选用结果（轻量 DTO）。完整交互见 PlayerInteractionGate / ChoiceRequest（16-player-interaction.md）。
var handler: SequenceHandler
var controller_confirmed: bool = true


static func forced(handler: SequenceHandler) -> ResponsePrompt:
	var p := ResponsePrompt.new()
	p.handler = handler
	p.controller_confirmed = true
	return p


static func reaction(handler: SequenceHandler, use: bool) -> ResponsePrompt:
	var p := ResponsePrompt.new()
	p.handler = handler
	p.controller_confirmed = use
	return p
