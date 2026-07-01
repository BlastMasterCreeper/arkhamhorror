class_name StatProjectionStore
extends RefCounted

var _events: EventRecordLog = null
var _state: GameStateStore = null
var _by_reg: Dictionary = {}  # reg_id -> { queries, controller_id }
var _interest_ref: Dictionary = {}  # interest_token -> int
var _hot: Dictionary = {}  # projection_key -> StatProjection


func bind(events: EventRecordLog, state: GameStateStore) -> void:
	_events = events
	_state = state


func attach(reg_id: StringName, queries: Array, controller_id: StringName) -> void:
	if reg_id == &"":
		return
	var qlist: Array = []
	for q in queries:
		if q is StatQuery:
			qlist.append(q)
	_by_reg[reg_id] = {"queries": qlist, "controller_id": controller_id}
	var scope := StatScope.for_inv_turn(controller_id, _state.turn_id if _state else 0)
	for q in qlist:
		var token := (q as StatQuery).interest_token(scope)
		_interest_ref[token] = int(_interest_ref.get(token, 0)) + 1


func detach(reg_id: StringName) -> void:
	var entry: Variant = _by_reg.get(reg_id)
	if entry == null:
		return
	var data: Dictionary = entry
	var controller_id: StringName = data.get("controller_id", &"")
	var queries: Array = data.get("queries", [])
	var scope := StatScope.for_inv_turn(controller_id, _state.turn_id if _state else 0)
	for q in queries:
		if q is StatQuery:
			var token := (q as StatQuery).interest_token(scope)
			var next_ref: int = int(_interest_ref.get(token, 0)) - 1
			if next_ref <= 0:
				_interest_ref.erase(token)
				_drop_hot_for_interest(token)
			else:
				_interest_ref[token] = next_ref
	_by_reg.erase(reg_id)


func ensure_hot(queries: Array, eval_ctx: EvaluationContext) -> Dictionary:
	var snapshot: Dictionary = {}
	if _events == null or eval_ctx == null:
		return snapshot
	for q in queries:
		if q is not StatQuery:
			continue
		var scope := eval_ctx.scope()
		var pkey := (q as StatQuery).snapshot_key(scope)
		var proj: StatProjection = _hot.get(pkey)
		if proj == null or proj.state != StatProjection.State.HOT:
			proj = _cold_materialize(q as StatQuery, scope, eval_ctx.as_of_seq)
			_hot[pkey] = proj
		snapshot[pkey] = proj.value
	return snapshot


func ensure_hot_for_registrations(eval_ctx: EvaluationContext) -> Dictionary:
	var union: Array = []
	for reg_id in _by_reg.keys():
		var data: Dictionary = _by_reg[reg_id]
		for q in data.get("queries", []):
			if q is StatQuery and q not in union:
				union.append(q)
	return ensure_hot(union, eval_ctx)


func on_event(rec: EventRecord) -> void:
	if rec == null:
		return
	for pkey in _hot.keys():
		var proj: StatProjection = _hot[pkey]
		if proj.state != StatProjection.State.HOT:
			continue
		if not _interest_ref.has(_interest_token_for_projection(proj)):
			continue
		_apply_event_to_projection(proj, rec)


func hot_count() -> int:
	return _hot.size()


func get_value(query: StatQuery, eval_ctx: EvaluationContext) -> Variant:
	var snap := ensure_hot([query], eval_ctx)
	var pkey := query.snapshot_key(eval_ctx.scope())
	return snap.get(pkey, 0)


func _cold_materialize(query: StatQuery, scope: StatScope, as_of_seq: int) -> StatProjection:
	var proj := StatProjection.new()
	proj.query_key = query.snapshot_key(scope)
	proj.query = query
	proj.scope = scope
	proj.state = StatProjection.State.HOT
	proj.watermark_seq = as_of_seq
	var window := _events.event_index.window_for(scope.inv_id, scope.turn_id, as_of_seq)
	var start_seq: int = int(window.get("start_seq", 0))
	var end_seq: int = int(window.get("end_seq", as_of_seq))
	var slice: Array = []
	for rec in _events.get_records():
		if rec.seq >= start_seq and rec.seq <= end_seq:
			slice.append(rec)
	proj.value = StatFolder.fold(slice, query, scope)
	var token := query.interest_token(scope)
	proj.ref_count = int(_interest_ref.get(token, 0))
	return proj


func _apply_event_to_projection(proj: StatProjection, rec: EventRecord) -> void:
	if proj.scope == null:
		return
	if rec.payload.get("inv_id", &"") != proj.scope.inv_id:
		return
	match rec.kind:
		AhcEnums.EventRecordKind.ACTION_SPEND:
			proj.value = int(proj.value) + int(rec.payload.get("cost", 1))
			proj.watermark_seq = rec.seq
		AhcEnums.EventRecordKind.ACTION_SPEND_VOID:
			proj.value = maxi(int(proj.value) - int(rec.payload.get("cost", 1)), 0)
			proj.watermark_seq = rec.seq


func _interest_token_for_projection(proj: StatProjection) -> StringName:
	if proj.query == null or proj.scope == null:
		return &""
	return proj.query.interest_token(proj.scope)


func _drop_hot_for_interest(token: StringName) -> void:
	var to_erase: Array[StringName] = []
	for pkey in _hot.keys():
		var proj: StatProjection = _hot[pkey]
		if proj.query == null or proj.scope == null:
			continue
		if proj.query.interest_token(proj.scope) == token:
			to_erase.append(pkey)
	for pkey in to_erase:
		_hot.erase(pkey)
