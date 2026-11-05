class_name EncounterGainedKeyword
extends RefCounted

## 动态 / 印刷关键词 KEYWORD 标记 · WHILE_DRAWN_CARD_RESOLVING · 06 §3.1–§3.2
## 幂等：已有同名标记则 no-op（印刷 WHEN + gains 不叠）。开火见 KeywordMount / KeywordConsumer。


static func register_if_absent(
	game_ctx: GameContext,
	card_id: StringName,
	keyword: StringName,
	_provenance: AbilityUnitRef = null
) -> void:
	if game_ctx == null or card_id == &"" or keyword == &"":
		return
	if game_ctx.registrations.has_keyword_buff(card_id, keyword):
		return
	var template := RegistrationTemplate.gained_keyword_drawn_card_resolving(card_id, keyword)
	CompositionMount.register_effect(game_ctx, template, &"", card_id)


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
