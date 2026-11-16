class_name InterruptFlowHandlers
extends RefCounted

## `seq.interrupt.cancel` / `seq.interrupt.ignore` RESOLVE · 直调 ERG dispatch（无中间 Handler）。


static func resolve_cancel(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.effects == null:
		return {"ok": false, "error": "missing_effects"}
	return game_ctx.effects.interrupt_cancel_dispatch(_target_from_params(params))


static func resolve_ignore(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.effects == null:
		return {"ok": false, "error": "missing_effects"}
	return game_ctx.effects.interrupt_ignore_dispatch(_target_from_params(params))


static func _target_from_params(params: Dictionary) -> InterruptTarget:
	var raw: Variant = params.get("target", null)
	if raw is InterruptTarget:
		return raw as InterruptTarget
	if raw is Dictionary:
		return InterruptTarget.from_params(raw as Dictionary)
	return InterruptTarget.from_params({})
