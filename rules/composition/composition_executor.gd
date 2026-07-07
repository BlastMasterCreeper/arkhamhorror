class_name CompositionExecutor
extends RefCounted

var _state: GameStateStore
var _registrations: RegistrationStore
var _mutator: StateMutator
var _log: GameLog
var _game_ctx: GameContext
var _draw: DrawInvestigatorService
var _last_step_created: bool = false


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


## Seq 内上一子步是否 CREATED（after_step If · 07 §3.3 / §4.4）。
func last_step_created() -> bool:
	return _last_step_created


func execute(node: CompositionNode) -> void:
	_last_step_created = false
	_run_node(node)


func _run_node(node: CompositionNode) -> void:
	_stamp_provenance(node)
	match node.kind:
		AhcEnums.CompositionNodeKind.SEQ:
			for child in node.children:
				_run_node(child)
		AhcEnums.CompositionNodeKind.ATOM:
			_last_step_created = _execute_atom(node)
			_record_composition_step(node, _last_step_created)
		AhcEnums.CompositionNodeKind.REGISTER:
			_last_step_created = _execute_register(node)
			_record_composition_step(node, _last_step_created)
		AhcEnums.CompositionNodeKind.IF:
			_execute_if(node)


func _stamp_provenance(node: CompositionNode) -> void:
	if node.provenance == null:
		return
	_log.log(
		AhcEnums.LogCategory.ABILITY,
		"composition:provenance",
		node.provenance.to_log_dict()
	)


func _record_composition_step(node: CompositionNode, created: bool) -> void:
	if _game_ctx == null or _game_ctx.events == null:
		return
	var payload := {
		"created": created,
		"inv_id": node.inv_id,
		"card_id": node.card_id,
	}
	if node.kind == AhcEnums.CompositionNodeKind.ATOM:
		payload["atom"] = node.atom_name
	var rec := _game_ctx.events.append(
		AhcEnums.EventRecordKind.COMPOSITION_STEP,
		payload,
		_state.compute_state_hash() if _state else ""
	)
	if _game_ctx.stat_projections != null:
		_game_ctx.stat_projections.on_event(rec)


