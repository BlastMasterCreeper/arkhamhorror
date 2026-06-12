class_name EffectResolutionGraph
extends RefCounted

var _events: EventRecordLog
var _state: GameStateStore
var _log: GameLog


func _init(state: GameStateStore, events: EventRecordLog, log: GameLog) -> void:
	_state = state
	_events = events
	_log = log


func submit(request: EffectRequest) -> Dictionary:
	_log.log(AhcEnums.LogCategory.ABILITY, "effect:%s" % request.op, {"amount": request.amount})
	_events.append(
		AhcEnums.EventRecordKind.EFFECT_APPLIED,
		{"op": request.op, "amount": request.amount},
		_state.compute_state_hash()
	)
	return {"ok": true}
