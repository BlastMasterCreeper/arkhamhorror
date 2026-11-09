class_name EnterThreatAreaFlow
extends RefCounted

## 敌人进入威胁区时点信封 · `seq.effect.enter_threat_area`。
##
## 纸面「After … engages you / After you engage …」订本条 AFTER（match_kind=
## `enter_threat_area`），**不是** `seq.engage` 手续完成。
## 物理移入威胁区仍由 `seq.engage` / `spawn_engaged` / 蜂拥垫牌完成；本流程只提供
## 可被听到的时点（RESOLVE 为空）。
##
## 庞大虚拟交战 / `placement=grant` 不进威胁区 → **不** announce。


const FLOW: StringName = &"seq.effect.enter_threat_area"


static func resolve(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	## 时点信封：物理已在调用方落地；此处只回报指称。
	var enemy_id: StringName = params.get("enemy_id", &"") as StringName
	var inv_id: StringName = params.get(
		"investigator_id", params.get("controller_id", &"")
	) as StringName
	return {
		"ok": true,
		"enemy_id": enemy_id,
		"investigator_id": inv_id,
		"timing_only": true,
	}


static func nest_or_run(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if (
		game_ctx != null
		and game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(FLOW)
	):
		return game_ctx.sequence_catalog.nest(game_ctx, FLOW, params)
	return resolve(game_ctx, params)


## 仅当敌人确实在该调查员威胁区时开火（每实例一条）。
static func announce_if_in_threat(
	game_ctx: GameContext,
	enemy_id: StringName,
	investigator_id: StringName
) -> Dictionary:
	if game_ctx == null or enemy_id == &"" or investigator_id == &"":
		return {"ok": false, "skipped": true}
	var inv := game_ctx.state.registry.get_investigator(investigator_id)
	if inv == null or not inv.threat_area.has(enemy_id):
		return {"ok": true, "skipped": true, "reason": &"not_in_threat"}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy != null and enemy.massive:
		## 庞大永不进威胁区；防守性跳过。
		return {"ok": true, "skipped": true, "reason": &"massive"}
	return nest_or_run(
		game_ctx,
		{"enemy_id": enemy_id, "investigator_id": investigator_id}
	)


## 主体 + 已在威胁区的集群卡牌各 announce 一次（for-each）。
static func announce_pack_in_threat(
	game_ctx: GameContext,
	source_id: StringName,
	investigator_id: StringName
) -> Dictionary:
	if game_ctx == null or source_id == &"" or investigator_id == &"":
		return {"ok": false, "announced": 0}
	var announced: Array[StringName] = []
	for mid in SwarmPack.pack_ids(game_ctx, source_id):
		var res := announce_if_in_threat(game_ctx, mid, investigator_id)
		if bool(res.get("ok", false)) and not bool(res.get("skipped", false)):
			announced.append(mid)
	return {"ok": true, "announced": announced.size(), "enemy_ids": announced}
