class_name EvadeFlow
extends RefCounted

## 躲避效果核 · `seq.effect.evade`。
## 横置该敌 + 解除交战。入口：成功躲避尝试（ST.7）、自动躲避、卡面效果。
## 不含：躲避行动外壳 `seq.action.evade`；躲避尝试（检定本身）。
## 自动躲避 = 本核包装（无检定）；≠ 自动成功的躲避尝试。

const FLOW := &"seq.effect.evade"

## 成功躲避尝试后产生的躲避效果。
const MODE_ATTEMPT := &"attempt"
## 自动躲避包装（不做躲避尝试）。
const MODE_AUTOMATIC := &"automatic"
## 卡面 / 其它效果直接产生躲避效果。
const MODE_EFFECT := &"effect"


static func nest_or_run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(FLOW)
	):
		return game_ctx.sequence_catalog.nest(game_ctx, FLOW, params)
	return run(game_ctx, params)


## 自动躲避：不经检定，直接产生躲避效果。
static func automatically_evade(
	game_ctx: GameContext,
	enemy_id: StringName,
	investigator_id: StringName = &""
) -> Dictionary:
	return nest_or_run(
		game_ctx,
		{
			"enemy_id": enemy_id,
			"investigator_id": investigator_id,
			"mode": MODE_AUTOMATIC,
		}
	)


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "error": "no_context"}
	var enemy_id: StringName = params.get("enemy_id", &"") as StringName
	if enemy_id == &"":
		return {"ok": false, "error": "missing_enemy_id"}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy"}
	var mode: StringName = params.get("mode", MODE_EFFECT) as StringName
	if mode == &"":
		mode = MODE_EFFECT
	## 1. 横置（可被 after_exhaust 听到）→ nest seq.effect.exhaust。
	var exhaust_res := ExhaustReadyFlow.nest_or_run_exhaust(
		game_ctx,
		{
			"target_kind": ExhaustReadyFlow.TARGET_ENEMY,
			"enemy_id": enemy_id,
			"trigger_area_change": false,
		}
	)
	## 2. 解除交战（不二次横置）；区域变更后 auto engage 会因已横置而跳过。
	var disengage_res := {"ok": true}
	if game_ctx.enemy != null:
		disengage_res = game_ctx.enemy.disengage(game_ctx, enemy_id, false, true)
	else:
		EngagementStatus.clear(game_ctx, enemy_id)
		if enemy.engaged_with != &"":
			var prev := game_ctx.state.registry.get_investigator(enemy.engaged_with)
			if prev != null:
				prev.threat_area.erase(enemy_id)
		enemy.engaged_with = &""
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"evade:effect",
			{
				"enemy_id": enemy_id,
				"mode": mode,
				"exhausted": enemy.exhausted,
				"engaged_with": enemy.engaged_with,
			}
		)
	return {
		"ok": bool(exhaust_res.get("ok", false)) and bool(disengage_res.get("ok", true)),
		"enemy_id": enemy_id,
		"mode": mode,
		"exhausted": enemy.exhausted,
		"engaged_with": enemy.engaged_with,
		"automatic": mode == MODE_AUTOMATIC,
	}
