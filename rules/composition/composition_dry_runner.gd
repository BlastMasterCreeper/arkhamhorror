class_name CompositionDryRunner
extends RefCounted


func simulate(node: CompositionNode, sim: GameSimulator) -> DryRunResult:
	var result := DryRunResult.new()
	result.has_any_created = _simulate_node(node, sim)
	return result


func _simulate_node(node: CompositionNode, sim: GameSimulator) -> bool:
	match node.kind:
		AhcEnums.CompositionNodeKind.SEQ:
			var any := false
			for child in node.children:
				var created := _simulate_node(child, sim)
				sim.last_step_created = created
				any = any or created
			return any
		AhcEnums.CompositionNodeKind.ATOM:
			var created := _simulate_atom(node, sim)
			sim.last_step_created = created
			return created
		AhcEnums.CompositionNodeKind.REGISTER:
			var created := _simulate_register(node, sim)
			sim.last_step_created = created
			return created
		AhcEnums.CompositionNodeKind.IF:
			return _simulate_if(node, sim)
		AhcEnums.CompositionNodeKind.CHOICE:
			return _simulate_choice(node, sim)
		AhcEnums.CompositionNodeKind.REPEAT:
			return _simulate_repeat(node, sim)
		AhcEnums.CompositionNodeKind.FOR_EACH:
			return _simulate_for_each(node, sim)
	return false


func _simulate_for_each(node: CompositionNode, sim: GameSimulator) -> bool:
	if node.children.is_empty() or sim.state == null:
		return false
	var any := false
	for inv_id in sim.state.registry.all_investigator_ids():
		var inv := sim.state.registry.get_investigator(inv_id)
		if inv == null or inv.eliminated or inv.resigned:
			continue
		var fork := sim.fork()
		fork.for_each_inv_override = inv_id
		any = _simulate_node(node.children[0], fork) or any
	return any


func _resolve_sim_inv(node: CompositionNode, sim: GameSimulator) -> StringName:
	if node.inv_id == CompositionNode.INV_EACH and sim.for_each_inv_override != &"":
		return sim.for_each_inv_override
	return node.inv_id


## Must resolve：返回 dry-run 下至少 CREATED 一项的分支下标（07 §4.2 · 16 §7.2.1）。
func filter_executable_indices(node: CompositionNode, sim: GameSimulator) -> Array[int]:
	var out: Array[int] = []
	if node == null or node.kind != AhcEnums.CompositionNodeKind.CHOICE:
		return out
	for i in node.children.size():
		var fork := sim.fork()
		if _simulate_node(node.children[i], fork):
			out.append(i)
	return out


func _simulate_repeat(node: CompositionNode, sim: GameSimulator) -> bool:
	if node.children.is_empty():
		return false
	var count := _repeat_count_for_sim(node, sim)
	if count <= 0:
		return false
	var any := false
	for _i in count:
		var fork := sim.fork()
		any = any or _simulate_node(node.children[0], fork)
	return any


func _repeat_count_for_sim(node: CompositionNode, sim: GameSimulator) -> int:
	if node.repeat_count_source == &"last_skill_test_fail_by":
		return sim.last_skill_test_fail_by
	if node.repeat_count_fixed > 0:
		return node.repeat_count_fixed
	return 0


func _simulate_choice(node: CompositionNode, sim: GameSimulator) -> bool:
	for child in node.children:
		var fork := sim.fork()
		if _simulate_node(child, fork):
			return true
	return false


func _simulate_if(node: CompositionNode, sim: GameSimulator) -> bool:
	if node.branch_condition == null:
		return false
	var take_then := node.branch_condition.matches_domain_sim(sim, node.inv_id)
	var branch: CompositionNode = node.then_branch if take_then else node.else_branch
	if branch == null:
		return false
	return _simulate_node(branch, sim)


