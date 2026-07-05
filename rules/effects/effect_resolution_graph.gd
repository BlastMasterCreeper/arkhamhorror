class_name EffectResolutionGraph
extends RefCounted

var _events: EventRecordLog
var _state: GameStateStore
var _log: GameLog
var _game_ctx: GameContext
var _pending_store: PendingResolutionStore = PendingResolutionStore.new()


func _init(state: GameStateStore, events: EventRecordLog, log: GameLog) -> void:
	_state = state
	_events = events
	_log = log


func bind_game_context(ctx: GameContext) -> void:
	_game_ctx = ctx


## 登记 pending，不立即 resolve（Cancel / Replacement 窗口）。
func begin_pending(
	request: EffectRequest,
	triggering_condition_id: StringName = &""
) -> Dictionary:
	if request == null:
		return {"ok": false, "error": "invalid_request"}
	var validation := _validate_targets(request)
	if not validation.get("ok", false):
		return validation
	var pending := _pending_store.create(request, triggering_condition_id)
	_log.log(
		AhcEnums.LogCategory.ABILITY,
		"effect:pending",
		{
			"pending_id": pending.id,
			"op": request.op,
			"trigger": pending.triggering_condition_id,
		}
	)
	return {"ok": true, "pending_id": pending.id}


func interrupt_cancel_dispatch(target: InterruptTarget) -> Dictionary:
	if target == null:
		return {"ok": false, "error": "invalid_target"}
	match target.kind:
		InterruptTarget.Kind.SEQUENCE, InterruptTarget.Kind.IMPACT:
			if target.pending_id != &"":
				var result := _pending_store.cancel(target.pending_id)
				if result.get("ok", false):
					_log.log(
						AhcEnums.LogCategory.ABILITY,
						"effect:cancelled",
						{"pending_id": target.pending_id}
					)
				return result
			if target.flow_id != &"":
				if _game_ctx == null or _game_ctx.memory == null:
					return {"ok": false, "error": "missing_memory"}
				_game_ctx.memory.cancel_sequence(target.flow_id, target.bind)
				_log.log(
					AhcEnums.LogCategory.ABILITY,
					"effect:sequence_cancelled",
					{"flow_id": target.flow_id, "bind": target.bind}
				)
				return {"ok": true, "flow_id": target.flow_id, "cancelled": true}
			return {"ok": false, "error": "missing_cancel_bind"}
		_:
			return {"ok": false, "error": "cancel_kind_mismatch", "kind": target.kind}


func interrupt_ignore_dispatch(target: InterruptTarget) -> Dictionary:
	if target == null:
		return {"ok": false, "error": "invalid_target"}
	match target.kind:
		InterruptTarget.Kind.IMPACT, InterruptTarget.Kind.SEQUENCE:
			if target.pending_id != &"":
				var result := _pending_store.ignore(target.pending_id)
				if result.get("ok", false):
					_log.log(
						AhcEnums.LogCategory.ABILITY,
						"effect:ignored",
						{"pending_id": target.pending_id}
					)
				return result
			return {"ok": false, "error": "missing_ignore_bind"}
		InterruptTarget.Kind.COST:
			return {"ok": false, "error": "cost_ignore_not_wired"}
		InterruptTarget.Kind.KEYWORD:
			return {"ok": false, "error": "keyword_ignore_not_wired", "keyword": target.keyword}
		InterruptTarget.Kind.CHAOS_TOKEN:
			return {"ok": false, "error": "chaos_ignore_not_wired"}
		_:
			return {"ok": false, "error": "ignore_kind_mismatch", "kind": target.kind}


func apply_interrupt_cancel(target: InterruptTarget) -> Dictionary:
	return interrupt_cancel_dispatch(target)


func apply_interrupt_ignore(target: InterruptTarget) -> Dictionary:
	return interrupt_ignore_dispatch(target)


func cancel_pending(pending_id: StringName) -> Dictionary:
	return interrupt_cancel_dispatch(InterruptTarget.pending_impact(pending_id))


func ignore_pending(pending_id: StringName) -> Dictionary:
	return interrupt_ignore_dispatch(InterruptTarget.pending_impact(pending_id))


func is_pending_registered(pending_id: StringName) -> bool:
	var pending := _pending_store.get_pending(pending_id)
	return pending != null and pending.is_registered()


func replace_instead_dispatch(
	target: ReplacementTarget,
	replacement_request: EffectRequest,
	source_ability_id: StringName = &""
) -> Dictionary:
	if target == null:
		return {"ok": false, "error": "invalid_target"}
	if replacement_request == null:
		return {"ok": false, "error": "invalid_replacement"}
	match target.kind:
		ReplacementTarget.Kind.PENDING:
			if target.pending_id == &"":
				return {"ok": false, "error": "missing_replace_bind"}
			return _register_replacement_store(
				target.pending_id, replacement_request, source_ability_id
			)
		ReplacementTarget.Kind.SEQUENCE:
			return {"ok": false, "error": "sequence_replace_not_wired", "flow_id": target.flow_id}
		ReplacementTarget.Kind.WOULD_TRIGGER:
			return {"ok": false, "error": "would_replace_not_wired", "trigger": target.triggering_condition_id}
		_:
			return {"ok": false, "error": "replace_kind_mismatch", "kind": target.kind}


