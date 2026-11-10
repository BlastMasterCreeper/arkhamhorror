class_name ReplacementFlowHandlers
extends RefCounted

## `seq.replace.instead` RESOLVE · 参数装配 + ERG dispatch（无中间 Handler）。


static func resolve_instead(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	if game_ctx == null or game_ctx.effects == null:
		return {"ok": false, "error": "missing_effects"}
	var target := ReplacementTarget.from_params(params.get("target", {}) as Dictionary)
	var replacement := request_from_params(params.get("replacement", {}) as Dictionary)
	var source_ability_id: StringName = params.get("source_ability_id", &"") as StringName
	return game_ctx.effects.replace_instead_dispatch(target, replacement, source_ability_id)


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
