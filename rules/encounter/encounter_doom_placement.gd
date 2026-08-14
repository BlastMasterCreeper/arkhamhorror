class_name EncounterDoomPlacement
extends RefCounted

## 12160 等 · 最近无 doom 敌人放置 1 doom（Domain 写入；CREATED 由 CompositionExecutor 记录 · 07 §4.4/§5）。


static func place_on_nearest_enemy_without_doom(
	game_ctx: GameContext,
	drawer_id: StringName,
	card_id: StringName
) -> bool:
	if game_ctx == null or game_ctx.mutator == null:
		return false
	var enemy_id := NearestEnemyResolver.pick_nearest_enemy_without_doom(game_ctx, drawer_id)
	if enemy_id == &"":
		return false
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return false
	enemy.doom += 1
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"encounter:place_doom_enemy",
			{"enemy": enemy_id, "doom": enemy.doom, "drawer": drawer_id, "card": card_id}
		)
	return true
