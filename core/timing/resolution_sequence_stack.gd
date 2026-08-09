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


func run(trigger: TriggeringCondition, resolve_fn: Callable) -> void:
	_push_frame(trigger)
	_run_response_loop(AhcEnums.SequencePhase.WHEN)
	_run_phase(AhcEnums.SequencePhase.RESOLVE, resolve_fn)
	_run_response_loop(AhcEnums.SequencePhase.AFTER)
	_pop_frame()


func nest(trigger: TriggeringCondition, resolve_fn: Callable) -> void:
	run(trigger, resolve_fn)


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
	while true:
		_response_window.next_round()
		var handled := _dispatch_handlers(frame, phase)
		if handled == 0:
			break
	if phase == AhcEnums.SequencePhase.AFTER:
		_emit_after_timing(frame)
	_response_window.close()
	_resolved_in_window = previous_resolved


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
	var matched: Array[SequenceHandler] = []
	for handler in _handlers:
		if handler.phase != phase:
			continue
		if not handler.enabled:
			continue
		if not handler.matches(frame.trigger):
			continue
		if _is_handler_resolved(handler):
			continue
		if is_self_response_blocked(handler.source_id):
			continue
		matched.append(handler)
	if matched.is_empty():
		return 0
	# 类别优先级：整 tier 排序；同类内顺序待 ResponseWindow.resolve_batch（06 §8.2）。
	matched.sort_custom(func(a: SequenceHandler, b: SequenceHandler) -> bool:
		return int(a.tier) < int(b.tier)
	)
	var handled := 0
	for handler in matched:
		if not handler.callback.is_valid():
			continue
		_mark_handler_resolved(handler)
		handler.callback.call()
		handled += 1
	return handled


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
