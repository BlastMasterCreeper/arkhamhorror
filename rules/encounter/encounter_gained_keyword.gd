class_name EncounterGainedKeyword
extends RefCounted

## 动态 keyword · G3 Grant · G5 evaluate · GainStore（非 Registration 载荷）。
## Grimoire：同一 keyword 不可 gain 超过一次（含印刷已有）。


static func register_if_absent(
	game_ctx: GameContext,
	card_id: StringName,
	keyword: StringName,
	provenance: AbilityUnitRef = null
) -> void:
	if game_ctx == null or card_id == &"" or keyword == &"":
		return
	var def_id: StringName = &""
	var card = game_ctx.state.registry.get_card(card_id) if game_ctx.state != null else null
	if card != null:
		def_id = card.id.definition_id
	if EffectiveCharacteristicQuery.has_effective_keyword(game_ctx, card_id, def_id, keyword):
		return
	var template := GainTemplate.keyword_drawn_card_resolving(
		card_id, keyword, AhcEnums.CharacteristicSourceKind.ENCOUNTER
	)
	if game_ctx.sequence_catalog == null:
		push_error("EncounterGainedKeyword: sequence_catalog missing; vacuum refused")
		return
	game_ctx.sequence_catalog.nest(
		game_ctx,
		&"seq.effect.grant",
		{
			"controller_id": &"",
			"card_id": card_id,
			"template": template,
		}
	)


static func register_surge(
	game_ctx: GameContext,
	card_id: StringName,
	provenance: AbilityUnitRef = null
) -> void:
	register_if_absent(game_ctx, card_id, &"surge", provenance)


static func unregister_for_card(game_ctx: GameContext, card_id: StringName) -> void:
	if game_ctx == null or card_id == &"" or game_ctx.gains == null:
		return
	game_ctx.gains.unregister_keywords_for_drawn_card(card_id)
	if game_ctx.losts != null:
		game_ctx.losts.unregister_for_drawn_card(card_id)
