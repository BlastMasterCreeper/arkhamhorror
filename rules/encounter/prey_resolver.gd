class_name PreyResolver
extends RefCounted


static func filter_candidates(
	spec: PreyInstructionSpec,
	game_ctx: GameContext,
	candidates: Array[StringName]
) -> Array[StringName]:
	if spec == null or game_ctx == null or candidates.is_empty():
		return []
	var scoped := _filter_by_investigator_title(spec, game_ctx, candidates)
	if scoped.is_empty():
		return []
	if spec.investigator_title_only != "":
		return scoped
	var best_value: int = -1
	var pick_high := spec.compare_mode == PreyInstructionSpec.CompareMode.HIGHEST
	if not pick_high:
		best_value = 999999
	for inv_id in scoped:
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null:
			continue
		var value := _candidate_value(inv, spec)
		if pick_high:
			best_value = maxi(best_value, value)
		else:
			best_value = mini(best_value, value)
	var out: Array[StringName] = []
	for inv_id in scoped:
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null:
			continue
		if _candidate_value(inv, spec) == best_value:
			out.append(inv_id)
	return out


static func best_match(
	spec: PreyInstructionSpec,
	game_ctx: GameContext,
	candidates: Array[StringName]
) -> StringName:
	var filtered := filter_candidates(spec, game_ctx, candidates)
	if filtered.is_empty():
		return &""
	if filtered.size() == 1:
		return filtered[0]
	var lead := game_ctx.lead_investigator_id if game_ctx != null else &""
	if lead != &"" and filtered.has(lead):
		return lead
	return filtered[0]


static func _filter_by_investigator_title(
	spec: PreyInstructionSpec,
	game_ctx: GameContext,
	candidates: Array[StringName]
) -> Array[StringName]:
	if spec.investigator_title_only == "":
		return candidates.duplicate()
	var want := spec.investigator_title_only.to_lower()
	var out: Array[StringName] = []
	for inv_id in candidates:
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null:
			continue
		if inv.display_name.to_lower() == want:
			out.append(inv_id)
	return out


static func _candidate_value(inv: InvestigatorState, spec: PreyInstructionSpec) -> int:
	if spec.value_kind == PreyInstructionSpec.ValueKind.RESOURCES:
		return inv.resource_pool
	return inv.get_skill(spec.skill)
