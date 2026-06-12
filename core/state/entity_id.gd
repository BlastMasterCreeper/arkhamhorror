class_name EntityId
extends RefCounted

var kind: AhcEnums.EntityKind
var instance_id: StringName
var definition_id: StringName


static func create(p_kind: AhcEnums.EntityKind, p_instance_id: StringName, p_definition_id: StringName) -> EntityId:
	var id := EntityId.new()
	id.kind = p_kind
	id.instance_id = p_instance_id
	id.definition_id = p_definition_id
	return id
