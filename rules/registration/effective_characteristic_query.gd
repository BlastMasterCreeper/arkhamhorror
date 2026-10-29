class_name EffectiveCharacteristicQuery
extends RefCounted

## 06 §3.2 · printed ∪ gained。gained 读 GainStore（不是 Buff）。


static func has_effective_keyword(
	game_ctx: GameContext,
	card_id: StringName,
	definition_id: StringName,
	keyword: StringName
) -> bool:
	if keyword == &"":
		return false
	if CardRegistry.has_keyword(definition_id, keyword):
		return true
	if game_ctx == null or game_ctx.gains == null or card_id == &"":
		return false
	return game_ctx.gains.has_gained_keyword(card_id, keyword)


static func has_printed_keyword(definition_id: StringName, keyword: StringName) -> bool:
	return CardRegistry.has_keyword(definition_id, keyword)
