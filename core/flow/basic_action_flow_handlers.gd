class_name BasicActionFlowHandlers
extends RefCounted

var _state: GameStateStore
var _skill_tests: SkillTestEngine


func _init(state: GameStateStore, skill_tests: SkillTestEngine) -> void:
	_state = state
	_skill_tests = skill_tests


func investigate(game_ctx: GameContext, inv_id: StringName, extra: Dictionary) -> Dictionary:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var location_id: StringName = extra.get("location_id", inv.location_tag)
	var loc := _state.registry.get_location(location_id)
	if loc == null:
		return {"ok": false, "error": "unknown_location"}
	if inv.location_tag != loc.id:
		return {"ok": false, "error": "not_at_location"}
	var commits := _commits_from_extra(extra)
	var test := SkillTestContext.new()
	test.performing_investigator = inv_id
	test.skill = AhcEnums.SkillType.INTELLECT
	## MOD-Q-SHROUD：印刷 shroud 经 ModifierEngine 后再作难度（下限 0）。
	var shroud := loc.shroud
	if game_ctx != null and game_ctx.modifiers != null:
		var shroud_q := ModifierQuery.new()
		shroud_q.controller_id = inv_id
		shroud_q.stat = AhcEnums.StatRef.SHROUD
		shroud = game_ctx.modifiers.compute(loc.shroud, shroud_q)
	test.difficulty = shroud
	var location_id_copy := location_id
	var inv_copy := inv_id
	## ST.7：AmountPlan(DISCOVER) → 消费式修正 → 仅 amount>0 落点（06 §6 / §16.3.2）。
	test.on_success = func(_ctx: SkillTestContext) -> void:
		var plan := AmountPlan.discover_single(location_id_copy, 1)
		if game_ctx != null and game_ctx.modifiers != null:
			plan = game_ctx.modifiers.apply_to_amount_plan(plan, inv_copy, game_ctx)
		ModifierEngine.settle_amount_plan(game_ctx, plan, {"inv_id": inv_copy})
	var result := _skill_tests.run_full_test(test, game_ctx, commits)
	return {
		"ok": true,
		"success": result.success,
		"modified_value": result.modified_value,
		"skill_test_id": test.id,
	}


## move / engage 已统一 nest `seq.effect.move` / `seq.engage`；本类只保留检定核。


func fight(game_ctx: GameContext, inv_id: StringName, extra: Dictionary) -> Dictionary:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var enemy_id: StringName = extra.get("enemy_id", &"")
	var enemy := _state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy"}
	var target_err := _validate_fight_target(game_ctx, inv, enemy)
	if target_err != "":
		return {"ok": false, "error": target_err}
	var commits := _commits_from_extra(extra)
	var test := SkillTestContext.new()
	test.performing_investigator = inv_id
	test.target_enemy_id = enemy_id
	test.skill = AhcEnums.SkillType.COMBAT
	test.difficulty = enemy.fight
	var enemy_id_copy := enemy_id
	var inv_copy := inv_id
	## ST.7：AmountPlan(ATTACK_DAMAGE) → 消费式修正 → 仅 amount>0 落点（06 §6 / §16.3.2）。
	test.on_success = func(_ctx: SkillTestContext) -> void:
		var plan := AmountPlan.attack_damage_single(enemy_id_copy, 1)
		if game_ctx != null and game_ctx.modifiers != null:
			plan = game_ctx.modifiers.apply_to_amount_plan(plan, inv_copy, game_ctx)
		ModifierEngine.settle_amount_plan(game_ctx, plan)
	test.on_fail = func(_ctx: SkillTestContext) -> void:
		var fight_damage: int = int(extra.get("fight_damage", 1))
		RuleMount.consume_at(
			game_ctx,
			RuleProfileTable.SLOT_FIGHT_FAIL,
			{
				"investigator_id": inv_copy,
				"enemy_id": enemy_id_copy,
				"card_id": enemy_id_copy,
				"fight_damage": fight_damage,
			}
		)
	var result := _skill_tests.run_full_test(test, game_ctx, commits)
	return {
		"ok": true,
		"success": result.success,
		"modified_value": result.modified_value,
		"skill_test_id": test.id,
	}


func evade(game_ctx: GameContext, inv_id: StringName, extra: Dictionary) -> Dictionary:
	var inv := _state.registry.get_investigator(inv_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var enemy_id: StringName = extra.get("enemy_id", &"")
	var enemy := _state.registry.get_enemy(enemy_id)
	if enemy == null:
		return {"ok": false, "error": "unknown_enemy"}
	if not EngagementStatus.is_engaged_with(game_ctx, enemy_id, inv_id):
		return {"ok": false, "error": "not_engaged"}
	var commits := _commits_from_extra(extra)
	var test := SkillTestContext.new()
	test.performing_investigator = inv_id
	test.target_enemy_id = enemy_id
	test.skill = AhcEnums.SkillType.AGILITY
	test.difficulty = enemy.evade
	var enemy_id_copy := enemy_id
	var inv_copy := inv_id
	## ST.7：成功 → nest 躲避效果核（非 pop 后父 Seq；非真空 disengage+exhaust）。
	test.on_success = func(_ctx: SkillTestContext) -> void:
		EvadeFlow.after_attempt_success(game_ctx, enemy_id_copy, inv_copy)
	var result := _skill_tests.run_full_test(test, game_ctx, commits)
	return {
		"ok": true,
		"success": result.success,
		"modified_value": result.modified_value,
		"skill_test_id": test.id,
	}


func _validate_fight_target(
	game_ctx: GameContext,
	inv: InvestigatorState,
	enemy: EnemyState
) -> String:
	if not enemy.is_at_location(inv.location_tag):
		return "wrong_location"
	## REST-E-ACTION：冷漠 FORBID_ATTACK（未交战）；已交战 Evaluator 放行。
	if (
		game_ctx != null
		and game_ctx.registrations != null
		and RestrictionEvaluator.blocks_fight(inv.id, enemy.id, game_ctx.registrations)
	):
		return "aloof"
	## 拥有已标 aloof、尚未挂 Register 时的兜底（测试 Domain-only）。
	if enemy.aloof and not EngagementStatus.is_engaged(game_ctx, enemy.id):
		return "aloof"
	return ""


func _commits_from_extra(extra: Dictionary) -> Array[CommittedCard]:
	var out: Array[CommittedCard] = []
	for item in extra.get("commits", []):
		if item is CommittedCard:
			out.append(item)
	return out

