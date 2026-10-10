class_name PatrolKeywordFlow
extends RefCounted

## Patrol LISTENER 开火体 · nest 自 `seq.enemy.3_2`（KeywordConsumer @ ENEMY_3_2）。
## 括号目标 = PatrolTargetSpec（①）；不写进 Framework 3.2 handler。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "moved": false}
	var enemy_id: StringName = params.get("card_id", params.get("enemy_id", &""))
	if enemy_id == &"":
		return {"ok": false, "moved": false, "reason": &"missing_enemy"}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null or enemy.exhausted or enemy.engaged_with != &"":
		return {"ok": true, "moved": false, "skipped": true, "enemy_id": enemy_id}
	var def_id: StringName = params.get("def_id", &"")
	if def_id == &"":
		var card := game_ctx.state.registry.get_card(enemy_id)
		if card != null:
			def_id = card.id.definition_id
	var spec := CardRegistry.patrol_spec(def_id)
	if spec == null:
		return {"ok": true, "moved": false, "skipped": true, "enemy_id": enemy_id}
	var target_loc := PatrolTargetResolver.resolve(spec, game_ctx, enemy_id)
	if target_loc == &"" or enemy.location_tag == target_loc:
		return {"ok": true, "moved": false, "skipped": true, "enemy_id": enemy_id}
	var body := EnemyPhaseFlow.move(
		game_ctx,
		{
			"enemy_id": enemy_id,
			"target_location": target_loc,
			"steps": 1,
		}
	)
	var did_move := bool(body.get("moved", false))
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"keyword:patrol",
			{"enemy_id": enemy_id, "moved": did_move, "target_location": target_loc}
		)
	return {"ok": true, "moved": did_move, "enemy_id": enemy_id}
