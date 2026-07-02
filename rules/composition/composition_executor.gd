class_name CompositionExecutor
extends RefCounted

var _state: GameStateStore
var _registrations: RegistrationStore
var _mutator: StateMutator
var _log: GameLog
var _game_ctx: GameContext
var _draw: DrawInvestigatorService


func _init(
	state: GameStateStore,
	registrations: RegistrationStore,
	mutator: StateMutator,
	log: GameLog
) -> void:
	_state = state
	_registrations = registrations
	_mutator = mutator
	_log = log


func bind_game_context(ctx: GameContext) -> void:
	_game_ctx = ctx
	if ctx:
		_draw = ctx.draw_investigator


func execute(node: CompositionNode) -> void:
	_stamp_provenance(node)
	match node.kind:
		AhcEnums.CompositionNodeKind.SEQ:
			for child in node.children:
				execute(child)
		AhcEnums.CompositionNodeKind.ATOM:
			_execute_atom(node)
		AhcEnums.CompositionNodeKind.REGISTER:
			_execute_register(node)


func _stamp_provenance(node: CompositionNode) -> void:
	if node.provenance == null:
		return
	_log.log(
		AhcEnums.LogCategory.ABILITY,
		"composition:provenance",
		node.provenance.to_log_dict()
	)


func _execute_atom(node: CompositionNode) -> void:
	match node.atom_name:
		&"draw":
			if RestrictionEvaluator.blocks_draw(node.inv_id, _registrations):
				_log.log(AhcEnums.LogCategory.CARD, "composition:draw_blocked", {"inv": node.inv_id})
				return
			var amount := maxi(node.draw_amount, 1)
			if _draw and _game_ctx:
				_draw.draw_cards(_game_ctx, node.inv_id, amount, [&"composition_draw"])
			else:
				_mutator.execute_draw_instruction(node.inv_id, amount)
			_log.log(AhcEnums.LogCategory.CARD, "composition:draw", {"inv": node.inv_id, "amount": amount})
		&"move_card":
			if node.to_slot != null:
				_mutator.move_card(node.card_id, node.to_slot)
				_log.log(AhcEnums.LogCategory.CARD, "composition:move_card", {"card": node.card_id})
		&"adjust_marker":
			if node.marker_slot != null:
				_mutator.adjust_marker(node.marker_slot, node.marker_delta)
				_log.log(
					AhcEnums.LogCategory.CARD,
					"composition:adjust_marker",
					{"delta": node.marker_delta}
				)
		&"set_flag":
			_mutator.set_flag(node.inv_id, node.flag_field, node.flag_value)
			_log.log(AhcEnums.LogCategory.CARD, "composition:set_flag", {"bearer": node.inv_id})
		&"reveal_to_controller":
			_mutator.reveal_to_controller(node.card_id, node.inv_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:reveal_to_controller",
				{"card": node.card_id, "controller": node.inv_id}
			)
		&"reveal_to_all":
			_mutator.reveal_to_all(node.card_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:reveal_to_all",
				{"card": node.card_id}
			)
		&"pop_deck_top":
			var card_id := _mutator.pop_deck_top(node.inv_id)
			if _game_ctx != null and _game_ctx.memory != null and card_id != &"":
				DrawInvestigatorComposition.append_pending(_game_ctx.memory, node.inv_id, card_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:pop_deck_top",
				{"inv": node.inv_id, "card": card_id}
			)
		&"shuffle_discard_into_deck":
			_mutator.shuffle_discard_into_deck(node.inv_id)
			_log.log(AhcEnums.LogCategory.CARD, "composition:shuffle_discard", {"inv": node.inv_id})
		&"commit_enter_hand":
			_mutator.commit_enter_hand(node.card_id, node.inv_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:commit_enter_hand",
				{"inv": node.inv_id, "card": node.card_id}
			)
		&"commit_hidden_enter_hand":
			_mutator.commit_hidden_enter_hand(node.card_id, node.inv_id)
			if _game_ctx != null:
				EncounterPrivacy.register_leave_hand_restriction(
					_game_ctx, node.card_id, node.inv_id
				)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:commit_hidden_enter_hand",
				{"inv": node.inv_id, "card": node.card_id}
			)
		&"expose_hidden":
			_mutator.expose_hidden_card(node.card_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:expose_hidden",
				{"card": node.card_id}
			)
		&"spawn_encounter_enemy":
			if _game_ctx != null and _game_ctx.sequence_catalog != null:
				_game_ctx.sequence_catalog.nest(
					_game_ctx,
					&"seq.encounter.spawn",
					{
						"drawer_id": node.inv_id,
						"card_id": node.card_id,
						"from_hand": true,
					}
				)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:spawn_encounter_enemy",
				{"inv": node.inv_id, "card": node.card_id}
			)
		&"discard_encounter_from_hand":
			if _game_ctx != null:
				EncounterCardDiscard.discard_from_investigator_to_encounter_pile(
					_game_ctx, node.card_id, node.inv_id
				)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:discard_encounter_from_hand",
				{"inv": node.inv_id, "card": node.card_id}
			)
		_:
			push_warning("CompositionExecutor: unknown atom %s" % node.atom_name)


func _execute_register(node: CompositionNode) -> void:
	if node.register_template == null:
		return
	var reg_id := _registrations.register(node.register_template)
	_log.log(AhcEnums.LogCategory.ABILITY, "composition:register", {"reg": reg_id})
