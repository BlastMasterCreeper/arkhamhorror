class_name ReplacementFlowHandlers
extends RefCounted


static func resolve_instead(game_ctx: GameContext, params: Dictionary) -> Dictionary:
	var target := ReplacementTarget.from_params(params.get("target", {}) as Dictionary)
	var replacement := ReplacementHandler.request_from_params(
		params.get("replacement", {}) as Dictionary
	)
	var source_ability_id: StringName = params.get("source_ability_id", &"") as StringName
	return ReplacementHandler.apply_instead(game_ctx, target, replacement, source_ability_id)
