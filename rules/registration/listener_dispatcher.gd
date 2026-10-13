class_name ListenerDispatcher
extends RefCounted

var _registrations: RegistrationStore
var _game_ctx: GameContext = null


func _init(registrations: RegistrationStore, game_ctx: GameContext = null) -> void:
	_registrations = registrations
	_game_ctx = game_ctx


func bind_game_context(ctx: GameContext) -> void:
	_game_ctx = ctx


func dispatch(timing_name: StringName) -> int:
	var fired := 0
	for entry in _registrations.collect_listeners(timing_name):
		if entry.composition == null:
			continue
		CompositionMount.resolve_ability(
			_game_ctx,
			entry.composition,
			entry.controller_id,
			&"",
			entry.reg_id
		)
		fired += 1
		if entry.lifetime_kind == AhcEnums.LifetimeKind.UNTIL_FIRED:
			_registrations.unregister(entry.reg_id)
	return fired
