class_name CandidateViability
extends RefCounted

## 候选 V 层：临时 bind → dry-run 效果尾 → 无 CREATED 则剔除。
## 见 docs/design/21-selection-spec.md §3.1.4


static func filter_viable(
	candidates: Array[StringName],
	game_ctx: GameContext,
	controller_id: StringName,
	bind_key: StringName,
	viability_tail: CompositionNode
) -> Array[StringName]:
	if game_ctx == null:
		return candidates.duplicate()
	return filter_viable_on_sim(
		candidates,
		GameSimulator.from_context(game_ctx),
		controller_id,
		bind_key,
		viability_tail
	)


static func filter_viable_on_sim(
	candidates: Array[StringName],
	base: GameSimulator,
	controller_id: StringName,
	bind_key: StringName,
	viability_tail: CompositionNode
) -> Array[StringName]:
	var out: Array[StringName] = []
	if (
		candidates.is_empty()
		or base == null
		or viability_tail == null
		or controller_id == &""
		or bind_key == &""
	):
		return candidates.duplicate()
	var runner := CompositionDryRunner.new()
	for cand in candidates:
		var fork := base.fork()
		fork.set_referent(controller_id, bind_key, cand)
		fork.last_step_enemy_id = cand
		var result := runner.simulate(viability_tail, fork)
		if result != null and result.has_any_created:
			out.append(cand)
	return out
