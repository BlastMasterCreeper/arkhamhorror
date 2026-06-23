class_name DrawInvestigatorFlow
extends RefCounted

## 调查员抽牌：catalog 子 flow 收集 + L1 Composition 批量 D2/D3。


static func run(game_ctx: GameContext, inv_id: StringName, amount: int) -> Dictionary:
	if game_ctx == null or game_ctx.mutator == null:
		return _fail_result()
	return _run_core(game_ctx, inv_id, amount)


static func run_mutator_only(mutator: StateMutator, inv_id: StringName, amount: int) -> Dictionary:
	var inv := mutator.state().registry.get_investigator(inv_id)
	if inv == null:
		return _fail_result()
	if amount <= 0:
		return _empty_result()
	var memory := RulesMemory.new()
	var ctx := GameContext.new()
	ctx.mutator = mutator
	ctx.memory = memory
	return _run_core(ctx, inv_id, amount)


static func _run_core(game_ctx: GameContext, inv_id: StringName, amount: int) -> Dictionary:
	var mutator := game_ctx.mutator
	var executor := game_ctx.composition
	var memory := game_ctx.memory
	var catalog := game_ctx.sequence_catalog
	var inv := mutator.state().registry.get_investigator(inv_id)
	if inv == null:
		return _fail_result()
	if amount <= 0:
		return _empty_result()
	DrawInvestigatorComposition.init_draw_state(memory, inv_id)
	while DrawInvestigatorComposition.pending_count(memory, inv_id) < amount:
		var collect: Dictionary
		if catalog != null and game_ctx.sequences != null:
			collect = catalog.nest(game_ctx, &"seq.draw.collect_one", {"inv_id": inv_id})
		else:
			collect = DrawSubflowHandlers.resolve_collect_one(game_ctx, inv_id, null)
		if collect.get("defeated", false):
			return _result_from_memory(memory, inv_id, true)
		if not collect.get("collected", false):
			if mutator.discard_is_empty(inv_id):
				return _result_from_memory(memory, inv_id, true)
			continue
	var drawn := DrawInvestigatorComposition.pending_cards(memory, inv_id)
	if executor != null:
		executor.execute(DrawInvestigatorComposition.reveal_batch(inv_id, drawn))
		executor.execute(DrawInvestigatorComposition.enter_hand_batch(inv_id, drawn))
	else:
		for card_id in drawn:
			mutator.reveal_to_controller(card_id, inv_id)
		for card_id in drawn:
			mutator.commit_enter_hand(card_id, inv_id)
	return _result_from_memory(memory, inv_id, false)


static func _result_from_memory(memory: RulesMemory, inv_id: StringName, defeated: bool) -> Dictionary:
	var drawn := DrawInvestigatorComposition.pending_cards(memory, inv_id)
	var shuffles := int(memory.get_referent(inv_id, DrawInvestigatorComposition.SHUFFLES_KEY)) if memory else 0
	var horror := int(memory.get_referent(inv_id, DrawInvestigatorComposition.HORROR_KEY)) if memory else 0
	return _result(drawn, shuffles, horror, defeated)


static func _fail_result() -> Dictionary:
	return {
		"ok": false,
		"error": "unknown_investigator",
		"drawn": [],
		"drew": false,
		"shuffled": false,
		"shuffles": 0,
		"horror_taken": 0,
		"defeated": false,
	}


static func _empty_result() -> Dictionary:
	return _result([], 0, 0, false)


static func _result(
	drawn: Array[StringName],
	shuffles: int,
	horror_taken: int,
	defeated: bool
) -> Dictionary:
	return {
		"ok": true,
		"drawn": drawn.duplicate(),
		"drew": not drawn.is_empty(),
		"shuffled": shuffles > 0,
		"shuffles": shuffles,
		"horror_taken": horror_taken,
		"defeated": defeated,
	}
