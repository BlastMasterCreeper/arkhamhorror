class_name EncounterGainedKeyword
extends RefCounted

## 动态 keyword · G3 Grant · G5 evaluate · GainStore（非 Registration 载荷）。


static func register_if_absent(
	game_ctx: GameContext,
	card_id: StringName,
	keyword: StringName,
	provenance: AbilityUnitRef = null
) -> void:
	if game_ctx == null or card_id == &"" or keyword == &"":
		return
	if game_ctx.gains != null and game_ctx.gains.has_gained_keyword(card_id, keyword):
		return
	var template := GainTemplate.keyword_drawn_card_resolving(card_id, keyword)
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