func apply_replace_instead(
	target: ReplacementTarget,
	replacement_request: EffectRequest,
	source_ability_id: StringName = &""
) -> Dictionary:
	return replace_instead_dispatch(target, replacement_request, source_ability_id)


func register_replacement(
	pending_id: StringName,
	replacement_request: EffectRequest,
	source_ability_id: StringName = &""
) -> Dictionary:
	return replace_instead_dispatch(
		ReplacementTarget.pending(pending_id),
		replacement_request,
		source_ability_id
	)


func _register_replacement_store(
	pending_id: StringName,
	replacement_request: EffectRequest,
	source_ability_id: StringName = &""
) -> Dictionary:
	var result := _pending_store.register_replacement(
		pending_id, replacement_request, source_ability_id
	)
	if result.get("ok", false):
		_log.log(
			AhcEnums.LogCategory.ABILITY,
			"effect:replacement",
			{
				"pending_id": pending_id,
				"initiation_seq": result.get("initiation_seq", 0),
				"source": source_ability_id,
			}
		)
	return result


func resolve_pending(pending_id: StringName) -> Dictionary:
	var pending := _pending_store.get_pending(pending_id)
	if pending == null:
		return {"ok": false, "error": "unknown_pending"}
	if pending.state == PendingResolution.State.RESOLVED:
		return {"ok": false, "error": "already_resolved"}
	if pending.state == PendingResolution.State.IGNORED:
		pending.state = PendingResolution.State.RESOLVED
		pending.was_ignored = true
		_log.log(
			AhcEnums.LogCategory.ABILITY,
			"effect:ignored_resolve",
			{"pending_id": pending_id, "op": pending.request.op}
		)
		return {
			"ok": true,
			"ignored": true,
			"applied": false,
			"pending_id": pending_id,
		}
	var request := _pending_store.request_to_resolve(pending)
	pending.resolved_request = request
	pending.state = PendingResolution.State.RESOLVED
	var winner := _pending_store.winning_replacement(pending)
	if winner != null:
		pending.was_replaced = true
	return _resolve_request(request, pending.id, pending.was_replaced)


func submit(request: EffectRequest, defer_resolve: bool = false) -> Dictionary:
	if defer_resolve:
		return begin_pending(request)
	var begin := begin_pending(request)
	if not begin.get("ok", false):
		return begin
	return resolve_pending(begin.get("pending_id", &""))


func submit_batch(requests: Array, simultaneous: bool = false) -> Array:
	var results: Array = []
	for request in requests:
		if request is EffectRequest:
			results.append(submit(request))
	if simultaneous:
		pass
	return results


func _resolve_request(
	request: EffectRequest,
	pending_id: StringName,
	replaced: bool
) -> Dictionary:
	if request == null:
		return {"ok": false, "error": "invalid_request"}
	var block_reason := _check_cannot(request)
	if block_reason != &"":
		_log.log(
			AhcEnums.LogCategory.ABILITY,
			"effect:blocked",
			{"pending_id": pending_id, "op": request.op, "reason": block_reason}
		)
		return {
			"ok": false,
			"error": RestrictionEvaluator.api_error(block_reason),
			"blocked_by_restriction": true,
			"pending_id": pending_id,
		}
	var result := EffectOpExecutor.execute(request, _game_ctx)
	if result.get("ok", false):
		result["pending_id"] = pending_id
		result["replaced"] = replaced
		_record_applied(request, pending_id)
	return result


func _validate_targets(request: EffectRequest) -> Dictionary:
	if request.controller_id == &"":
		return {"ok": false, "error": "missing_controller"}
	if _state.registry.get_investigator(request.controller_id) == null:
		return {"ok": false, "error": "unknown_controller"}
	return {"ok": true}


func _check_cannot(request: EffectRequest) -> StringName:
	var store := _registration_store()
	if store == null:
		return &""
	return EffectRestrictionGate.block_reason(request, store)


func _registration_store() -> RegistrationStore:
	if _game_ctx == null:
		return null
	return _game_ctx.registrations


func _record_applied(request: EffectRequest, pending_id: StringName = &"") -> void:
	_log.log(
		AhcEnums.LogCategory.ABILITY,
		"effect:%s" % request.op,
		{
			"amount": request.amount,
			"controller": request.controller_id,
			"pending_id": pending_id,
		}
	)
	_events.append(
		AhcEnums.EventRecordKind.EFFECT_APPLIED,
		{
			"op": request.op,
			"amount": request.amount,
			"controller": request.controller_id,
			"pending_id": pending_id,
		},
		_state.compute_state_hash()
	)
