class_name CompositionExecutor
extends RefCounted

var _state: GameStateStore
var _registrations: RegistrationStore
var _mutator: StateMutator
var _log: GameLog
var _game_ctx: GameContext
var _draw: DrawInvestigatorService
var _dry_runner: CompositionDryRunner = CompositionDryRunner.new()
var _last_step_created: bool = false
var _last_skill_test_fail_by: int = 0
var _last_step_enemy_id: StringName = &""
var _last_step_engaged_investigator: StringName = &""
var _last_resolved_location: StringName = &""
var _inv_override_stack: Array[StringName] = []


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


func last_step_engaged_investigator() -> StringName:
	return _last_step_engaged_investigator


func last_skill_test_fail_by() -> int:
	return _last_skill_test_fail_by


func execute(node: CompositionNode) -> void:
	_last_step_created = false
	_last_skill_test_fail_by = 0
	_last_step_enemy_id = &""
	_last_step_engaged_investigator = &""
	_last_resolved_location = &""
	_inv_override_stack.clear()
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
		AhcEnums.CompositionNodeKind.CHOICE:
			_execute_choice(node)
		AhcEnums.CompositionNodeKind.REPEAT:
			_execute_repeat(node)
		AhcEnums.CompositionNodeKind.FOR_EACH:
			_execute_for_each(node)


func _resolve_inv(node: CompositionNode) -> StringName:
	if node.inv_id == CompositionNode.INV_EACH and not _inv_override_stack.is_empty():
		return _inv_override_stack[_inv_override_stack.size() - 1]
	return node.inv_id


func _execute_for_each(node: CompositionNode) -> void:
	if node.children.is_empty() or _game_ctx == null or _game_ctx.framework == null:
		return
	var order: Array[StringName] = []
	if node.for_each_source == &"player_order":
		order = _game_ctx.framework.player_order.duplicate()
	else:
		order = _state.registry.all_investigator_ids()
	for inv_id in order:
		var inv := _state.registry.get_investigator(inv_id)
		if inv == null or inv.eliminated or inv.resigned:
			continue
		_inv_override_stack.append(inv_id)
		_run_node(node.children[0])
		_inv_override_stack.pop_back()


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
			var entered := _mutator.commit_enter_threat_area(node.card_id, node.inv_id)
			if entered and _game_ctx != null and _game_ctx.triggered_abilities != null:
				_game_ctx.triggered_abilities.install_card(node.inv_id, node.card_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:enter_threat_area",
				{"inv": node.inv_id, "card": node.card_id}
			)
			return entered
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
		&"place_doom_on_current_agenda":
			if _game_ctx != null:
				return EncounterAgendaDoomPlacement.place_on_current_agenda(
					_game_ctx, node.may_advance_agenda
				)
			return false
		&"place_clue_on_investigator_location":
			if _game_ctx != null:
				return InvestigatorCluePlacement.place_one_on_investigator_location(
					_game_ctx, node.inv_id
				)
			return false
		&"nest_skill_test":
			return _execute_nest_skill_test(node)
		&"nest_enemy_resolve_location":
			return _execute_nest_enemy_resolve_location(node)
		&"nest_enemy_move":
			return _execute_nest_enemy_move(node)
		&"nest_enemy_attack":
			return _execute_nest_enemy_attack(node)
		&"exhaust_card":
			return _execute_exhaust_card(node)
		&"nest_move_connecting":
			return _execute_nest_move_connecting(node)
		&"take_horror":
			var horror_inv := _resolve_inv(node)
			if horror_inv == &"":
				return false
			_mutator.take_horror(horror_inv, node.marker_delta)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:take_horror",
				{"inv": horror_inv, "amount": node.marker_delta}
			)
			return true
		&"take_damage":
			var dmg_inv := _resolve_inv(node)
			if dmg_inv == &"":
				return false
			_mutator.adjust_marker(
				MarkerSlot.investigator(dmg_inv, AhcEnums.MarkerKind.DAMAGE),
				node.marker_delta
			)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:take_damage",
				{"inv": dmg_inv, "amount": node.marker_delta}
			)
			return true
		&"discard_all_enemies_in_play":
			return ScenarioCompositionAtoms.discard_all_enemies_in_play(_game_ctx)
		&"put_locations_into_play":
			return ScenarioCompositionAtoms.put_locations_into_play(
				_game_ctx, node.location_ids
			)
		&"spawn_set_aside_enemy_at":
			return ScenarioCompositionAtoms.spawn_set_aside_enemy_at(
				_game_ctx, node.definition_id, node.location_target
			)
		&"attach_set_aside_to_host":
			return ScenarioCompositionAtoms.attach_set_aside_to_host(
				_game_ctx, node.definition_id, node.card_id, node.atom_count
			)
		&"attach_limbo_to_nearest_location_without":
			return EncounterAttachment.attach_limbo_to_nearest_location_without(
				_game_ctx,
				node.card_id,
				_resolve_inv(node),
				node.definition_id
			)
		&"discard_set_aside_to_encounter_discard":
			return ScenarioCompositionAtoms.discard_set_aside_to_encounter_discard(
				_game_ctx, node.definition_id, node.atom_count
			)
		&"nest_scenario_resolution":
			var resolution := node.scenario_resolution
			if resolution <= 0 and node.definition_id != &"":
				resolution = ScenarioResolutionParser.parse(
					CardRegistry.back_text(node.definition_id)
				)
			return ScenarioCompositionAtoms.trigger_scenario_resolution(
				_game_ctx, resolution, node.definition_id
			)
		&"defeat_surviving_non_resigned":
			return ScenarioCompositionAtoms.defeat_surviving_non_resigned(
				_game_ctx, node.marker_delta, node.draw_amount
			)
		&"heal_and_set_aside_enemy":
			return ScenarioCompositionAtoms.heal_and_set_aside_enemy(
				_game_ctx, node.definition_id
			)
		&"remove_location_from_game":
			return ScenarioCompositionAtoms.remove_location_from_game(
				_game_ctx, node.card_id
			)
		&"put_story_asset_from_set_aside":
			return ScenarioCompositionAtoms.put_story_asset_from_set_aside(
				_game_ctx, node.definition_id, node.location_target
			)
		&"place_clues_on_location":
			return ScenarioCompositionAtoms.place_clues_on_location(
				_game_ctx, node.location_target, node.atom_count
			)
		&"lead_search_draw_encounter_copies":
			return ScenarioCompositionAtoms.lead_search_draw_encounter_copies(
				_game_ctx, node.definition_id, bool(node.flag_value)
			)
		&"lead_draw_topmost_encounter_discard_copy":
			return ScenarioCompositionAtoms.lead_draw_topmost_encounter_discard_copy(
				_game_ctx, node.definition_id
			)
		_:
			push_warning("CompositionExecutor: unknown atom %s" % node.atom_name)
			return false


