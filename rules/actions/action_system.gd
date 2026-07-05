class_name ActionSystem
extends RefCounted

var _state: GameStateStore
var _events: EventRecordLog
var _initiation: AbilityInitiationPipeline
var _log: GameLog
var _framework: FrameworkFlowEngine
var _aoo: AttackOfOpportunityResolver
var _mutator: StateMutator
var _action_sequences: ActionSequenceService
var _game_ctx: GameContext


func _init(
	state: GameStateStore,
	events: EventRecordLog,
	initiation: AbilityInitiationPipeline,
	log: GameLog,
	framework: FrameworkFlowEngine = null,
	skill_tests: SkillTestEngine = null,
	combat: CombatResolver = null,
	mutator: StateMutator = null
) -> void:
	_state = state
	_events = events
	_initiation = initiation
	_log = log
	_framework = framework
	if combat:
		_aoo = AttackOfOpportunityResolver.new(state, combat)
	_mutator = mutator


func bind_game_context(ctx: GameContext) -> void:
	_game_ctx = ctx
	if ctx:
		_action_sequences = ctx.action_sequences


## REST-E-PLAY：打出 asset/event — 经 Initiation Sequence（Grimoire V）。
func play_card(investigator_id: StringName, card_id: StringName) -> Dictionary:
	if _game_ctx == null or _initiation == null:
		return {"ok": false, "error": "no_context"}
	var inv := _state.registry.get_investigator(investigator_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var card := _state.registry.get_card(card_id)
	if card == null:
		return {"ok": false, "error": "unknown_card"}
	if card.zone != AhcEnums.Zone.HAND or not inv.hand.has(card_id):
		return {"ok": false, "error": "not_in_hand"}
	var def_id := card.id.definition_id
	var on_play := CardRegistry.build_on_play_composition(_game_ctx, investigator_id, card_id)
	var intent := InitiationIntent.play_card(
		investigator_id,
		card_id,
		CardRegistry.resource_cost(def_id),
		CardRegistry.action_cost(def_id),
		on_play
	)
	var res := _initiation.initiate(intent, _game_ctx)
	if res.ok:
		_log.log(
			AhcEnums.LogCategory.ACTION,
			"action:play_card",
			{"inv": investigator_id, "card": card_id}
		)
	return res


func execute(action_type: AhcEnums.ActionType, investigator_id: StringName, extra: Dictionary = {}) -> Dictionary:
	if _framework and not _framework.is_action_phase():
		return {"ok": false, "error": "not_action_phase"}
	if _framework and _state.active_investigator_id != investigator_id:
		return {"ok": false, "error": "not_active_investigator"}
	var inv := _state.registry.get_investigator(investigator_id)
	if inv == null:
		return {"ok": false, "error": "unknown_investigator"}
	var action_cost: int = int(extra.get("action_cost", 1))
	if inv.actions_remaining < action_cost:
		return {"ok": false, "error": "insufficient_actions"}
	var restriction_reason := _restriction_block_for_action(action_type, investigator_id)
	if restriction_reason != &"":
		return {"ok": false, "error": RestrictionEvaluator.api_error(restriction_reason)}
	inv.actions_remaining -= action_cost
	var spend_id := -1
	if _game_ctx != null and _game_ctx.stat_emitter != null:
		spend_id = _game_ctx.stat_emitter.record_action_spend(
			investigator_id, action_type, action_cost
		)
	_log.log(AhcEnums.LogCategory.ACTION, "action:%s" % action_type, {"inv": investigator_id, "cost": action_cost})
	var aoo_result := _resolve_aoo(investigator_id, action_type)
	var result := {"ok": true, "aoo_attacks": int(aoo_result.get("attacks", 0))}
	match action_type:
		AhcEnums.ActionType.RESOURCE:
			if _action_sequences and _game_ctx:
				var gain_result := _action_sequences.gain_resource(
					_game_ctx,
					investigator_id,
					1,
					[&"resource_action"]
				)
				result["amount"] = gain_result.get("amount", 1)
			elif _mutator:
				inv.resource_pool += 1
			else:
				inv.resource_pool += 1
		AhcEnums.ActionType.DRAW:
			if _action_sequences and _game_ctx:
				result = _action_sequences.draw(
					_game_ctx,
					investigator_id,
					1,
					[&"draw_action"]
				)
			elif _mutator:
				result = _mutator.perform_draw_action(investigator_id)
			else:
				result = {"ok": false, "error": "draw_unavailable"}
		AhcEnums.ActionType.MOVE:
			result = _run_resolved_action(AhcEnums.ActionType.MOVE, investigator_id, extra)
		AhcEnums.ActionType.INVESTIGATE:
			result = _run_resolved_action(AhcEnums.ActionType.INVESTIGATE, investigator_id, extra)
		AhcEnums.ActionType.FIGHT:
			result = _run_resolved_action(AhcEnums.ActionType.FIGHT, investigator_id, extra)
		AhcEnums.ActionType.ENGAGE:
			result = _run_resolved_action(AhcEnums.ActionType.ENGAGE, investigator_id, extra)
		AhcEnums.ActionType.EVADE:
			result = _run_resolved_action(AhcEnums.ActionType.EVADE, investigator_id, extra)
	if not result.ok:
		inv.actions_remaining += action_cost
		if spend_id >= 0 and _game_ctx != null and _game_ctx.stat_emitter != null:
			_game_ctx.stat_emitter.record_action_spend_void(spend_id, investigator_id, action_cost)
		return result
	result["aoo_attacks"] = int(aoo_result.get("attacks", 0))
	if _framework:
		_framework.on_action_completed(investigator_id)
	return result


func _resolve_aoo(investigator_id: StringName, action_type: AhcEnums.ActionType) -> Dictionary:
	if _aoo == null:
		return {"ok": true, "attacks": 0}
	return _aoo.resolve(investigator_id, action_type)


func _run_resolved_action(
	action_type: AhcEnums.ActionType,
	investigator_id: StringName,
	extra: Dictionary
) -> Dictionary:
	if _action_sequences == null or _game_ctx == null:
		return _run_basic_action(action_type, investigator_id, extra)
	match action_type:
		AhcEnums.ActionType.MOVE:
			return _action_sequences.move(_game_ctx, investigator_id, extra)
		AhcEnums.ActionType.INVESTIGATE:
			return _action_sequences.investigate(_game_ctx, investigator_id, extra)
		AhcEnums.ActionType.FIGHT:
			return _action_sequences.fight(_game_ctx, investigator_id, extra)
		AhcEnums.ActionType.ENGAGE:
			return _action_sequences.engage(_game_ctx, investigator_id, extra)
		AhcEnums.ActionType.EVADE:
			return _action_sequences.evade(_game_ctx, investigator_id, extra)
	return {"ok": false, "error": "unsupported_action"}


func _run_basic_action(
	action_type: AhcEnums.ActionType,
	investigator_id: StringName,
	extra: Dictionary
) -> Dictionary:
	if _game_ctx == null:
		return {"ok": false, "error": "basic_actions_unavailable"}
	return ActionFlowHandlers.resolve_basic_action(_game_ctx, action_type, {
		"inv_id": investigator_id,
		"extra": extra,
	})


func _registration_store() -> RegistrationStore:
	if _game_ctx == null:
		return null
	return _game_ctx.registrations


func _restriction_block_for_action(
	action_type: AhcEnums.ActionType,
	investigator_id: StringName
) -> StringName:
	var store := _registration_store()
	if store == null:
		return &""
	if action_type == AhcEnums.ActionType.DRAW:
		return RestrictionEvaluator.block_reason(
			RestrictionEvaluator.Intent.DRAW,
			investigator_id,
			store
		)
	return &""
