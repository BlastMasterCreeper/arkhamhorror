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
			if prior_fail.is_valid():
				prior_fail.call(ctx)
			game_ctx.composition.execute(fail_body)
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
