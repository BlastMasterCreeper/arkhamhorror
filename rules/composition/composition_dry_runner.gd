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
			var result := sim.mutator.execute_draw_instruction(node.inv_id, maxi(node.draw_amount, 1))
			return result.ok and result.drew and not result.defeated
		&"take_horror":
			sim.mutator.take_horror(node.inv_id, maxi(node.atom_amount, 1))
			return true
		&"discard_from_hand":
			return sim.mutator.discard_from_hand(node.card_id, node.inv_id)
	return false


func _simulate_register(node: CompositionNode, sim: GameSimulator) -> bool:
	if node.register_template == null:
		return false
	sim.registrations.register(node.register_template)
	return true
