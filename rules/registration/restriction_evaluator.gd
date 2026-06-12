class_name RestrictionEvaluator
extends RefCounted


static func blocks_draw(controller_id: StringName, store: RegistrationStore) -> bool:
	for payload in _collect_restrictions(controller_id, store):
		if payload.kind == AhcEnums.RestrictionKind.FORBID_DRAW:
			return true
	return false


static func _collect_restrictions(controller_id: StringName, store: RegistrationStore) -> Array[RestrictionPayload]:
	var out: Array[RestrictionPayload] = []
	for reg in store.all_registrations():
		if reg.controller_id != controller_id and reg.controller_id != &"":
			continue
		for buff in reg.buffs:
			if buff.type == AhcEnums.BuffType.RESTRICTION and buff.restriction:
				out.append(buff.restriction)
	return out
