class_name ResolutionSequenceStack
extends RefCounted

var _frames: Array[ResolutionSequenceFrame] = []
var _handlers: Array[SequenceHandler] = []
var _log: GameLog
var _events: EventRecordLog
var _memory: RulesMemory
var _game_ctx: GameContext = null
var _response_window: TimingWindow = TimingWindow.new()
var _causation_stack: Array[StringName] = []
var _resolved_in_window: Dictionary = {}
## 时点响应窗粘性意愿池（16 §7.1）；仅当前 _run_response_loop 生命周期。
var _willingness_pool: Array[SequenceHandler] = []
var _willingness_declined: Dictionary = {}


func _init(log: GameLog, events: EventRecordLog, memory: RulesMemory) -> void:
	_log = log
	_events = events
	_memory = memory


func bind_game_context(ctx: GameContext) -> void:
	_game_ctx = ctx


func register_handler(handler: SequenceHandler) -> void:
	_handlers.append(handler)


func unregister_handlers_by_source(source_id: StringName) -> void:
	if source_id == &"":
		return
	for i in range(_handlers.size() - 1, -1, -1):
		if _handlers[i].source_id == source_id:
			_handlers.remove_at(i)


func depth() -> int:
	return _frames.size()


func response_window_open() -> bool:
	return _response_window.open


func response_round() -> int:
	return _response_window.response_round


func current_trigger() -> TriggeringCondition:
	if _frames.is_empty():
		return null
	return _frames[_frames.size() - 1].trigger


func build_application_context(phase: AhcEnums.SequencePhase = AhcEnums.SequencePhase.RESOLVE) -> ApplicationContext:
	var trigger := current_trigger()
	if trigger == null or _game_ctx == null:
		return ApplicationContext.new()
	return ApplicationContext.from_sequence(_game_ctx, trigger, phase)


func begin_ability_resolution(source_id: StringName) -> void:
	if source_id != &"":
		_causation_stack.append(source_id)


func end_ability_resolution() -> void:
	if not _causation_stack.is_empty():
		_causation_stack.pop_back()


func is_self_response_blocked(source_id: StringName) -> bool:
	if source_id == &"":
		return false
	return source_id in _causation_stack


## `split_timing`：信封头 **WOULD**（抽牌第一块前）。
## `no_envelope_slot`：信封不开槽（伤害等：时点只挂 Apply 砖，见 `offer_slot`）。
func run(
	trigger: TriggeringCondition,
	resolve_fn: Callable,
	split_timing: bool = false,
	no_envelope_slot: bool = false
) -> void:
	_push_frame(trigger)
	if not no_envelope_slot:
		if split_timing:
			_run_response_loop(AhcEnums.SequencePhase.WOULD)
		else:
			_run_response_loop(AhcEnums.SequencePhase.WHEN)
	_run_phase(AhcEnums.SequencePhase.RESOLVE, resolve_fn)
	_run_response_loop(AhcEnums.SequencePhase.AFTER)
	_pop_frame()


func nest(
	trigger: TriggeringCondition,
	resolve_fn: Callable,
	split_timing: bool = false,
	no_envelope_slot: bool = false
) -> void:
	run(trigger, resolve_fn, split_timing, no_envelope_slot)


## RESOLVE 砖块边界打开 WOULD / WHEN（当前帧，不 push）。
## 抽牌：信封 WOULD + 入手后 WHEN；伤害：Apply 前 WOULD→WHEN（均 PreImpact）。
func offer_slot(phase: AhcEnums.SequencePhase) -> void:
	if _frames.is_empty():
		return
	if (
		phase != AhcEnums.SequencePhase.WOULD
		and phase != AhcEnums.SequencePhase.WHEN
	):
		push_warning("ResolutionSequenceStack.offer_slot: only WOULD/WHEN (%s)" % phase)
		return
	var frame := _frames[_frames.size() - 1]
	var previous_phase := frame.phase
	_run_response_loop(phase)
	frame.phase = previous_phase


func _push_frame(trigger: TriggeringCondition) -> void:
	var frame := ResolutionSequenceFrame.new()
	frame.trigger = trigger
	frame.depth = _frames.size()
	_frames.append(frame)


func _pop_frame() -> void:
	if not _frames.is_empty():
		_frames.pop_back()


