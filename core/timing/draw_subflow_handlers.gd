class_name DrawSubflowHandlers
extends RefCounted

## seq.draw.collect_one / seq.draw.empty_piles_defeated 的 resolve 体。


static func resolve_collect_one(game_ctx: GameContext, inv_id: StringName, catalog: SequenceCatalog) -> Dictionary:
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
	var before := DrawInvestigatorComposition.pending_count(memory, inv_id)
	if executor != null:
		executor.execute(CompositionNode.pop_deck_top(inv_id))
	else:
		var card_id := mutator.pop_deck_top(inv_id)
		if card_id != &"":
			DrawInvestigatorComposition.append_pending(memory, inv_id, card_id)
	var collected := DrawInvestigatorComposition.pending_count(memory, inv_id) > before
	return {"collected": collected, "defeated": false}


static func resolve_empty_piles_defeated(game_ctx: GameContext, inv_id: StringName) -> Dictionary:
	var mutator := game_ctx.mutator
	var executor := game_ctx.composition
	if executor != null:
		executor.execute(CompositionNode.set_flag(inv_id, AhcEnums.FlagField.ELIMINATED, true))
	elif mutator != null:
		mutator.set_flag(inv_id, AhcEnums.FlagField.ELIMINATED, true)
	return {"defeated": true}
