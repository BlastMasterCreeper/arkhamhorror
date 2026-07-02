class_name CompositionDryRunner
extends RefCounted


func simulate(node: CompositionNode, sim: GameSimulator) -> DryRunResult:
	var result := DryRunResult.new()
	match node.kind:
		AhcEnums.CompositionNodeKind.SEQ:
			for child in node.children:
				var child_result := simulate(child, sim)
				if child_result.has_any_created:
					result.has_any_created = true
		AhcEnums.CompositionNodeKind.ATOM:
			result.has_any_created = _simulate_atom(node, sim)
		AhcEnums.CompositionNodeKind.REGISTER:
			result.has_any_created = _simulate_register(node, sim)
	return result


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
	return false


func _simulate_register(node: CompositionNode, sim: GameSimulator) -> bool:
	if node.register_template == null:
		return false
	sim.registrations.register(node.register_template)
	return true
