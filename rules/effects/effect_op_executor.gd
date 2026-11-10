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
	if game_ctx == null or game_ctx.sequence_catalog == null:
		return {"ok": false, "error": "draw_unavailable"}
	var amount := maxi(request.amount, 1)
	return game_ctx.run_seq(
		&"seq.draw.investigator",
		{
			"inv_id": request.controller_id,
			"amount": amount,
			"source_tags": [&"effect_draw"],
		}
	)


static func _gain_resource(request: EffectRequest, game_ctx: GameContext) -> Dictionary:
	if game_ctx == null or game_ctx.sequence_catalog == null:
		return {"ok": false, "error": "gain_unavailable"}
	var amount := maxi(request.amount, 1)
	var result := game_ctx.run_seq(
		&"seq.effect.gain_resource",
		{
			"controller_id": request.controller_id,
			"base_amount": amount,
			"source_tags": [&"effect_gain"],
		}
	)
	return {"ok": true, "amount": int(result.get("amount", amount))}
