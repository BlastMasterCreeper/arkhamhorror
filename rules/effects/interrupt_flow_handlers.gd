class_name InterruptFlowHandlers
extends RefCounted


static func resolve_cancel(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var target := InterruptTarget.from_params(params.get("target", {}) as Dictionary)
	return InterruptHandler.apply_cancel(game_ctx, target)


static func resolve_ignore(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var target := InterruptTarget.from_params(params.get("target", {}) as Dictionary)
	return InterruptHandler.apply_ignore(game_ctx, target)
