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
	if node.atom_name == &"draw":
		if RestrictionEvaluator.blocks_draw(node.inv_id, sim.registrations):
			return false
		return sim.mutator.draw_from_deck_to_hand(node.inv_id)
	return false


func _simulate_register(node: CompositionNode, sim: GameSimulator) -> bool:
	if node.register_template == null:
		return false
	sim.registrations.register(node.register_template)
	return true