func _execute_choice(node: CompositionNode) -> void:
	if node.children.is_empty():
		return
	var indices: Array[int] = []
	if _game_ctx != null:
		var sim := GameSimulator.from_context(_game_ctx)
		if node.choice_must:
			indices = _dry_runner.filter_executable_indices(node, sim)
		else:
			for i in node.children.size():
				indices.append(i)
	else:
		for i in node.children.size():
			indices.append(i)
	if indices.is_empty():
		_log.log(
			AhcEnums.LogCategory.CARD,
			"composition:choice_skip",
			{"must": node.choice_must, "prompt": node.choice_prompt_id}
		)
		return
	var pick_idx: int = indices[0]
	if indices.size() > 1:
		var option_ids: Array = []
		for idx in indices:
			var oid: StringName = (
				node.choice_option_ids[idx]
				if idx < node.choice_option_ids.size()
				else StringName("opt_%d" % idx)
			)
			option_ids.append(oid)
		var picked: Variant = null
		if _game_ctx != null and _game_ctx.interaction != null:
			picked = _game_ctx.interaction.ask_pick_option(
				option_ids,
				node.inv_id,
				node.choice_prompt_id,
				_game_ctx
			)
		if picked == null:
			pick_idx = indices[0]
		else:
			pick_idx = indices[0]
			for j in indices.size():
				var idx_at: int = indices[j]
				var oid_at: StringName = (
					node.choice_option_ids[idx_at]
					if idx_at < node.choice_option_ids.size()
					else StringName("opt_%d" % idx_at)
				)
				if oid_at == picked or str(oid_at) == str(picked):
					pick_idx = idx_at
					break
	var branch: CompositionNode = node.children[pick_idx]
	if branch != null:
		branch.provenance = node.provenance
		_run_node(branch)


func _execute_repeat(node: CompositionNode) -> void:
	if node.children.is_empty():
		return
	var count := _resolve_repeat_count(node)
	for _i in count:
		var body: CompositionNode = node.children[0]
		if body != null:
			body.provenance = node.provenance
			_run_node(body)


func _resolve_repeat_count(node: CompositionNode) -> int:
	if node.repeat_count_source == &"last_skill_test_fail_by":
		return _last_skill_test_fail_by
	if node.repeat_count_fixed > 0:
		return node.repeat_count_fixed
	return 0


