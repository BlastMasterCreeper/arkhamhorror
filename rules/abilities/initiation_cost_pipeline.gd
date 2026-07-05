class_name InitiationCostPipeline
extends RefCounted

var _state: GameStateStore
var _modifiers: ModifierEngine


func _init(state: GameStateStore, modifiers: ModifierEngine = null) -> void:
	_state = state
	_modifiers = modifiers


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
	return true


func pay(intent: InitiationIntent) -> bool:
	if not can_pay(intent):
		return false
	var inv := _state.registry.get_investigator(intent.controller_id)
	inv.resource_pool -= intent.modified_resource_cost
	inv.actions_remaining -= intent.modified_action_cost
	return true


func refund(intent: InitiationIntent) -> void:
	var inv := _state.registry.get_investigator(intent.controller_id)
	if inv == null:
		return
	inv.resource_pool += intent.modified_resource_cost
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
