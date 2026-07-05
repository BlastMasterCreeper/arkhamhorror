class_name SequenceCatalogBootstrap
extends RefCounted


static func register_builtin(
	catalog: SequenceCatalog,
	mutator: StateMutator,
	card_abilities: CardAbilityService
) -> void:
	_register_flows(catalog, mutator, card_abilities)


static func _register_flows(
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
		&"seq.draw.encounter",
		func(params: Dictionary) -> TriggeringCondition:
			var drawer_id: StringName = params.get("drawer_id", &"")
			return TriggeringCondition.draw_encounter(drawer_id),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			var drawer_id: StringName = params.get("drawer_id", &"")
			return DrawEncounterFlow.run(game_ctx, drawer_id)
	)
	catalog.register_run(
		&"seq.draw.encounter.resolve_bound",
		func(params: Dictionary) -> TriggeringCondition:
			var drawer_id: StringName = params.get("drawer_id", &"")
			var card_id: StringName = params.get("card_id", &"")
			return TriggeringCondition.draw_encounter_resolve_bound(drawer_id, card_id),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			var drawer_id: StringName = params.get("drawer_id", &"")
			var card_id: StringName = params.get("card_id", &"")
			return DrawEncounterFlow.resolve_bound(game_ctx, drawer_id, card_id)
	)
	catalog.register_run(
		&"seq.encounter.revelation",
		func(params: Dictionary) -> TriggeringCondition:
			var drawer_id: StringName = params.get("drawer_id", &"")
			var card_id: StringName = params.get("card_id", &"")
			return TriggeringCondition.encounter_revelation(drawer_id, card_id),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			return _resolve_encounter_revelation(game_ctx, params, card_abilities)
	)
	catalog.register_run(
		&"seq.encounter.spawn",
		func(params: Dictionary) -> TriggeringCondition:
			var drawer_id: StringName = params.get("drawer_id", &"")
			var card_id: StringName = params.get("card_id", &"")
			var from_hand: bool = bool(params.get("from_hand", false))
			return TriggeringCondition.encounter_spawn(drawer_id, card_id, &"after_encounter_spawn", from_hand),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			return _resolve_encounter_spawn(game_ctx, params)
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
	_register_interrupt_flows(catalog)
	_register_replace_flows(catalog)
	_register_action_flows(catalog)


static func _register_interrupt_flows(catalog: SequenceCatalog) -> void:
	catalog.register_run(
		&"seq.interrupt.cancel",
		func(params: Dictionary) -> TriggeringCondition:
			var controller_id: StringName = params.get("controller_id", &"")
			return TriggeringCondition.custom(
				&"interrupt_cancel", controller_id, [&"interrupt", &"cancel"]
			),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			return InterruptFlowHandlers.resolve_cancel(game_ctx, params)
	)
	catalog.register_run(
		&"seq.interrupt.ignore",
		func(params: Dictionary) -> TriggeringCondition:
			var controller_id: StringName = params.get("controller_id", &"")
			return TriggeringCondition.custom(
				&"interrupt_ignore", controller_id, [&"interrupt", &"ignore"]
			),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			return InterruptFlowHandlers.resolve_ignore(game_ctx, params)
	)


static func _register_replace_flows(catalog: SequenceCatalog) -> void:
	catalog.register_run(
		&"seq.replace.instead",
		func(params: Dictionary) -> TriggeringCondition:
			var controller_id: StringName = params.get("controller_id", &"")
			return TriggeringCondition.custom(
				&"replace_instead", controller_id, [&"replace", &"instead"]
			),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			return ReplacementFlowHandlers.resolve_instead(game_ctx, params)
	)


static func _register_action_flows(catalog: SequenceCatalog) -> void:
	catalog.register_run(
		&"seq.action.draw",
		func(params: Dictionary) -> TriggeringCondition:
			var inv_id: StringName = params.get("inv_id", &"")
			var tags := ActionFlowHandlers._merge_tags([&"draw_action"], params.get("source_tags", []))
			return TriggeringCondition.action_committed(
				&"draw", inv_id, tags, &"after_action_draw", params
			),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			return ActionFlowHandlers.resolve_action_draw(game_ctx, catalog, params)
	)
	catalog.register_run(
		&"seq.action.gain_resource",
		func(params: Dictionary) -> TriggeringCondition:
			var controller_id: StringName = params.get("controller_id", &"")
			var tags := ActionFlowHandlers._merge_tags([&"resource_action"], params.get("source_tags", []))
			return TriggeringCondition.action_committed(
				&"gain_resource", controller_id, tags, &"after_action_gain_resource", params
			),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			return ActionFlowHandlers.resolve_action_gain_resource(game_ctx, catalog, params)
	)
	_register_basic_action_flow(catalog, &"seq.action.move", &"move", &"after_action_move", AhcEnums.ActionType.MOVE)
	_register_basic_action_flow(
		catalog, &"seq.action.investigate", &"investigate", &"after_action_investigate", AhcEnums.ActionType.INVESTIGATE
	)
	_register_basic_action_flow(catalog, &"seq.action.fight", &"fight", &"after_fight", AhcEnums.ActionType.FIGHT)
	_register_basic_action_flow(catalog, &"seq.action.engage", &"engage", &"after_action_engage", AhcEnums.ActionType.ENGAGE)
	_register_basic_action_flow(catalog, &"seq.action.evade", &"evade", &"after_action_evade", AhcEnums.ActionType.EVADE)


static func _register_basic_action_flow(
	catalog: SequenceCatalog,
	flow_id: StringName,
	action_kind: StringName,
	after_timing: StringName,
	action_type: AhcEnums.ActionType
) -> void:
	catalog.register_run(
		flow_id,
		func(params: Dictionary) -> TriggeringCondition:
			var inv_id: StringName = params.get("inv_id", &"")
			return TriggeringCondition.action_committed(
				action_kind, inv_id, [action_kind], after_timing, params
			),
		func(game_ctx: GameContext, params: Dictionary) -> Dictionary:
			return ActionFlowHandlers.resolve_basic_action(game_ctx, action_type, params)
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


static func _resolve_encounter_revelation(
	game_ctx: GameContext,
	params: Dictionary,
	abilities: CardAbilityService
) -> Dictionary:
	var drawer_id: StringName = params.get("drawer_id", &"")
	var card_id: StringName = params.get("card_id", &"")
	if abilities != null and abilities.has_revelation(game_ctx, card_id):
		var ok := abilities.resolve_revelations(
			game_ctx, drawer_id, card_id, &"seq.encounter.revelation", true
		)
		return {"resolved": ok}
	var card := game_ctx.state.registry.get_card(card_id) if game_ctx != null else null
	if card == null:
		return {"resolved": false}
	if CardRegistry.is_hidden(card.id.definition_id) and game_ctx.mutator != null:
		var ok_hidden := game_ctx.mutator.commit_hidden_enter_hand(card_id, drawer_id)
		if ok_hidden:
			EncounterPrivacy.register_leave_hand_restriction(game_ctx, card_id, drawer_id)
			game_ctx.mutator.finalize_limbo_discard(card_id, drawer_id)
		return {"resolved": ok_hidden}
	return {"resolved": false}


static func _resolve_encounter_spawn(
	game_ctx: GameContext,
	params: Dictionary
) -> Dictionary:
	var drawer_id: StringName = params.get("drawer_id", &"")
	var card_id: StringName = params.get("card_id", &"")
	var from_hand: bool = bool(params.get("from_hand", false))
	if game_ctx == null or game_ctx.enemy == null or card_id == &"":
		return {"spawned": false, "discarded": false}
	if from_hand:
		if game_ctx.mutator == null:
			return {"spawned": false, "discarded": false, "error": &"no_mutator"}
		EncounterPrivacy.unregister_for_card(game_ctx, card_id)
		if not game_ctx.mutator.prepare_hand_card_for_encounter_spawn(card_id, drawer_id):
			return {"spawned": false, "discarded": false, "error": &"invalid_hand_spawn"}
	var result := game_ctx.enemy.spawn_from_encounter_draw(game_ctx, card_id, drawer_id)
	if result.get("discarded", false):
		return {"spawned": false, "discarded": true, "card_id": card_id}
	if result.get("ok", false) and result.has("enemy_id"):
		return {
			"spawned": true,
			"discarded": false,
			"enemy_id": result.get("enemy_id", card_id),
		}
	return {"spawned": false, "discarded": false, "error": result.get("error", &"")}


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
	if game_ctx == null:
		return {"revelations": resolved}
	for card_id in ordered_cards:
		var cid := card_id as StringName
		if abilities.has_revelation(game_ctx, cid):
			if game_ctx.sequences == null:
				abilities.resolve_revelations(
					game_ctx, controller_id, cid, provenance_flow_id, true
				)
				resolved.append(cid)
			else:
				var trigger := TriggeringCondition.enter_hand(controller_id, cid, tags)
				game_ctx.sequences.nest(
					trigger,
					func() -> void:
						abilities.resolve_revelations(
							game_ctx, controller_id, cid, provenance_flow_id, true
						)
				)
				resolved.append(cid)
		_finalize_enter_hand_limbo(game_ctx, controller_id, cid)
	return {"revelations": resolved}


static func _finalize_enter_hand_limbo(
	game_ctx: GameContext,
	controller_id: StringName,
	card_id: StringName
) -> void:
	if game_ctx == null or game_ctx.mutator == null:
		return
	game_ctx.mutator.finalize_limbo_discard(card_id, controller_id)


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