func _run_response_loop(phase: AhcEnums.SequencePhase) -> void:
	if _frames.is_empty():
		return
	var frame := _frames[_frames.size() - 1]
	frame.phase = phase
	_record_phase(frame, phase)
	_response_window.open_for(frame.trigger, phase)
	## 每层 response 窗口独立已结算表，避免 nest 清空父窗口导致 Forced 重入死循环。
	var previous_resolved: Dictionary = _resolved_in_window
	_resolved_in_window = {}
	var previous_pool: Array[SequenceHandler] = _willingness_pool
	var previous_declined: Dictionary = _willingness_declined
	_willingness_pool = []
	_willingness_declined = {}
	while true:
		_response_window.next_round()
		var handled := _dispatch_handlers(frame, phase)
		if handled == 0:
			break
	if phase == AhcEnums.SequencePhase.AFTER:
		_emit_after_timing(frame)
	_response_window.close()
	_resolved_in_window = previous_resolved
	_willingness_pool = previous_pool
	_willingness_declined = previous_declined


func _run_phase(phase: AhcEnums.SequencePhase, resolve_fn: Callable = Callable()) -> void:
	if _frames.is_empty():
		return
	var frame := _frames[_frames.size() - 1]
	frame.phase = phase
	_record_phase(frame, phase)
	if phase == AhcEnums.SequencePhase.RESOLVE and resolve_fn.is_valid():
		resolve_fn.call()


func _record_phase(frame: ResolutionSequenceFrame, phase: AhcEnums.SequencePhase) -> void:
	_memory.record_phase(frame.trigger, phase, frame.depth)
	_log.log(
		AhcEnums.LogCategory.SYSTEM,
		"sequence:%s" % _memory.phase_label(phase),
		{"kind": frame.trigger.kind, "depth": frame.depth}
	)
	if _events:
		_events.append(
			AhcEnums.EventRecordKind.SEQUENCE_STEP,
			{"phase": phase, "kind": frame.trigger.kind, "depth": frame.depth}
		)


func _dispatch_handlers(frame: ResolutionSequenceFrame, phase: AhcEnums.SequencePhase) -> int:
	var matched: Array[SequenceHandler] = _collect_matched_handlers(frame, phase)
	if matched.is_empty() and _willingness_pool.is_empty():
		return 0
	var auto_batch: Array[SequenceHandler] = []
	var willingness_candidates: Array[SequenceHandler] = []
	for handler in matched:
		if _is_willingness_candidate(handler):
			willingness_candidates.append(handler)
		else:
			auto_batch.append(handler)
	auto_batch.sort_custom(func(a: SequenceHandler, b: SequenceHandler) -> bool:
		return int(a.tier) < int(b.tier)
	)
	var handled := 0
	for handler in auto_batch:
		if not handler.callback.is_valid():
			continue
		_mark_handler_resolved(handler)
		handler.callback.call()
		handled += 1
	handled += _run_willingness_round(willingness_candidates)
	return handled


func _collect_matched_handlers(
	frame: ResolutionSequenceFrame,
	phase: AhcEnums.SequencePhase
) -> Array[SequenceHandler]:
	## L0 = matches(kind)；其后 EligibilityPipeline COLLECT L1–L5（06 §5）。
	var matched: Array[SequenceHandler] = []
	var app_ctx := build_application_context(phase)
	for handler in _handlers:
		if handler.phase != phase:
			continue
		if not handler.matches(frame.trigger):
			continue
		if _is_handler_resolved(handler):
			continue
		if not EligibilityPipeline.passes_collect(
			handler,
			_game_ctx,
			app_ctx,
			is_self_response_blocked(handler.source_id)
		):
			continue
		matched.append(handler)
	return matched


func _is_willingness_candidate(handler: SequenceHandler) -> bool:
	return (
		handler != null
		and handler.tier == SequenceHandler.Tier.TRIGGERED
		and handler.player_initiated
	)


## 粘性意愿池一轮：未入池者 join/decline → 池非空则队长放行 1 条（16 §7.1）。
func _run_willingness_round(candidates: Array[SequenceHandler]) -> int:
	_prune_willingness_pool()
	for handler in candidates:
		var key := _handler_key(handler)
		if _willingness_declined.has(key):
			continue
		if _willingness_pool_has(handler):
			continue
		if _ask_willingness_join(handler):
			_willingness_pool.append(handler)
		else:
			_willingness_declined[key] = true
	if _willingness_pool.is_empty():
		return 0
	var picked: SequenceHandler = _pick_willingness_one()
	if picked == null:
		return 0
	_remove_from_willingness_pool(picked)
	if not picked.callback.is_valid():
		_mark_handler_resolved(picked)
		return 1
	_mark_handler_resolved(picked)
	picked.callback.call()
	return 1


