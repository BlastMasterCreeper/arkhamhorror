class_name PreyResolver
extends RefCounted


static func filter_candidates(
	spec: PreyInstructionSpec,
	game_ctx: GameContext,
	candidates: Array[StringName],
	source_enemy_id: StringName = &""
) -> Array[StringName]:
	if spec == null or game_ctx == null or candidates.is_empty():
		return []
	var scoped := _filter_by_investigator_title(spec, game_ctx, candidates)
	if scoped.is_empty():
		return []
	if spec.investigator_title_only != "":
		return scoped
	if spec.is_nearest_to_enemy_trait():
		return _filter_nearest_to_enemy_trait(spec, game_ctx, scoped, source_enemy_id)
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


## Prey 过滤后取 WHO：唯一则直返；并列 → Lead 开 PICK_TARGET 窗（有限期确认 / 默认 first）。
static func best_match(
	spec: PreyInstructionSpec,
	game_ctx: GameContext,
	candidates: Array[StringName],
	source_enemy_id: StringName = &""
) -> StringName:
	var filtered := filter_candidates(spec, game_ctx, candidates, source_enemy_id)
	if filtered.is_empty():
		return &""
	if filtered.size() == 1:
		return filtered[0]
	return lead_pick(game_ctx, filtered, &"pick:prey_tie")


## 无 Prey / Prey 未命中后的并列：Lead 开选择窗；单候选直返。
static func lead_pick(
	game_ctx: GameContext,
	candidates: Array[StringName],
	prompt_id: StringName = &"pick:engage_tie"
) -> StringName:
	if candidates.is_empty():
		return &""
	if candidates.size() == 1:
		return candidates[0]
	var lead := &""
	if game_ctx != null:
		lead = game_ctx.lead_investigator_id
		if lead == &"" and game_ctx.state != null:
			lead = game_ctx.state.lead_investigator_id
	var decider := lead if lead != &"" else candidates[0]
	if game_ctx == null or game_ctx.interaction == null:
		## 无 Gate：稳定回退 first（不静默改成 Lead 本尊为目标）。
		return candidates[0]
	var chosen: Variant = game_ctx.interaction.ask_pick_target(
		candidates, decider, prompt_id, game_ctx
	)
	if chosen is StringName and chosen != &"":
		return chosen as StringName
	if chosen != null:
		var as_name := StringName(str(chosen))
		if as_name != &"" and candidates.has(as_name):
			return as_name
	return candidates[0]


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
	if spec.value_kind == PreyInstructionSpec.ValueKind.CLUES:
		return inv.clues_on_card
	return inv.get_skill(spec.skill)


## 候选调查员中保留「到另一带 trait 敌人」路径距离最小者；无锚点则不筛（交给 Lead 窗）。
static func _filter_nearest_to_enemy_trait(
	spec: PreyInstructionSpec,
	game_ctx: GameContext,
	candidates: Array[StringName],
	source_enemy_id: StringName
) -> Array[StringName]:
	var anchors := _enemy_locations_with_trait(
		game_ctx, spec.nearest_enemy_trait, source_enemy_id if spec.exclude_self else &""
	)
	if anchors.is_empty():
		return candidates.duplicate()
	var best_dist := 999999
	var scored: Array[Dictionary] = []
	for inv_id in candidates:
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null or inv.location_tag == &"":
			continue
		var dist := _min_distance_to_locations(inv.location_tag, anchors, game_ctx)
		if dist < 0:
			continue
		scored.append({"id": inv_id, "dist": dist})
		if dist < best_dist:
			best_dist = dist
	if scored.is_empty():
		return candidates.duplicate()
	var out: Array[StringName] = []
	for row in scored:
		if int(row["dist"]) == best_dist:
			out.append(row["id"] as StringName)
	return out


static func _enemy_locations_with_trait(
	game_ctx: GameContext,
	trait_name: StringName,
	exclude_enemy_id: StringName
) -> Array[StringName]:
	var out: Array[StringName] = []
	if game_ctx == null or game_ctx.state == null or trait_name == &"":
		return out
	var seen_loc: Dictionary = {}
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		if exclude_enemy_id != &"" and enemy_id == exclude_enemy_id:
			continue
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null or enemy.location_tag == &"":
			continue
		var card := game_ctx.state.registry.get_card(enemy_id)
		if card == null:
			continue
		if not CardRegistry.card_has_trait(card, trait_name):
			continue
		if seen_loc.has(enemy.location_tag):
			continue
		seen_loc[enemy.location_tag] = true
		out.append(enemy.location_tag)
	return out


static func _min_distance_to_locations(
	from_tag: StringName,
	location_tags: Array[StringName],
	game_ctx: GameContext
) -> int:
	var best := -1
	for loc in location_tags:
		var dist := EnemyPathfinding.shortest_path_distance(from_tag, loc, game_ctx)
		if dist < 0:
			continue
		if best < 0 or dist < best:
			best = dist
	return best
