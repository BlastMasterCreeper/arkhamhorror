class_name EffectOpExecutor
extends RefCounted


static func execute(request: EffectRequest, game_ctx: GameContext) -> Dictionary:
	if request == null:
		return {"ok": false, "error": "invalid_request"}
	match request.op:
		AhcEnums.EffectOp.DRAW_CARDS:
			return _draw_cards(request, game_ctx)
		AhcEnums.EffectOp.GAIN_RESOURCE:
			return _gain_resource(request, game_ctx)
	return {"ok": false, "error": "unsupported_op"}


static func _draw_cards(request: EffectRequest, game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.draw_investigator == null:
		return {"ok": false, "error": "draw_unavailable"}
	var amount := maxi(request.amount, 1)
	return game_ctx.draw_investigator.draw_cards(
		game_ctx,
		request.controller_id,
		amount,
		[&"effect_draw"]
	)


static func _gain_resource(request: EffectRequest, game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.resource_gain == null:
		return {"ok": false, "error": "gain_unavailable"}
	var amount := maxi(request.amount, 1)
	var gained := game_ctx.resource_gain.gain(
		game_ctx,
		request.controller_id,
		amount,
		[&"effect_gain"]
	)
	return {"ok": true, "amount": gained}
