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
		var dist := _shortest_path_distance(from, enemy.location_tag, game_ctx)
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


static func _drawer_location_tag(game_ctx: GameContext, drawer_id: StringName) -> StringName:
	var inv := game_ctx.state.registry.get_investigator(drawer_id)
	if inv == null or inv.location_tag == &"":
		return &""
	if game_ctx.state.registry.get_location(inv.location_tag) == null:
		return &""
	return inv.location_tag


static func _shortest_path_distance(
	from_tag: StringName,
	to_tag: StringName,
	game_ctx: GameContext
) -> int:
	if from_tag == &"" or to_tag == &"":
		return -1
	if from_tag == to_tag:
		return 0
	var queue: Array = [[from_tag, 0]]
	var seen: Dictionary = {from_tag: true}
	while not queue.is_empty():
		var item: Array = queue.pop_front()
		var loc_tag: StringName = item[0]
		var dist: int = item[1]
		var loc := game_ctx.state.registry.get_location(loc_tag)
		if loc == null:
			continue
		for conn in loc.connections:
			if conn == to_tag:
				return dist + 1
			if not seen.has(conn):
				seen[conn] = true
				queue.append([conn, dist + 1])
	return -1
