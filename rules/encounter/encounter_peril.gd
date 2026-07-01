class_name EncounterPeril
extends RefCounted

## 险境 G2：Register RESTRICTION · WHILE_DRAWN_CARD_RESOLVING(card_id)；G4 完 Unregister。


static func register_if_peril(
	game_ctx: GameContext,
	drawer_id: StringName,
	card_id: StringName,
	has_peril_keyword: bool
) -> void:
	if not has_peril_keyword or game_ctx == null or card_id == &"":
		return
	if game_ctx.registrations.has_peril_for_drawn_card(card_id):
		return
	var template := RegistrationTemplate.peril_drawn_card_resolving(drawer_id, card_id)
	var node := CompositionNode.register(template)
	node.provenance = AbilityUnitRef.from_framework(&"seq.draw.encounter")
	game_ctx.composition.execute(node)


static func unregister_for_card(game_ctx: GameContext, card_id: StringName) -> void:
	if game_ctx == null or card_id == &"":
		return
	game_ctx.registrations.unregister_by_drawn_card(card_id)


## @deprecated 使用 register_if_peril / unregister_for_card
static func apply_e3_check(
	game_ctx: GameContext,
	frame: EncounterResolutionFrame,
	has_peril_keyword: bool
) -> void:
	if frame == null:
		return
	var card_id := frame.current_card_id
	if card_id == &"":
		card_id = frame.id
	register_if_peril(game_ctx, frame.drawer_id, card_id, has_peril_keyword)


static func detach_frame(game_ctx: GameContext, frame: EncounterResolutionFrame) -> void:
	if game_ctx == null or frame == null:
		return
	if frame.current_card_id != &"":
		unregister_for_card(game_ctx, frame.current_card_id)


static func peril_active_for_card(game_ctx: GameContext, card_id: StringName) -> bool:
	if game_ctx == null or card_id == &"":
		return false
	return game_ctx.registrations.has_peril_for_drawn_card(card_id)


static func sync_test_context_from_frame(
	test_ctx: SkillTestContext,
	game_ctx: GameContext
) -> void:
	if test_ctx == null or game_ctx == null or game_ctx.memory == null:
		return
	var frame := game_ctx.memory.peek_encounter_frame()
	if frame == null:
		return
	test_ctx.encounter_resolution_id = frame.id
	test_ctx.peril = peril_active_for_card(game_ctx, frame.current_card_id)
