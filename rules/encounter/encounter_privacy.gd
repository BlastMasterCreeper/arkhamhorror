class_name EncounterPrivacy
extends RefCounted

## 隐私（Hidden）E4：Register RESTRICTION · WHILE_HIDDEN_IN_HAND(card_id)；卡面能力合法离手时 Unregister。


static func register_leave_hand_restriction(
	game_ctx: GameContext,
	card_id: StringName,
	controller_id: StringName
) -> void:
	if game_ctx == null or card_id == &"" or controller_id == &"":
		return
	if game_ctx.registrations.has_hidden_leave_hand_restriction(card_id):
		return
	var template := RegistrationTemplate.hidden_in_hand(controller_id, card_id)
	var node := CompositionNode.register(template)
	node.provenance = AbilityUnitRef.from_framework(&"seq.encounter.revelation")
	game_ctx.composition.execute(node)


static func unregister_for_card(game_ctx: GameContext, card_id: StringName) -> void:
	if game_ctx == null or card_id == &"":
		return
	game_ctx.registrations.unregister_by_hidden_in_hand_card(card_id)
