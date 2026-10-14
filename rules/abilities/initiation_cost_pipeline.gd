class_name InitiationCostPipeline
extends RefCounted

var _state: GameStateStore
var _modifiers: ModifierEngine
var _mutator: StateMutator


func _init(
	state: GameStateStore,
	modifiers: ModifierEngine = null,
	mutator: StateMutator = null
) -> void:
	_state = state
	_modifiers = modifiers
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
	for raw in intent.spend_token_costs:
		if not raw is Dictionary:
			return false
		var cost: Dictionary = raw
		var card_id := _resolve_spend_card_id(intent, cost)
		var kind := StringName(str(cost.get("kind", cost.get("token", "ammo"))))
		var amount := maxi(int(cost.get("amount", 1)), 1)
		if card_id == &"" or kind == &"":
			return false
		var card := _state.registry.get_card(card_id)
		if card == null:
			return false
		if int(card.tokens.uses.get(kind, 0)) < amount:
			return false
	return true


func pay(intent: InitiationIntent) -> bool:
	if not can_pay(intent):
		return false
	var inv := _state.registry.get_investigator(intent.controller_id)
	inv.resource_pool -= intent.modified_resource_cost
	inv.actions_remaining -= intent.modified_action_cost
	## Uses Spend：Initiation 付费场合同核 L0 扣减（22 G10）；不 nest 效果 seq。
	for raw in intent.spend_token_costs:
		if not raw is Dictionary:
			return false
		var cost: Dictionary = raw
		var card_id := _resolve_spend_card_id(intent, cost)
		var kind := StringName(str(cost.get("kind", cost.get("token", "ammo"))))
		var amount := maxi(int(cost.get("amount", 1)), 1)
		if not _adjust_uses(card_id, kind, -amount):
			## 已扣行动/资源：调用方应 refund。
			return false
	return true


func refund(intent: InitiationIntent) -> void:
	var inv := _state.registry.get_investigator(intent.controller_id)
	if inv == null:
		return
	inv.resource_pool += intent.modified_resource_cost
	inv.actions_remaining += intent.modified_action_cost
	for raw in intent.spend_token_costs:
		if not raw is Dictionary:
			continue
		var cost: Dictionary = raw
		var card_id := _resolve_spend_card_id(intent, cost)
		var kind := StringName(str(cost.get("kind", cost.get("token", "ammo"))))
		var amount := maxi(int(cost.get("amount", 1)), 1)
		_adjust_uses(card_id, kind, amount)


static func _resolve_spend_card_id(intent: InitiationIntent, cost: Dictionary) -> StringName:
	var raw := str(cost.get("card_id", "source"))
	if raw == "" or raw == "source":
		return intent.source_id
	return StringName(raw)


func _adjust_uses(card_id: StringName, kind: StringName, delta: int) -> bool:
	if card_id == &"" or kind == &"" or delta == 0:
		return false
	if _mutator != null:
		return _mutator.adjust_marker(
			MarkerSlot.card(card_id, AhcEnums.MarkerKind.USES, kind),
			delta
		)
	## 无 mutator 时直接改 Domain（测试 / 早绑路径）。
	var card := _state.registry.get_card(card_id)
	if card == null:
		return false
	var have := int(card.tokens.uses.get(kind, 0))
	var next := have + delta
	if next < 0:
		return false
	if next == 0:
		card.tokens.uses.erase(kind)
	else:
		card.tokens.uses[kind] = next
	return true


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
