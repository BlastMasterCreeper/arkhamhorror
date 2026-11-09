class_name EnterThreatAreaFlow
extends RefCounted

## 进入威胁区 · `seq.effect.enter_threat_area`。
##
## **区划原语**：把敌人放进某调查员威胁区（可被 AFTER 听到）。
## 与交战（`seq.engage`）正交：
## - **交战** = ENGAGEMENT Buff 包装 + 本流程（仅 **场上 → 威胁区**）
## - **生成 engaged** = 场外（牌库等）→ 威胁区 + Buff；**不**压 `seq.engage`
## - **单纯进入威胁区**（诡计进威胁区等）也可 nest 本条，不必伴随交战
##
## 纸面「After … engages you / After you engage …」订本条 AFTER（`match_kind=
## enter_threat_area`）：听区划进入，不听交战手续完成 / 不听 grant·庞大。


const FLOW: StringName = &"seq.effect.enter_threat_area"

## 来源：交战包装（场上区域 → 威胁区）。
const FROM_IN_PLAY: StringName = &"in_play"
## 来源：生成等（场外 → 威胁区）；不是交战。
const FROM_OUT_OF_PLAY: StringName = &"out_of_play"


static func resolve(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var enemy_id: StringName = params.get("enemy_id", &"") as StringName
	var inv_id: StringName = params.get(
		"investigator_id", params.get("controller_id", &"")
	) as StringName
	var from: StringName = params.get("from", FROM_IN_PLAY) as StringName
	if from == &"":
		from = FROM_IN_PLAY
	if game_ctx == null or game_ctx.state == null or enemy_id == &"" or inv_id == &"":
		return {"ok": false, "error": "missing_pair"}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if enemy == null or inv == null:
		return {"ok": false, "error": "unknown_entity"}
	if enemy.massive:
		return {"ok": true, "skipped": true, "reason": &"massive"}
	if inv.threat_area.has(enemy_id):
		return {
			"ok": true,
			"skipped": true,
			"reason": &"already_in_threat",
			"enemy_id": enemy_id,
			"investigator_id": inv_id,
			"from": from,
		}
	## 离开其它调查员威胁区（一对一占位）。
	for other_id in game_ctx.state.registry.all_investigator_ids():
		if other_id == inv_id:
			continue
		var other := game_ctx.state.registry.get_investigator(other_id)
		if other != null:
			other.threat_area.erase(enemy_id)
	enemy.engaged_with = inv_id
	inv.threat_area.append(enemy_id)
	return {
		"ok": true,
		"enemy_id": enemy_id,
		"investigator_id": inv_id,
		"from": from,
		"moved_into_threat_area": true,
	}


static func nest_or_run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(FLOW)
	):
		return game_ctx.sequence_catalog.nest(game_ctx, FLOW, params)
	return resolve(game_ctx, params)


## 尚未在该威胁区时才压栈（已在则静默跳过，避免 sync 重入重开火）。
static func enter_if_needed(
	game_ctx: GameContext,
	enemy_id: StringName,
	investigator_id: StringName,
	from: StringName = FROM_IN_PLAY
) -> Dictionary:
	if game_ctx == null or enemy_id == &"" or investigator_id == &"":
		return {"ok": false, "skipped": true}
	var inv := game_ctx.state.registry.get_investigator(investigator_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	if inv.threat_area.has(enemy_id):
		return {"ok": true, "skipped": true, "reason": &"already_in_threat"}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy != null and enemy.massive:
		return {"ok": true, "skipped": true, "reason": &"massive"}
	return nest_or_run(
		game_ctx,
		{"enemy_id": enemy_id, "investigator_id": investigator_id, "from": from}
	)


## 主体 + 包内成员：各进入威胁区一次（for-each；已在则跳过）。
static func enter_pack_if_needed(
	game_ctx: GameContext,
	source_id: StringName,
	investigator_id: StringName,
	from: StringName = FROM_IN_PLAY
) -> Dictionary:
	if game_ctx == null or source_id == &"" or investigator_id == &"":
		return {"ok": false, "entered": 0}
	var entered: Array[StringName] = []
	for mid in SwarmPack.pack_ids(game_ctx, source_id):
		var res := enter_if_needed(game_ctx, mid, investigator_id, from)
		if bool(res.get("moved_into_threat_area", false)):
			entered.append(mid)
	return {"ok": true, "entered": entered.size(), "enemy_ids": entered}