func _execute_atom(node: CompositionNode) -> bool:
	match node.atom_name:
		&"draw":
			if RestrictionEvaluator.blocks_draw(node.inv_id, _registrations):
				_log.log(AhcEnums.LogCategory.CARD, "composition:draw_blocked", {"inv": node.inv_id})
				return false
			var amount := maxi(node.draw_amount, 1)
			if _draw and _game_ctx:
				_draw.draw_cards(_game_ctx, node.inv_id, amount, [&"composition_draw"])
			else:
				_mutator.execute_draw_instruction(node.inv_id, amount)
			_log.log(AhcEnums.LogCategory.CARD, "composition:draw", {"inv": node.inv_id, "amount": amount})
			return true
		&"move_card":
			if node.to_slot != null:
				_mutator.move_card(node.card_id, node.to_slot)
				_log.log(AhcEnums.LogCategory.CARD, "composition:move_card", {"card": node.card_id})
				return true
			return false
		&"adjust_marker":
			if node.marker_slot != null:
				_mutator.adjust_marker(node.marker_slot, node.marker_delta)
				_log.log(
					AhcEnums.LogCategory.CARD,
					"composition:adjust_marker",
					{"delta": node.marker_delta}
				)
				return true
			return false
		&"set_flag":
			_mutator.set_flag(node.inv_id, node.flag_field, node.flag_value)
			_log.log(AhcEnums.LogCategory.CARD, "composition:set_flag", {"bearer": node.inv_id})
			return true
		&"reveal_to_controller":
			_mutator.reveal_to_controller(node.card_id, node.inv_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:reveal_to_controller",
				{"card": node.card_id, "controller": node.inv_id}
			)
			return true
		&"reveal_to_all":
			_mutator.reveal_to_all(node.card_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:reveal_to_all",
				{"card": node.card_id}
			)
			return true
		&"pop_deck_top":
			var card_id := _mutator.pop_deck_top(node.inv_id)
			if _game_ctx != null and _game_ctx.memory != null and card_id != &"":
				DrawInvestigatorComposition.append_pending(_game_ctx.memory, node.inv_id, card_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:pop_deck_top",
				{"inv": node.inv_id, "card": card_id}
			)
			return card_id != &""
		&"shuffle_discard_into_deck":
			if _mutator.deck_is_empty(node.inv_id) and not _mutator.discard_is_empty(node.inv_id):
				_mutator.shuffle_discard_into_deck(node.inv_id)
				_log.log(AhcEnums.LogCategory.CARD, "composition:shuffle_discard", {"inv": node.inv_id})
				return true
			return false
		&"commit_enter_hand":
			_mutator.commit_enter_hand(node.card_id, node.inv_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:commit_enter_hand",
				{"inv": node.inv_id, "card": node.card_id}
			)
			return true
		&"enter_threat_area":
			_mutator.commit_enter_threat_area(node.card_id, node.inv_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:enter_threat_area",
				{"inv": node.inv_id, "card": node.card_id}
			)
			return true
		&"lose_all_resources":
			var inv := _state.registry.get_investigator(node.inv_id)
			if inv != null and inv.resource_pool > 0:
				_mutator.adjust_marker(
					MarkerSlot.investigator(node.inv_id, AhcEnums.MarkerKind.RESOURCE),
					-inv.resource_pool
				)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:lose_all_resources",
				{"inv": node.inv_id}
			)
			return inv != null
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
			return true
		&"expose_hidden":
			_mutator.expose_hidden_card(node.card_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:expose_hidden",
				{"card": node.card_id}
			)
			return true
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
			return true
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
			return true
		&"cancel_pending":
			if _game_ctx != null and _game_ctx.effects != null:
				_game_ctx.effects.cancel_pending(node.pending_id)
				return node.pending_id != &""
			return false
		&"ignore_pending":
			if _game_ctx != null and _game_ctx.effects != null:
				_game_ctx.effects.ignore_pending(node.pending_id)
				return node.pending_id != &""
			return false
		&"interrupt":
			if _game_ctx != null and _game_ctx.effects != null and node.interrupt_target != null:
				if node.interrupt_mode == &"ignore":
					_game_ctx.effects.apply_interrupt_ignore(node.interrupt_target)
				else:
					_game_ctx.effects.apply_interrupt_cancel(node.interrupt_target)
				return true
			return false
		&"replace_pending":
			if _game_ctx != null and _game_ctx.effects != null and node.effect_request != null:
				_game_ctx.effects.register_replacement(
					node.pending_id,
					node.effect_request,
					node.source_ability_id
				)
				return node.pending_id != &""
			return false
		&"replace_instead":
			if (
				_game_ctx != null
				and _game_ctx.effects != null
				and node.replace_target != null
				and node.effect_request != null
			):
				_game_ctx.effects.apply_replace_instead(
					node.replace_target,
					node.effect_request,
					node.source_ability_id
				)
				return true
			return false
		&"resolve_pending":
			if _game_ctx != null and _game_ctx.effects != null:
				_game_ctx.effects.resolve_pending(node.pending_id)
				return node.pending_id != &""
			return false
		&"place_doom_nearest_enemy_without_doom":
			if _game_ctx != null:
				return EncounterDoomPlacement.place_on_nearest_enemy_without_doom(
					_game_ctx, node.inv_id, node.card_id
				)
			return false
		_:
			push_warning("CompositionExecutor: unknown atom %s" % node.atom_name)
			return false


func _execute_if(node: CompositionNode) -> void:
	if node.branch_condition == null:
		return
	var take_then := node.branch_condition.matches_domain(_game_ctx, node.inv_id)
	var branch: CompositionNode = node.then_branch if take_then else node.else_branch
	if branch != null:
		branch.provenance = node.provenance
		_run_node(branch)


func _execute_register(node: CompositionNode) -> bool:
	if node.register_template == null:
		return false
	var reg_id := _registrations.register(node.register_template)
	_log.log(AhcEnums.LogCategory.ABILITY, "composition:register", {"reg": reg_id})
	return reg_id != &""
