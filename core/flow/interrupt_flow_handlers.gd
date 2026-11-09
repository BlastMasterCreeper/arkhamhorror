class_name InterruptFlowHandlers
extends RefCounted


static func resolve_cancel(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	return InterruptHandler.apply_cancel(game_ctx, _target_from_params(params))


static func resolve_ignore(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	return InterruptHandler.apply_ignore(game_ctx, _target_from_params(params))


static func _target_from_params(params: Dictionary) -> InterruptTarget:
	var raw: Variant = params.get("target", null)
	if raw is InterruptTarget:
		return raw as InterruptTarget
	if raw is Dictionary:
		return InterruptTarget.from_params(raw as Dictionary)
	return InterruptTarget.from_params({})
