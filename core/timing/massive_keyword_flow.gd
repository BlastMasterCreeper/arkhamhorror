class_name MassiveKeywordFlow
extends RefCounted

## Massive（庞大）· 对基础阶段攻击的 **效果替换** 体。
## 开火锚：(seq.enemy.phase_attacks / seq.enemy.attack@PHASE, REPLACE)
## 不另铸 seq.enemy.massive_phase_attacks。


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null:
		return {"ok": false, "attacks": 0}
	var enemy_id: StringName = params.get("card_id", params.get("enemy_id", &""))
	if enemy_id == &"":
		return {"ok": false, "attacks": 0, "reason": &"missing_enemy"}
	var batch := MassiveEngagement.resolve_phase_batch(game_ctx, enemy_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"keyword:massive",
			{
				"enemy_id": enemy_id,
				"attacks": batch.get("attacks", 0),
				"interrupted": batch.get("interrupted", false),
			}
		)
	batch["ok"] = bool(batch.get("ok", true))
	return batch
