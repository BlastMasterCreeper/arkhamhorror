class_name InitiationCostPipeline
extends RefCounted

var _state: GameStateStore
var _modifiers: ModifierEngine
var _mutator: StateMutator = null


func _init(
	state: GameStateStore,
	modifiers: ModifierEngine = null,
	mutator: StateMutator = null
) -> void:
	_state = state
	_modifiers = modifiers
	_mutator = mutator


func bind_mutator(mutator: StateMutator) -> void:
	_mutator = mutator


func apply_modifiers(intent: InitiationIntent, ctx: GameContext) -> void:
	if _modifiers == null or intent == null:
		intent.modified_resource_cost = intent.resource_cost
		intent.modified_action_cost = intent.action_cost
		return
	var app_ctx := _initiation_app_ctx(intent, ctx)
	var res_q := ModifierQuery.new()
	res_q.controller_id = intent.controller_id
	res_q.stat = AhcEnums.StatRef.INITIATION_RESOURCE_COST
	intent.modified_resource_cost = _modifiers.compute(intent.resource_cost, res_q, app_ctx)
	var act_q := ModifierQuery.new()
	act_q.controller_id = intent.controller_id
	act_q.stat = AhcEnums.StatRef.INITIATION_ACTION_COST
	intent.modified_action_cost = _modifiers.compute(intent.action_cost, act_q, app_ctx)


func can_pay(intent: InitiationIntent) -> bool:
	var inv := _state.registry.get_investigator(intent.controller_id)
	if inv == null:
		return false
	if inv.resource_pool < intent.modified_resource_cost:
		return false
	if inv.actions_remaining < intent.modified_action_cost:
		return false
	## Seal 关键词：额外费用门槛（袋内须有指定标记）；支付在进场序列。
	if not _can_pay_seal_keyword(intent):
		return false
	return true


func pay(intent: InitiationIntent) -> bool:
	if not can_pay(intent):
		return false
	var inv := _state.registry.get_investigator(intent.controller_id)
	var res_cost := intent.modified_resource_cost
	if res_cost > 0:
		if _mutator == null:
			return false
		if not _mutator.transfer_marker(
			AhcEnums.MarkerKind.RESOURCE,
			res_cost,
			MarkerSlot.investigator(intent.controller_id, AhcEnums.MarkerKind.RESOURCE),
			MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE)
		):
			return false
	inv.actions_remaining -= intent.modified_action_cost
	## Seal 关键词不在 L6 扣袋：进场后 `SealFlow.pay_keyword_on_enter`。
	return true


func _can_pay_seal_keyword(intent: InitiationIntent) -> bool:
	if intent == null or intent.kind != InitiationIntent.Kind.PLAY_CARD:
		return true
	if intent.card_id == &"" or _state == null:
		return true
	var card := _state.registry.get_card(intent.card_id)
	if card == null:
		return true
	var spec: SealSpec = CardRegistry.seal_spec(card.id.definition_id)
	if spec == null or not spec.as_play_cost:
		return true
	return SealFlow.can_satisfy(_state.chaos_bag, spec)


func refund(intent: InitiationIntent) -> void:
	var inv := _state.registry.get_investigator(intent.controller_id)
	if inv == null:
		return
	var res_cost := intent.modified_resource_cost
	if res_cost > 0 and _mutator != null:
		_mutator.transfer_marker(
			AhcEnums.MarkerKind.RESOURCE,
			res_cost,
			MarkerSlot.supply(AhcEnums.MarkerKind.RESOURCE),
			MarkerSlot.investigator(intent.controller_id, AhcEnums.MarkerKind.RESOURCE)
		)
	elif res_cost > 0:
		inv.resource_pool += res_cost
	inv.actions_remaining += intent.modified_action_cost


static func _initiation_app_ctx(intent: InitiationIntent, ctx: GameContext) -> ApplicationContext:
	var app_ctx := ApplicationContext.new()
	app_ctx.controller_id = intent.controller_id
	app_ctx.tags = [&"initiation"]
	match intent.kind:
		InitiationIntent.Kind.PLAY_CARD:
			app_ctx.tags.append(&"play_card")
		InitiationIntent.Kind.ABILITY:
			app_ctx.tags.append(&"ability")
	if ctx != null and ctx.framework:
		app_ctx.framework_step = ctx.framework.current_step
	return app_ctx
