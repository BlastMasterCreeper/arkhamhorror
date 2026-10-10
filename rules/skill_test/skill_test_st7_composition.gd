class_name SkillTestSt7Composition
extends RefCounted

## ST.7 Apply results · 内联 Composition 执行槽（非 ST.6 nest；非 nest pop 后父 Seq）。
##
## 覆盖：*If you succeed/fail* · *If this test is successful/failed* · *for each fail by* ·
## committed skill *If successful…*（由发起方/提交方注册进同一 plan）。


static func register_plan(
	test: SkillTestContext,
	game_ctx: GameContext,
	plan: SkillTestSt7Plan
) -> void:
	if test == null or plan == null or game_ctx == null or plan.is_empty():
		return
	if plan.on_success != null:
		var success_body := plan.on_success
		test.on_success = func(_ctx: SkillTestContext) -> void:
			game_ctx.composition.execute(success_body)
	if plan.on_fail != null:
		var fail_body := plan.on_fail
		var prior_fail := test.on_fail
		test.on_fail = func(ctx: SkillTestContext) -> void:
			# #region agent log
			var _f := FileAccess.open("/opt/cursor/logs/debug.log", FileAccess.READ_WRITE)
			if _f == null:
				_f = FileAccess.open("/opt/cursor/logs/debug.log", FileAccess.WRITE)
			if _f != null:
				_f.seek_end()
				_f.store_line(JSON.stringify({
					"hypothesisId": "D",
					"location": "skill_test_st7_composition.gd:on_fail",
					"message": "before_execute_fail_body",
					"data": {
						"success": ctx.success if ctx else null,
						"fail_by": ctx.fail_by if ctx else -1,
						"inv": str(ctx.performing_investigator) if ctx else "",
						"body_kind": fail_body.kind if fail_body else -1,
						"body_atom": str(fail_body.atom_name) if fail_body else "",
						"children": fail_body.children.size() if fail_body else 0,
					},
					"timestamp": Time.get_ticks_msec(),
				}))
				_f.close()
			# #endregion
			if prior_fail.is_valid():
				prior_fail.call(ctx)
			game_ctx.composition.execute(fail_body)
			# #region agent log
			var inv := game_ctx.state.registry.get_investigator(ctx.performing_investigator) if game_ctx != null and game_ctx.state != null and ctx != null else null
			var _f2 := FileAccess.open("/opt/cursor/logs/debug.log", FileAccess.READ_WRITE)
			if _f2 == null:
				_f2 = FileAccess.open("/opt/cursor/logs/debug.log", FileAccess.WRITE)
			if _f2 != null:
				_f2.seek_end()
				_f2.store_line(JSON.stringify({
					"hypothesisId": "D",
					"location": "skill_test_st7_composition.gd:on_fail",
					"message": "after_execute_fail_body",
					"data": {
						"damage": inv.damage_taken if inv else -1,
						"hand": inv.hand.size() if inv else -1,
						"last_fail_by": game_ctx.composition.last_skill_test_fail_by() if game_ctx.composition else -1,
					},
					"timestamp": Time.get_ticks_msec(),
				}))
				_f2.close()
			# #endregion
	if plan.on_fail_by_each != null:
		var each_body := plan.on_fail_by_each
		test.st7_fail_by_effects.append(
			func(ctx: SkillTestContext) -> void:
				if ctx.success or ctx.fail_by <= 0:
					return
				for _i in ctx.fail_by:
					game_ctx.composition.execute(each_body)
		)


## @deprecated 用 register_plan + SkillTestSt7Plan.on_fail_by_each
static func register_fail_by_loop(
	test: SkillTestContext,
	game_ctx: GameContext,
	per_fail_body: CompositionNode
) -> void:
	var plan := SkillTestSt7Plan.new()
	plan.on_fail_by_each = per_fail_body
	register_plan(test, game_ctx, plan)
