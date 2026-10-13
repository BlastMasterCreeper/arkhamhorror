class_name PatrolTargetResolver
extends RefCounted

## 同步解析 Patrol designated target → 地点 tag（① · 不 nest）。


static func resolve(
	spec: PatrolTargetSpec,
	game_ctx: GameContext,
	enemy_id: StringName = &""
) -> StringName:
	if spec == null or game_ctx == null or game_ctx.state == null:
		return &""
	match spec.mode:
		PatrolTargetSpec.Mode.NAMED_LOCATION:
			return _valid_location(game_ctx, spec.location_tag)
		PatrolTargetSpec.Mode.NAMED_LOCATION_CHOICE:
			return _pick_named_candidate(game_ctx, spec.location_candidates, enemy_id)
	return &""


static func _valid_location(game_ctx: GameContext, location_tag: StringName) -> StringName:
	if location_tag == &"":
		return &""
	if game_ctx.state.registry.get_location(location_tag) == null:
		return &""
	return location_tag


static func _pick_named_candidate(
	game_ctx: GameContext,
	candidates: Array[StringName],
	_enemy_id: StringName
) -> StringName:
	var valid: Array[StringName] = []
	for tag in candidates:
		if _valid_location(game_ctx, tag) != &"":
			valid.append(tag)
	if valid.is_empty():
		return &""
	if valid.size() == 1:
		return valid[0]
	if game_ctx.interaction != null:
		var lead := game_ctx.lead_investigator_id
		if lead == &"":
			var ids := game_ctx.state.registry.all_investigator_ids()
			if not ids.is_empty():
				lead = ids[0]
		var pick: Variant = game_ctx.interaction.ask_pick_target(
			valid,
			lead,
			&"pick:patrol_target",
			game_ctx
		)
		if pick is StringName:
			return pick as StringName
		if pick != null:
			return StringName(str(pick))
	return valid[0]
