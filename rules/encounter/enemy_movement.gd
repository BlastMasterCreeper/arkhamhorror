class_name EnemyMovement
extends RefCounted

## 敌人移动 1 步（交战由区域变化后的 seq.engage 嵌套响应处理）。


static func move_one_step_toward_location(
	game_ctx: GameContext,
	enemy_id: StringName,
	target_location_tag: StringName
) -> Dictionary:
	var result := {
		"ok": false,
		"moved": false,
		"enemy_id": enemy_id,
		"from_location": &"",
		"to_location": &"",
	}
	if game_ctx == null or game_ctx.state == null or enemy_id == &"":
		return result
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null or enemy.location_tag == &"":
		return result
	result["from_location"] = enemy.location_tag
	if enemy.location_tag == target_location_tag:
		result["ok"] = true
		return result
	var next_hop := EnemyPathfinding.pick_next_hop_toward(
		enemy.location_tag, target_location_tag, game_ctx
	)
	if next_hop == &"":
		result["ok"] = true
		return result
	enemy.location_tag = next_hop
	result["moved"] = true
	result["to_location"] = next_hop
	result["ok"] = true
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:move",
			{
				"enemy_id": enemy_id,
				"from": result["from_location"],
				"to": next_hop,
				"target": target_location_tag,
			}
		)
	return result
