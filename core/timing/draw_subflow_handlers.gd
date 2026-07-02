class_name DrawSubflowHandlers
extends RefCounted

## D1 内联收集步 + weakness 重定向 + `seq.draw.empty_piles_defeated` resolve。


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
			mutator.adjust_marker(
				MarkerSlot.investigator(inv_id, AhcEnums.MarkerKind.HORROR_TAKEN),
				1
			)
		DrawInvestigatorComposition.increment_shuffle_horror(memory, inv_id)
	var card_id := mutator.pop_deck_top(inv_id)
	if card_id == &"":
		return {"collected": false, "defeated": false}
	if WeaknessRoute.is_encounter_draw(game_ctx, card_id):
		var bound_result := _redirect_encounter_weakness(game_ctx, inv_id, card_id, catalog)
		var spawn_failed: Array = bound_result.get("spawn_failed_discards", [])
		if not spawn_failed.has(card_id):
			DrawInvestigatorComposition.append_bound(memory, inv_id, card_id)
		return {"collected": true, "defeated": false, "redirected": true, "bound_card_id": card_id}
	DrawInvestigatorComposition.append_pending(memory, inv_id, card_id)
	return {"collected": true, "defeated": false}


static func _redirect_encounter_weakness(
	game_ctx: GameContext,
	inv_id: StringName,
	card_id: StringName,
	catalog: SequenceCatalog
) -> Dictionary:
	var result: Dictionary = {}
	if catalog != null:
		result = catalog.nest(
			game_ctx,
			&"seq.draw.encounter.resolve_bound",
			{"drawer_id": inv_id, "card_id": card_id}
		)
	else:
		result = DrawEncounterFlow.resolve_bound(game_ctx, inv_id, card_id)
	var memory := game_ctx.memory
	if memory != null:
		for failed_id in result.get("spawn_failed_discards", []):
			DrawInvestigatorComposition.append_spawn_failed(
				memory, inv_id, failed_id as StringName
			)
	return result


static func resolve_empty_piles_defeated(game_ctx: GameContext, inv_id: StringName) -> Dictionary:
	return InvestigatorElimination.eliminate(game_ctx, inv_id)