func _execute_nest_skill_test(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.sequence_catalog == null:
		return false
	var inv_id := _resolve_inv(node)
	if inv_id == &"":
		return false
	var flow_id := SkillTestFlowHandlers.flow_id_for_skill(node.test_skill)
	var result := _game_ctx.sequence_catalog.nest(
		_game_ctx,
		flow_id,
		{
			"inv_id": node.inv_id,
			"skill": node.test_skill,
			"difficulty": node.test_difficulty,
			"card_id": node.card_id,
			"st7_plan": node.st7_plan,
		}
	)
	_last_skill_test_fail_by = int(result.get("fail_by", 0))
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:nest_skill_test",
		{
			"flow": flow_id,
			"inv": node.inv_id,
			"skill": node.test_skill,
			"difficulty": node.test_difficulty,
			"fail_by": _last_skill_test_fail_by,
			"success": bool(result.get("success", false)),
		}
	)
	return bool(result.get("ok", false))


func _execute_nest_enemy_resolve_location(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.sequence_catalog == null:
		return false
	var target := node.location_target if node.location_target != &"" else &"drawer_location"
	var result := _game_ctx.sequence_catalog.nest(
		_game_ctx,
		&"seq.enemy.resolve_location",
		{"target": target, "drawer_id": node.inv_id, "controller_id": node.inv_id}
	)
	_last_resolved_location = result.get("location_tag", &"") as StringName
	return bool(result.get("ok", false)) and _last_resolved_location != &""


func _execute_nest_enemy_move(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.sequence_catalog == null:
		return false
	if _last_resolved_location == &"":
		return false
	var enemy_id := NearestEnemyResolver.pick_nearest_enemy_toward_investigator(
		_game_ctx, node.inv_id, node.trait_exclude, false
	)
	if enemy_id == &"":
		return false
	var result := _game_ctx.sequence_catalog.nest(
		_game_ctx,
		&"seq.enemy.move",
		{
			"enemy_id": enemy_id,
			"target_location": _last_resolved_location,
			"steps": 1,
		}
	)
	_last_step_enemy_id = enemy_id
	_last_step_engaged_investigator = result.get("engaged_investigator", &"") as StringName
	_last_step_created = enemy_id != &""
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:nest_enemy_move",
		{
			"enemy": _last_step_enemy_id,
			"location": _last_resolved_location,
			"engaged": _last_step_engaged_investigator,
			"moved": bool(result.get("moved", false)),
		}
	)
	return _last_step_created


func _execute_nest_enemy_attack(node: CompositionNode) -> bool:
	if _game_ctx == null or _game_ctx.sequence_catalog == null:
		return false
	var enemy_id := node.enemy_ref_id if node.enemy_ref_id != &"" else _last_step_enemy_id
	var target := (
		node.target_investigator_id
		if node.target_investigator_id != &""
		else _last_step_engaged_investigator
	)
	if enemy_id == &"" or target == &"":
		return false
	var result := _game_ctx.sequence_catalog.nest(
		_game_ctx,
		&"seq.enemy.attack",
		{"enemy_id": enemy_id, "target_investigator": target, "exhaust_after": false}
	)
	return bool(result.get("ok", false))


func _execute_exhaust_card(node: CompositionNode) -> bool:
	if _state == null or node.card_id == &"":
		return false
	var card := _state.registry.get_card(node.card_id)
	if card == null or card.exhausted:
		return false
	card.exhausted = true
	_log.log(AhcEnums.LogCategory.CARD, "composition:exhaust_card", {"card": node.card_id})
	return true


func _execute_nest_move_connecting(node: CompositionNode) -> bool:
	if _game_ctx == null or _state == null or _game_ctx.skill_tests == null:
		return false
	var inv_id := _resolve_inv(node)
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null or inv.location_tag == &"":
		return false
	var current := _state.registry.get_location(inv.location_tag)
	if current == null:
		return false
	var candidates: Array = []
	for conn in current.connections:
		candidates.append(conn)
	if candidates.is_empty():
		return false
	var dest_id: StringName = &""
	if _game_ctx.interaction != null:
		var picked: Variant = _game_ctx.interaction.ask_pick_target(
			candidates, inv_id, &"pick:move_connecting", _game_ctx
		)
		if picked != null:
			dest_id = picked as StringName
	elif candidates.size() == 1:
		dest_id = candidates[0] as StringName
	if dest_id == &"":
		return false
	var resolver := BasicActionResolver.new(_state, _game_ctx.skill_tests)
	var move_result := resolver.move(_game_ctx, inv_id, {"destination_id": dest_id})
	if not bool(move_result.get("ok", false)):
		return false
	EngageFlow.nest_after_area_change(_game_ctx, dest_id)
	_log.log(
		AhcEnums.LogCategory.CARD,
		"composition:nest_move_connecting",
		{"inv": inv_id, "destination": dest_id}
	)
	return true


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
