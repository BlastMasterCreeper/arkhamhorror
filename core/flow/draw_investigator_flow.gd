class_name DrawInvestigatorFlow
extends RefCounted

## 调查员抽牌：D1 内联 collect + L1 Composition 批量 D2/D3。


static func run(game_ctx: GameContext, inv_id: StringName, amount: int) -> Dictionary:
	if game_ctx == null or game_ctx.mutator == null:
		return _fail_result()
	return _run_core(game_ctx, inv_id, amount)


## 仅供 dry-run / GameSimulator（无 Catalog、无堆栈）。
## 生产路径必须走 `GameContext.run_seq(&"seq.draw.investigator", …)`（或 catalog.nest）。
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
	## 故意不绑 composition / sequences：走 L0 旁路，避免误触 I2 execute 守卫。
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
	## WHEN_HEADER 由栈信封在 RESOLVE 前打开（when 的 would 头）；此处只 offer WHEN。
	while DrawInvestigatorComposition.draw_slots_filled(memory, inv_id) < amount:
		var collect := collect_one_step(game_ctx, inv_id, catalog)
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
	## SPLIT WHEN：抽取步骤完成（HAND · 控制者已知牌面）。
	## 玩家显现不在此槽；bootstrap 随后 nest seq.enter_hand（绑入手）。
	_offer_draw_slot(game_ctx, AhcEnums.SequencePhase.WHEN)
	return _result_from_memory(memory, inv_id, false)


static func _offer_draw_slot(game_ctx: GameContext, phase: AhcEnums.SequencePhase) -> void:
	if game_ctx == null or game_ctx.sequences == null:
		return
	game_ctx.sequences.offer_slot(phase)


static func _result_from_memory(memory: RulesMemory, inv_id: StringName, defeated: bool) -> Dictionary:
	var drawn := DrawInvestigatorComposition.merged_drawn_cards(memory, inv_id)
	var shuffles := int(memory.get_referent(inv_id, DrawInvestigatorComposition.SHUFFLES_KEY)) if memory else 0
	var horror := int(memory.get_referent(inv_id, DrawInvestigatorComposition.HORROR_KEY)) if memory else 0
	var spawn_failed := (
		DrawInvestigatorComposition.spawn_failed_discards(memory, inv_id)
		if memory
		else [] as Array[StringName]
	)
	return _result(drawn, shuffles, horror, defeated, spawn_failed)


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
	defeated: bool,
	spawn_failed_discards: Array[StringName] = []
) -> Dictionary:
	return {
		"ok": true,
		"drawn": drawn.duplicate(),
		"drew": not drawn.is_empty(),
		"shuffled": shuffles > 0,
		"shuffles": shuffles,
		"horror_taken": horror_taken,
		"defeated": defeated,
		"spawn_failed_discards": spawn_failed_discards.duplicate(),
	}

## --- D1 子步（原 DrawSubflowFlowHandlers） ---

## D1 内联收集步 + 按卡面能力包分流 + `seq.draw.empty_piles_defeated` resolve。


static func collect_one_step(
	game_ctx: GameContext,
	inv_id: StringName,
	catalog: SequenceCatalog = null
) -> Dictionary:
	var mutator := game_ctx.mutator
	var memory := game_ctx.memory
	var executor := game_ctx.composition
	if mutator == null:
		return {"collected": false, "defeated": false}
	if mutator.deck_is_empty(inv_id):
		if mutator.discard_is_empty(inv_id):
			if catalog != null:
				catalog.nest(game_ctx, &"seq.draw.empty_piles_defeated", {"inv_id": inv_id})
			else:
				resolve_empty_piles_defeated(game_ctx, inv_id)
			return {"collected": false, "defeated": true}
		if executor != null:
			executor.execute(DrawInvestigatorComposition.shuffle_and_horror(inv_id))
		else:
			mutator.shuffle_discard_into_deck(inv_id)
			mutator.transfer_marker(
				AhcEnums.MarkerKind.HORROR_TAKEN,
				1,
				MarkerSlot.supply(AhcEnums.MarkerKind.HORROR_TAKEN),
				MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.HORROR_TAKEN)
			)
		DrawInvestigatorComposition.increment_shuffle_horror(memory, inv_id)
	var card_id := mutator.pop_deck_top(inv_id)
	if card_id == &"":
		return {"collected": false, "defeated": false}
	## enemy/treachery → 遭遇侧能力体系；其余 → 调查员揭示/入手包。
	if CardAbilityPackage.uses_encounter_package(game_ctx, card_id):
		var settle := _settle_encounter_package(game_ctx, inv_id, card_id, catalog)
		var spawn_failed: Array = settle.get("spawn_failed_discards", [])
		if not spawn_failed.has(card_id):
			DrawInvestigatorComposition.append_bound(memory, inv_id, card_id)
		return {
			"collected": true,
			"defeated": false,
			"encounter_package": true,
			"card_id": card_id,
		}
	DrawInvestigatorComposition.append_pending(memory, inv_id, card_id)
	return {"collected": true, "defeated": false}


static func _settle_encounter_package(
	game_ctx: GameContext,
	inv_id: StringName,
	card_id: StringName,
	catalog: SequenceCatalog
) -> Dictionary:
	var result: Dictionary = {}
	if catalog != null and catalog.has_flow(&"seq.encounter.resolve_card"):
		result = catalog.nest(
			game_ctx,
			&"seq.encounter.resolve_card",
			{"drawer_id": inv_id, "card_id": card_id}
		)
	else:
		result = DrawEncounterFlow.resolve_card(game_ctx, inv_id, card_id)
	var memory := game_ctx.memory
	if memory != null:
		for failed_id in result.get("spawn_failed_discards", []):
			DrawInvestigatorComposition.append_spawn_failed(
				memory, inv_id, failed_id as StringName
			)
	return result


static func resolve_empty_piles_defeated(game_ctx: GameContext, inv_id: StringName) -> Dictionary:
	## 空库+空弃 → 立即击败并受 1 点精神创伤（Grimoire）。
	if game_ctx != null and game_ctx.state != null:
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null:
			inv.mental_trauma += 1
	return DefeatFlow.defeat_investigator_effect(game_ctx, inv_id)
