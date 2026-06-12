class_name AbilityInitiationPipeline
extends RefCounted

var _state: GameStateStore
var _events: EventRecordLog
var _effects: EffectResolutionGraph
var _composition: CompositionExecutor
var _legality: InitiationLegalityChecker = InitiationLegalityChecker.new()


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


func can_initiate(intent: InitiationIntent, ctx: GameContext) -> bool:
	return _legality.dry_run(intent, ctx).has_any_created


func initiate(intent: InitiationIntent, ctx: GameContext) -> Dictionary:
	if intent == null or intent.composition == null:
		return {"ok": false, "error": "invalid_intent"}
	var hash := _state.compute_state_hash()
	var intent_payload := {"controller": intent.controller_id}
	_events.append_initiation(AhcEnums.InitiationStep.INIT_PRE_RESTRICTIONS, hash, intent_payload)
	if not can_initiate(intent, ctx):
		return {"ok": false, "error": "illegal"}
	_events.append_initiation(AhcEnums.InitiationStep.INIT_2_PAY_COSTS, hash, intent_payload)
	_events.append_initiation(AhcEnums.InitiationStep.INIT_4_RESOLVE, hash, intent_payload)
	if _composition:
		_composition.execute(intent.composition)
	return {"ok": true}
