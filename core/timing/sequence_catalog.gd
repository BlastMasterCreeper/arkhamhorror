class_name SequenceCatalog
extends RefCounted

enum EntryKind { RUN, NEST_BATCH }

var _entries: Dictionary = {}


## `split_timing`：信封头 WOULD（抽牌 SPLIT）。`no_envelope_slot`：信封不开槽，
## 由 handler 在砖块边界 `offer_slot`（伤害 Apply 等）。
func register_run(
	flow_id: StringName,
	build_trigger: Callable,
	resolve: Callable,
	split_timing: bool = false,
	no_envelope_slot: bool = false
) -> void:
	_entries[flow_id] = {
		"kind": EntryKind.RUN,
		"build_trigger": build_trigger,
		"handler": resolve,
		"split_timing": split_timing,
		"no_envelope_slot": no_envelope_slot,
	}


func register_nest_batch(flow_id: StringName, handler: Callable) -> void:
	_entries[flow_id] = {
		"kind": EntryKind.NEST_BATCH,
		"handler": handler,
	}


func has_flow(flow_id: StringName) -> bool:
	return _entries.has(flow_id)


## 已注册 flow_id 快照（审计 / 测试）；顺序不稳定。
func registered_flow_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key in _entries.keys():
		out.append(key as StringName)
	return out


func run(game_ctx: GameContext, flow_id: StringName, params: Dictionary = {}) -> Dictionary:
	return _invoke(game_ctx, flow_id, params, false)


func nest(game_ctx: GameContext, flow_id: StringName, params: Dictionary = {}) -> Dictionary:
	return _invoke(game_ctx, flow_id, params, true)


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
	## NEST_BATCH 无独立信封；在 handler 前消费账本（与 RUN 的 RESOLVE 同语义）。
	var gated := _apply_effect_gate(game_ctx, flow_id, params)
	if gated.has("early"):
		return gated.get("early", {}) as Dictionary
	var result: Dictionary = handler.call(game_ctx, gated.get("params", params))
	return _annotate_replaced(result, gated)


func _invoke(
	game_ctx: GameContext,
	flow_id: StringName,
	params: Dictionary,
	as_nest: bool
) -> Dictionary:
	var entry: Dictionary = _entries.get(flow_id, {})
	if entry.is_empty():
		push_warning("SequenceCatalog: unknown flow %s" % flow_id)
		return {}
	if entry.get("kind", EntryKind.RUN) != EntryKind.RUN:
		push_warning("SequenceCatalog: %s is not a RUN flow" % flow_id)
		return {}
	var resolved: Array[Dictionary] = [{}]
	## Cancel / Ignore / Instead 在 RESOLVE 砖消费（Would 窗内仍可打标）。
	var resolve_fn := func() -> void:
		var gated := _apply_effect_gate(game_ctx, flow_id, params)
		if gated.has("early"):
			resolved[0] = gated.get("early", {}) as Dictionary
			return
		var working: Dictionary = gated.get("params", params) as Dictionary
		var handler: Callable = entry.get("handler", Callable())
		if handler.is_valid():
			resolved[0] = _annotate_replaced(handler.call(game_ctx, working), gated)
	var build_trigger: Callable = entry.get("build_trigger", Callable())
	if game_ctx != null and game_ctx.sequences != null and build_trigger.is_valid():
		var trigger: TriggeringCondition = build_trigger.call(params)
		if as_nest:
			game_ctx.sequences.nest(
				trigger,
				resolve_fn,
				bool(entry.get("split_timing", false)),
				bool(entry.get("no_envelope_slot", false))
			)
		else:
			game_ctx.sequences.run(
				trigger,
				resolve_fn,
				bool(entry.get("split_timing", false)),
				bool(entry.get("no_envelope_slot", false))
			)
	else:
		resolve_fn.call()
	return resolved[0]


## 对可打断手续消费 RulesMemory 账本；interrupt/replace 自身不计。
func _apply_effect_gate(
	game_ctx: GameContext,
	flow_id: StringName,
	params: Dictionary
) -> Dictionary:
	if not uses_effect_gate(flow_id):
		return {"params": params}
	if game_ctx == null or game_ctx.memory == null:
		return {"params": params}
	var bind := RulesMemory.effect_bind_from_params(params)
	var gate: Dictionary = game_ctx.memory.consume_effect_gate(flow_id, bind)
	if bool(gate.get("cancelled", false)):
		return {
			"early": {
				"ok": false,
				"cancelled": true,
				"applied": false,
				"error": "sequence_cancelled",
			}
		}
	if bool(gate.get("ignored", false)):
		return {
			"early": {
				"ok": true,
				"ignored": true,
				"applied": false,
			}
		}
	var working := params
	var replaced := false
	if bool(gate.get("replaced", false)):
		replaced = true
		working = params.duplicate()
		var repl: Dictionary = gate.get("replacement_params", {}) as Dictionary
		for key in repl.keys():
			working[key] = repl[key]
		## gain 兼容：Instead 的 amount / base_amount 覆盖原 base_amount。
		if repl.has("base_amount"):
			working["base_amount"] = int(repl.get("base_amount", 0))
		elif repl.has("amount"):
			working["base_amount"] = int(repl.get("amount", 0))
	return {"params": working, "replaced": replaced}


func _annotate_replaced(result: Dictionary, gated: Dictionary) -> Dictionary:
	if result == null or result.is_empty():
		result = {}
	if bool(gated.get("replaced", false)):
		result["replaced"] = true
	return result


static func uses_effect_gate(flow_id: StringName) -> bool:
	var s := String(flow_id)
	if s.begins_with("seq.interrupt.") or s.begins_with("seq.replace."):
		return false
	if s.begins_with("seq.effect."):
		return true
	if s.begins_with("seq.draw."):
		return true
	if s.begins_with("seq.chaos."):
		return true
	match flow_id:
		&"seq.ability.resolve", &"seq.play", &"seq.encounter.revelation", &"seq.enter_hand":
			return true
		_:
			return false
