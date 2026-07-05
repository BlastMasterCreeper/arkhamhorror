class_name SpawnLocationResolver
extends RefCounted


static func resolve(
	spec: SpawnInstructionSpec,
	drawer_id: StringName,
	game_ctx: GameContext
) -> StringName:
	if spec == null or game_ctx == null:
		return &""
	match spec.selector_kind:
		SpawnInstructionSpec.SelectorKind.DRAWER_LOCATION:
			return _drawer_location(game_ctx, drawer_id)
		SpawnInstructionSpec.SelectorKind.NAMED_LOCATION:
			return _named_location(game_ctx, spec.location_tag)
		SpawnInstructionSpec.SelectorKind.NEAREST_EMPTY:
			return _nearest_empty(game_ctx, drawer_id)
		SpawnInstructionSpec.SelectorKind.FARTHEST_EMPTY:
			return _farthest_empty(game_ctx)
	return &""


static func _drawer_location(game_ctx: GameContext, drawer_id: StringName) -> StringName:
	var inv := game_ctx.state.registry.get_investigator(drawer_id)
	if inv == null or inv.location_tag == &"":
		return &""
	if game_ctx.state.registry.get_location(inv.location_tag) == null:
		return &""
	return inv.location_tag


static func _named_location(game_ctx: GameContext, location_tag: StringName) -> StringName:
	if location_tag == &"":
		return &""
	if game_ctx.state.registry.get_location(location_tag) == null:
		return &""
	return location_tag


static func _nearest_empty(game_ctx: GameContext, drawer_id: StringName) -> StringName:
	var from := _drawer_location(game_ctx, drawer_id)
	if from == &"":
		return &""
	var best_dist := 999999
	var best := &""
	for loc_id in _empty_location_ids(game_ctx):
		var dist := _shortest_path_distance(from, loc_id, game_ctx)
		if dist < 0:
			continue
		if dist < best_dist:
			best_dist = dist
			best = loc_id
	return best


static func _farthest_empty(game_ctx: GameContext) -> StringName:
	var best_min_dist := -1
	var best: Array[StringName] = []
	for loc_id in _empty_location_ids(game_ctx):
		var min_to_inv := _min_distance_to_investigators(loc_id, game_ctx)
		if min_to_inv < 0:
			continue
		if min_to_inv > best_min_dist:
			best_min_dist = min_to_inv
			best = [loc_id]
		elif min_to_inv == best_min_dist:
			best.append(loc_id)
	if best.is_empty():
		return &""
	return best[0]


static func _empty_location_ids(game_ctx: GameContext) -> Array[StringName]:
	var out: Array[StringName] = []
	for loc_id in game_ctx.state.registry.all_location_ids():
		if _is_empty_location(game_ctx, loc_id):
			out.append(loc_id)
	return out


static func _is_empty_location(game_ctx: GameContext, location_tag: StringName) -> bool:
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null and not inv.eliminated and inv.location_tag == location_tag:
			return false
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy != null and enemy.location_tag == location_tag:
			return false
	return true


static func _min_distance_to_investigators(location_tag: StringName, game_ctx: GameContext) -> int:
	var best := 999999
	var found := false
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null or inv.eliminated or inv.location_tag == &"":
			continue
		var dist := _shortest_path_distance(location_tag, inv.location_tag, game_ctx)
		if dist < 0:
			continue
		found = true
		best = mini(best, dist)
	if not found:
		return -1
	return best


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
