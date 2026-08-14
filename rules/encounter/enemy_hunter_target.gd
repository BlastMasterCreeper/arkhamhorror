class_name EnemyHunterTarget
extends RefCounted

## Hunter / 向调查员移动 · 等距 → Prey → Lead（08 §4）。


static func pick_nearest_investigator(
	game_ctx: GameContext,
	enemy_id: StringName
) -> StringName:
	if game_ctx == null or game_ctx.state == null:
		return &""
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null or enemy.location_tag == &"":
		return &""
	var def_id := _definition_id(game_ctx, enemy_id)
	var best_dist := 999999
	var best: Array[StringName] = []
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null or inv.location_tag == &"":
			continue
		var dist := EnemyPathfinding.shortest_path_distance(
			enemy.location_tag, inv.location_tag, game_ctx
		)
		if dist < 0:
			continue
		if dist < best_dist:
			best_dist = dist
			best = [inv_id]
		elif dist == best_dist:
			best.append(inv_id)
	if best.is_empty():
		return &""
	if best.size() == 1:
		return best[0]
	var prey := CardRegistry.prey_spec(def_id)
	var pick := PreyResolver.best_match(prey, game_ctx, best)
	if pick != &"":
		return pick
	var lead := game_ctx.lead_investigator_id
	if lead != &"" and best.has(lead):
		return lead
	if game_ctx.interaction != null:
		var chosen: Variant = game_ctx.interaction.ask_pick_target(
			best,
			lead if lead != &"" else best[0],
			&"pick:hunter_target_tie",
			game_ctx
		)
		if chosen is StringName:
			return chosen as StringName
		if chosen != null:
			return StringName(str(chosen))
	return best[0]


static func _definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null:
		return &""
	return card.id.definition_id
