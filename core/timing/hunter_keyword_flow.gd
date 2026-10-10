class_name HunterKeywordFlow
extends RefCounted

## Hunter LISTENER 开火体 · nest 自 `seq.enemy.3_2`（KeywordConsumer @ ENEMY_3_2）。
## 不写进 Framework 3.2 handler。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "moved": false}
	var enemy_id: StringName = params.get("card_id", params.get("enemy_id", &""))
	if enemy_id == &"":
		return {"ok": false, "moved": false, "reason": &"missing_enemy"}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null or enemy.exhausted or EngagementStatus.is_engaged(game_ctx, enemy_id):
		return {"ok": true, "moved": false, "skipped": true, "enemy_id": enemy_id}
	var target_inv := EnemyHunterTarget.pick_nearest_investigator(game_ctx, enemy_id)
	if target_inv == &"":
		return {"ok": true, "moved": false, "skipped": true, "enemy_id": enemy_id}
	var loc := EnemyLocationTarget.resolve(
		game_ctx, {"target": "investigator_location", "drawer_id": target_inv}
	)
	if not bool(loc.get("ok", false)):
		return {"ok": true, "moved": false, "skipped": true, "enemy_id": enemy_id}
	var body := EnemyPhaseFlow.move(
		game_ctx,
		{
			"enemy_id": enemy_id,
			"target_location": loc.get("location_tag", &""),
			"steps": 1,
		}
	)
	var did_move := bool(body.get("moved", false))
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"keyword:hunter",
			{"enemy_id": enemy_id, "moved": did_move, "target": target_inv}
		)
	return {"ok": true, "moved": did_move, "enemy_id": enemy_id}
