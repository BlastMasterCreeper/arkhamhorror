class_name GameStatEmitter
extends RefCounted

var _events: EventRecordLog
var _state: GameStateStore
var _projections: StatProjectionStore


func _init(events: EventRecordLog, state: GameStateStore, projections: StatProjectionStore) -> void:
	_events = events
	_state = state
	_projections = projections


func record_turn_begin(inv_id: StringName) -> void:
	if _state == null or _events == null:
		return
	_state.turn_id += 1
	_state.turn_owner_id = inv_id
	var rec := _events.append(
		AhcEnums.EventRecordKind.TURN_BEGIN,
		{"turn_id": _state.turn_id, "inv_id": inv_id},
		_state.compute_state_hash()
	)
	_events.event_index.on_turn_begin(_state.turn_id, inv_id, rec.seq)
	_notify(rec)


func record_turn_end(inv_id: StringName) -> void:
	if _state == null or _events == null:
		return
	var rec := _events.append(
		AhcEnums.EventRecordKind.TURN_END,
		{"turn_id": _state.turn_id, "inv_id": inv_id},
		_state.compute_state_hash()
	)
	_events.event_index.on_turn_end(_state.turn_id, inv_id, rec.seq)
	_notify(rec)


func record_action_spend(
	inv_id: StringName,
	action_type: AhcEnums.ActionType,
	cost: int = 1,
	extra: Dictionary = {}
) -> int:
	if _events == null:
		return -1
	var payload := {
		"inv_id": inv_id,
		"action_type": action_type,
		"cost": cost,
		"turn_id": _state.turn_id if _state else 0,
	}
	payload.merge(extra, true)
	var rec := _events.append(
		AhcEnums.EventRecordKind.ACTION_SPEND,
		payload,
		_state.compute_state_hash() if _state else ""
	)
	payload["spend_id"] = rec.seq
	rec.payload = payload
	_notify(rec)
	return rec.seq


func record_action_spend_void(spend_id: int, inv_id: StringName, cost: int = 1) -> void:
	if _events == null:
		return
	var rec := _events.append(
		AhcEnums.EventRecordKind.ACTION_SPEND_VOID,
		{"spend_id": spend_id, "inv_id": inv_id, "cost": cost},
		_state.compute_state_hash() if _state else ""
	)
	_notify(rec)


func _notify(rec: EventRecord) -> void:
	if _projections != null:
		_projections.on_event(rec)
