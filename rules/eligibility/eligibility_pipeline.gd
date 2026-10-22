class_name EligibilityPipeline
extends RefCounted

## Eligibility 关卡（06 §5）：COLLECT = L1–L5；不跑 L6 费用 / L7 dry-run。
## L0 订阅匹配仍由 SequenceHandler.matches 在栈侧完成。


enum Stage { COLLECT, PRE_INITIATE, PRE_RESOLVE }


class GateReport extends RefCounted:
	var level: int = 0
	var passed: bool = true
	var reason: StringName = &""

	static func ok(level: int) -> GateReport:
		var r := GateReport.new()
		r.level = level
		r.passed = true
		return r

	static func fail(level: int, reason: StringName) -> GateReport:
		var r := GateReport.new()
		r.level = level
		r.passed = false
		r.reason = reason
		return r


## COLLECT 是否通过 L1–L5（短路：首个失败即 false）。
static func passes_collect(
	handler: SequenceHandler,
	game_ctx: GameContext,
	app_ctx: ApplicationContext,
	self_response_blocked: bool = false
) -> bool:
	return first_fail_collect(handler, game_ctx, app_ctx, self_response_blocked) == null


static func first_fail_collect(
	handler: SequenceHandler,
	game_ctx: GameContext,
	app_ctx: ApplicationContext,
	self_response_blocked: bool = false
) -> GateReport:
	if handler == null:
		return GateReport.fail(1, &"no_handler")
	var r1 := _gate_l1(handler, game_ctx)
	if not r1.passed:
		return r1
	var r2 := _gate_l2(handler, self_response_blocked)
	if not r2.passed:
		return r2
	var r3 := _gate_l3(handler, game_ctx, app_ctx)
	if not r3.passed:
		return r3
	var r4 := _gate_l4(handler, game_ctx)
	if not r4.passed:
		return r4
	var r5 := _gate_l5(handler)
	if not r5.passed:
		return r5
	return null


static func run_collect(
	handler: SequenceHandler,
	game_ctx: GameContext,
	app_ctx: ApplicationContext,
	self_response_blocked: bool = false
) -> Array:
	var reports: Array = []
	reports.append(_gate_l1(handler, game_ctx))
	reports.append(_gate_l2(handler, self_response_blocked))
	reports.append(_gate_l3(handler, game_ctx, app_ctx))
	reports.append(_gate_l4(handler, game_ctx))
	reports.append(_gate_l5(handler))
	return reports


## L1 注册存续：enabled；若 source 是卡实例则须仍在可触发区划。
static func _gate_l1(handler: SequenceHandler, game_ctx: GameContext) -> GateReport:
	if handler == null or not handler.enabled:
		return GateReport.fail(1, &"disabled")
	if handler.source_id == &"" or game_ctx == null or game_ctx.state == null:
		return GateReport.ok(1)
	var card := game_ctx.state.registry.get_card(handler.source_id)
	if card == null:
		## 测试 / 合成 source_id（非卡实例）放行。
		return GateReport.ok(1)
	if game_ctx.state.removed_from_game.has(handler.source_id):
		return GateReport.fail(1, &"source_removed")
	match card.zone:
		AhcEnums.Zone.PLAY_AREA, AhcEnums.Zone.THREAT_AREA, AhcEnums.Zone.HAND, \
		AhcEnums.Zone.LIMBO, AhcEnums.Zone.ATTACHED, AhcEnums.Zone.LOCATION_AREA:
			return GateReport.ok(1)
		_:
			return GateReport.fail(1, &"source_zone")


## L2 结构：禁自响应（causation）；其余匹配已在栈侧。
static func _gate_l2(handler: SequenceHandler, self_response_blocked: bool) -> GateReport:
	if self_response_blocked:
		return GateReport.fail(2, &"self_response")
	return GateReport.ok(2)


## L3 情景 Condition（现态 / 历史谓词 / Domain）。
static func _gate_l3(
	handler: SequenceHandler,
	game_ctx: GameContext,
	app_ctx: ApplicationContext
) -> GateReport:
	var cond: Condition = handler.collect_condition
	if cond == null:
		return GateReport.ok(3)
	var ctx := app_ctx if app_ctx != null else ApplicationContext.new()
	var eval_ctx: EvaluationContext = null
	var snapshot: Dictionary = {}
	if game_ctx != null:
		eval_ctx = EvaluationContext.from_game(ctx, game_ctx.state, game_ctx.events)
		snapshot = EligibilityCollector.build_stat_snapshot(game_ctx, ctx)
	if not cond.matches_with_snapshot(ctx, snapshot, eval_ctx):
		return GateReport.fail(3, &"situational_fail")
	if cond.domain_predicate != Condition.DomainPredicate.NONE:
		var fallback: StringName = handler.controller_id
		if fallback == &"" and ctx != null:
			fallback = ctx.controller_id
		if not cond.matches_domain(game_ctx, fallback):
			return GateReport.fail(3, &"situational_fail")
	return GateReport.ok(3)


## L4 RESTRICTION：REST-E-TRIGGER（险境 FORBID_TRIGGER 等）。
static func _gate_l4(handler: SequenceHandler, game_ctx: GameContext) -> GateReport:
	if game_ctx == null or game_ctx.registrations == null:
		return GateReport.ok(4)
	var actor := handler.controller_id
	if actor == &"":
		return GateReport.ok(4)
	## LISTENER / FRAMEWORK 非玩家发起能力不走 TRIGGER Intent。
	if handler.tier == SequenceHandler.Tier.LISTENER \
			or handler.tier == SequenceHandler.Tier.FRAMEWORK:
		return GateReport.ok(4)
	if RestrictionEvaluator.blocks_trigger(actor, game_ctx.registrations):
		return GateReport.fail(4, &"restriction_forbid_trigger")
	return GateReport.ok(4)


## L5 次数配额：`limit_remaining < 0` = 无限；`0` = 耗尽。
static func _gate_l5(handler: SequenceHandler) -> GateReport:
	if handler.limit_remaining == 0:
		return GateReport.fail(5, &"limit_reached")
	return GateReport.ok(5)
