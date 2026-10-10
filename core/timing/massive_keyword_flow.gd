class_name MassiveKeywordFlow
extends RefCounted

## Massive（庞大）· 对一般敌人攻击效果（seq.enemy.attack）的 **REPLACE** 体。
## 敌军阶段 3.3 只是固定手续，nest 攻击；PHASE kind 时本流程替换为 batch。
## AOO 等非 PHASE 不走本替换（魔典：借机只打触发者）。


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