func _ask_willingness_join(handler: SequenceHandler) -> bool:
	if _game_ctx == null or _game_ctx.interaction == null:
		## 无交互层：保守不入池（与默认 skip 一致）。
		return false
	var mode := AhcEnums.AbilityResponseMode.ASK
	if _game_ctx.ability_response_prefs != null:
		mode = _game_ctx.ability_response_prefs.mode_for_handler(handler)
	match mode:
		AhcEnums.AbilityResponseMode.AUTO_JOIN:
			return true
		AhcEnums.AbilityResponseMode.AUTO_DECLINE:
			return false
		_:
			pass
	var controller := handler.controller_id
	if controller == &"" and _game_ctx.state != null:
		controller = _game_ctx.state.lead_investigator_id
	return _game_ctx.interaction.ask_willingness_join(handler, controller, _game_ctx)


func _pick_willingness_one() -> SequenceHandler:
	if _willingness_pool.is_empty():
		return null
	if _willingness_pool.size() == 1:
		return _willingness_pool[0]
	if _game_ctx == null or _game_ctx.interaction == null:
		return _willingness_pool[0]
	var lead := _lead_id()
	var option_ids: Array = []
	var by_id: Dictionary = {}
	for handler in _willingness_pool:
		var oid := _willingness_option_id(handler)
		option_ids.append(oid)
		by_id[oid] = handler
	var pick: Variant = _game_ctx.interaction.ask_pick_willingness(option_ids, lead, _game_ctx)
	if pick != null and by_id.has(pick):
		return by_id[pick] as SequenceHandler
	## 默认 / 未命中 → 注册序首项。
	return _willingness_pool[0]


func _willingness_option_id(handler: SequenceHandler) -> StringName:
	if handler.source_id != &"":
		return handler.source_id
	return StringName("handler_%s" % _handler_key(handler))


func _lead_id() -> StringName:
	if _game_ctx == null:
		return &""
	if _game_ctx.lead_investigator_id != &"":
		return _game_ctx.lead_investigator_id
	if _game_ctx.state != null:
		return _game_ctx.state.lead_investigator_id
	return &""


func _willingness_pool_has(handler: SequenceHandler) -> bool:
	var key := _handler_key(handler)
	for entry in _willingness_pool:
		if _handler_key(entry) == key:
			return true
	return false


func _remove_from_willingness_pool(handler: SequenceHandler) -> void:
	var key := _handler_key(handler)
	for i in range(_willingness_pool.size() - 1, -1, -1):
		if _handler_key(_willingness_pool[i]) == key:
			_willingness_pool.remove_at(i)


func _prune_willingness_pool() -> void:
	## nest 返回后重验：非法自动出池（16 §7.1）。
	var phase := AhcEnums.SequencePhase.AFTER
	if not _frames.is_empty():
		phase = _frames[_frames.size() - 1].phase
	var app_ctx := build_application_context(phase)
	for i in range(_willingness_pool.size() - 1, -1, -1):
		var handler := _willingness_pool[i]
		if handler == null or _is_handler_resolved(handler):
			_willingness_pool.remove_at(i)
			continue
		if not EligibilityPipeline.passes_collect(
			handler,
			_game_ctx,
			app_ctx,
			is_self_response_blocked(handler.source_id)
		):
			_willingness_pool.remove_at(i)


func _handler_key(handler: SequenceHandler) -> String:
	return str(handler.get_instance_id())


func _is_handler_resolved(handler: SequenceHandler) -> bool:
	return _resolved_in_window.has(_handler_key(handler))


func _mark_handler_resolved(handler: SequenceHandler) -> void:
	_resolved_in_window[_handler_key(handler)] = true


func _emit_after_timing(frame: ResolutionSequenceFrame) -> void:
	if _game_ctx == null or _game_ctx.timing == null:
		return
	var timing := frame.trigger.after_timing
	if timing == &"":
		return
	var payload := frame.trigger.payload.duplicate()
	payload["kind"] = frame.trigger.kind
	payload["controller"] = frame.trigger.controller_id
	payload["response_round"] = _response_window.response_round
	_game_ctx.timing.emit_timing(timing, payload)
