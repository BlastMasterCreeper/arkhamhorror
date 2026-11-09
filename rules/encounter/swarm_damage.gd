class_name SwarmDamage
extends RefCounted

## 蜂拥伤害：主体可超生命且不可击败；集群卡牌击败后超额伤害经 PI 选目标传递。
## 自动模式只是 Gate/DefaultResolver 的可选路径，不是强制自动。


static func host_blocks_defeat(game_ctx: GameContext, enemy_id: StringName) -> bool:
	if game_ctx == null or enemy_id == &"":
		return false
	if SwarmPack.is_swarm_card(game_ctx, enemy_id):
		return false
	return SwarmPack.has_swarm_cards(game_ctx, enemy_id)


## 对敌人造成伤害；处理主体超限与集群溢出。
static func deal_damage(game_ctx: GameContext, enemy_id: StringName, amount: int) -> Dictionary:
	if game_ctx == null or game_ctx.state == null or enemy_id == &"" or amount <= 0:
		return {"ok": false, "defeated": false}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "defeated": false}
	enemy.damage += amount
	if SwarmPack.is_swarm_card(game_ctx, enemy_id):
		if enemy.damage < enemy.health:
			return {"ok": true, "defeated": false, "damage": enemy.damage}
		var excess := enemy.damage - enemy.health
		enemy.damage = enemy.health
		## 退场会解绑；溢出候选须在 leave 前快照。
		var host_id := SwarmPack.host_of(game_ctx, enemy_id)
		var spill_candidates := _spill_candidates(game_ctx, host_id, enemy_id)
		var defeated := DefeatFlow.check_enemy_damage_cap(game_ctx, enemy_id)
		var spill := {"ok": true, "spilled": 0}
		if excess > 0 and bool(defeated.get("defeated", false)):
			spill = spill_excess(game_ctx, excess, spill_candidates)
		defeated["excess"] = excess
		defeated["spill"] = spill
		return defeated
	## 主体：可超生命；仍有集群卡牌则不击败。
	if host_blocks_defeat(game_ctx, enemy_id):
		return {
			"ok": true,
			"defeated": false,
			"damage": enemy.damage,
			"over_health": enemy.damage >= enemy.health,
			"host_blocked": true,
		}
	if enemy.damage < enemy.health:
		return {"ok": true, "defeated": false, "damage": enemy.damage}
	return DefeatFlow.check_enemy_damage_cap(game_ctx, enemy_id)


static func _spill_candidates(
	game_ctx: GameContext,
	host_id: StringName,
	from_swarm_id: StringName
) -> Array:
	var candidates: Array = []
	if game_ctx == null or host_id == &"":
		return candidates
	for sid in SwarmPack.swarm_ids(game_ctx, host_id):
		if sid != from_swarm_id and game_ctx.state.registry.get_enemy(sid) != null:
			candidates.append(sid)
	if game_ctx.state.registry.get_enemy(host_id) != null:
		candidates.append(host_id)
	return candidates


## `candidates` 为 leave 前快照。经 PI 选目标；支持自动默认，但不强制自动。
static func spill_excess(game_ctx: GameContext, excess: int, candidates: Array) -> Dictionary:
	if game_ctx == null or excess <= 0:
		return {"ok": true, "spilled": 0}
	## 过滤 leave 后仍在场的目标。
	var alive: Array = []
	for raw in candidates:
		var cid: StringName = raw as StringName
		if cid != &"" and game_ctx.state.registry.get_enemy(cid) != null:
			alive.append(cid)
	if alive.is_empty():
		return {"ok": true, "spilled": 0, "remaining": excess}
	## PI 有限期确认；未确认 / 无 Gate 时才用默认（自动模式可走这条）。
	var pick: Variant = null
	if game_ctx.interaction != null:
		var decider := game_ctx.lead_investigator_id
		if decider == &"":
			for inv_id in game_ctx.state.registry.all_investigator_ids():
				decider = inv_id
				break
		pick = game_ctx.interaction.ask_pick_target(
			alive,
			decider,
			&"swarm:spill_excess",
			game_ctx
		)
	if pick == null:
		pick = alive[0]
	var target_id: StringName = pick as StringName
	if target_id == &"":
		return {"ok": true, "spilled": 0, "remaining": excess}
	var nested := deal_damage(game_ctx, target_id, excess)
	return {
		"ok": true,
		"spilled": excess,
		"to": target_id,
		"result": nested,
	}
