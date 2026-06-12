class_name CompositionExecutor
extends RefCounted

var _state: GameStateStore
var _registrations: RegistrationStore
var _mutator: StateMutator
var _log: GameLog


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


func execute(node: CompositionNode) -> void:
	match node.kind:
		AhcEnums.CompositionNodeKind.SEQ:
			for child in node.children:
				execute(child)
		AhcEnums.CompositionNodeKind.ATOM:
			_execute_atom(node)
		AhcEnums.CompositionNodeKind.REGISTER:
			_execute_register(node)


func _execute_atom(node: CompositionNode) -> void:
	if node.atom_name == &"draw":
		if RestrictionEvaluator.blocks_draw(node.inv_id, _registrations):
			_log.log(AhcEnums.LogCategory.CARD, "composition:draw_blocked", {"inv": node.inv_id})
			return
		_mutator.draw_from_deck_to_hand(node.inv_id)
		_log.log(AhcEnums.LogCategory.CARD, "composition:draw", {"inv": node.inv_id})


func _execute_register(node: CompositionNode) -> void:
	if node.register_template == null:
		return
	var reg_id := _registrations.register(node.register_template)
	_log.log(AhcEnums.LogCategory.ABILITY, "composition:register", {"reg": reg_id})
