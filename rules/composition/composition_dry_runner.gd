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
	return false


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
			var test_inv := sim.state.registry.get_investigator(node.inv_id)
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
