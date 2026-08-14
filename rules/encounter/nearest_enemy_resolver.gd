class_name NearestEnemyResolver
extends RefCounted

## 最近敌人 · 等距时由当前交互玩家（drawer / controller）选目标。


static func candidates_without_doom(
	game_ctx: GameContext,
	drawer_id: StringName,
	require_no_doom: bool = true
) -> Array[StringName]:
	if game_ctx == null or game_ctx.state == null:
		return []
	var from := _drawer_location_tag(game_ctx, drawer_id)
	if from == &"":
		return []
	var best_dist := 999999
	var best: Array[StringName] = []
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null:
			continue
		if require_no_doom and enemy.doom > 0:
			continue
		if enemy.location_tag == &"":
			continue
		var dist := EnemyPathfinding.shortest_path_distance(from, enemy.location_tag, game_ctx)
		if dist < 0:
			continue
		if dist < best_dist:
			best_dist = dist
			best = [enemy_id]
		elif dist == best_dist:
			best.append(enemy_id)
	return best


static func pick_nearest_enemy_without_doom(
	game_ctx: GameContext,
	drawer_id: StringName
) -> StringName:
	var candidates := candidates_without_doom(game_ctx, drawer_id, true)
	if candidates.is_empty():
		return &""
	if candidates.size() == 1:
		return candidates[0]
	if game_ctx.interaction != null:
		var pick: Variant = game_ctx.interaction.ask_pick_target(
			candidates,
			drawer_id,
			&"pick:nearest_enemy_tie",
			game_ctx
		)
		if pick is StringName:
			return pick as StringName
		if pick != null:
			return StringName(str(pick))
	return candidates[0]


static func candidates_toward_investigator(
	game_ctx: GameContext,
	drawer_id: StringName,
	trait_exclude: Array[StringName] = [],
	require_no_doom: bool = false
) -> Array[StringName]:
	if game_ctx == null or game_ctx.state == null:
		return []
	var from := _drawer_location_tag(game_ctx, drawer_id)
	if from == &"":
		return []
	var best_dist := 999999
	var best: Array[StringName] = []
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null or enemy.location_tag == &"":
			continue
		if require_no_doom and enemy.doom > 0:
			continue
		var def_id := _definition_id(game_ctx, enemy_id)
		if _has_excluded_trait(def_id, trait_exclude):
			continue
		var dist := EnemyPathfinding.shortest_path_distance(from, enemy.location_tag, game_ctx)
		if dist < 0:
			continue
		if dist < best_dist:
			best_dist = dist
			best = [enemy_id]
		elif dist == best_dist:
			best.append(enemy_id)
	return best


static func pick_nearest_enemy_toward_investigator(
	game_ctx: GameContext,
	drawer_id: StringName,
	trait_exclude: Array[StringName] = [],
	require_no_doom: bool = false
) -> StringName:
	var candidates := candidates_toward_investigator(
		game_ctx, drawer_id, trait_exclude, require_no_doom
	)
	if candidates.is_empty():
		return &""
	if candidates.size() == 1:
		return candidates[0]
	if game_ctx.interaction != null:
		var pick: Variant = game_ctx.interaction.ask_pick_target(
			candidates,
			drawer_id,
			&"pick:nearest_enemy_tie",
			game_ctx
		)
		if pick is StringName:
			return pick as StringName
		if pick != null:
			return StringName(str(pick))
	return candidates[0]


static func _definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null:
		return &""
	return card.id.definition_id


static func _has_excluded_trait(def_id: StringName, trait_exclude: Array[StringName]) -> bool:
	if trait_exclude.is_empty() or def_id == &"":
		return false
	for trait_name in CardRegistry.traits(def_id):
		var normalized := StringName(str(trait_name))
		if trait_exclude.has(normalized):
			return true
	return false


static func _drawer_location_tag(game_ctx: GameContext, drawer_id: StringName) -> StringName:
	var inv := game_ctx.state.registry.get_investigator(drawer_id)
	if inv == null or inv.location_tag == &"":
		return &""
	if game_ctx.state.registry.get_location(inv.location_tag) == null:
		return &""
	return inv.location_tag
