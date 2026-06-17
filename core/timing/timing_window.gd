class_name TimingWindow
extends RefCounted

var window_id: StringName = &""
var trigger: TriggeringCondition = null
var phase: AhcEnums.SequencePhase = AhcEnums.SequencePhase.WHEN
var open: bool = false
var response_round: int = 0


func open_for(trigger: TriggeringCondition, phase: AhcEnums.SequencePhase) -> void:
	window_id = StringName("tw_%s_%d" % [trigger.kind, Time.get_ticks_msec()])
	self.trigger = trigger
	self.phase = phase
	open = true
	response_round = 0


func close() -> void:
	open = false
	trigger = null
	response_round = 0


func next_round() -> int:
	response_round += 1
	return response_round
