class_name CardRegistry
extends RefCounted

static var _definitions: Dictionary = {}


static func register_definition(definition_id: StringName, _data: Dictionary = {}) -> void:
	_definitions[definition_id] = _data
