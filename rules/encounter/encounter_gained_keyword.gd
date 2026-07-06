class_name EncounterGainedKeyword
extends RefCounted

## 动态 keyword · G3 Register · G5 evaluate · 06 §3.1–§3.2


static func register_if_absent(
	game_ctx: GameContext,
	card_id: StringName,
	keyword: StringName,
	provenance: AbilityUnitRef = null
) -> void:
	if game_ctx == null or card_id == &"" or keyword == &"":
		return
	if game_ctx.registrations.has_keyword_buff(card_id, keyword):
		return
	var template := RegistrationTemplate.gained_keyword_drawn_card_resolving(card_id, keyword)
	var node := CompositionNode.register(template)
	if provenance != null:
		node.provenance = provenance
	else:
		node.provenance = AbilityUnitRef.from_framework(&"seq.draw.encounter")
	game_ctx.composition.execute(node)


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
