class_name EnemyPhaseFlow
extends RefCounted

## 敌军阶段 3.2–3.3 + 卡面 resolve_location / move / attack 命名流程。
## 3.2 = Framework 基础手续（枚举合格敌人 → 开关键词消费槽）；关键词移动体在 seq.keyword.*。


static func framework_3_2(game_ctx: GameContext) -> Dictionary:
	## Grimoire 3.2 基础手续：对每个 ready、未交战的敌人，经 KeywordConsumer 开火
	## Hunter/Patrol LISTENER（seq.keyword.hunter / patrol）。本 handler **不含**移动路径。
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	var moved: Array[StringName] = []
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if not _eligible_for_3_2_move(enemy):
			continue
		var fired := KeywordConsumer.consume_at(
			game_ctx,
			KeywordProfileTable.SLOT_ENEMY_3_2,
			&"",
			enemy_id
		)
		if bool(fired.get("moved", false)):
			moved.append(enemy_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:3_2",
			{"moved": moved}
		)
	return {"ok": true, "moved": moved}


static func phase_attacks_for(
	game_ctx: GameContext,
	investigator_id: StringName
) -> Dictionary:
	## Framework 3.3 基础手续：本调查员结算与其交战的敌人攻击。
	## Massive = 对「单次阶段攻击」的效果替换（seq.keyword.massive），非平行流程。
	if game_ctx == null or game_ctx.state == null or game_ctx.combat == null:
		return {"ok": false}
	var inv := game_ctx.state.registry.get_investigator(investigator_id)
	if inv == null:
		return {"ok": false, "attacks": 0}
	var attack_count := 0
	for enemy_id in _enemies_attacking_investigator(game_ctx, investigator_id):
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null or enemy.exhausted:
			continue
		## 庞大：替换本敌本阶段攻击路径为 batch；已横置则跳过（batch 末或中断后）。
		if _has_massive(game_ctx, enemy_id):
			var replaced := _resolve_massive_replacement(game_ctx, enemy_id)
			attack_count += int(replaced.get("attacks", 0))
			continue
		if enemy.engaged_with != investigator_id:
			continue
		var params := {
			"enemy_id": enemy_id,
			"target_investigator": investigator_id,
			"exhaust_after": true,
		}
		## 经 catalog.nest 发出 enemy_attack WHEN/AFTER（卡面 Forced 可订阅）。
		if (
			game_ctx.sequence_catalog != null
			and game_ctx.sequence_catalog.has_flow(&"seq.enemy.attack")
		):
			game_ctx.sequence_catalog.nest(game_ctx, &"seq.enemy.attack", params)
		else:
			attack(game_ctx, params)
		attack_count += 1
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:phase_attacks",
			{"investigator_id": investigator_id, "attacks": attack_count}
		)
	return {"ok": true, "attacks": attack_count}


static func _enemies_attacking_investigator(
	game_ctx: GameContext,
	investigator_id: StringName
) -> Array[StringName]:
	var inv := game_ctx.state.registry.get_investigator(investigator_id)
	if inv == null:
		return []
	var out: Array[StringName] = []
	var seen: Dictionary = {}
	for enemy_id in inv.threat_area:
		if seen.has(enemy_id):
			continue
		seen[enemy_id] = true
		out.append(enemy_id)
	## 庞大永不进威胁区：虚拟交战同地点的 ready 庞大敌人也进入本步候选。
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		if seen.has(enemy_id):
			continue
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null or not _has_massive(game_ctx, enemy_id):
			continue
		if not MassiveEngagement.is_virtually_engaged_with(enemy, investigator_id, game_ctx):
			continue
		seen[enemy_id] = true
		out.append(enemy_id)
	return out


static func _has_massive(game_ctx: GameContext, enemy_id: StringName) -> bool:
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy != null and enemy.massive:
		return true
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null:
		return false
	return CardRegistry.is_massive(card.id.definition_id)


static func _resolve_massive_replacement(
	game_ctx: GameContext,
	enemy_id: StringName
) -> Dictionary:
	## 效果替换竖切：nest seq.keyword.massive（对齐 Hunter KeywordConsumer 模式）。
	if (
		game_ctx.sequence_catalog != null
		and game_ctx.sequence_catalog.has_flow(&"seq.keyword.massive")
	):
		return game_ctx.sequence_catalog.nest(
			game_ctx,
			&"seq.keyword.massive",
			{"card_id": enemy_id, "enemy_id": enemy_id}
		)
	return MassiveEngagement.resolve_phase_batch(game_ctx, enemy_id)


static func resolve_location(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	return EnemyLocationTarget.resolve(game_ctx, params)


static func move(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null:
		return {"ok": false}
	var enemy_id: StringName = params.get("enemy_id", &"")
	var target_loc: StringName = params.get("target_location", &"")
	if enemy_id == &"" or target_loc == &"":
		return {"ok": false, "reason": &"missing_enemy_or_location"}
	var steps: int = maxi(1, int(params.get("steps", 1)))
	## 卡面「移入后再明示交战」时可关自动交战，避免 Prey 抢先。
	var do_auto_engage: bool = bool(params.get("auto_engage", true))
	var last := {"ok": true, "enemy_id": enemy_id, "target_location": target_loc}
	for _i in steps:
		last = EnemyMovement.move_one_step_toward_location(game_ctx, enemy_id, target_loc)
		if not bool(last.get("moved", false)):
			break
		var to_loc: StringName = last.get("to_location", &"") as StringName
		if to_loc != &"" and do_auto_engage:
			var engage := EngageFlow.nest_after_area_change(game_ctx, to_loc, enemy_id)
			last["engaged_investigator"] = engage.get("investigator_id", &"")
			var moved_enemy := game_ctx.state.registry.get_enemy(enemy_id)
			if moved_enemy != null and moved_enemy.massive:
				MassiveEngagement.sync_for_enemy(game_ctx, enemy_id)
	last["enemy_id"] = enemy_id
	last["target_location"] = target_loc
	last["ok"] = true
	return last


static func attack(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.combat == null:
		return {"ok": false}
	var enemy_id: StringName = params.get("enemy_id", &"")
	var target: StringName = params.get(
		"target_investigator", params.get("investigator_id", &"")
	)
	if enemy_id == &"" or target == &"":
		return {"ok": true, "skipped": true}
	var enemy := game_ctx.state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false}
	var exhaust_after: bool = bool(params.get("exhaust_after", false))
	var strike := EnemyAttack.enemy_strike(
		enemy_id,
		target,
		enemy.attack_damage,
		enemy.attack_horror,
		exhaust_after
	)
	game_ctx.combat.perform_attack(strike)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:attack",
			{
				"enemy_id": enemy_id,
				"target": target,
				"damage": enemy.attack_damage,
				"horror": enemy.attack_horror,
				"exhaust_after": exhaust_after,
			}
		)
	return {"ok": true, "enemy_id": enemy_id, "target": target}


static func _eligible_for_3_2_move(enemy: EnemyState) -> bool:
	## Framework 资格：ready + 未交战。是否带 Hunter/Patrol 由 KeywordConsumer 判定。
	return enemy != null and not enemy.exhausted and enemy.engaged_with == &""
