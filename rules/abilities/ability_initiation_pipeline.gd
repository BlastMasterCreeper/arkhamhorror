class_name AbilityInitiationPipeline
extends RefCounted

var _state: GameStateStore
var _events: EventRecordLog
var _effects: EffectResolutionGraph
var _composition: CompositionExecutor
var _legality: InitiationLegalityChecker = InitiationLegalityChecker.new()
var _cost: InitiationCostPipeline
var _aoo: AttackOfOpportunityResolver
var _game_ctx: GameContext


func _init(
	state: GameStateStore,
	events: EventRecordLog,
	effects: EffectResolutionGraph,
	composition: CompositionExecutor = null
) -> void:
	_state = state
	_events = events
	_effects = effects
	_composition = composition
	_cost = InitiationCostPipeline.new(state)


func bind_game_context(ctx: GameContext) -> void:
	_game_ctx = ctx
	if ctx == null:
		return
	_cost = InitiationCostPipeline.new(ctx.state, ctx.modifiers)
	if ctx.combat:
		_aoo = AttackOfOpportunityResolver.new(ctx.state, ctx.combat)


func can_initiate(intent: InitiationIntent, ctx: GameContext) -> bool:
	if intent == null:
		return false
	if intent.kind == InitiationIntent.Kind.ABILITY and intent.composition == null:
		return false
	if _restriction_block_reason(intent, ctx) != &"":
		return false
	if intent.kind == InitiationIntent.Kind.PLAY_CARD and not _play_card_pre_valid(intent, ctx):
		return false
	_cost.apply_modifiers(intent, ctx)
	if not _cost.can_pay(intent):
		return false
	return _passes_dry_run(intent, ctx)


func initiate(intent: InitiationIntent, ctx: GameContext) -> Dictionary:
	if intent == null:
		return {"ok": false, "error": "invalid_intent"}
	if intent.kind == InitiationIntent.Kind.ABILITY and intent.composition == null:
		return {"ok": false, "error": "invalid_intent"}

	var hash := _state.compute_state_hash()
	var payload := _intent_payload(intent)
	_events.append_initiation(AhcEnums.InitiationStep.INIT_PRE_RESTRICTIONS, hash, payload)

	var restriction := _restriction_block_reason(intent, ctx)
	if restriction != &"":
		return {"ok": false, "error": RestrictionEvaluator.api_error(restriction)}

	if intent.kind == InitiationIntent.Kind.PLAY_CARD:
		var play_err := _play_card_pre_error(intent, ctx)
		if play_err != &"":
			return {"ok": false, "error": String(play_err)}

	_cost.apply_modifiers(intent, ctx)
	if not _cost.can_pay(intent):
		return {"ok": false, "error": "cannot_pay"}
	if not _passes_dry_run(intent, ctx):
		return {"ok": false, "error": "illegal"}

	_events.append_initiation(AhcEnums.InitiationStep.INIT_1_APPLY_MODIFIERS, hash, payload)
	_events.append_initiation(AhcEnums.InitiationStep.INIT_2_PAY_COSTS, hash, payload)
	if not _cost.pay(intent):
		return {"ok": false, "error": "cannot_pay"}

	## 行动开始：卡面「does not provoke AOO」→ Register 限制类 SKIP_AOO（INIT_2B 读取分支）。
	_mount_skip_aoo_buff(intent, ctx)

	_events.append_initiation(AhcEnums.InitiationStep.INIT_2B_AOO, hash, payload)
	var aoo_attacks := 0
	if intent.provokes_aoo and _aoo != null:
		var types: Array = intent.action_types
		if types.is_empty():
			types = [intent.aoo_action_type]
		var regs: RegistrationStore = ctx.registrations if ctx != null else null
		var aoo_result := _aoo.resolve_for_types(intent.controller_id, types, regs)
		aoo_attacks = int(aoo_result.get("attacks", 0))

	if not _passes_dry_run(intent, ctx):
		_cost.refund(intent)
		return {"ok": false, "error": "illegal"}

	_events.append_initiation(AhcEnums.InitiationStep.INIT_3_COMMENCE, hash, payload)
	if intent.kind == InitiationIntent.Kind.PLAY_CARD:
		if not _commence_play(intent, ctx):
			_cost.refund(intent)
			return {"ok": false, "error": "commence_failed"}

	_events.append_initiation(AhcEnums.InitiationStep.INIT_4_RESOLVE, hash, payload)
	if intent.composition != null:
		_resolve_composition_on_stack(intent, ctx)

	if intent.kind == InitiationIntent.Kind.PLAY_CARD:
		_finalize_play_card(intent, ctx)

	var result := {"ok": true}
	if intent.kind == InitiationIntent.Kind.PLAY_CARD:
		result["card_id"] = intent.card_id
	if intent.provokes_aoo:
		result["aoo_attacks"] = aoo_attacks
	return result


