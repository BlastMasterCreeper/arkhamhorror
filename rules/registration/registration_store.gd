class_name RegistrationStore
extends RefCounted

var _entries: Array[Registration] = []
var _next_id: int = 0


func register(template: RegistrationTemplate) -> StringName:
	_next_id += 1
	var reg_id := StringName("reg_%d" % _next_id)
	var reg := Registration.from_template(template, reg_id)
	_entries.append(reg)
	return reg_id


func unregister(id: StringName) -> void:
	for i in range(_entries.size() - 1, -1, -1):
		if _entries[i].id == id:
			_entries.remove_at(i)
			return


func unregister_by_encounter_frame(frame_id: StringName) -> void:
	if frame_id == &"":
		return
	var to_remove: Array[StringName] = []
	for reg in _entries:
		if reg.lifetime_kind == AhcEnums.LifetimeKind.WHILE_ENCOUNTER_FRAME \
				and reg.encounter_frame_id == frame_id:
			to_remove.append(reg.id)
	for id in to_remove:
		unregister(id)


func count() -> int:
	return _entries.size()


func collect_modifiers(controller_id: StringName) -> Array[ModifierPayload]:
	var out: Array[ModifierPayload] = []
	for reg in _entries:
		if reg.controller_id != controller_id and reg.controller_id != &"":
			continue
		for buff in reg.buffs:
			if buff.type == AhcEnums.BuffType.MODIFIER and buff.modifier:
				out.append(buff.modifier)
	return out


func all_registrations() -> Array[Registration]:
	return _entries.duplicate()


func collect_listeners(timing_name: StringName) -> Array[ListenerEntry]:
	var out: Array[ListenerEntry] = []
	for reg in _entries:
		for buff in reg.buffs:
			if buff.type != AhcEnums.BuffType.LISTENER or buff.listener == null:
				continue
			if buff.listener.timing != timing_name:
				continue
			var entry := ListenerEntry.new()
			entry.reg_id = reg.id
			entry.lifetime_kind = reg.lifetime_kind
			entry.composition = buff.listener.composition
			out.append(entry)
	return out


func duplicate_store() -> RegistrationStore:
	var copy := RegistrationStore.new()
	copy._next_id = _next_id
	for reg in _entries:
		var r := Registration.new()
		r.id = reg.id
		r.controller_id = reg.controller_id
		r.lifetime_kind = reg.lifetime_kind
		r.duration = reg.duration
		r.encounter_frame_id = reg.encounter_frame_id
		r.buffs = reg.buffs.duplicate()
		copy._entries.append(r)
	return copy


func tick_duration(anchor: AhcEnums.DurationAnchorKind) -> void:
	var to_remove: Array[StringName] = []
	for reg in _entries:
		if reg.lifetime_kind == AhcEnums.LifetimeKind.DURATION and reg.duration == anchor:
			to_remove.append(reg.id)
	for id in to_remove:
		unregister(id)
