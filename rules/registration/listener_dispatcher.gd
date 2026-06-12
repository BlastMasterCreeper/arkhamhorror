class_name ListenerDispatcher
extends RefCounted

var _registrations: RegistrationStore
var _composition: CompositionExecutor


func _init(registrations: RegistrationStore, composition: CompositionExecutor) -> void:
	_registrations = registrations
	_composition = composition


func dispatch(timing_name: StringName) -> int:
	var fired := 0
	for entry in _registrations.collect_listeners(timing_name):
		if entry.composition == null:
			continue
		_composition.execute(entry.composition)
		fired += 1
		if entry.lifetime_kind == AhcEnums.LifetimeKind.UNTIL_FIRED:
			_registrations.unregister(entry.reg_id)
	return fired
