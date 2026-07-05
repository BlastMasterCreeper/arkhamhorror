class_name ReplacementHandler
extends RefCounted


static func request_from_params(params: Dictionary) -> EffectRequest:
	if params.is_empty():
		return null
	var op: int = int(params.get("op", AhcEnums.EffectOp.CUSTOM))
	match op:
		AhcEnums.EffectOp.GAIN_RESOURCE:
			return EffectRequest.gain_resource(
				params.get("controller_id", &"") as StringName,
				int(params.get("amount", 1))
			)
		AhcEnums.EffectOp.DRAW_CARDS:
			return EffectRequest.draw_cards(
				params.get("controller_id", &"") as StringName,
				int(params.get("amount", 1))
			)
		_:
			return null


static func apply_instead(
	game_ctx: GameContext,
	target: ReplacementTarget,
	replacement: EffectRequest,
	source_ability_id: StringName = &""
) -> Dictionary:
	if game_ctx == null or game_ctx.effects == null:
		return {"ok": false, "error": "missing_effects"}
	return game_ctx.effects.replace_instead_dispatch(target, replacement, source_ability_id)
