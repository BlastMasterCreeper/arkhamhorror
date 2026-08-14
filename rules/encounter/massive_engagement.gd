class_name MassiveEngagement
extends RefCounted

## 庞大（Massive）敌人交战 · 虚拟 engage、阶段 batch 攻击。
##
## 魔典 p.16 / FAQ 2.29：batch 途中被横置 → 剩余攻击不发起；
## 全部攻击结算完毕后才横置庞大敌人。
## **永不进威胁区** — Fight 失败转嫁（Grimoire Fight Action）针对威胁区内交战的敌人，
## 庞大无此结构；另见魔典 Massive 专条：失败时不向其他虚拟交战调查员转嫁伤害（08 §6.6）。


static func is_virtually_engaged_with(
	enemy: EnemyState,
	inv_id: StringName,
	game_ctx: GameContext
) -> bool:
	if enemy == null or not enemy.massive or enemy.exhausted:
		return false
	var inv := game_ctx.state.registry.get_investigator(inv_id)
	if inv == null or inv.eliminated or inv.location_tag == &"":
		return false
	return inv.location_tag == enemy.location_tag


static func investigators_at_location(
	game_ctx: GameContext,
	location_tag: StringName
) -> Array[StringName]:
	var out: Array[StringName] = []
	if game_ctx == null or game_ctx.state == null or location_tag == &"":
		return out
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv == null or inv.eliminated or inv.location_tag != location_tag:
			continue
		out.append(inv_id)
	return out


static func sync_at_location(game_ctx: GameContext, location_tag: StringName) -> void:
	if game_ctx == null or game_ctx.state == null or location_tag == &"":
		return
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null or not enemy.massive or enemy.location_tag != location_tag:
			continue
		_clear_threat_area_membership(game_ctx, enemy_id)
		enemy.engaged_with = &""


static func sync_for_enemy(game_ctx: GameContext, enemy_id: StringName) -> void:
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null or not enemy.massive:
		return
	_clear_threat_area_membership(game_ctx, enemy_id)
	enemy.engaged_with = &""


static func resolve_phase_batch(
	game_ctx: GameContext,
	enemy_id: StringName,
	after_each_attack: Callable = Callable()
) -> Dictionary:
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null or not enemy.massive or enemy.exhausted:
		return {"ok": true, "attacks": 0, "interrupted": false}
	var order := _build_attack_order(game_ctx, enemy)
	if order.is_empty():
		return {"ok": true, "attacks": 0, "interrupted": false}
	var resolved := 0
	var resolved_set: Dictionary = {}
	var i := 0
	while i < order.size():
		if enemy.exhausted:
			return {
				"ok": true,
				"attacks": resolved,
				"interrupted": true,
				"enemy_id": enemy_id,
			}
		var target: StringName = order[i]
		if not is_virtually_engaged_with(enemy, target, game_ctx):
			i += 1
			continue
		EnemyPhaseFlow.attack(
			game_ctx,
			{
				"enemy_id": enemy_id,
				"target_investigator": target,
				"exhaust_after": false,
			}
		)
		resolved += 1
		resolved_set[target] = true
		if after_each_attack.is_valid():
			after_each_attack.call(enemy_id, target)
		for inv_id in investigators_at_location(game_ctx, enemy.location_tag):
			if not resolved_set.has(inv_id) and not order.has(inv_id):
				order.append(inv_id)
		i += 1
	if resolved > 0 and not enemy.exhausted:
		if game_ctx.enemy != null:
			game_ctx.enemy.set_enemy_exhausted(game_ctx, enemy_id, true, false)
		else:
			enemy.exhausted = true
	return {
		"ok": true,
		"attacks": resolved,
		"interrupted": false,
		"enemy_id": enemy_id,
	}


static func resolve_all_phase_batches(game_ctx: GameContext) -> Dictionary:
	var attacked: Array[StringName] = []
	var total := 0
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false, "attacks": 0, "enemies": attacked}
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null or not enemy.massive or enemy.exhausted:
			continue
		if investigators_at_location(game_ctx, enemy.location_tag).is_empty():
			continue
		var batch := resolve_phase_batch(game_ctx, enemy_id)
		var count: int = int(batch.get("attacks", 0))
		if count > 0:
			attacked.append(enemy_id)
			total += count
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:massive_phase_attacks",
			{"enemies": attacked, "attacks": total}
		)
	return {"ok": true, "attacks": total, "enemies": attacked}


static func _build_attack_order(
	game_ctx: GameContext,
	enemy: EnemyState
) -> Array[StringName]:
	var targets := investigators_at_location(game_ctx, enemy.location_tag)
	if targets.is_empty():
		return []
	if game_ctx.interaction != null:
		var lead := game_ctx.lead_investigator_id
		if lead == &"":
			var ids := game_ctx.state.registry.all_investigator_ids()
			if not ids.is_empty():
				lead = ids[0]
		var ordered: Array = game_ctx.interaction.ask_order_simultaneous(
			targets,
			lead,
			&"order:massive_phase_attacks",
			game_ctx
		)
		var out: Array[StringName] = []
		for item in ordered:
			out.append(item as StringName)
		return out
	return targets.duplicate()


static func _clear_threat_area_membership(game_ctx: GameContext, enemy_id: StringName) -> void:
	if game_ctx == null or game_ctx.state == null:
		return
	for inv_id in game_ctx.state.registry.all_investigator_ids():
		var inv := game_ctx.state.registry.get_investigator(inv_id)
		if inv != null:
			inv.threat_area.erase(enemy_id)
