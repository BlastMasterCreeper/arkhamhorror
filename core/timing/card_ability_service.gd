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
	flow_id: StringName = &"",
	defer_limbo_finalize: bool = false
) -> bool:
	if game_ctx == null or game_ctx.composition == null:
		return false
	var card := _get_card(game_ctx, card_id)
	if card == null:
		return false
	var units := CardRegistry.revelation_units_at(card.id.definition_id)
	if game_ctx.config != null and game_ctx.config.enter_hand_timing != null:
		units = game_ctx.config.enter_hand_timing.order_ability_units(units)
	if units.is_empty():
		return false
	var bind_dict := {"card_id": card_id}
	if (
		game_ctx.memory != null
		and game_ctx.memory.is_sequence_cancelled(flow_id, bind_dict)
	):
		return true
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
		# #region agent log
		if str(card.id.definition_id) == "12127":
			var _cf := FileAccess.open("/opt/cursor/logs/debug.log", FileAccess.READ_WRITE)
			if _cf == null:
				_cf = FileAccess.open("/opt/cursor/logs/debug.log", FileAccess.WRITE)
			if _cf != null:
				_cf.seek_end()
				var child_atoms: Array = []
				if node.kind == AhcEnums.CompositionNodeKind.SEQ:
					for ch in node.children:
						if ch != null:
							child_atoms.append({"kind": ch.kind, "atom": str(ch.atom_name), "skill_spec": str(ch.test_skill_spec), "diff_src": str(ch.test_difficulty_source), "mem": str(ch.memory_key), "opts": ch.choice_option_ids.duplicate(), "has_st7": ch.st7_plan != null})
				_cf.store_line(JSON.stringify({
					"hypothesisId": "E",
					"location": "card_ability_service.gd:resolve_revelations",
					"message": "built_tree",
					"data": {"def": str(card.id.definition_id), "controller": str(controller_id), "root_kind": node.kind, "root_atom": str(node.atom_name), "children": child_atoms},
					"timestamp": Time.get_ticks_msec(),
				}))
				_cf.close()
		# #endregion
		game_ctx.composition.execute(node)
	if not defer_limbo_finalize and _mutator != null:
		_mutator.finalize_limbo_discard(card_id, controller_id)
	return true


func _get_card(game_ctx: GameContext, card_id: StringName) -> CardInstance:
	if game_ctx == null or game_ctx.state == null:
		return null
	return game_ctx.state.registry.get_card(card_id)
