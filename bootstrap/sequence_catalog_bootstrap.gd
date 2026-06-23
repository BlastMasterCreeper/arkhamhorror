class_name SequenceCatalogBootstrap
extends RefCounted


static func register_builtin(
	catalog: SequenceCatalog,
	mutator: StateMutator,
	card_abilities: CardAbilityService
) -> void:
	catalog.register_nest_batch(
		&"seq.enter_hand",
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			return _nest_enter_hand_revelations(game_ctx, params, card_abilities)
	)
	catalog.register_run(
		&"seq.draw.empty_piles_defeated",
		func(params: Dictionary) -> TriggeringCondition:
			var inv_id: StringName = params.get("inv_id", &"")
			return TriggeringCondition.draw_empty_piles_defeated(inv_id),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			var inv_id: StringName = params.get("inv_id", &"")
			return DrawSubflowHandlers.resolve_empty_piles_defeated(game_ctx, inv_id)
	)
	catalog.register_run(
		&"seq.draw.collect_one",
		func(params: Dictionary) -> TriggeringCondition:
			var inv_id: StringName = params.get("inv_id", &"")
			return TriggeringCondition.draw_collect_one(inv_id),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			var inv_id: StringName = params.get("inv_id", &"")
			return DrawSubflowHandlers.resolve_collect_one(game_ctx, inv_id, catalog)
	)
	catalog.register_run(
		&"seq.draw.investigator",
		func(params: Dictionary) -> TriggeringCondition:
			var inv_id: StringName = params.get("inv_id", &"")
			var amount: int = int(params.get("amount", 1))
			var source_tags: Array = params.get("source_tags", [])
			var tags: Array[StringName] = [&"draw_investigator"]
			for tag in source_tags:
				tags.append(tag as StringName)
			return TriggeringCondition.draw_investigator(inv_id, amount, tags),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			return _resolve_draw_investigator(game_ctx, params, mutator, catalog)
	)
	catalog.register_run(
		&"seq.gain_resource",
		func(params: Dictionary) -> TriggeringCondition:
			var controller_id: StringName = params.get("controller_id", &"")
			var source_tags: Array = params.get("source_tags", [])
			var tags: Array[StringName] = []
			for tag in source_tags:
				tags.append(tag as StringName)
			return TriggeringCondition.gain_resource(controller_id, tags),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			return _resolve_gain_resource(game_ctx, params, mutator)
	)


static func _resolve_draw_investigator(
	game_ctx: GameContext,
	params: Dictionary,
	mutator: StateMutator,
	catalog: SequenceCatalog
) -> Dictionary:
	var inv_id: StringName = params.get("inv_id", &"")
	var amount: int = int(params.get("amount", 1))
	var source_tags: Array = params.get("source_tags", [])
	var result := DrawInvestigatorFlow.run(game_ctx, inv_id, amount)
	var drawn: Array = result.get("drawn", [])
	if game_ctx != null and game_ctx.memory != null:
		game_ctx.memory.set_referent(inv_id, &"last_draw_count", drawn.size())
	var nest := catalog.nest_batch(
		game_ctx,
		&"seq.enter_hand",
		{
			"controller_id": inv_id,
			"card_ids": drawn,
			"source_tags": source_tags,
			"provenance_flow_id": &"seq.draw.investigator",
		}
	)
	result["revelations"] = nest.get("revelations", [])
	return result


static func _nest_enter_hand_revelations(
	game_ctx: GameContext,
	params: Dictionary,
	abilities: CardAbilityService
) -> Dictionary:
	var controller_id: StringName = params.get("controller_id", &"")
	var card_ids: Array = params.get("card_ids", [])
	var source_tags: Array = params.get("source_tags", [])
	var provenance_flow_id: StringName = params.get("provenance_flow_id", &"seq.enter_hand")
	var tags: Array[StringName] = []
	for tag in source_tags:
		tags.append(tag as StringName)
	var policy := EnterHandTimingPolicy.new()
	if game_ctx != null and game_ctx.config != null:
		policy = game_ctx.config.enter_hand_timing
	var ordered_cards := policy.order_cards_for_revelation(
		game_ctx, controller_id, card_ids, params
	)
	var resolved: Array[StringName] = []
	if game_ctx == null or game_ctx.sequences == null:
		for card_id in ordered_cards:
			var cid := card_id as StringName
			if abilities.resolve_revelations(game_ctx, controller_id, cid, provenance_flow_id):
				resolved.append(cid)
		return {"revelations": resolved}
	for card_id in ordered_cards:
		var cid := card_id as StringName
		if not abilities.has_revelation(game_ctx, cid):
			continue
		var trigger := TriggeringCondition.enter_hand(controller_id, cid, tags)
		game_ctx.sequences.nest(
			trigger,
			func() -> void:
				abilities.resolve_revelations(game_ctx, controller_id, cid, provenance_flow_id)
		)
		resolved.append(cid)
	return {"revelations": resolved}


static func _resolve_gain_resource(
	game_ctx: GameContext,
	params: Dictionary,
	mutator: StateMutator
) -> Dictionary:
	var controller_id: StringName = params.get("controller_id", &"")
	var base_amount: int = int(params.get("base_amount", 0))
	var amount := base_amount
	if game_ctx != null and game_ctx.modifiers != null and game_ctx.sequences != null:
		var app_ctx := game_ctx.sequences.build_application_context(AhcEnums.SequencePhase.RESOLVE)
		var q := ModifierQuery.new()
		q.controller_id = controller_id
		q.stat = AhcEnums.StatRef.RESOURCE_GAIN_AMOUNT
		amount = game_ctx.modifiers.compute(base_amount, q, app_ctx)
	mutator.adjust_marker(
		MarkerSlot.investigator(controller_id, AhcEnums.MarkerKind.RESOURCE),
		amount
	)
	if game_ctx != null and game_ctx.memory != null:
		game_ctx.memory.set_referent(controller_id, &"last_gain_amount", amount)
	return {"amount": amount}
