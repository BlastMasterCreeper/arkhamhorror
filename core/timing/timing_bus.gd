class_name TimingBus
extends RefCounted

signal timing_point_emitted(timing_name: StringName, payload: Dictionary)

var _log: GameLog
var _listeners: ListenerDispatcher = null


func _init(log: GameLog) -> void:
	_log = log


func bind_listeners(dispatcher: ListenerDispatcher) -> void:
	_listeners = dispatcher


func emit_timing(timing_name: StringName, payload: Dictionary = {}) -> void:
	_log.log(AhcEnums.LogCategory.SYSTEM, "timing:%s" % timing_name, payload)
	if _listeners:
		_listeners.dispatch(timing_name)
	timing_point_emitted.emit(timing_name, payload)
