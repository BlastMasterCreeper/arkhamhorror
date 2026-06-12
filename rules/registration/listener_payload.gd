class_name ListenerPayload
extends RefCounted

var timing: StringName = &""
var composition: CompositionNode = null


static func at_timing(timing_name: StringName, node: CompositionNode) -> ListenerPayload:
	var p := ListenerPayload.new()
	p.timing = timing_name
	p.composition = node
	return p