## 卡面 no_provoke_aoo：挂限制类 Buff（非 Listener / 非 Cancel）。
## 仅当类型本身会借机时挂（Resign 等类型豁免无需挂）。
func _mount_skip_aoo_buff(intent: InitiationIntent, ctx: GameContext) -> void:
	if intent == null or ctx == null or ctx.registrations == null:
		return
	if not intent.provokes_aoo:
		return
	if not _composition_declares_skip_aoo(intent.composition):
		return
	if ctx.registrations.has_skip_aoo(intent.controller_id):
		return
	ctx.registrations.register(
		RegistrationTemplate.skip_aoo_for_action(intent.controller_id)
	)


static func _composition_declares_skip_aoo(node: CompositionNode) -> bool:
	if node == null:
		return false
	if node.kind == AhcEnums.CompositionNodeKind.ATOM and node.atom_name == &"no_provoke_aoo":
		return true
	if node.kind == AhcEnums.CompositionNodeKind.REGISTER and node.register_template != null:
		for buff in node.register_template.buffs:
			if buff.type != AhcEnums.BuffType.RESTRICTION or buff.restriction == null:
				continue
			if buff.restriction.kind == AhcEnums.RestrictionKind.SKIP_AOO:
				return true
	for child in node.children:
		if _composition_declares_skip_aoo(child):
			return true
	return false


## 禁止真空：优先 nest `seq.ability.resolve`；Catalog 缺失时才直 execute。
func _resolve_composition_on_stack(intent: InitiationIntent, ctx: GameContext) -> void:
	if intent == null or intent.composition == null:
		return
	if (
		ctx != null
		and ctx.sequence_catalog != null
		and ctx.sequence_catalog.has_flow(&"seq.ability.resolve")
	):
		ctx.sequence_catalog.nest(
			ctx,
			&"seq.ability.resolve",
			{
				"composition": intent.composition,
				"controller_id": intent.controller_id,
				"ability_id": intent.ability_id,
				"source_id": intent.source_id,
			}
		)
		return
	if _composition != null:
		_composition.execute(intent.composition)


func _intent_payload(intent: InitiationIntent) -> Dictionary:
	var payload := {
		"controller": intent.controller_id,
		"kind": intent.kind,
	}
	if intent.card_id != &"":
		payload["card"] = intent.card_id
	if intent.modified_resource_cost > 0 or intent.resource_cost > 0:
		payload["resource_cost"] = intent.modified_resource_cost
	if intent.ability_id != &"":
		payload["ability"] = intent.ability_id
	if intent.source_id != &"":
		payload["source"] = intent.source_id
	if intent.modified_action_cost > 0 or intent.action_cost > 0:
		payload["action_cost"] = intent.modified_action_cost
	return payload


func _passes_dry_run(intent: InitiationIntent, ctx: GameContext) -> bool:
	if intent.composition == null:
		return true
	return _legality.dry_run(intent, ctx).has_any_created


func _restriction_block_reason(intent: InitiationIntent, ctx: GameContext) -> StringName:
	if intent == null or ctx == null or ctx.registrations == null:
		return &""
	match intent.kind:
		InitiationIntent.Kind.PLAY_CARD:
			return RestrictionEvaluator.block_reason(
				RestrictionEvaluator.Intent.PLAY,
				intent.controller_id,
				ctx.registrations
			)
		_:
			return RestrictionEvaluator.block_reason(
				RestrictionEvaluator.Intent.TRIGGER,
				intent.controller_id,
				ctx.registrations
			)


func _play_card_pre_valid(intent: InitiationIntent, ctx: GameContext) -> bool:
	return _play_card_pre_error(intent, ctx) == &""


func _play_card_pre_error(intent: InitiationIntent, ctx: GameContext) -> StringName:
	if ctx == null or ctx.state == null:
		return &"no_context"
	var inv := ctx.state.registry.get_investigator(intent.controller_id)
	if inv == null:
		return &"unknown_investigator"
	var card := ctx.state.registry.get_card(intent.card_id)
	if card == null:
		return &"unknown_card"
	if card.zone != AhcEnums.Zone.HAND or not inv.hand.has(intent.card_id):
		return &"not_in_hand"
	return &""


func _commence_play(intent: InitiationIntent, ctx: GameContext) -> bool:
	var card := ctx.state.registry.get_card(intent.card_id)
	var inv := ctx.state.registry.get_investigator(intent.controller_id)
	if card == null or inv == null:
		return false
	var card_type := CardRegistry.card_type(card.id.definition_id)
	if card_type == &"event":
		return ctx.mutator.enter_limbo(intent.card_id, intent.controller_id)
	inv.hand.erase(intent.card_id)
	inv.play_area.append(intent.card_id)
	card.zone = AhcEnums.Zone.PLAY_AREA
	if ctx.triggered_abilities != null:
		ctx.triggered_abilities.install_card(intent.controller_id, intent.card_id)
	return true


func _finalize_play_card(intent: InitiationIntent, ctx: GameContext) -> void:
	var card := ctx.state.registry.get_card(intent.card_id)
	if card == null or card.zone != AhcEnums.Zone.LIMBO:
		return
	ctx.mutator.finalize_limbo_discard(intent.card_id, intent.controller_id)
