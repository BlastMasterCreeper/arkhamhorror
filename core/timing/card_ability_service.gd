class_name CardAbilityService
extends RefCounted

var _mutator: StateMutator


func _init(mutator: StateMutator = null) -> void:
	_mutator = mutator


func bind_mutator(mutator: StateMutator) -> void:
	_mutator = mutator


func has_revelation(game_ctx: GameContext, card_id: StringName) -> bool:
	var card := _get_card(game_ctx, card_id)
	if card == null:
		return false
	return CardRegistry.has_revelation(card.id.definition_id)


func resolve_revelations(
	game_ctx: GameContext,
	controller_id: StringName,
	card_id: StringName,
	flow_id: StringName = &""
) -> bool:
	if game_ctx == null or game_ctx.composition == null:
		return false
	var card := _get_card(game_ctx, card_id)
	if card == null:
		return false
	var units := CardRegistry.revelation_units_at(card.id.definition_id)
	if units.is_empty():
		return false
	var bind := AbilityBindContext.new()
	bind.flow_id = flow_id
	bind.controller_id = controller_id
	bind.card_id = card_id
	for unit in units:
		var builder: Callable = unit.get("builder", Callable())
		if not builder.is_valid():
			continue
		var node: CompositionNode = builder.call(bind)
		if node == null:
			continue
		node.provenance = AbilityUnitRef.from_card_ability(
			flow_id,
			card.id.definition_id,
			unit.get("ability_id", &"") as StringName,
			card_id
		)
		game_ctx.composition.execute(node)
	if _mutator != null:
		_mutator.finalize_limbo_discard(card_id, controller_id)
	return true


func _get_card(game_ctx: GameContext, card_id: StringName) -> CardInstance:
	if game_ctx == null or game_ctx.state == null:
		return null
	return game_ctx.state.registry.get_card(card_id)
