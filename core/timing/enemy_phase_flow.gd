class_name EnemyPhaseFlow
extends RefCounted

## 敌军阶段 3.2–3.3 + 卡面 resolve_location / move / attack 命名流程。


static func hunter_patrol_3_2(game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	var moved: Array[StringName] = []
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if not _eligible_for_3_2_move(enemy):
			continue
		var def_id := _definition_id(game_ctx, enemy_id)
		if not CardRegistry.is_hunter(def_id):
			continue
		var target_inv := EnemyHunterTarget.pick_nearest_investigator(game_ctx, enemy_id)
		if target_inv == &"":
			continue
		var loc := EnemyLocationTarget.resolve(
			game_ctx, {"target": "investigator_location", "drawer_id": target_inv}
		)
		if not bool(loc.get("ok", false)):
			continue
		var body := move(
			game_ctx,
			{
				"enemy_id": enemy_id,
				"target_location": loc.get("location_tag", &""),
				"steps": 1,
			}
		)
		if bool(body.get("moved", false)):
			moved.append(enemy_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:3_2_hunter_patrol",
			{"moved": moved}
		)
	return {"ok": true, "moved": moved}


static func patrol_3_2(game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.state == null:
		return {"ok": false}
	var moved: Array[StringName] = []
	for enemy_id in game_ctx.state.registry.all_enemy_ids():
		var enemy := game_ctx.state.registry.get_enemy(enemy_id)
		if not _eligible_for_3_2_move(enemy):
			continue
		var def_id := _definition_id(game_ctx, enemy_id)
		if not CardRegistry.is_patrol(def_id):
			continue
		var spec := CardRegistry.patrol_spec(def_id)
		if spec == null:
			continue
		var target_loc := PatrolTargetResolver.resolve(spec, game_ctx, enemy_id)
		if target_loc == &"" or enemy.location_tag == target_loc:
			continue
		var body := move(
			game_ctx,
			{
				"enemy_id": enemy_id,
				"target_location": target_loc,
				"steps": 1,
			}
		)
		if bool(body.get("moved", false)):
			moved.append(enemy_id)
	if game_ctx.log != null:
		game_ctx.log.log(
			AhcEnums.LogCategory.SCENARIO,
			"enemy:3_2_patrol",
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
		attack(
			game_ctx,
			{
				"enemy_id": enemy_id,
				"target_investigator": investigator_id,
				"exhaust_after": true,
			}
		)
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
	var last := {"ok": true, "enemy_id": enemy_id, "target_location": target_loc}
	for _i in steps:
		last = EnemyMovement.move_one_step_toward_location(game_ctx, enemy_id, target_loc)
		if not bool(last.get("moved", false)):
			break
		var to_loc: StringName = last.get("to_location", &"") as StringName
		if to_loc != &"":
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
	return enemy != null and not enemy.exhausted and enemy.engaged_with == &""


static func _definition_id(game_ctx: GameContext, enemy_id: StringName) -> StringName:
	var card := game_ctx.state.registry.get_card(enemy_id)
	if card == null:
		return &""
	return card.id.definition_id
