class_name SequenceCatalog
extends RefCounted

enum EntryKind { RUN, NEST_BATCH }

var _entries: Dictionary = {}


func register_run(
	flow_id: StringName,
	build_trigger: Callable,
	resolve: Callable
) -> void:
	_entries[flow_id] = {
		"kind": EntryKind.RUN,
		"build_trigger": build_trigger,
		"handler": resolve,
	}


func register_nest_batch(flow_id: StringName, handler: Callable) -> void:
	_entries[flow_id] = {
		"kind": EntryKind.NEST_BATCH,
		"handler": handler,
	}


func has_flow(flow_id: StringName) -> bool:
	return _entries.has(flow_id)


func run(game_ctx: GameContext, flow_id: StringName, params: Dictionary = {}) -> Dictionary:
	var entry: Dictionary = _entries.get(flow_id, {})
	if entry.is_empty():
		push_warning("SequenceCatalog: unknown flow %s" % flow_id)
		return {}
	if entry.get("kind", EntryKind.RUN) != EntryKind.RUN:
		push_warning("SequenceCatalog: %s is not a RUN flow" % flow_id)
		return {}
	var resolved: Array[Dictionary] = [{}]
	var resolve_fn := func() -> void:
		var handler: Callable = entry.get("handler", Callable())
		if handler.is_valid():
			resolved[0] = handler.call(game_ctx, params)
	var build_trigger: Callable = entry.get("build_trigger", Callable())
	if game_ctx != null and game_ctx.sequences != null and build_trigger.is_valid():
		var trigger: TriggeringCondition = build_trigger.call(params)
		game_ctx.sequences.run(trigger, resolve_fn)
	else:
		resolve_fn.call()
	return resolved[0]


func nest_batch(game_ctx: GameContext, flow_id: StringName, params: Dictionary = {}) -> Dictionary:
	var entry: Dictionary = _entries.get(flow_id, {})
	if entry.is_empty():
		push_warning("SequenceCatalog: unknown flow %s" % flow_id)
		return {}
	if entry.get("kind", EntryKind.RUN) != EntryKind.NEST_BATCH:
		push_warning("SequenceCatalog: %s is not a NEST_BATCH flow" % flow_id)
		return {}
	var handler: Callable = entry.get("handler", Callable())
	if not handler.is_valid():
		return {}
	return handler.call(game_ctx, params)


func nest(game_ctx: GameContext, flow_id: StringName, params: Dictionary = {}) -> Dictionary:
	var entry: Dictionary = _entries.get(flow_id, {})
	if entry.is_empty():
		push_warning("SequenceCatalog: unknown flow %s" % flow_id)
		return {}
	if entry.get("kind", EntryKind.RUN) != EntryKind.RUN:
		push_warning("SequenceCatalog: %s is not a RUN flow" % flow_id)
		return {}
	var resolved: Array[Dictionary] = [{}]
	var resolve_fn := func() -> void:
		var handler: Callable = entry.get("handler", Callable())
		if handler.is_valid():
			resolved[0] = handler.call(game_ctx, params)
	var build_trigger: Callable = entry.get("build_trigger", Callable())
	if game_ctx != null and game_ctx.sequences != null and build_trigger.is_valid():
		var trigger: TriggeringCondition = build_trigger.call(params)
		game_ctx.sequences.nest(trigger, resolve_fn)
	else:
		resolve_fn.call()
	return resolved[0]
