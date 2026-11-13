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
	var resolver := BasicActionFlowHandlers.new(game_ctx.state, game_ctx.skill_tests)
	match action_type:
		AhcEnums.ActionType.MOVE:
			## 行动外壳 → nest 狭义移动内核（与 draw/gain/engage 对称）；禁真空旁路。
			if game_ctx.sequence_catalog == null or not game_ctx.sequence_catalog.has_flow(&"seq.effect.move"):
				return {"ok": false, "error": "move_unavailable"}
			var dest_id: StringName = extra.get("destination_id", &"")
			return game_ctx.sequence_catalog.nest(
				game_ctx,
				&"seq.effect.move",
				{
					"subject": MoveFlow.SUBJECT_INVESTIGATOR,
					"investigator_id": inv_id,
					"destination_id": dest_id,
					"move_kind": MoveFlow.KIND_MOVE,
					"auto_engage_after": true,
				}
			)
		AhcEnums.ActionType.INVESTIGATE:
			return resolver.investigate(game_ctx, inv_id, extra)
		AhcEnums.ActionType.FIGHT:
			return resolver.fight(game_ctx, inv_id, extra)
		AhcEnums.ActionType.ENGAGE:
			## 基础行动 = 调查员自带能力 → nest 效果交战（mode=effect）；溯源靠行动外壳栈帧。
			if game_ctx.sequence_catalog == null or not game_ctx.sequence_catalog.has_flow(&"seq.engage"):
				return {"ok": false, "error": "engage_unavailable"}
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
		AhcEnums.ActionType.EVADE:
			return resolver.evade(game_ctx, inv_id, extra)
	return {"ok": false, "error": "unsupported_action"}


static func _merge_tags(base: Array[StringName], source_tags: Array) -> Array[StringName]:
	var tags := base.duplicate()
	for tag in source_tags:
		tags.append(tag as StringName)
	return tags
