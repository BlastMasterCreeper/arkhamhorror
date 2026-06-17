class_name ResourceGainService
extends RefCounted

var _mutator: StateMutator


func _init(mutator: StateMutator) -> void:
	_mutator = mutator


func gain(game_ctx: GameContext, controller_id: StringName, base_amount: int, source_tags: Array[StringName]) -> int:
	if game_ctx == null or game_ctx.sequences == null:
		_mutator.add_resources(controller_id, base_amount)
		return base_amount
	var trigger := TriggeringCondition.gain_resource(controller_id, source_tags)
	var resolved := [base_amount]
	game_ctx.sequences.run(
		trigger,
		func() -> void:
			var app_ctx := game_ctx.sequences.build_application_context(AhcEnums.SequencePhase.RESOLVE)
			var q := ModifierQuery.new()
			q.controller_id = controller_id
			q.stat = AhcEnums.StatRef.RESOURCE_GAIN_AMOUNT
			var amount := game_ctx.modifiers.compute(base_amount, q, app_ctx)
			_mutator.add_resources(controller_id, amount)
			game_ctx.memory.set_referent(controller_id, &"last_gain_amount", amount)
			resolved[0] = amount
	)
	return int(resolved[0])