func _simulate_atom(node: CompositionNode, sim: GameSimulator) -> bool:
	match node.atom_name:
		&"draw":
			if RestrictionEvaluator.blocks_draw(node.inv_id, sim.registrations):
				return false
			var draw_result := sim.mutator.execute_draw_instruction(node.inv_id, maxi(node.draw_amount, 1))
			return draw_result.ok and draw_result.drew and not draw_result.defeated
		&"move_card":
			if node.to_slot == null:
				return false
			return sim.mutator.move_card(node.card_id, node.to_slot)
		&"adjust_marker":
			if node.marker_slot == null:
				return false
			return sim.mutator.adjust_marker(node.marker_slot, node.marker_delta)
		&"set_flag":
			return sim.mutator.set_flag(node.inv_id, node.flag_field, node.flag_value)
		&"reveal_to_controller":
			return sim.mutator.reveal_to_controller(node.card_id, node.inv_id)
		&"reveal_to_all":
			return sim.mutator.reveal_to_all(node.card_id)
		&"pop_deck_top":
			var card_id := sim.mutator.pop_deck_top(node.inv_id)
			return card_id != &""
		&"shuffle_discard_into_deck":
			if sim.mutator.deck_is_empty(node.inv_id) and not sim.mutator.discard_is_empty(node.inv_id):
				sim.mutator.shuffle_discard_into_deck(node.inv_id)
				return true
			return false
		&"commit_enter_hand":
			return sim.mutator.commit_enter_hand(node.card_id, node.inv_id)
		&"commit_hidden_enter_hand":
			return sim.mutator.commit_hidden_enter_hand(node.card_id, node.inv_id)
		&"expose_hidden":
			var expose_card := sim.state.registry.get_card(node.card_id)
			return expose_card != null and expose_card.is_hidden
		&"spawn_encounter_enemy":
			var card := sim.state.registry.get_card(node.card_id)
			return (
				card != null
				and card.zone == AhcEnums.Zone.HAND
				and CardRegistry.card_type(card.id.definition_id) == &"enemy"
			)
		&"discard_encounter_from_hand":
			var discard_card := sim.state.registry.get_card(node.card_id)
			return (
				discard_card != null
				and discard_card.zone == AhcEnums.Zone.HAND
				and discard_card.owner_id == &"encounter"
			)
		&"cancel_pending":
			return node.pending_id != &""
		&"ignore_pending":
			return node.pending_id != &""
		&"interrupt":
			return node.interrupt_target != null
		&"replace_pending":
			return node.pending_id != &"" and node.effect_request != null
		&"replace_instead":
			return node.replace_target != null and node.effect_request != null
		&"resolve_pending":
			return node.pending_id != &""
		&"place_doom_nearest_enemy_without_doom":
			var inv := sim.state.registry.get_investigator(node.inv_id)
			if inv == null or inv.location_tag == &"":
				return false
			for enemy_id in sim.state.registry.all_enemy_ids():
				var enemy := sim.state.registry.get_enemy(enemy_id)
				if enemy != null and enemy.doom == 0 and enemy.location_tag != &"":
					return true
			return false
		&"place_doom_on_current_agenda":
			return sim.state != null
		&"place_clue_on_investigator_location":
			var clue_inv := sim.state.registry.get_investigator(node.inv_id)
			if clue_inv == null or clue_inv.clues_on_card <= 0 or clue_inv.location_tag == &"":
				return false
			return sim.state.registry.get_location(clue_inv.location_tag) != null
		&"nest_skill_test":
			var test_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			if test_inv == null:
				return false
			sim.last_skill_test_fail_by = _estimate_fail_by(test_inv, node.test_skill, node.test_difficulty)
			if node.st7_plan != null:
				if sim.last_skill_test_fail_by > 0 and node.st7_plan.on_fail_by_each != null:
					var fork := sim.fork()
					return _simulate_node(node.st7_plan.on_fail_by_each, fork)
				if node.st7_plan.on_success != null and sim.last_skill_test_fail_by == 0:
					var fork_ok := sim.fork()
					return _simulate_node(node.st7_plan.on_success, fork_ok)
				if node.st7_plan.on_fail != null and sim.last_skill_test_fail_by > 0:
					var fork_fail := sim.fork()
					return _simulate_node(node.st7_plan.on_fail, fork_fail)
			return sim.last_skill_test_fail_by >= 0
		&"nest_enemy_resolve_location":
			var resolve_inv := sim.state.registry.get_investigator(node.inv_id)
			if resolve_inv == null or resolve_inv.location_tag == &"":
				return false
			sim.last_resolved_location = resolve_inv.location_tag
			return true
		&"nest_enemy_move":
			var move_inv := sim.state.registry.get_investigator(node.inv_id)
			if move_inv == null or move_inv.location_tag == &"":
				return false
			for enemy_id in sim.state.registry.all_enemy_ids():
				var enemy := sim.state.registry.get_enemy(enemy_id)
				if enemy != null and enemy.location_tag != &"":
					sim.last_step_created = true
					sim.last_step_engaged_investigator = node.inv_id
					return true
			return false
		&"nest_enemy_attack":
			return sim.last_step_engaged_investigator != &""
		&"exhaust_card":
			var exh := sim.state.registry.get_card(node.card_id) if sim.state != null else null
			if exh == null or exh.exhausted:
				return false
			exh.exhausted = true
			return true
		&"nest_move_connecting":
			var move_free_inv := sim.state.registry.get_investigator(_resolve_sim_inv(node, sim))
			if move_free_inv == null or move_free_inv.location_tag == &"":
				return false
			var from_loc := sim.state.registry.get_location(move_free_inv.location_tag)
			return from_loc != null and not from_loc.connections.is_empty()
		&"nest_gain_resource":
			if sim.state.registry.get_investigator(_resolve_sim_inv(node, sim)) != null:
				return true
			return not sim.state.registry.all_investigator_ids().is_empty()
		&"take_horror", &"take_damage":
			return sim.state.registry.get_investigator(_resolve_sim_inv(node, sim)) != null
		&"discard_all_enemies_in_play":
			return ScenarioCompositionAtoms.dry_discard_all_enemies_in_play(sim)
		&"put_locations_into_play":
			return ScenarioCompositionAtoms.dry_put_locations_into_play(sim, node.location_ids)
		&"spawn_set_aside_enemy_at":
			return ScenarioCompositionAtoms.dry_spawn_set_aside_enemy_at(
				sim, node.definition_id, node.location_target
			)
		&"attach_set_aside_to_host":
			return ScenarioCompositionAtoms.dry_attach_set_aside_to_host(
				sim, node.definition_id, node.card_id, node.atom_count
			)
		&"attach_limbo_to_nearest_location_without":
			var exclude := node.definition_id
			if exclude == &"" and node.card_id != &"":
				var c := sim.state.registry.get_card(node.card_id) if sim.state != null else null
				if c != null:
					exclude = c.id.definition_id
			return EncounterAttachment.dry_attach_limbo_to_nearest_location_without(
				sim, _resolve_sim_inv(node, sim), exclude
			)
		&"discard_set_aside_to_encounter_discard":
			return ScenarioCompositionAtoms.dry_discard_set_aside_to_encounter_discard(
				sim, node.definition_id, node.atom_count
			)
		&"nest_scenario_resolution":
			var resolution := node.scenario_resolution
			if resolution <= 0 and node.definition_id != &"":
				resolution = ScenarioResolutionParser.parse(
					CardRegistry.back_text(node.definition_id)
				)
			return ScenarioCompositionAtoms.dry_trigger_scenario_resolution(resolution)
		&"defeat_surviving_non_resigned":
			return ScenarioCompositionAtoms.dry_defeat_surviving_non_resigned(sim)
		&"heal_and_set_aside_enemy":
			return ScenarioCompositionAtoms.dry_heal_and_set_aside_enemy(sim, node.definition_id)
		&"remove_location_from_game":
			return ScenarioCompositionAtoms.dry_remove_location_from_game(sim, node.card_id)
		&"put_story_asset_from_set_aside":
			return ScenarioCompositionAtoms.dry_put_story_asset_from_set_aside(sim, node.definition_id)
		&"place_clues_on_location":
			return ScenarioCompositionAtoms.dry_place_clues_on_location(sim, node.location_target)
		&"lead_search_draw_encounter_copies":
			return ScenarioCompositionAtoms.dry_lead_search_draw_encounter_copies(
				sim, node.definition_id
			)
		&"lead_draw_topmost_encounter_discard_copy":
			return ScenarioCompositionAtoms.dry_lead_draw_topmost_encounter_discard_copy(
				sim, node.definition_id
			)
		_:
			push_warning("CompositionDryRunner: unknown atom %s" % node.atom_name)
			return false
	return false


func _estimate_fail_by(
	inv: InvestigatorState,
	skill: AhcEnums.SkillType,
	difficulty: int
) -> int:
	var base := _investigator_skill_value(inv, skill)
	return maxi(difficulty - base, 0)


func _investigator_skill_value(inv: InvestigatorState, skill: AhcEnums.SkillType) -> int:
	match skill:
		AhcEnums.SkillType.WILLPOWER:
			return inv.skill_willpower
		AhcEnums.SkillType.INTELLECT:
			return inv.skill_intellect
		AhcEnums.SkillType.COMBAT:
			return inv.skill_combat
		AhcEnums.SkillType.AGILITY:
			return inv.skill_agility
	return 0


func _simulate_register(node: CompositionNode, sim: GameSimulator) -> bool:
	if node.register_template == null:
		return false
	sim.registrations.register(node.register_template)
	return true
