class_name EvaluationContext
extends RefCounted

var app: ApplicationContext = null
var inv_id: StringName = &""
var turn_id: int = 0
var round_id: int = 0
var as_of_seq: int = -1


static func from_game(app_ctx: ApplicationContext, state: GameStateStore, events: EventRecordLog) -> EvaluationContext:
	var ctx := EvaluationContext.new()
	ctx.app = app_ctx
	ctx.round_id = state.round_number if state != null else 0
	var inv := &""
	if app_ctx != null and app_ctx.controller_id != &"":
		inv = app_ctx.controller_id
	elif state != null:
		inv = state.turn_owner_id if state.turn_owner_id != &"" else state.active_investigator_id
	ctx.inv_id = inv
	ctx.turn_id = state.turn_id if state != null else 0
	ctx.as_of_seq = events.last_seq() if events != null else -1
	return ctx


func scope() -> StatScope:
	return StatScope.for_inv_turn(inv_id, turn_id)
