class_name InvestigatorElimination
extends RefCounted

## 调查员淘汰 · 遭遇牌清理（威胁区 + 手牌隐私遭遇 → 遭遇弃牌堆）。


static func eliminate(game_ctx: GameContext, inv_id: StringName) -> Dictionary:
	var discarded: Array[StringName] = []
	if game_ctx == null or game_ctx.mutator == null:
		return {"eliminated": false, "defeated": false, "discarded": discarded}
	if game_ctx.state == null:
		game_ctx.mutator.set_flag(inv_id, AhcEnums.FlagField.ELIMINATED, true)
		return {"eliminated": true, "defeated": true, "discarded": discarded}
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null:
		return {"eliminated": false, "defeated": false, "discarded": discarded}
	for card_id in inv.threat_area.duplicate():
		if _is_encounter_card(game_ctx, card_id):
			if EncounterCardDiscard.discard_from_investigator_to_encounter_pile(
				game_ctx, card_id, inv_id
			):
				discarded.append(card_id)
	for card_id in inv.hand.duplicate():
		if _is_hidden_encounter_in_hand(game_ctx, inv_id, card_id):
			if EncounterCardDiscard.discard_from_investigator_to_encounter_pile(
				game_ctx, card_id, inv_id
			):
				discarded.append(card_id)
	game_ctx.mutator.set_flag(inv_id, AhcEnums.FlagField.ELIMINATED, true)
	return {"eliminated": true, "defeated": true, "discarded": discarded}


static func _is_encounter_card(game_ctx: GameContext, card_id: StringName) -> bool:
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	if card.owner_id == &"encounter":
		return true
	return game_ctx.state.registry.get_enemy(card_id) != null


static func _is_hidden_encounter_in_hand(
	game_ctx: GameContext,
	inv_id: StringName,
	card_id: StringName
) -> bool:
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return false
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null or not inv.hand.has(card_id):
		return false
	if not CardRegistry.is_hidden(card.id.definition_id):
		return false
	return card.owner_id == &"encounter"
