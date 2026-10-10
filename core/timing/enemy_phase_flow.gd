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
	if game_ctx == null or game_ctx.state == null or game_ctx.combat == null:
		return {"ok": false}
	var inv := game_ctx.state.registry.get_investigator(investigator_id)
	if inv == null:
		return {"ok": false, "attacks": 0}
	var attack_count := 0
	for enemy_id in inv.threat_area.duplicate():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if enemy == null or enemy.exhausted or enemy.massive:
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


static func massive_phase_attacks_all(game_ctx: GameContext) -> Dictionary:
	return MassiveEngagement.resolve_all_phase_batches(game_ctx)


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
