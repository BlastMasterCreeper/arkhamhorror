class_name EncounterGainedKeyword
extends RefCounted

## 动态 / 印刷关键词 KEYWORD 标记门面 → KeywordMount.mount_gained。
## 幂等；开火见 KeywordMount / KeywordConsumer。


static func register_if_absent(
	game_ctx: GameContext,
	card_id: StringName,
	keyword: StringName,
	provenance: AbilityUnitRef = null
) -> void:
	KeywordMount.mount_gained(game_ctx, card_id, keyword, provenance)


static func register_surge(
	game_ctx: GameContext,
	card_id: StringName,
	provenance: AbilityUnitRef = null
) -> void:
	register_if_absent(game_ctx, card_id, &"surge", provenance)


static func unregister_for_card(game_ctx: GameContext, card_id: StringName) -> void:
	if game_ctx == null or card_id == &"":
		return
	game_ctx.registrations.unregister_gained_keywords_for_drawn_card(card_id)
