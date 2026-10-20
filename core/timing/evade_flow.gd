class_name EvadeFlow
extends RefCounted

## 躲避效果核 · `seq.effect.evade`。
## 体：nest 横置 + 若交战则解除交战（内联 L0）。
## 入口：成功躲避尝试（ST.7）或自动躲避（卡面 nest；无检定）。
## 不是：躲避行动外壳、躲避尝试本身、自动成功的检定。

const FLOW := &"seq.effect.evade"

## cause：可听标签（非第二套结算）。automatic = 自动躲避；attempt_success = 尝试成功。
const CAUSE_AUTOMATIC := &"automatic"
const CAUSE_ATTEMPT_SUCCESS := &"attempt_success"


static func nest_or_run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := _normalize_params(params)
	if p.is_empty():
		return {"ok": false, "error": "invalid_params"}
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(FLOW)
	):
		return game_ctx.sequence_catalog.nest(game_ctx, FLOW, p)
	return resolve(game_ctx, p)


static func run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := _normalize_params(params)
	if p.is_empty():
		return {"ok": false, "error": "invalid_params"}
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(FLOW)
	):
		return game_ctx.sequence_catalog.run(game_ctx, FLOW, p)
	return resolve(game_ctx, p)


## 自动躲避入口（cause=automatic）。
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
			"cause": CAUSE_AUTOMATIC,
		}
	)


## 成功躲避尝试入口（cause=attempt_success）。
static func after_attempt_success(
	game_ctx: GameContext,
	enemy_id: StringName,
	investigator_id: StringName = &""
) -> Dictionary:
	return nest_or_run(
		game_ctx,
		{
			"enemy_id": enemy_id,
			"investigator_id": investigator_id,
			"cause": CAUSE_ATTEMPT_SUCCESS,
		}
	)


static func resolve(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var p := _normalize_params(params)
	if game_ctx == null or game_ctx.state == null or p.is_empty():
		return {"ok": false, "error": "invalid_params"}
	var enemy_id: StringName = p.get("enemy_id", &"") as StringName
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy", "enemy_id": enemy_id}
	if enemy.location_tag == &"":
		return {"ok": false, "error": "not_in_play", "enemy_id": enemy_id}
	var cause: StringName = p.get("cause", CAUSE_AUTOMATIC) as StringName
	var was_engaged := enemy.engaged_with != &""
	## 1) nest 横置（可听）；先于脱离，避免同地点 auto-engage 在未横置时重接。
	var exhaust_res := ExhaustReadyFlow.nest_or_run_exhaust(
		game_ctx,
		{
			"target_kind": ExhaustReadyFlow.TARGET_ENEMY,
			"enemy_id": enemy_id,
			"trigger_area_change": false,
		}
	)
	var exhaust_ok := bool(exhaust_res.get("ok", false))
	var exhaust_changed := bool(exhaust_res.get("changed", false))
	## 2) 若交战：内联解除（无独立 seq.disengage）；禁止再带 exhaust 糖。
	var disengage_res := {"ok": true, "skipped": true}
	var disengaged := false
	if was_engaged and game_ctx.enemy != null:
		disengage_res = game_ctx.enemy.disengage(game_ctx, enemy_id, false, true)
		disengaged = bool(disengage_res.get("ok", false))
	var created := exhaust_changed or disengaged
	var ok := exhaust_ok and (not was_engaged or disengaged)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"effect:evade",
			{
				"enemy_id": enemy_id,
				"cause": cause,
				"exhaust_changed": exhaust_changed,
				"disengaged": disengaged,
				"ok": ok,
			}
		)
	return {
		"ok": ok,
		"enemy_id": enemy_id,
		"cause": cause,
		"investigator_id": p.get("investigator_id", &""),
		"exhaust": exhaust_res,
		"exhaust_changed": exhaust_changed,
		"disengage": disengage_res,
		"disengaged": disengaged,
		"created": created,
	}


static func _normalize_params(params: Dictionary) -> Dictionary:
	if params.is_empty():
		return {}
	var out := params.duplicate()
	var enemy_id: StringName = out.get(
		"enemy_id", out.get("target_enemy_id", &"")
	) as StringName
	if enemy_id == &"":
		return {}
	out["enemy_id"] = enemy_id
	var inv_id: StringName = out.get(
		"investigator_id", out.get("inv_id", &"")
	) as StringName
	out["investigator_id"] = inv_id
	var cause: StringName = out.get("cause", CAUSE_AUTOMATIC) as StringName
	if cause == &"":
		cause = CAUSE_AUTOMATIC
	out["cause"] = cause
	return out
