class_name ResponsePrompt
extends RefCounted

## Headless / UI 共用：🕭 是否由控制者选用；Forced 恒为 true。
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
