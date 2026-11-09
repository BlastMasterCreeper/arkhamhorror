class_name EffectiveCharacteristicQuery
extends RefCounted

## 06 §3.2 · printed ∪ gained characteristic 查询。


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
	if game_ctx == null or game_ctx.registrations == null or card_id == &"":
		return false
	return game_ctx.registrations.has_keyword_buff(card_id, keyword)


static func has_printed_keyword(definition_id: StringName, keyword: StringName) -> bool:
	return CardRegistry.has_keyword(definition_id, keyword)
