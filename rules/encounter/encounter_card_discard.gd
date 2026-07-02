class_name EncounterCardDiscard
extends RefCounted

## 遭遇牌离手 → 遭遇弃牌堆（卡面能力 / 淘汰清理共用）。


static func discard_from_investigator_to_encounter_pile(
	game_ctx: GameContext,
	card_id: StringName,
	inv_id: StringName
) -> bool:
	if game_ctx == null or game_ctx.mutator == null or card_id == &"":
		return false
	EncounterPrivacy.unregister_for_card(game_ctx, card_id)
	var registry := game_ctx.state.registry
	if registry.get_enemy(card_id) != null:
		registry.unregister_enemy(card_id)
	var inv := registry.get_investigator(inv_id)
	if inv != null:
		inv.threat_area.erase(card_id)
	return game_ctx.mutator.move_card(card_id, CardSlot.encounter_discard_top())
