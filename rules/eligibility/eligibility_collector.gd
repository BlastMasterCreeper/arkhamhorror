class_name EligibilityCollector
extends RefCounted

## Catalog COLLECT 竖切：L3 情景 + StatProjection snapshot。完整 L0–L5 待接。


static func build_stat_snapshot(game_ctx: GameContext, app_ctx: ApplicationContext) -> Dictionary:
	if game_ctx == null or game_ctx.stat_projections == null:
		return {}
	var eval_ctx := EvaluationContext.from_game(app_ctx, game_ctx.state, game_ctx.events)
	return game_ctx.stat_projections.ensure_hot_for_registrations(eval_ctx)
