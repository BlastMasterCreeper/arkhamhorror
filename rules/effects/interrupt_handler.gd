class_name InterruptHandler
extends RefCounted


static func apply_cancel(game_ctx: GameContext, target: InterruptTarget) -> Dictionary:
	if game_ctx == null or game_ctx.effects == null:
		return {"ok": false, "error": "missing_effects"}
	return game_ctx.effects.interrupt_cancel_dispatch(target)


static func apply_ignore(game_ctx: GameContext, target: InterruptTarget) -> Dictionary:
	if game_ctx == null or game_ctx.effects == null:
		return {"ok": false, "error": "missing_effects"}
	return game_ctx.effects.interrupt_ignore_dispatch(target)
