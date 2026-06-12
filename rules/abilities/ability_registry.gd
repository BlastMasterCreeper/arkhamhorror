class_name AbilityRegistry
extends RefCounted

var _forced: Dictionary = {}  # timing -> Array


func register_forced(timing: StringName, handler: Callable) -> void:
	if not _forced.has(timing):
		_forced[timing] = []
	(_forced[timing] as Array).append(handler)


func get_forced_listeners(timing: StringName) -> Array:
	return _forced.get(timing, [])
