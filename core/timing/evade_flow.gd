class_name EvadeFlow
extends RefCounted

## 躲避效果核 · `seq.effect.evade`。
## 效果体同时组：**横置** 与 **解除交战**（若交战）同一时刻；组完才 After。
## ≠ nest 横置后再内联脱离（那会让 after_exhaust 插在脱离前）。
## 入口：成功躲避尝试（ST.7）或自动躲避（卡面 nest；无检定）。
## 不是：躲避行动外壳、躲避尝试本身、自动成功的检定。
##
## 卡面措辞：
## - 「automatically evade」= **执行**本核（mode=automatic）
## - 「evade」作效果词多用于**时点**（听本 seq）；执行体仍用自动躲避

const FLOW := &"seq.effect.evade"

## mode：入口标签（非第二套结算）。automatic = 自动躲避；attempt = 尝试成功。
const MODE_AUTOMATIC := &"automatic"
const MODE_ATTEMPT := &"attempt"


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


## 自动躲避入口（mode=automatic）。
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


## 成功躲避尝试入口（mode=attempt）。
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
			"mode": MODE_ATTEMPT,
		}
	)


static func normalize_mode(mode: StringName) -> StringName:
	if mode == MODE_ATTEMPT or mode == &"attempt_success":
		return MODE_ATTEMPT
	## automatic，以及历史 effect / cause 别名 / 空 → 自动躲避。
	return MODE_AUTOMATIC


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
	var mode: StringName = p.get("mode", MODE_AUTOMATIC) as StringName
	var was_engaged := enemy.engaged_with != &""
	var location_tag := enemy.location_tag
	## 同时组（01 §5.3）：横置 + 解除交战同一时刻；组内不 nest、不放 After。
	## 横置走 ExhaustReadyFlow.exhaust（直写；禁 nest seq.effect.exhaust，否则 After 插入组中）。
	var exhaust_res := ExhaustReadyFlow.exhaust(
		game_ctx,
		{
			"target_kind": ExhaustReadyFlow.TARGET_ENEMY,
			"enemy_id": enemy_id,
			"trigger_area_change": false,
		}
	)
	var exhaust_ok := bool(exhaust_res.get("ok", false))
	var exhaust_changed := bool(exhaust_res.get("changed", false))
	var disengage_res := {"ok": true, "skipped": true}
	var disengaged := false
	if was_engaged and game_ctx.enemy != null:
		## 组内脱离：不触发区域变更 After（组后再 nest auto-engage）。
		disengage_res = game_ctx.enemy.disengage(game_ctx, enemy_id, false, false)
		disengaged = bool(disengage_res.get("ok", false))
	## 组 commit 后：脱离带来的同地点 auto-engage（敌已横置 → 不会重接自己）。
	if was_engaged and disengaged and location_tag != &"":
		EngageFlow.nest_after_area_change(
			game_ctx, location_tag, enemy_id, &"engagement"
		)
	var created := exhaust_changed or disengaged
	var ok := exhaust_ok and (not was_engaged or disengaged)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"effect:evade",
			{
				"enemy_id": enemy_id,
				"mode": mode,
				"exhaust_changed": exhaust_changed,
				"disengaged": disengaged,
				"simultaneous": true,
				"ok": ok,
			}
		)
	return {
		"ok": ok,
		"enemy_id": enemy_id,
		"mode": mode,
		"investigator_id": p.get("investigator_id", &""),
		"exhaust": exhaust_res,
		"exhaust_changed": exhaust_changed,
		"disengage": disengage_res,
		"disengaged": disengaged,
		"created": created,
		"simultaneous": true,
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
	## 兼容历史 `cause` 键。
	var raw_mode: StringName = out.get(
		"mode", out.get("cause", MODE_AUTOMATIC)
	) as StringName
	out["mode"] = normalize_mode(raw_mode)
	out.erase("cause")
	return out
