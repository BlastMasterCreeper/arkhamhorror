class_name EncounterDoomPlacement
extends RefCounted

## 卡面放置毁灭 · Domain 写入；CREATED 由 nest `seq.effect.place_doom` 的返回值记录。


static func place_on_nearest_enemy_without_doom(
	game_ctx: GameContext,
	drawer_id: StringName,
	card_id: StringName
) -> bool:
	return _place_on_enemy(
		game_ctx,
		NearestEnemyResolver.pick_nearest_enemy_without_doom(game_ctx, drawer_id),
		drawer_id,
		card_id
	)


static func place_on_nearest_enemy_without_doom_from_origin(
	game_ctx: GameContext,
	origin_id: StringName,
	picker_id: StringName,
	card_id: StringName
) -> bool:
	var exclude: Array = []
	if origin_id != &"":
		exclude.append(origin_id)
	return _place_on_enemy(
		game_ctx,
		NearestEnemyResolver.pick_nearest_enemy_without_doom(
			game_ctx, origin_id, picker_id, exclude
		),
		picker_id,
		card_id
	)


static func place_on_source(
	game_ctx: GameContext,
	card_id: StringName,
	amount: int = 1
) -> bool:
	if game_ctx == null or game_ctx.state == null or card_id == &"":
		return false
	var enemy := game_ctx.state.registry.get_enemy(card_id)
	if enemy == null:
		return false
	enemy.doom += maxi(amount, 1)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.CARD,
			"encounter:place_doom_source",
			{"enemy": card_id, "doom": enemy.doom}
		)
	return true


static func _place_on_enemy(
	game_ctx: GameContext,
	enemy_id: StringName,
	drawer_id: StringName,
	card_id: StringName
) -> bool:
	if game_ctx == null or enemy_id == &"":
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
