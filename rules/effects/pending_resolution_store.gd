class_name PendingResolutionStore
extends RefCounted

var _pendings: Dictionary = {}
var _next_id: int = 0
var _next_initiation_seq: int = 0


func create(request: EffectRequest, triggering_condition_id: StringName = &"") -> PendingResolution:
	var pending := PendingResolution.new()
	_next_id += 1
	pending.id = StringName("pending_%d" % _next_id)
	pending.request = request
	pending.triggering_condition_id = (
		triggering_condition_id if triggering_condition_id != &"" else pending.id
	)
	_pendings[pending.id] = pending
	return pending


func get_pending(pending_id: StringName) -> PendingResolution:
	return _pendings.get(pending_id, null) as PendingResolution


func cancel(pending_id: StringName) -> Dictionary:
	var pending := get_pending(pending_id)
	if pending == null:
		return {"ok": false, "error": "unknown_pending"}
	if pending.state == PendingResolution.State.RESOLVED:
		return {"ok": false, "error": "already_resolved"}
	if not pending.is_registered():
		return {"ok": true, "already_cancelled": true}
	## Cancel：未结算前注销 pending（视为从未登记可结算序列）。
	_pendings.erase(pending_id)
	return {"ok": true}


func ignore(pending_id: StringName) -> Dictionary:
	var pending := get_pending(pending_id)
	if pending == null:
		return {"ok": false, "error": "unknown_pending"}
	if pending.state == PendingResolution.State.RESOLVED:
		return {"ok": false, "error": "already_resolved"}
	if pending.state == PendingResolution.State.IGNORED:
		return {"ok": true, "already_ignored": true}
	if pending.state != PendingResolution.State.OPEN:
		return {"ok": false, "error": "pending_closed"}
	pending.state = PendingResolution.State.IGNORED
	return {"ok": true}


func register_replacement(
	pending_id: StringName,
	replacement_request: EffectRequest,
	source_ability_id: StringName = &""
) -> Dictionary:
	var pending := get_pending(pending_id)
	if pending == null:
		return {"ok": false, "error": "unknown_pending"}
	if pending.blocks_replacement():
		return {"ok": false, "error": "pending_closed"}
	if replacement_request == null:
		return {"ok": false, "error": "invalid_replacement"}
	_next_initiation_seq += 1
	var candidate := ReplacementCandidate.new()
	candidate.source_ability_id = source_ability_id
	candidate.triggering_condition_id = pending.triggering_condition_id
	candidate.initiation_seq = _next_initiation_seq
	candidate.replacement_request = replacement_request
	pending.replacements.append(candidate)
	return {"ok": true, "initiation_seq": candidate.initiation_seq}


func winning_replacement(pending: PendingResolution) -> ReplacementCandidate:
	if pending == null or pending.replacements.is_empty():
		return null
	var winner: ReplacementCandidate = pending.replacements[0]
	for candidate in pending.replacements:
		if candidate.initiation_seq > winner.initiation_seq:
			winner = candidate
	return winner


func request_to_resolve(pending: PendingResolution) -> EffectRequest:
	if pending == null:
		return null
	var winner := winning_replacement(pending)
	if winner != null and winner.replacement_request != null:
		return winner.replacement_request
	return pending.request
