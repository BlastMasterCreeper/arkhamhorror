class_name WeaknessRoute
extends RefCounted

enum Route { INVESTIGATOR_DRAW, ENCOUNTER_DRAW }


static func route_for_definition(definition_id: StringName) -> Route:
	if not CardRegistry.is_weakness(definition_id):
		return Route.INVESTIGATOR_DRAW
	match CardRegistry.card_type(definition_id):
		&"enemy", &"treachery":
			return Route.ENCOUNTER_DRAW
		_:
			return Route.INVESTIGATOR_DRAW


static func route_for_card(game_ctx: GameContext, card_id: StringName) -> Route:
	if game_ctx == null or game_ctx.state == null:
		return Route.INVESTIGATOR_DRAW
	var card := game_ctx.state.registry.get_card(card_id)
	if card == null:
		return Route.INVESTIGATOR_DRAW
	return route_for_definition(card.id.definition_id)


static func is_encounter_draw(game_ctx: GameContext, card_id: StringName) -> bool:
	return route_for_card(game_ctx, card_id) == Route.ENCOUNTER_DRAW
