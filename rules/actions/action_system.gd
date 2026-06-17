class_name ActionSystem
extends RefCounted

var _state: GameStateStore
var _events: EventRecordLog
var _initiation: AbilityInitiationPipeline
var _log: GameLog
var _framework: FrameworkFlowEngine
var _skill_tests: SkillTestEngine
var _basic_actions: BasicActionResolver
var _aoo: AttackOfOpportunityResolver
var _mutator: StateMutator
var _resource_gain: ResourceGainService
var _draw_investigator: DrawInvestigatorService
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
	_skill_tests = skill_tests
	if skill_tests:
		_basic_actions = BasicActionResolver.new(state, skill_tests)
	if combat:
		_aoo = AttackOfOpportunityResolver.new(state, combat)
	_mutator = mutator


func bind_game_context(ctx: GameContext) -> void:
	_game_ctx = ctx
	if ctx:
		_resource_gain = ctx.resource_gain
		_draw_investigator = ctx.draw_investigator


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
	inv.actions_remaining -= action_cost
	_log.log(AhcEnums.LogCategory.ACTION, "action:%s" % action_type, {"inv": investigator_id, "cost": action_cost})
	var aoo_result := _resolve_aoo(investigator_id, action_type)
	var result := {"ok": true, "aoo_attacks": int(aoo_result.get("attacks", 0))}
	match action_type:
		AhcEnums.ActionType.RESOURCE:
			if _resource_gain and _game_ctx:
				_resource_gain.gain(
					_game_ctx,
					investigator_id,
					1,
					[&"resource_action"]
				)
			else:
				inv.resource_pool += 1
		AhcEnums.ActionType.DRAW:
			if _draw_investigator and _game_ctx:
				result = _draw_investigator.draw_cards(
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
			result = _run_basic_action(action_type, investigator_id, extra)
		AhcEnums.ActionType.INVESTIGATE:
			result = _run_basic_action(action_type, investigator_id, extra)
		AhcEnums.ActionType.FIGHT:
			result = _run_basic_action(action_type, investigator_id, extra)
		AhcEnums.ActionType.ENGAGE:
			result = _run_basic_action(action_type, investigator_id, extra)
		AhcEnums.ActionType.EVADE:
			result = _run_basic_action(action_type, investigator_id, extra)
	if not result.ok:
		inv.actions_remaining += action_cost
		return result
	result["aoo_attacks"] = int(aoo_result.get("attacks", 0))
	if _framework:
		_framework.on_action_completed(investigator_id)
	return result


func _resolve_aoo(investigator_id: StringName, action_type: AhcEnums.ActionType) -> Dictionary:
	if _aoo == null:
		return {"ok": true, "attacks": 0}
	return _aoo.resolve(investigator_id, action_type)


func _run_basic_action(
	action_type: AhcEnums.ActionType,
	investigator_id: StringName,
	extra: Dictionary
) -> Dictionary:
	if _basic_actions == null or _game_ctx == null:
		return {"ok": false, "error": "basic_actions_unavailable"}
	match action_type:
		AhcEnums.ActionType.MOVE:
			return _basic_actions.move(_game_ctx, investigator_id, extra)
		AhcEnums.ActionType.INVESTIGATE:
			return _basic_actions.investigate(_game_ctx, investigator_id, extra)
		AhcEnums.ActionType.FIGHT:
			return _basic_actions.fight(_game_ctx, investigator_id, extra)
		AhcEnums.ActionType.ENGAGE:
			return _basic_actions.engage(_game_ctx, investigator_id, extra)
		AhcEnums.ActionType.EVADE:
			return _basic_actions.evade(_game_ctx, investigator_id, extra)
	return {"ok": false, "error": "unsupported_action"}
