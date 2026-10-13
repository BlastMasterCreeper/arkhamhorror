class_name EnemyPathfinding
extends RefCounted

## 朝目标地点移动 1 步 · 尽量执行（缩短距离优先；无法缩短仍须移动；并列由队长选）。


static func shortest_path_distance(
	from_tag: StringName,
	to_tag: StringName,
	game_ctx: GameContext
) -> int:
	if game_ctx == null or game_ctx.state == null:
		return -1
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


static func candidate_hops_toward(
	from_tag: StringName,
	to_tag: StringName,
	game_ctx: GameContext
) -> Array[StringName]:
	if from_tag == &"" or to_tag == &"" or from_tag == to_tag:
		return []
	if game_ctx == null or game_ctx.state == null:
		return []
	var loc := game_ctx.state.registry.get_location(from_tag)
	if loc == null:
		return []
	var current_dist := shortest_path_distance(from_tag, to_tag, game_ctx)
	if current_dist < 0:
		return []
	var hops: Array[StringName] = []
	var hop_dists: Array[int] = []
	for conn in loc.connections:
		var hop: StringName = conn as StringName
		var hop_dist := shortest_path_distance(hop, to_tag, game_ctx)
		if hop_dist < 0:
			continue
		hops.append(hop)
		hop_dists.append(hop_dist)
	if hops.is_empty():
		return []
	var shortening: Array[StringName] = []
	var best_short := 999999
	for i in hops.size():
		if hop_dists[i] < current_dist:
			if hop_dists[i] < best_short:
				best_short = hop_dists[i]
				shortening = [hops[i]]
			elif hop_dists[i] == best_short:
				shortening.append(hops[i])
	if not shortening.is_empty():
		return shortening
	return hops.duplicate()


static func pick_next_hop_toward(
	from_tag: StringName,
	to_tag: StringName,
	game_ctx: GameContext
) -> StringName:
	var candidates := candidate_hops_toward(from_tag, to_tag, game_ctx)
	if candidates.is_empty():
		return &""
	if candidates.size() == 1:
		return candidates[0]
	if game_ctx != null and game_ctx.interaction != null:
		var lead := game_ctx.lead_investigator_id
		if lead == &"" and game_ctx.state != null:
			var ids := game_ctx.state.registry.all_investigator_ids()
			if not ids.is_empty():
				lead = ids[0]
		var pick: Variant = game_ctx.interaction.ask_pick_target(
			candidates,
			lead,
			&"pick:enemy_move_toward",
			game_ctx
		)
		if pick is StringName:
			return pick as StringName
		if pick != null:
			return StringName(str(pick))
	return candidates[0]


## @deprecated 用 pick_next_hop_toward
static func next_step_toward(
	from_tag: StringName,
	to_tag: StringName,
	game_ctx: GameContext
) -> StringName:
	return pick_next_hop_toward(from_tag, to_tag, game_ctx)
