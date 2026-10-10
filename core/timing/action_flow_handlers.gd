class_name ActionFlowHandlers
extends RefCounted


static func resolve_action_draw(
	game_ctx: GameContext,
	catalog: SequenceCatalog,
	params: Dictionary
) -> Dictionary:
	var inv_id: StringName = params.get("inv_id", &"")
	var amount: int = int(params.get("amount", 1))
	var tags := _merge_tags([&"draw_action"], params.get("source_tags", []))
	return catalog.nest(
		game_ctx,
		&"seq.draw.investigator",
		{
			"inv_id": inv_id,
			"amount": amount,
			"source_tags": tags,
		}
	)


static func resolve_action_gain_resource(
	game_ctx: GameContext,
	catalog: SequenceCatalog,
	params: Dictionary
) -> Dictionary:
	var controller_id: StringName = params.get("controller_id", &"")
	var base_amount: int = int(params.get("base_amount", 1))
	var tags := _merge_tags([&"resource_action"], params.get("source_tags", []))
	return catalog.nest(
		game_ctx,
		&"seq.effect.gain_resource",
		{
			"controller_id": controller_id,
			"base_amount": base_amount,
			"source_tags": tags,
		}
	)


static func resolve_basic_action(
	game_ctx: GameContext,
	action_type: AhcEnums.ActionType,
	params: Dictionary
) -> Dictionary:
	if game_ctx == null or game_ctx.skill_tests == null:
		return {"ok": false, "error": "basic_actions_unavailable"}
	var inv_id: StringName = params.get("inv_id", &"")
	var extra: Dictionary = params.get("extra", {})
	var resolver := BasicActionResolver.new(game_ctx.state, game_ctx.skill_tests)
	match action_type:
		AhcEnums.ActionType.MOVE:
			var move_result := resolver.move(game_ctx, inv_id, extra)
			if bool(move_result.get("ok", false)):
				var dest: StringName = move_result.get("destination_id", &"") as StringName
				if dest != &"":
					EngageFlow.nest_after_area_change(game_ctx, dest)
			return move_result
		AhcEnums.ActionType.INVESTIGATE:
			return resolver.investigate(game_ctx, inv_id, extra)
		AhcEnums.ActionType.FIGHT:
			return resolver.fight(game_ctx, inv_id, extra)
		AhcEnums.ActionType.ENGAGE:
			## 基础行动 = 调查员自带能力 → nest 效果交战（mode=effect）；溯源靠行动外壳栈帧。
			if game_ctx.sequence_catalog != null and game_ctx.sequence_catalog.has_flow(&"seq.engage"):
				var enemy_id: StringName = extra.get("enemy_id", &"")
				var enemy := game_ctx.state.registry.get_enemy(enemy_id)
				if enemy != null and enemy.massive:
					return {"ok": false, "error": "massive"}
				return game_ctx.sequence_catalog.nest(
					game_ctx,
					&"seq.engage",
					{
						"mode": EngageFlow.MODE_EFFECT,
						"placement": EngageFlow.PLACEMENT_ENTER_THREAT,
						"require_same_location": true,
						"enemy_id": enemy_id,
						"investigator_id": inv_id,
					}
				)
			return resolver.engage(game_ctx, inv_id, extra)
		AhcEnums.ActionType.EVADE:
			return resolver.evade(game_ctx, inv_id, extra)
	return {"ok": false, "error": "unsupported_action"}


static func _merge_tags(base: Array[StringName], source_tags: Array) -> Array[StringName]:
	var tags := base.duplicate()
	for tag in source_tags:
		tags.append(tag as StringName)
	return tags
