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
	return false


func _simulate_register(node: CompositionNode, sim: GameSimulator) -> bool:
	if node.register_template == null:
		return false
	sim.registrations.register(node.register_template)
	return true
