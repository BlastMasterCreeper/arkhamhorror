class_name EffectiveCharacteristicQuery
extends RefCounted

## 06 §3.2 · printed ∪ gained − lose（互斥时 Silver / 同级 PI 默认）。


static func has_effective_keyword(
	game_ctx: GameContext,
	card_id: StringName,
	definition_id: StringName,
	keyword: StringName
) -> bool:
	return CharacteristicPossessionResolver.has_effective_keyword(
		game_ctx, card_id, definition_id, keyword
	)


static func has_printed_keyword(definition_id: StringName, keyword: StringName) -> bool:
	return CardRegistry.has_keyword(definition_id, keyword)
