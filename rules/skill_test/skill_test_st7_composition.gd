class_name SkillTestSt7Composition
extends RefCounted

## ST.7 Apply results · 内联 Composition（非 ST.6 nest；非 nest pop 后父 Seq）。
##
## 多来源成败后果：COLLECT → ORDER_SIMULTANEOUS（prompt order:st7）→ 按序内联执行。
## 覆盖：发起方 / committed skill / 符号 fail-by 等并入同一批。


static func register_plan(
	test: SkillTestContext,
	game_ctx: GameContext,
	plan: SkillTestSt7Plan,
	source_id: StringName = &"",
	requires_committed_card: StringName = &""
) -> void:
	if test == null or plan == null or game_ctx == null or plan.is_empty():
		return
	var src := source_id
	if src == &"":
		src = plan.source_id
	if src == &"":
		src = &"st7_plan"
	var committed := requires_committed_card
	if committed == &"":
		committed = plan.requires_committed_card
	if plan.on_success != null:
		var success_body := plan.on_success
		_append_unit(
			test,
			SkillTestSt7Unit.create(
				StringName("%s:on_success" % String(src)),
				src,
				&"on_success",
				func(ctx: SkillTestContext) -> void:
					CompositionMount.resolve_ability(
						game_ctx, success_body, ctx.performing_investigator
					),
				committed
			)
		)
	if plan.on_fail != null:
		var fail_body := plan.on_fail
		_append_unit(
			test,
			SkillTestSt7Unit.create(
				StringName("%s:on_fail" % String(src)),
				src,
				&"on_fail",
				func(ctx: SkillTestContext) -> void:
					CompositionMount.resolve_ability(
						game_ctx, fail_body, ctx.performing_investigator
					),
				committed
			)
		)
	if plan.on_fail_by_each != null:
		var each_body := plan.on_fail_by_each
		_append_unit(
			test,
			SkillTestSt7Unit.create(
				StringName("%s:on_fail_by_each" % String(src)),
				src,
				&"on_fail_by_each",
				func(ctx: SkillTestContext) -> void:
					if ctx.success or ctx.fail_by <= 0:
						return
					for _i in ctx.fail_by:
						CompositionMount.resolve_ability(
							game_ctx, each_body, ctx.performing_investigator
						),
				committed
			)
		)


## @deprecated 用 register_plan + SkillTestSt7Plan.on_fail_by_each
static func register_fail_by_loop(
	test: SkillTestContext,
	game_ctx: GameContext,
	per_fail_body: CompositionNode,
	source_id: StringName = &"fail_by_loop"
) -> void:
	var plan := SkillTestSt7Plan.new()
	plan.on_fail_by_each = per_fail_body
	plan.source_id = source_id
	register_plan(test, game_ctx, plan, source_id)


static func append_callable_unit(
	test: SkillTestContext,
	source_id: StringName,
	slot: StringName,
	run: Callable,
	requires_committed_card: StringName = &""
) -> void:
	if test == null or not run.is_valid():
		return
	_append_unit(
		test,
		SkillTestSt7Unit.create(
			StringName("%s:%s" % [String(source_id), String(slot)]),
			source_id,
			slot,
			run,
			requires_committed_card
		)
	)


static func collect_active_units(
	test: SkillTestContext,
	state: GameStateStore = null
) -> Array:
	var out: Array = []
	if test == null:
		return out
	for raw in test.st7_units:
		var unit: SkillTestSt7Unit = raw as SkillTestSt7Unit
		if unit != null and unit.applies(test, state):
			out.append(unit)
	## 遗留：直接挂在 ctx.on_success / on_fail / st7_fail_by_effects 的回调。
	if test.st7_units.is_empty():
		if test.success and test.on_success.is_valid():
			out.append(
				SkillTestSt7Unit.create(
					&"legacy:on_success",
					&"legacy",
					&"on_success",
					test.on_success
				)
			)
		if not test.success and test.on_fail.is_valid():
			out.append(
				SkillTestSt7Unit.create(
					&"legacy:on_fail",
					&"legacy",
					&"on_fail",
					test.on_fail
				)
			)
		if not test.success:
			var i := 0
			for effect in test.st7_fail_by_effects:
				if not effect.is_valid():
					continue
				var cb: Callable = effect
				out.append(
					SkillTestSt7Unit.create(
						StringName("legacy:fail_by_%d" % i),
						&"legacy",
						&"symbol_fail_by",
						cb
					)
				)
				i += 1
	return out


## COLLECT → ORDER_SIMULTANEOUS（order:st7）→ 内联执行。
static func apply_ordered(test: SkillTestContext, game_ctx: GameContext) -> Array:
	var state: GameStateStore = game_ctx.state if game_ctx != null else null
	var units: Array = collect_active_units(test, state)
	if units.is_empty():
		return []
	var ordered: Array = units
	if units.size() > 1 and game_ctx != null and game_ctx.interaction != null:
		var lead := game_ctx.lead_investigator_id
		if lead == &"":
			lead = test.performing_investigator
		ordered = game_ctx.interaction.ask_order_simultaneous(
			units, lead, &"order:st7", game_ctx
		)
		if ordered.is_empty():
			ordered = units
	test.st7_order_applied = ordered.duplicate()
	for raw in ordered:
		var unit: SkillTestSt7Unit = raw as SkillTestSt7Unit
		if unit == null or not unit.applies(test, state):
			continue
		unit.run.call(test)
	return ordered


static func _append_unit(test: SkillTestContext, unit: SkillTestSt7Unit) -> void:
	if test == null or unit == null:
		return
	test.st7_units.append(unit)
