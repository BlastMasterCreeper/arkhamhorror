class_name CompositionExecutor
extends RefCounted

var _state: GameStateStore
var _registrations: RegistrationStore
var _mutator: StateMutator
var _log: GameLog
var _game_ctx: GameContext
var _draw: DrawInvestigatorService


func _init(
	state: GameStateStore,
	registrations: RegistrationStore,
	mutator: StateMutator,
	log: GameLog
) -> void:
	_state = state
	_registrations = registrations
	_mutator = mutator
	_log = log


func bind_game_context(ctx: GameContext) -> void:
	_game_ctx = ctx
	if ctx:
		_draw = ctx.draw_investigator


func execute(node: CompositionNode) -> void:
	_stamp_provenance(node)
	match node.kind:
		AhcEnums.CompositionNodeKind.SEQ:
			for child in node.children:
				execute(child)
		AhcEnums.CompositionNodeKind.ATOM:
			_execute_atom(node)
		AhcEnums.CompositionNodeKind.REGISTER:
			_execute_register(node)


func _stamp_provenance(node: CompositionNode) -> void:
	if node.provenance == null:
		return
	_log.log(
		AhcEnums.LogCategory.ABILITY,
		"composition:provenance",
		node.provenance.to_log_dict()
	)


func _execute_atom(node: CompositionNode) -> void:
	match node.atom_name:
		&"draw":
			if RestrictionEvaluator.blocks_draw(node.inv_id, _registrations):
				_log.log(AhcEnums.LogCategory.CARD, "composition:draw_blocked", {"inv": node.inv_id})
				return
			var amount := maxi(node.draw_amount, 1)
			if _draw and _game_ctx:
				_draw.draw_cards(_game_ctx, node.inv_id, amount, [&"composition_draw"])
			else:
				_mutator.execute_draw_instruction(node.inv_id, amount)
			_log.log(AhcEnums.LogCategory.CARD, "composition:draw", {"inv": node.inv_id, "amount": amount})
		&"take_horror":
			_mutator.take_horror(node.inv_id, maxi(node.atom_amount, 1))
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:take_horror",
				{"inv": node.inv_id, "amount": node.atom_amount}
			)
		&"discard_from_hand":
			_mutator.discard_from_hand(node.card_id, node.inv_id)
			_log.log(
				AhcEnums.LogCategory.CARD,
				"composition:discard_from_hand",
				{"inv": node.inv_id, "card": node.card_id}
			)
		_:
			push_warning("CompositionExecutor: unknown atom %s" % node.atom_name)


func _execute_register(node: CompositionNode) -> void:
	if node.register_template == null:
		return
	var reg_id := _registrations.register(node.register_template)
	_log.log(AhcEnums.LogCategory.ABILITY, "composition:register", {"reg": reg_id})
